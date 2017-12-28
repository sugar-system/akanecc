-----------------------------------------------------------
-- gate_keeper(lua)
-- 門番プログラム
-- CCのアドオン、Open Peripheralsで追加される、センサーを使って
-- プレーヤーを検知した時に門を開けるよ
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('lib/peripherals/sensorapis')

-- 門を開けていいプレーヤーリスト
local ALLOWED_PLAYERS = {
  'lapse13',
}

local args = { ... }

if table.maxn(args) < 2 then
  error('NEED two args, [sensor_direction] [gate_direction]')
end

-- センサーの方向
local sensor_direction = args[1]

-- 門を開けるRS信号を送信する方向
local gate_direction = args[2]

-- センサー制御クラス
local sensor = sensorapis.new(sensor_direction)


-- メイン処理
function main()
  local open_door = false
  while true do
    local detected = sensor.detectPlayerByNames(ALLOWED_PLAYERS)
    if detected then
      if not open_door then
        print(string.format('%d', os.clock()) ..': Welcome, Player '.. detected ..'!')
      end
      open_door = true
    else
      open_door = false
    end
    rs.setOutput(gate_direction, open_door)
    sleep(0.2)
  end
end

main()
