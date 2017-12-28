-----------------------------------------------------------
-- @file  akaneutils(lua)
-- @brief 茜ちゃんによるユーティリティ集や
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------

-----------------------------------------------------------
-- 引数なしの関数を作るよ<br>
-- CCのparallel APIに渡したりするのに便利やで
--
-- @param func 元の関数
-- @param ... 関数に渡す引数
-- @return 作った関数
-----------------------------------------------------------
function getNoArgFunc(func, ...)
  if select('#', ...) < 1 then
    return func -- 引数がなければそのまま返す
  end
  local args = { ... } -- ...のままではクロージャで参照できんからテーブルに入れるよ
  return function()
    return func(unpack(args)) -- argsを参照できるのはクロージャだからやで
  end
end


-----------------------------------------------------------
-- テーブルを上書きするよ<br>
-- baseをoverで上書きするよ
-- luaのテーブルは参照渡しだから、関数呼び出し元の方のテーブルも上書きされてるよ
--
-- @param base 上書きされるテーブル
-- @param over 上書きするテーブル
-----------------------------------------------------------
function overwrite(base, over)
  for k, v in pairs(over) do
    base[k] = v -- テーブル上書きや！ 以上！
  end
end

-----------------------------------------------------------
-- テーブルにイベントハンドラを追加するよ<br>
-- 追加前に登録されてたハンドラもちゃんと呼ぶよ
-- いまんとこ追加されたハンドラを削除する方法は無いよ
-- CCのイベントシステム使わん場合の簡易な方法やな
-- @param table [in/out]ハンドラを登録するテーブル
-- @param key [in]登録対象のキー
-- @param handler [in]登録するイベントハンドラ
-----------------------------------------------------------
function addHandler(table, key, handler)
  local org_handler = table[key]
  local new_handler = handler
  if type(org_handler) == 'function' then -- すでにハンドラが登録されてたら
    new_handler = function(...) -- 元のハンドラと追加するハンドラ両方呼ぶ関数を作るよ
      org_handler(...)
      handler(...)
    end
  end
  table[key] = new_handler -- ハンドラ登録や！
end

-----------------------------------------------------------
-- イベントハンドラを呼び出すよ<br>
-- 引数はイベントハンドラに渡すよ
-- @param sender [in/out]イベントの発生もと
-- @param ... イベントハンドラに渡す引数
-- @return イベントハンドラの戻り値
-----------------------------------------------------------
function callHandlers(handler, sender, ...)
  if not handler then return nil end
  return handler(sender, ...)
end

-----------------------------------------------------------
-- ファイルを書き込む準備をするよ
-- いまんとこ具体的には必要なディレクトリがなければ作る、ってだけやけどな
-- @param path [in]書き込む予定のファイルのパス
-----------------------------------------------------------
function prepareToWrite(path)
  local dir = fs.getDir(path)
  if not fs.exists(dir) then -- ディレクトリが存在するか見るで
    fs.makeDir(dir) -- 無いから作るよ
  end
end

-----------------------------------------------------------
-- 文字列をセパレータで分割する、イテレータ関数を作って返すよ
-- セパレータが省略されると','を使うよ
-- @param str [in]分割する文字列
-- @param separator [in]セパレータ・区切り文字。省略時は','
-- @return イテレータ関数
-----------------------------------------------------------
function stringSplitter(str, separator)
  separator = separator or ',' -- 省略時はカンマを使うで
  local init = 1
  return function()
    if not init then return nil end -- 終わりや
    local sep_head, sep_tail, col_head, col_tail

    sep_head, sep_tail = string.find(str, separator, init, true) -- セパレータを探すよ
    if sep_head then -- 見つかったか？
      col_head, col_tail = init, sep_head - 1 -- 見つかったよ！
      init = sep_tail + 1 -- 次はセパレータの次の文字から探すよ
    else
      col_head, col_tail = init, -1 -- 見つからんかった
      init = nil -- 次はもうないよ
    end
    return string.sub(str, col_head, col_tail) -- 分割や！
  end
end

-----------------------------------------------------------
-- セパレータで区切られた文字列を分割するよ
-- セパレータが省略されると','を使うよ
-- strがnilの場合はnilを返すよ
-- @param str [in]分割する文字列
-- @param separator [in]セパレータ・区切り文字。省略時は','
-- @return 分割された文字列を格納した配列
-- @see stringSplitter
-----------------------------------------------------------
function splitString(str, separator)
  if not str then return nil end
  local result = {} -- 結果を入れる配列や

  for column in stringSplitter(str, separator) do -- 分割するよ
    result[#result + 1] = column
  end
  return result
end

-----------------------------------------------------------
-- テキストファイルを読んで1行ずつ返す、イテレータ関数を作って返すよ
-- 第二戻り値でopen中のファイルハンドルも返すで
-- ファイルの最後まで読み込まないとファイルクローズしないから
-- forの途中で抜け出す場合は、そっちでファイルクローズしないとあかんよ
-- @param path [in]csvファイルのパス
-- @return イテレータ
-- @return ファイルハンドル
-----------------------------------------------------------
function fileEachLine(path)
  -- ファイルがなければnilを返すだけの関数を返すよ
  if not fs.exists(path) then return (function() return nil end) end

  local h = fs.open(path, 'r')
  assert(h, 'fileEachLine cant open : '.. path)

  -- イテレータ関数
  local function iterator()
    local line = h.readLine() -- 次の行を読むよ
    if not line then -- ファイルはもう終わりか？
      h.close()
      h = nil
    end
    return line, h
  end

  return iterator, h
end

-----------------------------------------------------------
-- csvファイルを読んでカラムの配列を返す、イテレータ関数を作って返すよ
-- ファイルのクローズに関してはfileEachLine()と同じやで
-- セパレータが省略されると','を使うよ
-- @param path [in]csvファイルのパス
-- @param separator [in]セパレータ・区切り文字。省略時は','
-- @return イテレータ
-- @return ファイルハンドル
-- @see fileEachLine
-----------------------------------------------------------
function csvEachLine(path, separator)
  separator = separator or ','

  local each_line, h = fileEachLine(path)

  -- イテレータ関数
  local function parser()
    return splitString(each_line(), separator), h
  end

  return parser, h
end

-----------------------------------------------------------
-- 四捨五入するよ
-----------------------------------------------------------
function round(x)
  if x > 0 then
    return math.floor(x + 0.5)
  else
    return math.floor(math.abs(x) + 0.5) * -1
  end
end

-----------------------------------------------------------
-- 秒をマイクラのTickに変換するよ
-----------------------------------------------------------
function secToTick(sec)
  return round(sec * 20)
end

-----------------------------------------------------------
-- マイクラのTickを秒に変換するよ
-----------------------------------------------------------
function tickToSec(tick)
  return tick / 20
end

-----------------------------------------------------------
-- プログラム開始からの経過時間をTickで返すよ
-----------------------------------------------------------
function getTickCount()
  return secToTick(os.clock())
end
