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


--*********************************************************
-- 移動系関数
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