-----------------------------------------------------------
-- turtlenavi(lua)
-- ローカル座標ナビAPI
-- プログラム開始時の位置を原点とした
-- タートル固有のローカル座標系によるナビゲーション
-- moduleそのものをグローバルシングルトンクラスのインスタンスとして使用する
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/const')
os.loadAPI('/lib/apis/navigation/turtleloc')
os.loadAPI('/lib/apis/navigation/turtlelocsync')
os.loadAPI('/lib/apis/turtleapis')

-----------------------------------------------------------
-- 初期化時のローカル座標
local INITIAL_X = 0
local INITIAL_Y = 0
local INITIAL_Z = 0

-- 初期化時の方角
local INITIAL_BEARING = const.NORTH

-- locationオブジェクト
local location = turtleloc.new()

-----------------------------------------------------------
-- 現在地の座標を設定するよ
-- @param new_x 設定するX座標
-- @param new_y 設定するY座標
-- @param new_z 設定するZ座標
-----------------------------------------------------------
function setCoord(new_x, new_y, new_z)
  return location.setCoord(new_x, new_y, new_z)
end

-----------------------------------------------------------
-- 現在地の座標を取得できるよ
-- @return X座標
-- @return Y座標
-- @return Z座標
-----------------------------------------------------------
function getCoord()
  -- いまのところローカルシンクロナイザしかないから必要ないけど、
  -- GPSシンクロナイザなどを実装した際には
  -- ここでシンクロナイザにGPSからの座標取得を行わせる必要があるよ。
  -- 例えば、turtle.synchronizer.synchronize()みたいな関数？
  return location.getCoord()
end

-----------------------------------------------------------
-- 現在地のローカル座標テーブルを取得するよ
-- @return ローカル座標テーブル
-----------------------------------------------------------
function getCoordTable()
  local x, y, z = getCoord()
  return { x = x, y = y, z = z }
end

-----------------------------------------------------------
-- 現在のタートルの向きを設定するよ
-- @param new_bearing 設定する向き
-----------------------------------------------------------
function setBearing(new_bearing)
  location.setBearing(new_bearing)
end

-----------------------------------------------------------
-- 現在のタートルの向きを取得するよ
-- @return 現在の向き
-----------------------------------------------------------
function getBearing()
  return location.getBearing()
end

-----------------------------------------------------------
-- 現在地の座標と向いてる方角を初期化するよ
-----------------------------------------------------------
function initLocation()
  setCoord(INITIAL_X, INITIAL_Y, INITIAL_Z)
  setBearing(INITIAL_BEARING)
end

-----------------------------------------------------------
-- 初期処理
-----------------------------------------------------------
initLocation()

-- タートルの移動関数と同期
turtlelocsync.setSynchronizer(location)


-----------------------------------------------------------
-- 補助関数
-----------------------------------------------------------
-- 2つの座標間の相対座標を計算するよ
-- @param src  基点の座標
-- @param dest 目的点の座標
-----------------------------------------------------------
function calcRelativeCoord(src, dest)
  local relative_coord = {}
  for i=1, 3 do
    relative_coord[i] = dest[i] - src[i]
  end
  return unpack(relative_coord)
end

--*********************************************************
-- 回転関数
--*********************************************************

-- ある方角を向いてる時、
-- 特定の方角に向きを変える場合に
-- どう回転すればいいかを格納したテーブルやで
local _bearing_relation = {
  [const.NORTH] = {
    [const.NORTH] = const.FORWARD,
    [const.SOUTH] = const.BACK,
    [const.WEST ] = const.LEFT,
    [const.EAST ] = const.RIGHT,
  },
  [const.SOUTH] = {
    [const.NORTH] = const.BACK,
    [const.SOUTH] = const.FORWARD,
    [const.WEST ] = const.RIGHT,
    [const.EAST ] = const.LEFT,
  },
  [const.WEST] = {
    [const.NORTH] = const.RIGHT,
    [const.SOUTH] = const.LEFT,
    [const.WEST ] = const.FORWARD,
    [const.EAST ] = const.BACK,
  },
  [const.EAST] = {
    [const.NORTH] = const.LEFT,
    [const.SOUTH] = const.RIGHT,
    [const.WEST ] = const.BACK,
    [const.EAST ] = const.FORWARD,
  },
}

-----------------------------------------------------------
-- タートルに指定した方角を向かせるよ
-- 方角は東西南北のどれかやで
-- 右とか左向かせたい場合はturtleapis.TURN()を使ってな
-- @param bearing 方角
-----------------------------------------------------------
function faceTo(bearing)
  local bearing = _bearing_relation[getBearing()][bearing]
  assert(bearing, 'bearing error ('.. getBearing() ..'->'.. bearing ..')')
  return turtleapis.TURN(bearing)
end


--*****************************************************************************
--* 移動関数
--*****************************************************************************

