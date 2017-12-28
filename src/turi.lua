-----------------------------------------------------------
-- turi.lua
-- 自動釣りプログラム
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
dofile('/lib/turi_lib')

application.turtleInit('turi')

-----------------------------------------------------------
-- プログラム引数処理
-----------------------------------------------------------
local args = { ... }
local config_path = args[1] or 'turi_config' -- 第一引数はコンフィグファイル名や

-----------------------------------------------------------
-- コンフィグファイル読み込み
-----------------------------------------------------------
local config = application.loadConfig(config_path)

-----------------------------------------------------------
-- result_file定義ブロック
-----------------------------------------------------------
local result_file = config.save
do
  -- クロージャOOPや
  local self = result_file

  -- 出力済みの釣り回数
  self.last = 0

  -----------------------------------------------------------
  -- 釣り結果を出力するで
  -- @param turi [in]自動釣りオブジェクト
  -- @param force [in]trueなら回数に関係なく書き込むよ
  -----------------------------------------------------------
  function result_file.write(turi, force)
    -- 書き込むのは釣り何回かに1回だけやで
    local tried = turi.getTriedCount()
    if not force and (tried % self.frequency ~= 0 or tried <= self.last) then
      return
    end

    print('tureta item csv wo save suruyo!')
    turi.saveStats() -- 書き込むよ

    self.last = tried -- 最後に書き込んだ釣り回数を覚えとくよ
  end

  -----------------------------------------------------------
  -- 自動釣りの結果保存用コルーチン
  -- @param turi [in]自動釣りオブジェクト
  -----------------------------------------------------------
  function result_file.saveResult(turi)
    while true do
      sleep(self.interval)
      self.write(turi)
    end
  end

end

-----------------------------------------------------------
-- 釣り終了判定コルーチン
-- @param turi [in]自動釣りオブジェクト
-----------------------------------------------------------
function checkExit(turi)
  repeat
    sleep(turi.wait_fishing - 1) -- 釣り1回につき1回動いて欲しいねん
  -- 釣り終了判定や
  until config.turi_limit and turi.getTriedCount() >= config.turi_limit
end

-----------------------------------------------------------
-- main
-----------------------------------------------------------
-- 自動釣りオブジェクト生成
local turi = jidoturi.new(config.turi)

-- 自動釣りで一緒に動かすコルーチンのリストを作るよ
local coroutines = {
  akaneutils.getNoArgFunc(result_file.saveResult, turi),
}
if config.turi_limit then -- 釣り回数制限があるときだけ追加するよ
  coroutines[#coroutines + 1] = akaneutils.getNoArgFunc(checkExit, turi)
end

-- 釣り実行
print('turi suruyo!! ('.. turtlefuel.getFuelLevelString() ..')')
turi.doFishing(unpack(coroutines))

-- 終わり
print(string.format('%d kai turi sitasi tomaru yo!', turi.getTriedCount()))
print(string.format('%d kai tureta de!', turi.getSuccessCount()))
result_file.write(turi, true) -- 最後に統計ファイル書き出すよ
