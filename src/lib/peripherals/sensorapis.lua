-----------------------------------------------------------
-- sensorapis(lua)
-- センサー制御API
-- CCのアドオン、Open Peripheralsで追加される、センサーを制御するよ
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------

-----------------------------------------------------------
-- センサーのメソッドテーブルを取得するよ
-- @param name センサーが設置されている方向、またはセンサーの名前
-- @return peripheral.call関数のテーブル
-----------------------------------------------------------
local function wrapSensor(name)
  if peripheral.isPresent(name) and
  peripheral.getType(name) == 'openperipheral_sensor' then
    local sensor = peripheral.wrap(name)
    if sensor then
      return sensor
    end
  end
  error('[ERROR]Sensor('.. name ..') does NOT exist.')
end

-----------------------------------------------------------
-- センサー制御クラスを新規に生成するよ
-- @param name センサーが設置されている方向、またはセンサーの名前
-- @return センサー制御クラス
-----------------------------------------------------------
function new(name)
  -- センサー制御クラス
  local sensor_ctrl = {}
  local self = sensor_ctrl

  -- 周辺機器(センサー)
  local sensor = wrapSensor(name)

  -----------------------------------------------------------
  -- プレーヤーがセンサー範囲内に居るかどうか調べるよ
  -- 引数で与えられたプレーヤーリストの内、
  -- 一人でも範囲内に居るかどうか調べるよ
  -- @param names プレーヤー名の配列
  -- @return 検知したプレーヤー名 / 1人も居なければ false
  -----------------------------------------------------------
  function sensor_ctrl.detectPlayerByNames(names)
    local players = sensor.getPlayers()
    for _i, player in ipairs(players) do
      for _i, name in ipairs(names) do
        if player.name == name then
          return player.name
        end
      end
    end
    return false
  end

  return sensor_ctrl
end
