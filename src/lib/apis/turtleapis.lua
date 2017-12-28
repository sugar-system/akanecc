-----------------------------------------------------------
-- @file  turtleapis(lua)
-- @brief turtle API で方向別のものを簡易に取得できるテーブル集
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/const')

-----------------------------------------------------------
-- 方向別のタートルAPIを格納したテーブルに関数呼出しをセットするよ
-- 例えばDROP(方向, ...)みたいに呼び出すと
-- 該当する方向の関数を呼び出すよ。引数もちゃんと渡すよ
-- @param table [in/out]関数呼び出しをセットするテーブル
-- @return setmetatableの戻り値。すなわち、関数呼び出しをセットしたテーブル
-----------------------------------------------------------
local function setMetaCall(table)
  local mt = getmetatable(table)
  if not mt then mt = {} end

  mt.__call = function(t, direction, ...)
    assert(t[direction], direction ..' is N/A.')
    return t[direction](...)
  end
  return setmetatable(table, mt)
end

-----------------------------------------------------------
-- 回転
-----------------------------------------------------------
TURN = {
  -- 整合性のために正面バージョンも用意するけどもちろんなんもしないよ
  [const.FORWARD] = function() return true end,
  [const.RIGHT]   = turtle.turnRight,
  [const.LEFT]    = turtle.turnLeft,
  [const.BACK]    = function() -- 真後ろに回転するやつや
      local turn = turtle.turnRight -- 右回りやで
      if not turn() then return false end -- 1回目の回転に失敗したらそこまでや
      return turn() -- 2回めの回転や
    end
}
setMetaCall(TURN)

-----------------------------------------------------------
-- タートルが右か左を向いて、関数を実行して、元の向きに戻る
-- っていう関数を作って返すよ
-- 後ろまで向くのもついでに作るけど、TURN[BACK]の途中で失敗するとどうなるかわからん
-- そもそもタートルが回転に失敗することあるかどうか知らんけど
--
-- @param func [in]実行する関数
-- @param direction [in]タートルが向く向き
-- @return 作った関数
-----------------------------------------------------------
local function createSideFunc(func, direction)
  -- タートルが横向く関数や。とりあえず右向くもんとして設定しとくで
  local turn1st, turn2nd = TURN[const.RIGHT], TURN[const.LEFT]

  if direction == const.LEFT then -- 左に向く時は入れ替えればええで
    turn1st, turn2nd = turn2nd, turn1st
  elseif direction == const.BACK then -- 後ろ向く場合や
    turn1st = TURN[const.BACK] -- 後ろ向くで
    turn2nd = turn1st -- 同じ方向でまた後ろ向くで
  end

  -- 関数を作って返すよ
  return function(not_return, ...)
    if not turn1st() then return false end -- 最初の横向くの失敗したらどうにもならん
    local result = func(...) -- 戻り値は関数の戻り値をそのまま返すんや
    if not not_return then turn2nd() end -- 引数が真でなければ元の向きに戻るよ
    return result, not_return and turn2nd
  end
end

-----------------------------------------------------------
-- 方向別のタートルAPIを格納したテーブルを作るよ
-- 例えばDROP[方向]で必要な関数がもらえる感じのやつや
-- このテーブルは例えばDROP(方向, ...)みたいに関数呼出ししても使えるよ
--
-- 横向くやつは使い途が限られるかもなあ
--
-- @param methods [in]FORWARD UP DOWNの順にAPIメソッドを格納した配列
-- @return 作ったテーブル
-----------------------------------------------------------
local function createFuncsTable(methods)
  local methods_table = {}

  -- 前・上・下やで
  for i, direction in ipairs { const.FORWARD, const.UP, const.DOWN } do
    methods_table[direction] = methods[i]
  end

  -- 横向くやつや
  for _i, direction in ipairs { const.RIGHT, const.LEFT, const.BACK } do
    methods_table[direction] = createSideFunc(methods[1], direction)
  end

  -- 関数呼び出しを設定するよ
  setMetaCall(methods_table)

  return methods_table
end

-----------------------------------------------------------
-- 方向別のタートルAPIメソッドを取得するためのテーブルやで
-- DROP[方向]でメソッドがもらえるで
DROP = createFuncsTable {
  turtle.drop,
  turtle.dropUp,
  turtle.dropDown,
}

-- 以下、似たようなのが続くで

ATTACK = createFuncsTable {
  turtle.attack,
  turtle.attackUp,
  turtle.attackDown,
}

DIG = createFuncsTable {
  turtle.dig,
  turtle.digUp,
  turtle.digDown,
}

PLACE = createFuncsTable {
  turtle.place,
  turtle.placeUp,
  turtle.placeDown,
}

DETECT = createFuncsTable {
  turtle.detect,
  turtle.detectUp,
  turtle.detectDown,
}

INSPECT = createFuncsTable {
  turtle.inspect,
  turtle.inspectUp,
  turtle.inspectDown,
}

COMPARE = createFuncsTable {
  turtle.compare,
  turtle.compareUp,
  turtle.compareDown,
}

SUCK = createFuncsTable {
  turtle.suck,
  turtle.suckUp,
  turtle.suckDown,
}

-----------------------------------------------------------
-- 一歩移動
-----------------------------------------------------------
STEP = createFuncsTable {
  turtle.forward,
  turtle.up,
  turtle.down,
}
STEP[const.BACK] = turtle.back -- 一歩移動の[BACK]だけは他と違って回らずそのまま下がるよ

-----------------------------------------------------------
-- 成功するまで一歩移動
-----------------------------------------------------------
local function createStepCertainly(direction)
  local step = STEP[direction]
  local dig  = DIG [direction]
  return function(permit_dig, try_count)
    local tryed = 0
    repeat
      tryed = tryed + 1
      if permit_dig then
        dig()
      end
      if step() then
        return true
      end
    until try_count and tryed >= try_count
    return false
  end
end

STEP_CERTAINLY = createFuncsTable {
  createStepCertainly(const.FORWARD),
  createStepCertainly(const.UP),
  createStepCertainly(const.DOWN),
}
