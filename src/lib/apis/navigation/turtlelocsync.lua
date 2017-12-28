-----------------------------------------------------------
-- turtleLocSync(lua)
-- ローカル位置同期API
-- タートルの移動時にローカル位置座標の同期を行うよ
-- 位置座標の変化時に、座標をファイルに保存するよ
-- 同期オブジェクト生成時に、保存したファイルから座標を読み込むよ
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/const')
os.loadAPI('/lib/apis/bearingutils')

local PATH_LOCAL_LOCATION = '/local_location'

--*********************************************************
-- モンキーパッチ
--*********************************************************
-- プログラムが終了しても、タートルOSが起動している間は
-- os.loadAPI()で読み込んだAPIは読み込まれたままだよ
-- モンキーパッチを多重に当ててしまうのを防がんといかんから
-- 初回時だけモンキーパッチをあてるよ
local function patchMoveingFunc()
  -----------------------------------------------------------
  -- タートルAPIへのモンキーパッチ
  -- turtle.forward()など、タートルAPIの移動・回転関数の実行時に、
  -- ローカル座標を正しく更新する関数が自動で実行されるように
  -- 各関数にモンキーパッチを当てるよ
  -----------------------------------------------------------
  -- 移動系関数にモンキーパッチを当てる関数や
  local function patch(org_func_name, direction, func_name)
    local org_func = turtle[org_func_name]
    turtle[org_func_name] = function()
      local result = org_func()
      if result then
        turtle.synchronizer[func_name](direction)
      end
      return result
    end
  end

  -----------------------------------------------------------
  -- その1 移動系関数
  -- 移動が成功した場合、local_location.move()を
  -- 移動方向を引数として実行するようにするねん
  -----------------------------------------------------------
  -- 移動関数名と、方向の対応リスト
  local moveing_functions = {
    forward = const.FORWARD,
    back    = const.BACK,
    up      = const.UP,
    down    = const.DOWN
  }

  -- モンキーパッチを当てるよ
  for k, v in pairs(moveing_functions) do
    patch(k, v, 'move')
  end

  -----------------------------------------------------------
  -- その2 回転系関数
  -- 移動系と同じように、回転系関数も変更するよ
  -- 回転系関数成功時に、local_location.turn()を実行するようにするよ
  -----------------------------------------------------------
  -- 回転関数名と、方向の対応リスト
  local turning_functions = {
    turnLeft  = const.LEFT,
    turnRight = const.RIGHT
  }

  -- モンキーパッチを当てるよ
  for k, v in pairs(turning_functions) do
    patch(k, v, 'turn')
  end
end

-----------------------------------------------------------
-- 位置同期機構を初期化するよ
-----------------------------------------------------------
local function initialize()
  patchMoveingFunc()
end

-----------------------------------------------------------
-- location_syncオブジェクトの生成
-- @param location 同期させるlocationオブジェクト
-----------------------------------------------------------
function new(location)
  if not turtle['synchronizer'] then
    -- turtle APIにsynchronizerが未登録の場合まず初期化するよ
    print('turtleapi patching...')
    initialize()
  end

  local synchronizer = {}
  local self = synchronizer

  -----------------------------------------------------------
  -- synchronizer.move()で使用するテーブル
  -- directionに対し、座標を相対移動させる関数を格納している
  -----------------------------------------------------------
  local _move = {}
  _move[const.NORTH] = function(n) return location.translate( 0,  0, -n) end
  _move[const.SOUTH] = function(n) return location.translate( 0,  0,  n) end
  _move[const.EAST ] = function(n) return location.translate( n,  0,  0) end
  _move[const.WEST ] = function(n) return location.translate(-n,  0,  0) end
  _move[const.UP   ] = function(n) return location.translate( 0,  n,  0) end
  _move[const.DOWN ] = function(n) return location.translate( 0, -n,  0) end

  _move[const.FORWARD] = function(n) return _move[location.getBearing()](n) end
  _move[const.BACK   ] = function(n)
    return _move[bearingutils.getOpposite(location.getBearing())](n)
  end

  -----------------------------------------------------------
  -- 座標を指定方向へ、指定距離だけ相対移動させる
  -- @param direction 相対移動させる方向 東西南北 前後上下
  -- @param distance 相対移動させる距離 省略時は1
  -----------------------------------------------------------
  -- 移動同期
  function synchronizer.move(direction, distance)
    distance = distance or 1
    local f = _move[direction]
    assert(f, "synchronizer.move() received invalid direction '" .. direction .."'")
    if f(distance) then
      self.saveLocation()
      return true
    end
    return false
  end

  -----------------------------------------------------------
  -- location.turn()で使用するテーブル
  -- directionごとに、対応する向き変更関数を格納している
  -----------------------------------------------------------
  local _turn = {}
  for _i, bearing in ipairs { const.NORTH, const.SOUTH, const.EAST, const.WEST } do
    _turn[bearing] = function()
      location.setBearing(bearing)
    end
  end

  _turn[const.RIGHT] = function()
    return _turn[ bearingutils.getRightSide(location.getBearing()) ]()
  end
  _turn[const.LEFT ] = function()
    return _turn[ bearingutils.getLeftSide (location.getBearing()) ]()
  end

  -----------------------------------------------------------
  -- 向きを指定方向へ変更する
  -- @param direction 変更する方向 東西南北 左右
  --   const API で定義
  -----------------------------------------------------------
  function synchronizer.turn(direction)
    local f = _turn[direction]
    assert(f, "synchronizer.turn() received invalid direction '" .. direction .."'")
    if f() then
      self.saveLocation()
      return true
    end
    return false
  end

  -----------------------------------------------------------
  -- 位置情報ファイル
  -- ローカル座標とタートルが向いている方角が記録されたファイル
  -- 1行目にx座標が、2･3･4行目にそれぞれy, z, 方角が記録されている。
  -----------------------------------------------------------
  -- 位置情報をファイルに保存する
  -----------------------------------------------------------
  function synchronizer.saveLocation()
    local fh = fs.open(PATH_LOCAL_LOCATION, 'w')
    local x, y, z = location.getCoord()
    local bearing = location.getBearing()
    -- 書き込み
    for _i, value in ipairs { x, y, z, bearing } do
      fh.writeLine(value)
    end
    fh.close()
    return true
  end

  -----------------------------------------------------------
  -- 位置情報をファイルから読み込む
  -----------------------------------------------------------
  function synchronizer.loadLocation()
    local fh = fs.open(PATH_LOCAL_LOCATION, 'r')
    -- 読み込み
    local lines = {}
    for i=1, 3 do
      lines[i] = tonumber(fh.readLine())
    end
    local x, y, z = unpack(lines)
    local bearing = fh.readLine()
    fh.close()

    location.setCoord(x, y, z)
    location.setBearing(bearing)
    return true
  end

  return synchronizer
end

-----------------------------------------------------------
-- タートルの移動と同期させるlocationオブジェクトを設定するよ
-- @param location 同期させるlocationオブジェクト
-----------------------------------------------------------
function setSynchronizer(location)
  turtle.synchronizer = new(location)
  turtle.synchronizer.loadLocation()
end
