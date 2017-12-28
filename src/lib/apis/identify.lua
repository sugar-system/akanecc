-----------------------------------------------------------
-- identify(lua)
-- アイテム識別モジュール
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------

-- アイテムID
local ID_FISH             = 'minecraft:fish'
local ID_LEATHER_BOOTS    = 'minecraft:leather_boots'
local ID_TURIZAO          = 'minecraft:fishing_rod'
local ID_POTION           = 'minecraft:potion'
local ID_SADDLE           = 'minecraft:saddle'
local ID_COBBLE           = 'minecraft:cobblestone'

local ID_WATER            = 'minecraft:water'
local ID_FLOWING_WATER    = 'minecraft:flowing_water'

-----------------------------------------------------------
-- turtle.getItemDetailまたはinspectの戻り値から
-- アイテムIDを取得するよ<br>
-- これ要るんやろか
-- @param item_detail [in]アイテム詳細テーブル
-- @return アイテムID
-----------------------------------------------------------
function getItemID(item_detail)
  return item_detail.name
end

-----------------------------------------------------------
-- turtle.getItemDetailの戻り値からアイテムのDVを取得する<br>
--
-- CCのアイテム詳細テーブルではDVは'damage'に格納されるぽいな
-- minecraft wikiによるとDVはデータ値(Data values)てことになっとるけど
-- なんでdamageなんやろ
--
-- @param item_detail [in]アイテム詳細テーブル
-- @return アイテムのDV
-----------------------------------------------------------
function getItemDV(item_detail)
  return item_detail.damage
end

-----------------------------------------------------------
-- turtle.inspectの戻り値からメタデータを取得するよ
-- @param data [in]ブロック詳細テーブル
-- @return アイテムID
-----------------------------------------------------------
function getMetadata(data)
  return data.metadata
end

-----------------------------------------------------------
-- turtle.getItemDetailの戻り値からアイテムのDVを取得する<br>
--
-- CCのアイテム詳細テーブルではDVは'damage'に格納されるぽいな
-- minecraft wikiによるとDVはデータ値(Data values)てことになっとるけど
-- なんでdamageなんやろ
--
-- @param item_detail [in]アイテム詳細テーブル
-- @return アイテムのDV
-----------------------------------------------------------
function getItemDV(item_detail)
  return item_detail.damage
end

-----------------------------------------------------------
-- 指定アイテムを識別するよ<br>
--
-- 引数で与えられた識別用テーブルを使ってアイテムを識別するよ
-- 識別用テーブルから、アイテムIDをkeyにしてvalueを取得し、
-- valueが関数ならば、item_detailを引数に実行し、
-- その戻り値を戻り値として返すよ。
--
-- valueが関数以外ならば(booleanまたはnilを想定)、
-- そのまま戻り値として返すよ。
--
-- @param identifier [in]アイテム識別用テーブル
-- @param item_detail [in]アイテム詳細テーブル
-- @return 識別結果
-----------------------------------------------------------
local function identify(identifier, item_detail)
  if not item_detail then return false end

  local value = identifier[getItemID(item_detail)]
  if type(value) == 'function' then
    return value(item_detail)
  end
  return value
end

-----------------------------------------------------------
-- 簡単に識別関数を作るよ<br>
-- 下のisFish()みたいなのをいちいち作ってたらメンドくて失踪あるのみやから
-- 単純な場合はサクッと作れる方法を用意するよ
-- (isFish()はサンプルとしてそのままのこすよ)
-- @param IDs [in]アイテムIDの配列
-- 使用例は下のisLeatherBootsとかを見てな
-----------------------------------------------------------
local function makeSimply(IDs)
  local t = {}
  for i, v in ipairs(IDs) do
    t[v] = true
  end
  return function(item_detail) return identify(t, item_detail) end
end

-----------------------------------------------------------
-- 指定アイテムが生魚かどうか調べるよ<br>
-- @param item_detail [in]アイテム詳細テーブル
-- @return true 魚や! / false 魚やないで!
-----------------------------------------------------------
function isFish(item_detail)
  local t = {}
  t[ID_FISH] = true

  return identify(t, item_detail)
end

-----------------------------------------------------------
-- 指定アイテムが焼き魚にできる生魚かどうか調べるよ<br>
-- アイテムIDが'minecraft:fish'で、DVが0または1なら焼ける魚や
--
-- @param item_detail [in]アイテム詳細テーブル
-- @return true 焼ける魚や! / false 焼ける魚やないで!
-----------------------------------------------------------
function isRoastableFish(item_detail)
  local t = {}
  t[ID_FISH] = function(item) return getItemDV(item) < 2 end

  return identify(t, item_detail)
end

-----------------------------------------------------------
-- 指定アイテムがポーションという名のただの水かどうか調べるよ<br>
-- DVが0のポーション、つまりアイテムIDが'minecraft:potion'が
-- 水入り瓶や
--
-- @param item_detail [in]アイテム詳細テーブル
-- @return true 水入り瓶や / false 水入り瓶やないで!
-----------------------------------------------------------
function isWaterPotion(item_detail)
  local t = {}
  t[ID_POTION] = function(item) return getItemDV(item) == 0 end

  return identify(t, item_detail)
end

-----------------------------------------------------------
-- こっから下は単純なやつ
-----------------------------------------------------------
-- 革ブーツ
isLeatherBoots = makeSimply {
  ID_LEATHER_BOOTS,
}

-- 釣り竿
isFishingRod = makeSimply {
  ID_TURIZAO,
}

-- サドル
isSaddle = makeSimply {
  ID_SADDLE,
}

-- 水ブロック
isWaterBlock = makeSimply {
  ID_WATER,
  ID_FLOWING_WATER,
}

-- 丸石
isCobble = makeSimply {
  ID_COBBLE,
}
