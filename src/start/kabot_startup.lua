-----------------------------------------------------------
-- kabot_startup.lua
-- 自動カボチャタワー収穫プログラムのスタートアップ
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/application')
os.loadAPI('/lib/apis/const')
os.loadAPI('/lib/apis/turtleapis')

application.turtleInit('kabot_startup')

-----------------------------------------------------------
-- とにかく行けるだけ下に行ったらkabot開始すればOKやで
local count = 0
while true do
  print('sita ikuyo!')
  if turtleapis.STEP[const.DOWN]() then
    count = 0
  else
    -- 下に行けんかった
    count = count + 1
    print('sita ni iken! '.. tostring(count) ..'kai me')
    if count > 3 then
      -- たぶん一番下ちゃうかな？
      print('kokoya!')
      break
    end
    -- ちょっとまってみる
    sleep(10)
  end
end

shell.run('kabot')
