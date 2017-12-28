-----------------------------------------------------------
-- inil(lua)
-- 位置情報初期化プログラム
-- turtlenavi locaionの保持するタートルのローカル位置座標を初期化するよ
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/turtlenavi')

turtlenavi.initLocation()
turtle.synchronizer.saveLocation()

local x, y, z = turtlenavi.getCoord()
local bearing = turtlenavi.getBearing()
print('current location = ('.. x ..', '.. y ..', '.. z ..', '.. bearing ..')')
