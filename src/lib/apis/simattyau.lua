-----------------------------------------------------------
-- simattyau.lua
-- アイテム収納 API
-- 収納したアイテムと数の記憶機能付き
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/akaneutils')
os.loadAPI('/lib/apis/turtleapis')
os.loadAPI('/lib/apis/identify')

-----------------------------------------------------------
-- アイテムをしまって、しまった種類と数を記憶するオブジェクトを作るよ
-- @param setting [in]アイテム収納オブジェクトの設定テーブル
-- @return アイテム収納オブジェクト
-----------------------------------------------------------
function new(setting)
  -- テーブル作成。デフォルト値も設定するよ
  -----------------------------------------------------------
  -- @class table
  -- @name simau
  -- @description アイテム収納オブジェクト
  -- @field counts 収納したアイテムの数を記憶するテーブル
  -----------------------------------------------------------
  local simau = {
    counts = {},
  }
  -- クロージャOOP
  local self = simau

  -----------------------------------------------------------
  -- アイテム数記憶テーブルのkeyを生成する
  -----------------------------------------------------------
  function simau.createKey(itemID, itemDV)
    if not itemDV then print('nil') end
    return string.format('%s,%d', itemID, tonumber(itemDV)) -- どうせcsvにするんやしなあ
  end

  -----------------------------------------------------------
  -- 指定スロットのアイテムを分類するよ
  -- 分類には引数で渡されたコールバック関数を使うよ
  -- コールバック関数を実行して、戻り値の方向のチェストにしまうよ
  -- 戻り値がfalseならなにもしないよ
  --
  -- @param callback [in]分類に使うコールバック関数
  -- @param slot_no [in]対象スロット番号
  -- @return しまったらture / しまわなかったらfalse
  -----------------------------------------------------------
  function simau.simau(callback, slot_no)
    local direction = callback(slot_no)
    if not direction then return false end
    return self.simauAny(slot_no, direction)
  end

  -----------------------------------------------------------
  -- 指定スロットのアイテムをチェストにしまうよ
  --
  -- @param slot_no [in]対象スロット番号
  -- @param direction [in]アイテムをしまう方向
  -- @return しまったらture / しまわなかったらfalse
  -----------------------------------------------------------
  function simau.simauAny(slot_no, direction)
    if not turtle.getItemDetail(slot_no) then return false end
    local selected_slot = turtle.getSelectedSlot() -- 選択スロットを覚えとくよ
    turtle.select(slot_no)
    local result = self.insert(direction) -- チェストにしまうよ
    turtle.select(selected_slot) -- 選択スロットを戻しとくんのが乙女のたしなみやで
    return result
  end

  -----------------------------------------------------------
  -- 選択中のスロットのアイテムをチェストにしまうよ
  -- しまったアイテムの種類と数を記憶するよ
  --
  -- @param direction [in]アイテムをしまう方向
  -- @return しまったらture / しまわなかったらfalse
  -----------------------------------------------------------
  function simau.insert(direction)
    local item = turtle.getItemDetail() -- アイテムは何やろ
    if not turtleapis.DROP[direction]() then -- アイテムをしまうよ
      return false
    end

    -- しまったアイテムを記憶するよ
    self.addCount(
      identify.getItemID(item),
      identify.getItemDV(item),
      item.count - turtle.getItemCount()
    )
    return true
  end

  -----------------------------------------------------------
  -- アイテムの種類と数を記憶するよ
  --
  -- @param itemID [in]しまったアイテムのID
  -- @param itemDV [in]しまったアイテムのDV
  -- @param count [in]しまったアイテムの数
  -----------------------------------------------------------
  function simau.addCount(itemID, itemDV, count)
    local key = self.createKey(itemID, itemDV)
    local old_count = self.counts[key] or 0
    self.counts[key] = old_count + count
  end

  -----------------------------------------------------------
  -- しまったアイテムの種類と数を(csv)ファイルに書き込むよ
  -- @param path [in]ファイルパス
  -----------------------------------------------------------
  function simau.saveStats(path)
    akaneutils.prepareToWrite(path) -- 書き込み準備や
    local h = fs.open(path, 'w')
    for k, v in pairs(self.counts) do
      h.writeLine(string.format('%s,%d', k, v)) -- 書くよ～
    end
    h.close()
  end

  -----------------------------------------------------------
  -- しまったアイテムの種類と数を書き込んだファイル(csv)を読み込むよ
  -- @param path [in]ファイルパス
  -----------------------------------------------------------
  function simau.loadStats(path)
    self.counts = {} -- 初期化するで
    if not fs.exists(path) then return end -- ファイルが無かったら何もしないよ

    -- csvを読み込んで行ごとに処理するよ
    for columns in akaneutils.csvEachLine(path) do
      if #columns == 3 then
        -- 読み込んだデータを格納するよ
        self.counts[self.createKey(columns[1], columns[2])] = columns[3]
      end
    end
  end

  return self
end
