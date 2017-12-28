-----------------------------------------------------------
-- @name  turtlefuel(lua)
-- @description タートルの燃料を扱う関数群
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/akaneutils')
os.loadAPI('/lib/apis/turtleapis')

-----------------------------------------------------------
-- タートルの燃料レベルを表す文字列を返すよ
-----------------------------------------------------------
function getFuelLevelString()
  return 'FL:'.. tostring(turtle.getFuelLevel())
end

-----------------------------------------------------------
-- 燃料補給を管理するオブジェクトを作って返すよ
-- 前に作った補給関数なんかも含まれてるよ
--
-- オブジェクトは燃料の最初の量と、補給量の合計を覚えてるよ
-- その合計から、現在の燃料の量を引いて
-- 燃料をどれだけ使ったか計算できるよ
--
-- @param setting 燃料補給管理オブジェクトの設定テーブル
-- @return 補給管理オブジェクト
-----------------------------------------------------------
function new(setting)
  -- テーブル作成。デフォルト値も設定するよ
  -----------------------------------------------------------
  -- @class table
  -- @name hokyu
  -- @description 燃料補給管理オブジェクト
  -- タートルの燃料補給と、燃料使用量を計算する機能があるよ
  -- @field direction   補給チェストがどっちにあるか
  -- @field wait        燃料確認間隔
  -- @field threashold  燃料補給閾値　これより少なかったら補給するよ
  -- @field enough      燃料十分量　補給時はコレより多くなったら補給をやめるよ
  -- @field sleep       待機に使用する関数
  -----------------------------------------------------------
  local hokyu = {
    direction = const.FORWARD,
    wait = 60,
    threashold = 1000,
    enough = threashold,
    sleep = sleep,
  }
  -- クロージャOOP
  local self = hokyu

  -- private
  -- 燃料の最初の量と、補給量の合計
  local total_fuel = turtle.getFuelLevel()

  -- 引数で渡された設定テーブルで上書き
  if setting then
    akaneutils.overwrite(hokyu, setting)
  end


  -----------------------------------------------------------
  -- 燃料の総使用量を計算して返すよ
  --
  -- 計算方法は、最初にあった量 + 総補給料 - 現在の燃料 やで
  -- どっかおかしかったら教えてな
  -- @return 燃料の総使用量
  -----------------------------------------------------------
  function hokyu.getTotalUsage()
    return total_fuel - turtle.getFuelLevel()
  end

  -----------------------------------------------------------
  -- 燃料の総使用量に加算するよ
  -- @param fuel_level [in]加算する量
  -----------------------------------------------------------
  function hokyu.addUsage(fuel_level)
    total_fuel = total_fuel + fuel_level
  end

  -----------------------------------------------------------
  -- 選択スロットから燃料を補給して、補給量を記憶するよ
  -- 補給する時はかならずこっちを使うようにしないとあかんで
  -- turtle.refuel()を直接使ってしまうと、補給量を記憶できんねん
  -- @param quantity 補給するアイテムの数
  -- @return turtle.refuel()の戻り値
  -----------------------------------------------------------
  function hokyu.refuel(quantity)
    quantity = quantity or math.huge
    local pre_level = turtle.getFuelLevel() -- 補給前の燃料レベルを覚えとくよ
    local result =  turtle.refuel()
    total_fuel = total_fuel + turtle.getFuelLevel() - pre_level -- 補給量を加算するで
    return result
  end

  -----------------------------------------------------------
  -- hokyu()のループ内容やで
  --
  -- @param take_fuel [in]燃料を補給する関数やで
  -- @param threashold [in]燃料補給する閾値やで
  -- @param enough [in]補給後の必要量や
  -----------------------------------------------------------
  function hokyu.hokyu_(take_fuel, threashold, enough)
    if turtle.getFuelLevel() >= threashold then return end -- 燃料があったら何もしないよ

    -- 補給するよ
    print('hokyu suruyo ('.. getFuelLevelString() ..')')

    while true do -- 必要量を超えるまで補給するで
      local selected_slot = turtle.getSelectedSlot() -- 選択スロットを覚えとくよ
      turtle.select(16) -- インベントリの最後のスロットを使うよ
      if take_fuel() and self.refuel() then -- 燃料補給するよ
        print('hokyu sitayo ('.. getFuelLevelString() ..')')
      else
        print('hara hetta') -- 燃料ないよー
      end
      turtle.select(selected_slot) -- 乙女のたしなみや
      if turtle.getFuelLevel() >= enough then break end -- 必要量以上なら補給終わりや
      self.sleep(self.wait)
    end
  end

  -----------------------------------------------------------
  -- 燃料がなかったら補給するよ<br>
  --
  -- 燃料がthreasholdより低かったら補給を開始するよ。
  -- enoughを超えるまで補給するよ。
  -- 引数省略時はselfの値を使うよ
  --
  -- @param threashold [in]燃料補給する閾値やで
  -- @param enough [in]補給後の必要量や
  -----------------------------------------------------------
  function hokyu.hokyu(threashold, enough)
    -- 引数の初期化
    threashold = threashold or self.threashold
    enough = enough or self.enough

    local takeFuel = turtleapis.SUCK[self.direction]
    while true do -- メインループや
      self.hokyu_(takeFuel, threashold, enough)
      self.sleep(self.wait) -- しばらく待機するで
    end
  end

  return self
end
