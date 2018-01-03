-----------------------------------------------------------
-- jidokabot.lua
-- 自動カボチャタワー畑収穫API
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/const')
os.loadAPI('/lib/apis/akaneutils')
os.loadAPI('/lib/apis/turtleapis')
os.loadAPI('/lib/apis/simattyau')
os.loadAPI('/lib/apis/turtlefuel')
os.loadAPI('/lib/apis/akanecoro')

-----------------------------------------------------------
-- 自動カボチャタワー収穫オブジェクトを作って返すよ<br>
-- @param setting [in]設定テーブル
-----------------------------------------------------------
function new(setting)
  -----------------------------------------------------------
  -- @class table
  -- @name kabot
  -- @description 自動カボチャタワー収穫プログラム
  -- 自動でひたすら回って収穫するよ。とれたものはチェストにしまうよ
  -- 燃料が減ったら補給するよ
  -- @field hokyu           自動補給管理オブジェクト
  -- @field simattyau       アイテム収納管理オブジェクト
  -- @field fuel_on_top     燃料チェストが上にあるかどうかやで
  --                        trueの時は燃料チェストが上、収穫物チェストが下、
  --                        falseなら逆や
  -- @field direction_mawaru 回る方向や
  -- @field level_height    タワー1階分の高さ(ブロック)
  -- @field level_count     タワーの階数
  -----------------------------------------------------------
  local kabot = {
    simau = simattyau.new(),
    hokyu = turtlefuel.new {
      sleep = akanecoro.sleep,
    },
    fuel_on_top = true,
    direction_mawaru = const.RIGHT,
    level_height = 3,
    level_count = 1,
  }

  -- クロージャOOP
  local self = kabot

  -----------------------------------------------------------
  -- 状態変数
  -----------------------------------------------------------
  local fuel_on_top = true  -- 燃料チェストは上に設置されてるんか？

  local on_top = false    -- タワーの一番上に居るよ
  local on_bottom = true  -- タワーの一番下に居るよ

  -- 燃料チェスト・収穫物チェストの方向だよ
  local direction_fuel, direction_simau

  -----------------------------------------------------------
  -- 状態変数制御
  -----------------------------------------------------------
  function kabot.setFuelOnTop(is_top)
    fuel_on_top = is_top -- 燃料チェストが上にあるかどうか設定するよ
    -- 燃料チェストの位置によってhokyu()とsimau()の方向が変わるねん
    if fuel_on_top then
      direction_fuel, direction_simau = const.UP, const.DOWN
    else
      direction_fuel, direction_simau = const.DOWN, const.UP
    end
    self.hokyu.direction = direction_fuel
  end

  -----------------------------------------------------------
  -- 移動中だよ
  -----------------------------------------------------------
  function kabot.onWay()
    on_top, on_bottom = false, false -- 今はタワーの途中にいるよ
  end

  -----------------------------------------------------------
  -- 一番上、または下に到着したよ
  -- @param direction [in]方向
  -----------------------------------------------------------
  function kabot.arrival(direction)
    if direction == const.UP then
      on_top, on_bottom = true, false -- 今いちばんうえにいるよ
    else
      on_top, on_bottom = false, true -- 今いちばんしたにいるよ
    end
  end

  -----------------------------------------------------------
  -- ぐるぐるまわりながら掘るコルーチンやで
  -----------------------------------------------------------
  function kabot.mawaru()
    while true do
      turtleapis.DIG[const.FORWARD]() -- 前を掘るよ
      for i=1, 3 do
        turtleapis.DIG[self.direction_mawaru](true) -- 回ってから掘るよ
      end
      akanecoro.yield()
    end
  end

  -----------------------------------------------------------
  -- カボチャタワーを上下移動するよ
  -- 一番上から下へ、または一番下から上へ移動するよ
  -- 1階層ごとにyieldで止まるで
  -- @param direction [in]方向
  -----------------------------------------------------------
  function kabot.moveVertical(direction)
    self.onWay() -- 移動するよ
    -- 移動階層は階層数 - 1 (3階分登れば4階に着く)
    for level = 1, self.level_count - 1 do
      for i = 1, self.level_height do
        turtleapis.STEP[direction]()
      end
      akanecoro.yield()
    end
    self.arrival(direction)  -- 端に着いたよ
  end

  -----------------------------------------------------------
  -- 待機時間ごとに、カボチャタワーの一番下とてっぺんを
  -- 行き来するコルーチンや
  -----------------------------------------------------------
  function kabot.jouge()
    while true do
      for _i, direction in ipairs { const.UP, const.DOWN } do
        akanecoro.sleep(self.interval_vertical_move) -- 待機や
        self.moveVertical(direction) -- 上行ったり下行ったりするで！
      end
    end
  end

  -----------------------------------------------------------
  -- いま燃料補給可能かな？
  -- 燃料チェストの隣りにいれば可能だよ
  -----------------------------------------------------------
  function kabot.canRefuel()
    if fuel_on_top then
      -- 燃料チェストは一番上だよ
      return on_top
    else
      -- 燃料チェストは一番下だよ
      return on_bottom
    end
  end

  -----------------------------------------------------------
  -- いまアイテムしまっちゃえるかな？
  -- 収穫物チェストの隣りにいれば可能だよ
  -----------------------------------------------------------
  function kabot.canStore()
    if fuel_on_top then
      -- 収穫物チェストは一番下だよ
      return on_bottom
    else
      -- 収穫物チェストは一番上だよ
      return on_top
    end
  end

  -----------------------------------------------------------
  -- なんでもしまっちゃうコルーチン
  -----------------------------------------------------------
  function kabot.simattyaoune()
    while true do
      -- アイテムしまえない時は待つよ
      while not self.canStore() do
        akanecoro.sleep(60)
      end
      -- なんでもしまうよ
      for i = 1, 16 do
        self.simau.simauAny(i, direction_simau)
        akanecoro.sleep(1)
      end
      akanecoro.sleep(10)
    end
  end

  -----------------------------------------------------------
  -- 燃料無ければ補給するコルーチン
  -----------------------------------------------------------
  function kabot.refuel()
    while true do
      -- 補給できない時は待つよ
      while not self.canRefuel() do
        akanecoro.sleep(60)
      end
      -- 燃料無ければ補給するよ
      self.hokyu.hokyu()
      akanecoro.sleep(5)
    end
  end

  -----------------------------------------------------------
  -- 自動カボチャタワー収穫実行
  -- @param ... [in]追加実行するコルーチン
  -----------------------------------------------------------
  function kabot.doKabot(...)
    akanecoro.waitForAny(
      self.mawaru,
      self.jouge,
      self.simattyaoune,
      self.refuel,
      ...
    )
  end

  -- 設定テーブルでオーバーライド
  if setting then
    akaneutils.overwrite(kabot, setting)
  end

  -- 燃料チェスト位置再設定
  self.setFuelOnTop(self.fuel_on_top)
  self.fuel_on_top = nil
  self.direction_fuel = nil
  self.direction_simau = nil

  return kabot
end
