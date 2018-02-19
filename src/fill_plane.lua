-----------------------------------------------------------
-- fill_plane(lua)
-- タートルが任意の平面(四角形)を塗りつぶすように移動しながら
-- 「何かをする」ためのプログラム
--
-- 何をするかは引数で指定できる
-- 具体的にはluaスクリプトファイル名を指定し、そのスクリプトをdofile()で実行、
-- 戻り値をturtlenavi.zigzag()へ引数として与える
--
-- プログラムの引数
-- fill_plane x1 y1 z1 x2 y2 z2 sclipt_name
--
-- x1, y1, z1
-- 対象四角形の塗りつぶし回始点Aのローカル座標
--
-- x2, y2, z2
-- 点Aの対角点のローカル座標
--
-- sclipt_name
-- スクリプトファイル名
-- 実際の検索はスクリプトディレクトリ内に対して行われる
--
-- スクリプトの戻り値
-- 指定スクリプトは戻り値としてテーブルを返さなければならない
-- テーブルのフィールドとして以下のものが設定されていた場合、
-- zigzag()へ同名の引数として与えられる
-- - permit_dig
-- - callback
-- - spacing
-- - order
--
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/turtlenavi')

---------------------------------------
-- プログラム引数
---------------------------------------
local args = { ... }
-- 引数チェック
if #args < 7 then
  print('need 7 args.\nfill_plane x1 y1 z1 x2 y2 z2 sclipt')
  return
end
-- 対象平面の2点
local points = {}
for i, v in ipairs {
  { 1, 2, 3 }, { 4, 5, 6 }
} do
  points[i] = { args[v[1]], args[v[2]], args[v[3]] }
end
-- スクリプト名
local script_file = args[7]

-- スクリプトの実行
local script_path = '/script/'.. script_file
if not fs.exists(script_path) then
  print('script '.. script_file ..' is not exists.')
  return
end
local script_returns = dofile(script_path)

-- zigzag実行
turtlenavi.zigzag(
  points[1],
  points[2],
  script_returns.permit_dig,
  script_returns.callback,
  script_returns.spacing,
  script_returns.order
)
