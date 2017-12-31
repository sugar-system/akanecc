-----------------------------------------------------------
-- bearingutils(lua)
-- 方角ユーティリティAPI
-- 方角に関わる便利関数をあつめたよ
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/const')

-----------------------------------------------------------
-- getOpposite()で使うテーブル
-- 反対の方角が入ってるよ
-----------------------------------------------------------
local _opposite = {}
_opposite[const.NORTH] = const.SOUTH
_opposite[const.SOUTH] = const.NORTH
_opposite[const.EAST ] = const.WEST
_opposite[const.WEST ] = const.EAST

-----------------------------------------------------------
-- 引数の方向の反対を取得するよ
-- 東西南北限定やねん
-- 方向はconst APIで定義されてるのを使ってね
-- 想定外の引数を与えられた場合、nilを返すよ
-- @param bearing 方角
-- @return 反対方向
-----------------------------------------------------------
function getOpposite(bearing)
  return _opposite[bearing]
end

-----------------------------------------------------------
-- getRightSide()で使うテーブル
-- 右側の方角が入ってるよ
-----------------------------------------------------------
local _right_side = {}
_right_side[const.NORTH] = const.EAST
_right_side[const.SOUTH] = const.WEST
_right_side[const.EAST ] = const.SOUTH
_right_side[const.WEST ] = const.NORTH

-----------------------------------------------------------
-- 引数の方向の右方向を取得するよ
-- 他に関してはgetOpposite()に準ずるよ
-- @param bearing 方角
-- @return 右方向
-----------------------------------------------------------
function getRightSide(bearing)
  return _right_side[bearing]
end

-----------------------------------------------------------
-- getLeftSide()で使うテーブル
-- 左側の方角が入ってるよ
-----------------------------------------------------------
local _left_side = {}
for _i, v in ipairs { const.NORTH, const.SOUTH, const.EAST, const.WEST } do
  _left_side[v] = getOpposite(getRightSide(v)) -- 左は右の反対
end

-----------------------------------------------------------
-- 引数の方向の左方向を取得するよ
-- getRightSide()の左版やから詳しくはあっち見てな
-- @param bearing 方角
-- @return 左方向
-- @see getRightSide()
-----------------------------------------------------------
function getLeftSide(bearing)
  return _left_side[bearing]
end

-----------------------------------------------------------
-- getMatchingAxis()で使うテーブル
-- 左側の方角が入ってるよ
-----------------------------------------------------------
local _matching_axis = {
  [const.NORTH] = { 'z', false },
  [const.SOUTH] = { 'z', true  },
  [const.WEST ] = { 'x', false },
  [const.EAST ] = { 'x', true  },
  [const.DOWN ] = { 'y', false },
  [const.UP   ] = { 'y', true  },
}
-----------------------------------------------------------
-- 方角に対応する座標軸と正負を返すよ
-- @param bearing 方角
-- @return 対応する座標軸を現す文字列 [x / y / z]
-- @return 符号の正負。[正:true / 負:false]
-----------------------------------------------------------
function getMatchingAxis(bearing)
  return unpack( _matching_axis[bearing] )
end

-----------------------------------------------------------
-- 移動軸と移動距離の正負から移動方角を得るテーブル
local _move_bearing = { x = {}, y = {}, z = {} }
local _directions =
{ const.NORTH, const.SOUTH, const.WEST, const.EAST, const.UP, const.DOWN }
for _i, direction in ipairs(_directions) do
  local axis, sign = getMatchingAxis(direction)
  _move_bearing[axis][sign] = direction
end

-----------------------------------------------------------
-- 移動軸とそれに対する相対座標から、移動方角を取得する
-- @param axis 移動軸
-- @param coord 移動先の相対座標
-- @return 移動方角 / 相対座標0のときはnil
-----------------------------------------------------------
function getMoveBearing(axis, coord)
  if coord == 0 then return nil end
  return _move_bearing[axis][coord > 0]
end
