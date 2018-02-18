-----------------------------------------------------------
-- akaneCoro(lua)
-- 自前コルーチン管理
-- だいぶparallel APIをパク…参考にしてるよ
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------

-- コルーチン中断メッセージ
MESSAGE_YIELD = 'akaneCoro:yield'

-- sleep()の別名を作っとくよ
-- akanecoro.sleep()と明確に区別できないと困るねん
local _sleep = sleep

-----------------------------------------------------------
-- 処理すべきイベントかどうか判定するで<br>
-- @param event_wait_for [in]待受中のイベント名
-- @param event_data [in]os.pullEventRawで取得したイベントテーブル
-- @retrun 処理すべきイベントかどうか
-----------------------------------------------------------
local function isListenableEvent(event_wait_for, event_data)
  return event_wait_for == nil or -- 待っとるイベントがそもそも空か
    event_wait_for == event_data[1] or -- 待っとるイベントが来たか
    event_data[1] == 'terminate' -- ターミネートイベントが来たとき真を返すで
end

-----------------------------------------------------------
-- akaneCoro.resume()で実行できるコルーチン(threadオブジェクト)を
-- 作って返す関数や<br>
--
-- 2つ以上の引数が渡された場合、
-- 2つ目以降の引数は全て関数に渡す引数として扱われるよ
-- コルーチンの仕様上、これらの引数が渡されるのは初回呼び出し時だけになるよ
--
-- @param func [in]コルーチンにする関数
-- @param ... [in/out]関数に渡す引数
-----------------------------------------------------------
function create(func, ...)
  return coroutine.create(akaneutils.getNoArgFunc(func, ...))
end

-- いまんとこwrap()は無いよ

-----------------------------------------------------------
-- CCのAPIを含むコルーチンをresumeできる関数や<br>
--
-- 中断メッセージが来ない限りコルーチンを動かし続けるで
-- @param coro [in]実行するコルーチン
-----------------------------------------------------------
function resume(coro)
  local event_data = {}
  local event_wait_for = nil

  while true do
    if isListenableEvent(event_wait_for, event_data) then -- イベント待受やで
      -- コルーチンを働かすで
      local ok, message = coroutine.resume(coro, unpack(event_data))
      assert(ok, message) -- コルーチンがなんかあかんかったらerror投げる

      if message == MESSAGE_YIELD then
        return ok, message  -- 中断メッセージが来たら一旦もどるで
      end

      event_wait_for = message
      if coroutine.status(coro) == 'dead' then  -- コルーチン生きとるんか？
        return false
      end
    end

    event_data = {os.pullEventRaw()} -- イベント確認や！
  end
end

-----------------------------------------------------------
-- コルーチンを中断する関数や<br>
--
-- akaneCoro.resume()から抜け出せるで
-- 引数はなんでもOKでakaneCoro.resume()の戻り値として返されるよ
-- @param ... [in/out]なんでも
-----------------------------------------------------------
function yield(...)
  local event =  {coroutine.yield(MESSAGE_YIELD, ...)}
  if event[1] == 'terminate' then
    error('Terminated')
  end
  return event
end

-----------------------------------------------------------
-- 指定秒数の間待機する関数や<br>
--
-- 待機中はakaneCoro.resume()から抜け出して他のことを出来るよ
-- @param wait [in]待機する秒数
-----------------------------------------------------------
function sleep(wait)
  local end_time = os.clock() + wait
  while end_time > os.clock() do
    yield()
    _sleep(0)
  end
end

-----------------------------------------------------------
-- 引数で与えられたすべての関数のコルーチン(threadオブジェクト)を
-- 作って返す
-- @param ... [in]関数
-- @return コルーチン
-----------------------------------------------------------
local function createAll(first, ...)
  if not first then return nil end
  if type(first) ~= 'function' then
    error('createAll : args MUST be function, got '.. type(first))
  end
  return create(first), createAll(...)
end

-----------------------------------------------------------
-- コルーチンを並列実行する
-- コルーチンの数がlimitを下回ったら処理を終了する
-- @param coroutines [in]コルーチンの配列
-- @param limit [in]処理を続行する、コルーチン数の下限
-----------------------------------------------------------
local function runUntilLimit(coroutines, limit)
  local living = #coroutines

  while true do
    for i, coro in ipairs(coroutines) do
      if coro then
        resume(coro) -- コルーチンを再開するよ
      end
      -- コルーチン1個動かす度に、コルーチン全部の生存確認をするよ
      for i, coro in ipairs(coroutines) do
        if coro and coroutine.status(coro) == 'dead' then
          coroutines[i] = nil -- し、死んどる！
          living = living - 1
        end
        if living <= limit then return i end
      end
    end
  end
end

-----------------------------------------------------------
-- コルーチンを並列実行する
-- @param ... [in]コルーチン
-- @return 最後に停止したコルーチンの順番
-----------------------------------------------------------
function waitForAny(...)
  local coroutines = { createAll(...) }
  return runUntilLimit(coroutines, #coroutines - 1)
end

-----------------------------------------------------------
-- コルーチンを並列実行する
-- @param ... [in]コルーチン
-- @return 最後に停止したコルーチンの順番
-----------------------------------------------------------
function waitForAll(...)
  local coroutines = { createAll(...) }
  return runUntilLimit(coroutines, 0)
end
