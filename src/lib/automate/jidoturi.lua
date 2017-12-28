-----------------------------------------------------------
-- jidoturi.lua
-- 自動釣りAPI
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/akaneutils')
os.loadAPI('/lib/apis/turtleapis')
os.loadAPI('/lib/apis/turtlefuel')
os.loadAPI('/lib/apis/identify')
os.loadAPI('/lib/apis/simattyau')

-----------------------------------------------------------
-- 自動釣りオブジェクトを作って返すよ<br>
-- つり関数としまっちゃおうね関数はここに入るよ
--
-- オブジェクトは釣りをした回数、釣れた回数を覚えてるよ
--
-- @param setting 自動釣りオブジェクトの設定テーブル
-- @return 自動釣りオブジェクト
-----------------------------------------------------------
function new(setting)
  -- テーブル作成。デフォルト値も設定するよ
  -----------------------------------------------------------
  -- @class table
  -- @name turi
  -- @description 自動釣りオブジェクト
  -- 自動でひたすら釣りするよ。釣ったものはチェストにしまうよ
  -- 焼ける魚とソレ以外でしまうチェストを分けられるよ
  -- 燃料が減ったら補給するよ
  -- @field hokyu           自動補給管理オブジェクト
  -- @field simattyau       アイテム収納管理オブジェクト
  -- @field dir_fishing     釣りする方向
  -- @field dir_store_fish  焼ける魚をしまうチェストの方向
  -- @field dir_store_other 焼ける魚以外をしまうチェストの方向
  -- @field wait_fishing    釣りの待機時間
  -- @field wait_check_slot インベントリスロット毎の確認待機時間
  -- @field start_fishing    釣り開始時に呼ばれるイベントハンドラ
  -- @field end_fishing      釣り終了時に呼ばれるイベントハンドラ
  -- @field stats_auto_load 生成時に統計情報を自動で読み込むかどうか
  -- @field stats_save_add  統計情報保存時に追加モードで書き込むかどうか
  -- @field stats_result_path 統計情報ファイルのパス
  -- @field stats_items_path  釣れたアイテム情報ファイルのパス
  -----------------------------------------------------------
  local turi = {
    hokyu           = turtlefuel.new(),
    simattyau       = simattyau.new(),
    dir_fishing     = const.FORWARD,-- 釣りをする方向や
    dir_store_fish  = const.UP,     -- 魚をしまう方向や
    dir_store_other = const.DOWN,   -- 魚以外をしまう方向や
    wait_fishing    = 30, -- 釣りの待ち時間(秒数)や
    wait_check_slot = 1, -- しまっちゃおうねチェックの待ち時間(秒数)や
    stats_auto_load = false,
    stats_save_add  = false,
    stats_result_path = 'turi.csv',
    stats_items_path  = 'turi_items.csv',
  }
  -- クロージャOOP
  local self = turi

  -- private
  local tried   = 0 -- 釣りした回数やで
  local success = 0 -- 釣れた回数やで

  local start_time -- 釣りを始めた時刻(os.clock())

  -----------------------------------------------------------
  -- 釣りを始める関数だよ<br>
  -- 釣り回数(self.tried)はまだカウントアップしないで
  -----------------------------------------------------------
  function turi.startFishing()
    self.onStartFishing()
    return turtleapis.ATTACK[self.dir_fishing]() -- 釣るよ
  end

  -----------------------------------------------------------
  -- 「釣り始めるで！」イベントを起こすよ<br>
  -- イベントと言ってもturiではCCのイベントシステムは使わんで
  -- 登録されたイベントハンドラを直接呼ぶよ
  -- @param result [in]釣りの結果
  -----------------------------------------------------------
  function turi.onStartFishing(result)
    akaneutils.callHandlers(self.start_fishing, self, result)
  end

  -----------------------------------------------------------
  -- 釣り上げる関数だよ<br>
  -- ここで釣れた回数(self.success)をカウントアップするよ
  -- 釣り回数(self.tried)も釣り上げた時点でカウントアップするで
  -----------------------------------------------------------
  function turi.endFishing()
    local result = turtleapis.DIG[self.dir_fishing]() -- 釣り上げるよ
    tried = tried + 1 -- 釣り上げたらまず、釣り回数をカウントアップするで
    if result then
      success = success + 1 -- 釣れたら釣れた回数をカウントアップや！
    end
    self.onEndFishing(result) -- 「釣り上げたで！」イベント発生
    return result
  end

  -----------------------------------------------------------
  -- 「釣り上げたで！」イベントを起こすよ<br>
  -- イベントと言ってもturiではCCのイベントシステムは使わんで
  -- 登録されたイベントハンドラを直接呼ぶよ
  -- @param result [in]釣りの結果
  -----------------------------------------------------------
  function turi.onEndFishing(result)
    akaneutils.callHandlers(self.end_fishing, self, result)
  end

  -----------------------------------------------------------
  -- タートルが釣りするよ<br>
  --
  -- @param wait [in]釣りの待ち時間(秒数)や。省略時はself.waitが使われるよ
  -----------------------------------------------------------
  function turi.turi(wait)
    wait = wait or self.wait_fishing

    while true do -- メインループや
      print('turude')
      self.startFishing() -- 釣り開始やで
      sleep(wait) -- ちょっと待つよ
      if self.endFishing() then -- 釣り上げるで
        print('tureta')
      else
        print('turen katta')
      end
    end
  end

  -----------------------------------------------------------
  -- しまっちゃおうねAPIに渡す分類コールバック関数だよ<br>
  --
  -- スロットを調べて、魚じゃなければチェストにしまうよ
  -- 焼ける魚とそれ以外でしまうチェストを分けるで
  -- 魚の場合はスタックがいっぱいな場合だけしまうよ
  -- @param slot_no [in]対象スロット番号
  -- @param force [in]trueの場合はスタックいっぱいじゃなくてもしまうよ
  -- @return しまったらture / しまわなかったらfalse
  -----------------------------------------------------------
  function turi.bunrui(slot_no, force)
    local item_detail = turtle.getItemDetail(slot_no) -- 対象のアイテム情報やで
    if not item_detail then return false end -- スロットが空ならなにもしないよ

    local direction = self.dir_store_other -- アイテムをしまう先
    if identify.isFish(item_detail) then -- 魚やろか？
      -- 魚の場合、スタックいっぱいやなかったら何もしないで
      if not force and turtle.getItemSpace(slot_no) ~= 0 then return false end

      if identify.isRoastableFish(item_detail) then -- この魚、焼けるか？
        direction = self.dir_store_fish -- 焼ける魚ならこっちのチェストや
      end
    end
    print('slot '.. slot_no ..' wo simau yo!') -- しまうで～
    return direction
  end

  -----------------------------------------------------------
  -- 持っとるアイテムをチェストにしまうよ<br>
  --
  -- インベントリスロットを順番に見ていって、
  -- アイテムがあったらチェストにしまうよ
  -- 焼ける魚とそれ以外でしまうチェストを分けるで
  -- 魚の場合はスタックがいっぱいな場合だけしまうよ
  -- @param wait [in]1スロット処理するごとの待機時間やで
  -----------------------------------------------------------
  function turi.simattyaoune(wait)
    wait = wait or self.wait_check_slot

    while true do -- メインループや
      for i = 1, 16 do -- タートルのインベントリスロットを順番に見てくよ
        self.simattyau.simau(self.bunrui, i)
        sleep(wait)
      end
    end
  end

  -----------------------------------------------------------
  -- 持っとるアイテム全部をチェストにしまうよ<br>
  --
  -- インベントリスロットを順番に見ていって、
  -- アイテムがあったらチェストにしまうよ
  -- 焼ける魚とそれ以外でしまうチェストを分けるで
  -- 魚の場合はスタックがいっぱいな場合だけしまうよ
  -----------------------------------------------------------
  function turi.simattyaouneAll()
    local bunrui = self.bunrui
    for i = 1, 16 do -- タートルのインベントリスロットを順番に見てくよ
      self.simattyau.simau(
        function(slot_no) return bunrui(slot_no, true) end,
        i
      )
    end
  end

  -----------------------------------------------------------
  -- 自動で釣りするよ<br>
  -- parallel.waitForAnyを使って自動で釣りを繰り返すよ
  -- 追加したいコルーチンを引数で渡せるよ
  -- @param ... 追加実行したいコルーチン(可変数)
  -----------------------------------------------------------
  function turi.doFishing(...)
    -- 釣り実行
    parallel.waitForAny(
      self.turi,
      self.simattyaoune,
      self.hokyu.hokyu,
      ...
    )
  end

  -----------------------------------------------------------
  -- 釣りを始めてからの経過時間を返すよ<br>
  -- まだ釣りを始めてなければ0を返すよ
  -----------------------------------------------------------
  function turi.getTimeElapsed()
    if not start_time then return 0 end
    return os.clock() - start_time
  end

  -----------------------------------------------------------
  -- 釣った回数を返すよ
  -----------------------------------------------------------
  function turi.getTriedCount()
    return tried
  end

  -----------------------------------------------------------
  -- 釣れた回数を返すよ
  -----------------------------------------------------------
  function turi.getSuccessCount()
    return success
  end

  -----------------------------------------------------------
  -- 統計情報をリセットするよ
  -- 経過時間・釣った回数・釣れた回数をリセットするよ
  -----------------------------------------------------------
  function turi.resetStats()
    tried, success = 0, 0
    start_time = os.clock()
  end

  -----------------------------------------------------------
  -- 統計情報を(csv)ファイルに書き込むよ
  -- @param result_path [in]統計ファイルパス
  -- @param items_path [in]アイテムファイルパス
  -----------------------------------------------------------
  function turi.saveStats(result_path, items_path)
    result_path = result_path or self.stats_result_path
    items_path  = items_path  or self.stats_items_path

    akaneutils.prepareToWrite(result_path) -- 書き込み準備や

    local mode = 'w'
    if self.stats_save_add then mode = 'a' end
    local h = fs.open(result_path, mode) -- ファイルオープン
    -- 釣り結果をcsv出力するよ
    h.writeLine(string.format('%d,%d,%d,%d,%d',
      self.wait_fishing,          -- 釣り待機時間の設定値
      self.getTriedCount(),       -- 釣り回数
      self.getSuccessCount(),     -- 釣れた回数
      self.getTimeElapsed(),      -- 経過時間(秒)
      self.hokyu.getTotalUsage()  -- 消費燃料(FL)
    ))
    h.close() -- ファイルクローズ

    -- 釣れたアイテムをcsv出力するよ
    self.simattyaouneAll() -- まず釣れたアイテムを全部しまっちゃうよ
    self.simattyau.saveStats(items_path) -- しまったアイテムをcsv出力や
  end

  -----------------------------------------------------------
  -- 統計情報(csv)ファイルを読み込むよ
  -- @param result_path [in]統計ファイルパス
  -- @param items_path [in]アイテムファイルパス
  -----------------------------------------------------------
  function turi.loadStats(result_path, items_path)
    result_path = result_path or self.stats_result_path
    items_path  = items_path  or self.stats_items_path
    self.resetStats()
    -- 統計ファイルを読み込むよ
    -- 複数行あった場合は最後の行を読み込むねん
    local result
    for columns in akaneutils.csvEachLine(result_path) do
      if #columns == 5 then result = columns end
    end
    if result then
      -- wait_fishingは読み込まないよ
      tried       = tonumber(result[2])
      success     = tonumber(result[3])
      start_time  = os.clock() - tonumber(result[4])
      self.hokyu.addUsage(tonumber(result[5]))
    end

    -- アイテムcsvを読み込むよ
    self.simattyau.loadStats(items_path)
  end


  -- 引数で渡された設定テーブルで上書き
  if setting then
    akaneutils.overwrite(turi, setting)
  end

  -- 統計情報初期化
  self.resetStats()
  if self.stats_auto_load then
    self.loadStats()
  end

  return self
end
