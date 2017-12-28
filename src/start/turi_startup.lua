-----------------------------------------------------------
-- turi_startup.lua
-- 自動釣りプログラムのスタートアップ
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/application')
os.loadAPI('/lib/apis/const')
os.loadAPI('/lib/apis/identify')
os.loadAPI('/lib/apis/turtlefuel')

application.turtleInit('turi_startup')

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
-- 釣りをする方向に水ブロックがあるか
-----------------------------------------------------------
local function isWater(direction)
  local success, data = turtleapis.INSPECT[direction]()
  if identify.isWaterBlock(data) then return true end
  return false
end

local search_water = {
  [const.FORWARD] = function()
    for i=1, 4 do
      if isWater(const.FORWARD) then return true end
      turtle.turnRight()
    end
    return false
  end,

  [const.UP] = function() return isWater(const.UP) end,
  [const.DOWN] = function() return isWater(const.DOWN) end,
}

if not search_water[config.turi.dir_fishing]() then
  -- 水ブロックは見つからんかった…
  return false
end

shell.run('turi')
