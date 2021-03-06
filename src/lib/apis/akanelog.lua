-----------------------------------------------------------
-- akanelog.lua
-- CC向けログ出力モジュール
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------

-- ログレベルの定義やで
SEVERITY = {
  UNKNOWN = 0,
  DEBUG = 1,
  INFO  = 2,
  WARN  = 3,
  ERROR = 4,
  FATAL = 5,
}

-----------------------------------------------------------
-- ログ出力用ファイルを確認して、無ければ作るよ
-- ディレクトリも同様やで
-- @param path [in]ログ出力用ファイルのパス
-----------------------------------------------------------
local function initLog(path)
  if fs.exists(path) then return end -- ファイルがもうあればなにもしないよ

  local logdir = fs.getDir(path)
  if not fs.exists(logdir) then -- ディレクトリが存在するか見るで
    fs.makeDir(logdir) -- 無いから作るよ
  end

  -- ファイルを作るよ


-----------------------------------------------------------
-- ログ出力用オブジェクトを作って返すよ
-- @param path [in]ログ出力先のパスやで
-- @param level [in]ログを記録する最低レベル
-- @return ログ出力用オブジェクト
-----------------------------------------------------------
function new(path, level)
  local logger = {
    logdev = path,
    level = level,
  }




  -----------------------------------------------------------
  -- ログを出力するよ
  -- @param level [in]ログのレベルやで
  -- @param message