-----------------------------------------------------------
-- 現在向いている方角と、移動したい相対座標から、
-- 軸をどういう順番で移動するのが早いか調べるよ
-- @param relative_dest 相対移動距離。 { x = dx, y = dy, z = dz }なテーブル
-- @return 軸の順番を示す文字列
-----------------------------------------------------------
local function getBestAxisOrder(relative_dest)
  -- *** Y軸は最後に移動することにするから、最後まで無視しちゃうよ ***
  local order = ''
  -- まず各軸の移動方向をしらべるよ
  local bearings = {}
  for _i, axis in ipairs{ 'x', 'z' } do
    bearings[axis] = bearingutils.getMoveBearing(axis, relative_dest[axis] > 0)
  end

  -- 相対方角(現在の正面・右・左・後ろ、の方角)を格納したテーブル
  -- この順番で、X・Y軸の移動方角と一致するか調べて、該当した方角から移動するのが早いよ
  local relative_bearings = {
    getBearing(),
    bearingutils.getRightSide(getBearing()),
    bearingutils.getLeftSide (getBearing()),
    bearingutils.getOpposite (getBearing()),
  }
  -- 相対方角とX・Z軸の移動方向を比べて、X・Z軸どっちを先に移動するか考えるよ
  for _i, bearing in ipairs(relative_bearings) do
    for _i, axis in ipairs{ 'x', 'z' } do
      if bearings[axis] == bearing then
        order = order .. axis
      end
    end
  end
  -- Y軸は最後に移動するよ
  order = order ..'y'
  return order
end

-----------------------------------------------------------
-- 上のgetBestAxisOrder()とだいたい同じだけど、
-- 優先しなければならない、基礎にする移動順を指定できるよ。
-- @param base_order 基礎にする移動順。基準順。これにたいする変更は許されない。
-- @param relative_dest 相対移動距離。 { x = dx, y = dy, z = dz }なテーブル
-- @return 軸の順番を示す文字列
-----------------------------------------------------------
local function getAxisOrder(base_order, relative_dest)
  -- 基準順は無条件で確定だよ
  local order = base_order or ''

  -- 基準を考慮しない、最適な移動順を探すよ
  local best_order = getBestAxisOrder(relative_dest)

  -- 基準順と最適な移動順を比べて、移動順を決定するよ
  for i=1, 3 do
    local axis = string.sub(best_order, i, i)
    if not string.find(order, axis) then
      -- 対象の軸がまだなければ、最後にくっつけるよ
      order = order .. axis
    end
  end
  print(order)
  return order
end

-----------------------------------------------------------
-- 移動軸と移動距離を指定してタートルを移動させるよ
-- @param axis 移動軸。xyzのどれかを文字列で指定
-- @param distance 移動距離。負でもOK
-- @param permit_dig 邪魔なブロックのdig許可
-----------------------------------------------------------
local function moveByCoord(axis, distance, permit_dig)
  -- 軸と移動距離の正負から移動する方角を決める
  local bearing = bearingutils.getMoveBearing(axis, distance >= 0)

  -- 移動
  for i=1, math.abs(distance) do
    turtleapis.STEP(bearing, true, permit_dig)
  end
end

-----------------------------------------------------------
-- タートルを指定座標に移動させるよ
-- @param dest 移動先の座標配列 { x, y, z }
-- @param permit_dig 移動途中で邪魔なブロックのdig()許可
-- @param order 座標軸の優先順 'xz'のような文字列。省略可
-----------------------------------------------------------
function moveTo(dest, permit_dig, order)
  -- 移動量
  local dx, dy, dz = calcRelativeCoord({getCoord()}, dest)
  local relative_dest = { x = dx, y = dy, z = dz }

  -- 回転回数が少なくなるような移動順を取得
  order = getAxisOrder(order, relative_dest)

  -- 移動処理
  for i=1, 3 do
    local axis = string.sub(order, i, i)
    moveByCoord(axis, relative_dest[axis], permit_dig)
  end
end

--*********************************************************
-- turtleapisへの追加
--*********************************************************
-- turtleapisの各関数に、方角を引数にするバージョンを追加するよ

-- 追加対象関数
local _turtle_api_names = {
  'DROP',
  'ATTACK',
  'DIG',
  'PLACE',
  'DETECT',
  'INSPECT',
  'COMPARE',
  'SUCK',
  'STEP',
  'STEP_CERTAINLY',
}

-- 方角
local _bearings = { const.NORTH, const.SOUTH, const.WEST, const.EAST }

-- 対象APIに各方角バージョンを追加するよ
for _i, api_name in ipairs(_turtle_api_names) do
  for _i, bearing in ipairs(_bearings) do
    local api = turtleapis[api_name]

    -- 関数生成
    api[bearing] = function(not_return, ...)
      local original_bearing = getBearing()
      -- 指定された方角を向くよ
      if not faceTo(bearing) then
        return false
      end
      -- apiを実行するよ
      local result = api(const.FORWARD, ...)
      -- 元の向きに戻るよ
      if not not_return then
        faceTo(original_bearing)
      end
      return result
    end

  end
end

-- TURN
for _i, bearing in ipairs(_bearings) do
  turtleapis.TURN[bearing] = function() return faceTo(bearing) end
end
