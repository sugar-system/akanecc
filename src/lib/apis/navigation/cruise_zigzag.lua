-----------------------------------------------------------
-- zigzag(lua)
-- ジグザグAPI
-- タートルで平面を塗りつぶすように移動する
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/navigation/cruise')

-----------------------------------------------------------
-- zigzagのデフォルトコールバック
-----------------------------------------------------------
local function defaultCallback()
  os.queueEvent(turtlenavi.EVENT_ZIGZAG_STEP)
end

-----------------------------------------------------------
-- ジグザグ移動クラス初期化
-----------------------------------------------------------
local function initialize(zigzag, start, dest, permit_dig, callback, spacing, order)
  zigzag.reset()

  zigzag.setStart(start)
  zigzag.setDest(dest)
  zigzag.setPermitDig(permit_dig)
  zigzag.setCallback(callback)
  zigzag.setSpacing(spacing)
  zigzag.setOrder(order)
end

-----------------------------------------------------------
-- ジグザグ移動クラスを生成して返す
-----------------------------------------------------------
-- 指定範囲を塗りつぶすように、タートルを移動させるよ
-- 床を貼る時なんかにつかえます
-- 塗りつぶす範囲はstartとdestを頂点とする平面だよ
-- @param start 開始点の座標(配列) { x, y, z }
-- @param dest  終了点の座標(配列) { x, y, z }
-- @param permit_dig 移動途中で邪魔なブロックのdig()許可
-- @param callback 1歩移動する度に呼ばれるコールバック関数
-- @param spacing 各軸の塗りつぶし間隔(?行おき)(配列) { x, y, z }
-- @param order 座標軸の優先順 'xz'のような文字列。省略可
-----------------------------------------------------------
function new(start, dest, permit_dig, callback, spacing, order)
  local zigzag = {}
  local self = zigzag

  order = order or ''

  -----------------------------------------------------------
  -- setter / getter
  -----------------------------------------------------------
  function zigzag.setCallback(callback)
    self.callback = callback or defaultCallback
  end

  function zigzag.setStart(start)
    self.start = vector.new(unpack(start))
  end

  function zigzag.setDest(dest)
    self.dest = vector.new(unpack(dest))
  end

  function zigzag.setPermitDig(permit_dig)
    self.permit_dig = permit_dig
  end

  function zigzag.setSpacing(spacing)
    self.spacing = vector.new( unpack(spacing or { 0, 0, 0 }) )
  end

  function zigzag.setOrder(order_string)
    self.order = cruise.stringToAxisOrder(order_string)
  end

  -----------------------------------------------------------
  -- 1行ごとに進む、第2軸の距離を求める
  -----------------------------------------------------------
  function zigzag.getPitch()
    return cruise.calcPitch(self.getRelativeDest(), self.spacing, self.order[2])
  end

  -----------------------------------------------------------
  -- 相対移動ベクトルを得る
  -- 相対移動ベクトルはstartからdestへの相対座標
  -----------------------------------------------------------
  function zigzag.getRelativeDest()
    return self.dest - self.start
  end

  -----------------------------------------------------------
  -- 現在地を基点に最適な移動軸順を再計算する
  -----------------------------------------------------------
  function zigzag.updateAxisOrder()
    local relative_dest = self.getRelativeDest()

    local first =
      cruise.getFirstBearing(turtlenavi.getBearing(), relative_dest)

    local row_count = cruise.calcRowCountTable(relative_dest, self.spacing)
    akaneutils.dumplog(row_count, 'row_count')

    -- 一番列数が少なくなる順番で移動する
    -- (TURNの回数が少なくなる分、塗りつぶしが早く終る)
    local axis_order = akaneutils.sortTable(row_count, true)

    if #axis_order > 1 then
      -- 第1軸と第2軸の列数が同じ場合は、firstを優先
      if row_count[axis_order[1]] == row_count[axis_order[2]] then
        if axis_order[2] == first then
          axis_order[1], axis_order[2] = axis_order[2], axis_order[1]
        end
      end
      -- 平面移動なので第3軸は無視(移動距離0のはずだし)
      axis_order[3] = nil
    end

    self.order = axis_order
  end

  -----------------------------------------------------------
  -- 塗りつぶし完了判定に使うチェックポイント配列を再計算する
  -----------------------------------------------------------
  function zigzag.updateCheckpoints()
    self.checkpoints = cruise.createCheckpointsPlane(
      self.start, self.dest, turtlenavi.getCoordVector(), self.order
    )
  end

  -----------------------------------------------------------
  -- チェックポイント通過判定
  -----------------------------------------------------------
  function zigzag.checkPassed()
    local current = turtlenavi.getCoordVector()
    for _i, cp in ipairs(self.checkpoints) do
      local passed = true
      for _i, axis in ipairs{ 'x', 'y', 'z' } do
        if cp.point[axis] and cp.point[axis] ~= current[axis] then
          passed = false
          break
        end
      end
      if passed then cp.passed = true end
    end
  end

  -----------------------------------------------------------
  -- 塗りつぶし完了判定
  -----------------------------------------------------------
  function zigzag.isDone()
    for _i, cp in ipairs(self.checkpoints) do
      if not cp.passed then
        return false
      end
    end
    return true
  end

  -----------------------------------------------------------
  -- 一歩移動するごとに呼ばれる
  -----------------------------------------------------------
  function zigzag.onStep()
    self.callback()
    self.checkPassed()
  end

  -----------------------------------------------------------
  -- リセット
  -----------------------------------------------------------
  function zigzag.reset()
    self.ready = false
  end

  -----------------------------------------------------------
  -- 移動準備する
  -----------------------------------------------------------
  function zigzag.getReady()
    -- スタート地点に移動
    turtlenavi.moveTo(akaneutils.vectorToArray(self.start))

    self.updateAxisOrder()
    self.updateCheckpoints()
    self.ready = true
  end

  -----------------------------------------------------------
  -- 塗りつぶし移動を実行する
  -- @return 正常完了時true / そうでないならfalse
  -----------------------------------------------------------
  function zigzag.go()
    if not self.ready then
      self.getReady()
    end
    self.onStep()

    -- 移動軸
    local axis1, axis2 = self.order[1], self.order[2]
    if not axis1 then return true end

    -- 塗りつぶし範囲からのはみ出しチェックに使う照合関数
    local comparef = (self.getPitch() >= 0) and math.min or math.max

    -- 各軸の移動距離
    local relative_dest = self.getRelativeDest()
    local distances = {}
    distances[axis1] = relative_dest[axis1]
    if axis2 then
      distances[axis2] = self.getPitch()
    end

    akaneutils.dumplog(self.order, 'axis_order')
    akaneutils.dumplog(axis1, 'axis1')
    akaneutils.dumplog(axis2, 'axis2')
    -- 平面塗りつぶし
    repeat
      turtlenavi.moveByCoord(axis1, distances[axis1], self.permit_dig, self.onStep)
      -- 次列では逆転
      distances[axis1] = distances[axis1] * -1

      if axis2 then
         -- はみ出しチェック
        distances[axis2] =
          comparef(
            distances[axis2],
            self.dest[axis2] - turtlenavi.getCoordVector()[axis2]
          )
        turtlenavi.moveByCoord(axis2, distances[axis2], self.permit_dig, self.onStep)
      end
    until self.isDone()

    return true
  end

  initialize(zigzag, start, dest, permit_dig, callback, spacing, order)
  return zigzag
end
