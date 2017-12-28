-----------------------------------------------------------
-- application.lua
-- プログラム実行に関わるAPI
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/turtleutils')

-----------------------------------------------------------
-- turtleで実行されるプログラムの一般的な初期化処理をするよ
-- @param program_name [in]実行中のプログラム名
-----------------------------------------------------------
function turtleInit(program_name)
  -- 起動メッセージを表示しとくよ
  print(string.format('%s(%dDay) %s: <%s> ikude!!',
    textutils.formatTime(os.time(), true),
    os.day(),
    turtleutils.getCompName(),
    program_name
  ))

  turtleutils.resetSlot()  -- タートルの選択スロットをリセットしとくよ

  -- 他になんか思いついたら追加するよ
end

-----------------------------------------------------------
-- コンフィグファイルを読み込んで返すよ
-- メッセージ表示もするよ
-- @param path [in]コンフィグファイルのpath
-- @return 読み込んだコンフィグテーブル
-----------------------------------------------------------
function loadConfig(path)
  print('config<'.. path ..'> wo load suru yo!')
  local config = dofile(path)
  assert(config, 'config load SIPPAI SITADE nande yanenn...')

  print('config load seikou!!')
  return config
end
