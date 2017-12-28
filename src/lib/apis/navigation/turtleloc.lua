-----------------------------------------------------------
-- location(lua)
-- 位置座標API
-- タートルの位置・向きを記憶するよ
-- @author 琴葉茜(さとうけい)
-----------------------------------------------------------
os.loadAPI('/lib/apis/const')
os.loadAPI('/lib/apis/bearingutils')

-----------------------------------------------------------
-- 初期設定
-----------------------------------------------------------
local INITIAL_BEARING = const.NORTH

-----------------------------------------------------------
-- location クラスのインスタンスを生成するよ
-- @return locationオブジェクト
-----------------------------------------------------------
function new()

  local location = {
    x = 0,
    y = 0,
    z = 0,
    bearing = INITIAL_BEARING
  }
  local self = location

  -----------------------------------------------------------
  -- setter / getter
  -----------------------------------------------------------
  function location.setBearing(new_bearing)
    self.bearing = new_bearing
    return true
  end

  function location.getBearing()
    return self.bearing
  end

  function location.setCoord(new_x, new_y, new_z)
    self.x, self.y, self.z = new_x, new_y, new_z
    return true
  end

  function location.getCoord()
    return self.x, self.y, self.z
  end

  -----------------------------------------------------------
  -- 座標を相対移動させるよ
  -- @param dx, dy, dz 相対移動させる各軸の距離
  -----------------------------------------------------------
  function location.translate(dx, dy, dz)
    self.setCoord(
      self.x + dx,
      self.y + dy,
      self.z + dz
    )
    return true
  end

  return location
end
