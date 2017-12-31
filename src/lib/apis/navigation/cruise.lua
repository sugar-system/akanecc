-----------------------------------------------------------
-- cruise(lua)
-- タートル巡航API
-- タートルでの自動移動を扱う
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/akaneutils')

-----------------------------------------------------------
-- 軸順文字列をテーブル型に変換する
-- @param order_string 軸順文字列
-- @return 軸順テーブル
-----------------------------------------------------------
function stringToAxisOrder(order_string)
  return akaneutils.stringToArray(order_string)
end

-----------------------------------------------------------
-- 平面塗りつぶし移動において、1行ごとに進む、第2軸の距離を求める
-- 第2軸がnilの場合、進むべき距離は0となる
-- @param relative_dest 相対移動距離テーブル
-- @param spacing_table 間隔テーブル
-- @aram axis 第2軸(文字列)
-- @return 1行ごとに進む距離
-----------------------------------------------------------
function calcPitch(relative_dest, spacing_table, axis)
  if not axis then return 0 end
  local pitch = spacing_table[axis] + 1
  if relative_dest[axis] < 0 then
    pitch = pitch * -1
  end
  return pitch
end

-----------------------------------------------------------
-- スタート時に向いている方角と、移動したい相対座標から、
-- 最初はどっちから移動するべきか調べるよ
-- @param start_bearing スタート時の向き
-- @param relative_dest 相対移動距離。 { x = dx, y = dy, z = dz }なテーブル
-- @return 最初に移動すべき軸名 / なければnil
-----------------------------------------------------------
function getFirstBearing(start_bearing, relative_dest)
  -- まず各軸の移動方向をしらべるよ
  local move_bearings = {}
  for _i, axis in ipairs{ 'x', 'y', 'z' } do -- yも一応
    move_bearings[axis] = bearingutils.getMoveBearing(axis, relative_dest[axis])
  end

  -- スタート時の正面、右、左と調べていって、一致した時点でその軸が対象となるよ
  local relative_bearings = {
    start_bearing,
    bearingutils.getRightSide(start_bearing),
    bearingutils.getLeftSide (start_bearing)
  }
  for _i, relative_bearing in ipairs(relative_bearings) do
    for axis, move_bearing in ipairs(move_bearings) do
      if relative_bearing == move_bearing then
        return move_bearing
      end
    end
  end

  -- 該当なしならなんでもいいよ
  return next(move_bearings)
end

-----------------------------------------------------------
-- 塗りつぶし移動したい相対座標と間隔から、各軸に対し、
-- その軸を第2軸に設定した場合の移動列数を計算する
-- @param relative_dest 相対移動距離テーブル
-- @param spacing_table 間隔テーブル
-- @return 列数テーブル
-----------------------------------------------------------
function calcRowCountTable(relative_dest, spacing_table)
  local row_count = {}
  for _i, axis in ipairs{ 'x', 'y', 'z' } do
    if relative_dest[axis] ~= 0 then
      row_count[axis] = 
        math.ceil(math.abs(relative_dest[axis]) / (spacing_table[axis] + 1))
    end
  end
  return row_count
end

-----------------------------------------------------------
-- 平面塗りつぶし移動時のチェックポイントリストを生成する
-- @param p1 塗りつぶし対象領域(四角形)の頂点
-- @param p2 p1の対頂点
-- @param start 塗りつぶし開始地点
-- @param order 移動軸順
-- @return 列数テーブル
-----------------------------------------------------------
function createCheckpointsPlane(p1, p2, start, order)
  -- 塗りつぶし領域の4頂点
  -- 平面なので第3軸は考慮しない
  local points = {}
  points[1] = {
    [order[1]] = p1[order[1]],
    [order[2]] = p1[order[2]]
  }
  points[2] = {
    [order[1]] = p1[order[1]],
    [order[2]] = p2[order[2]]
  }
  points[3] = {
    [order[1]] = p2[order[1]],
    [order[2]] = p1[order[2]]
  }
  points[4] = {
    [order[1]] = p2[order[1]],
    [order[2]] = p2[order[2]]
  }

  local checkpoints = {}
  for _i, point in ipairs(points) do
    table.insert(checkpoints, { point = point, passed = false })
  end
  return checkpoints
end
