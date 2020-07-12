pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- wooltergeist
-- by ethan muller, brian wo, meidie lo

dbg = false

ctrl = {
  out = false,
}

-- entity library
library = {
  sheep = {
    s=96,
    name="sheep",
    music="sheep_theme",
  },
  chicken = {
    s=98,
    name="chicken",
    music="sheep_theme",
  },
  cow = {
    s=100,
    name="cow",
    music="sheep_theme",
  },
  rock = {
    s=113,
    name="rock",
  },
  demon = {
    s=64,
    name="demon",
  },
  grass = {
    s=182,
    name="grass",
  },
  door = {
    s=72,
    name="door",
  }
}

-- sfx
snd = {
  step=0,
  thump=1,
  out_of_control=2,
  in_control=3,
  blip=4,
  chime=5,
  nope=6,
  push=7,
  thunder=8,
  elevator=9,
}

tunes = {
  ambient=0,
  sheep_theme=1,
  door_open=6,
  elevator=8,
}

levels = {}

add(levels, {
    x=0,
    y=0,
    message="cold open",
})

add(levels, {
  -- hack to avoid manual typing
  -- will break at > 16 levels
  x=16*#levels,
  y=0,
  message="wooltergeist",
})

add(levels, {
  -- hack to avoid manual typing
  -- will break at > 16 levels
  x=16*#levels,
  y=0,
  -- message="yeah, you got it"
  -- message="level "..#levels..":",
  message="level "..(#levels+1)..": fenced",
})

add(levels, {
  -- hack to avoid manual typing
  -- will break at > 16 levels
  x=16*#levels,
  y=0,
  -- message="you are not bound by the physical realm\nsheep are, though"
  message="level "..(#levels+1)..": double ewe",
})

add(levels, {
  -- hack to avoid manual typing
  -- will break at > 16 levels
  x=16*#levels,
  y=0,
  -- message="you are not bound by the physical realm\nsheep are, though"
  message="level "..(#levels+1)..": push it good",
})

add(levels, {
  -- hack to avoid manual typing
  -- will break at > 16 levels
  x=16*#levels,
  y=0,
  -- message="you are not bound by the physical realm\nsheep are, though"
  message="level "..(#levels+1)..": rock + hard place",
})

-- time
t = 0

-- game state

-- game state
gs = {}

-- first level
gs.map = 1

-- last level
gs.map = #levels

-- second to last level
gs.map = #levels - 1

-- game mode
-- 0: title
-- 1: gameplay
-- 2: won stage
-- 3: ???
gs.mode = 1

function actor_i_at_cell(x,y)
  for i,a in ipairs(actors) do
    if a.x == x and a.y == y then
      return i
    end
  end
  return nil
end

function actor_at_cell(x,y)
  for i,a in ipairs(actors) do
    if a.x == x and a.y == y then
      return a
    end
  end
  return nil
end

function item_at_cell(x,y)
  for i,a in ipairs(items) do
    if a.x == x and a.y == y then
      return a
    end
  end
  return nil
end

function set_ctrl(i, x, y)
  if i > 0 then
    ctrl.target = i
    ctrl.out = false

    local a = actors[i]

    a.controlled = true

    sfx(snd["in_control"])

    if not gs.door_open then
      music(tunes[a.music])
    end
    
  else
    local a = actors[ctrl.target]

    ctrl.out = true
    ctrl.x = x or actors[ctrl.target].x
    ctrl.y = y or actors[ctrl.target].y

    if a then
      actors[ctrl.target].controlled = false
    end

    -- prevent this from happening on stage load
    if t > 1 then
      sfx(snd["out_of_control"])
    end

    if not gs.door_open then
      music(tunes["ambient"])
    end
  end
end

function move_animal(a, x, y)
  a.time_at_last_move = t

  local target_x = a.x + (x or 0)
  local target_y = a.y + (y or 0)

  local map_sprite = mget(target_x + position_x, target_y + position_y)
  local map_flag = fget(map_sprite)

  local actor_in_cell = actor_at_cell(target_x, target_y)
  local item_in_cell = item_at_cell(target_x, target_y)

  -- if wall is solid...
  if map_flag == 1 then
    -- prevent movement
    target_x = a.x
    target_y = a.y
    -- oof
    sfx(snd["thump"])
    return false
  end
  
  if actor_in_cell then
    if actor_in_cell.name == "sheep" and not actor_in_cell.controlled then
      -- 
      local dx = target_x - a.x
      local dy = target_y - a.y
      local move = move_animal(actor_in_cell, dx, dy)
      if (move==false) then
        target_x = a.x
        target_y = a.y
      end
    else
      -- prevent movement
      target_x = a.x
      target_y = a.y
      -- oof
      sfx(snd["thump"])
      return false
    end
  end
  -- player with item...
  if item_in_cell then
    if item_in_cell.s == library["rock"].s then
      if(a.s == library["chicken"].s) then
        target_x = a.x
        target_y = a.y

        sfx(snd["thump"])
        return false
      else
        if(a.controlled == true or a.s == library["cow"].s) then
          local dx = target_x - a.x
          local dy = target_y - a.y
          local move = move_item(item_in_cell, dx, dy)
          if (move==false) then
            target_x = a.x
            target_y = a.y
          end
        else
          target_x = a.x
          target_y = a.y

          sfx(snd["thump"])
          return false
        end
      end
    end
  end

  -- if player should move...
  if a.x != target_x or
  a.y != target_y then
    a.x = target_x
    a.y = target_y
    sfx(snd["step"])
  end

  return true
end

function move_item(item, x, y)
  local target_x = item.x + (x or 0)
  local target_y = item.y + (y or 0)

  local map_sprite = mget(target_x + position_x,target_y + position_y)
  local map_flag = fget(map_sprite)

  local actor_in_cell = actor_at_cell(target_x, target_y)
  local item_in_cell = item_at_cell(target_x, target_y)


  -- if wall is solid...
  if map_flag == 1 or item_in_cell then
    -- prevent movement
    target_x = item.x
    target_y = item.y
    -- oof
    sfx(snd["thump"])

    return false
  end
  if actor_in_cell then
    -- prevent movement
    target_x = item.x
    target_y = item.y
    -- oof
    sfx(snd["thump"])

    return false
  end

  if item.x != target_x or
  item.y != target_y then
    item.x = target_x
    item.y =  target_y
  end 

  sfx(snd["push"])
  return true
end

function won_stage()
  t = 0
  music(tunes["elevator"])

  gs.mode = 2
  gs.map+=1

  -- check if game is won
  if gs.map > #levels then
    t = 0
    gs.mode = 3
  end
end

function reset_stage()
  -- reset any changes to map
  reload(0x2000, 0x2000, 0x1000)

  music(tunes["ambient"])

  load_map(gs.map)
end

function get_gameplay_input()
  if btnp(❎) then
    reset_stage()
  end


  if ctrl.out then
    -- ghost movement
    if btnp(⬅️) then ctrl.x -= 1 end
    if btnp(➡️) then ctrl.x += 1 end
    if btnp(⬆️) then ctrl.y -= 1 end
    if btnp(⬇️) then ctrl.y += 1 end

    if btnp(⬅️) or
      btnp(➡️) or
      btnp(⬆️) or
      btnp(⬇️) then

      sfx(snd["blip"])
    end

    if btnp(🅾️) then
      local i = actor_i_at_cell(ctrl.x, ctrl.y)
      if i then
          set_ctrl(i)
      else
        sfx(snd["nope"])
      end
    end

    -- check for win
    local item = item_at_cell(ctrl.x, ctrl.y)

    if item and item.name == "door" and gs.door_open then
      -- next_stage()
      won_stage()
    end
    
  else
    -- animal movement
    local a = actors[ctrl.target]
    local dx, dy

    if btnp(⬅️) then dx = -1 end
    if btnp(➡️) then dx =  1 end
    if btnp(⬆️) then dy = -1 end
    if btnp(⬇️) then dy =  1 end

    if dx or dy then
      move_animal(a, dx, dy)
    end

    if btnp(🅾️) then
      set_ctrl(0)
    end
  end
  
end

function load_map(i)
  t = 0
  -- clear out all actors
  actors = {}
  items = {}

  -- load map based on index
  gs.map = i

  position_x = levels[gs.map].x
  position_y = levels[gs.map].y

  music(tunes["ambient"])

  for i=position_x,position_x + 16 do
    for j=position_y,position_y + 16 do
      local screen_x = i - position_x
      local screen_y = j - position_y

      local current_cell = mget(i,j)
            
      if current_cell == library["sheep"].s then
        local s = clone_table(library["sheep"])
        s.x = screen_x
        s.y = screen_y
        s.time_at_last_move=t

        add(actors, s)

        -- remove from map
        mset(i, j, library["grass"].s)
      end
             
      if current_cell == library["chicken"].s then
        local s = clone_table(library["chicken"])
        s.x = screen_x
        s.y = screen_y
        s.time_at_last_move=t

        add(actors, s)

        -- remove from map
        mset(i, j, library["grass"].s)
      end

      if current_cell == library["cow"].s then
        local s = clone_table(library["cow"])
        s.x = screen_x
        s.y = screen_y
        s.time_at_last_move=t

        add(actors, s)

        -- remove from map
        mset(i, j, library["grass"].s)
      end

      if current_cell == library["rock"].s then
        local r = clone_table(library["rock"])
        r.x = screen_x
        r.y = screen_y

        add(items, r)

        -- remove from map
        mset(i, j, library["grass"].s)
      end
      
      if current_cell == library["demon"].s then
        -- put demon here
        set_ctrl(0, screen_x, screen_y)

        -- remove from map
        mset(i, j, library["grass"].s)
      end

      if current_cell == library["door"].s then
        local r = clone_table(library["door"])
        r.x = screen_x
        r.y = screen_y

        add(items, r)

        -- remove from map
        mset(i, j, library["grass"].s)
      end
      
    end
  end
end

function update_all_animals()
  for i,a in ipairs(actors) do
    local options = {
      {0, -1},
      {1, 0},
      {0, 1},
      {-1, 0},
    }

    local last_x = a.x
    local last_y = a.y

    local random_option = options[flr(rnd(#options))+1]
    
    if(a.s == library["chicken"].s) then
      if not a.controlled and (t - a.time_at_last_move > 15) then
        move_animal(a, unpack(random_option))
      end
    else
      if not a.controlled and (t - a.time_at_last_move > 70) then
        move_animal(a, unpack(random_option))
      end
    end
  end
end

function get_num_sheep_in_pit()
  local num = 0
  for i,a in ipairs(actors) do
    local animal_in_pit = fget(mget(a.x + position_x, a.y + position_y)) == 128
    if animal_in_pit then
      num += 1
    end
  end
  return num
end

function should_door_open()
  return #actors == get_num_sheep_in_pit()
end

function update_door()
  local door_was_open = gs.door_open

  gs.door_open = should_door_open()

  local door_did_change = (gs.door_open ~= door_was_open) and not (door_was_open == nil)

  if door_did_change then
    if gs.door_open then
      sfx(snd["thunder"], 3)
      music(tunes["door_open"])
    else
      -- prevent this from happening on stage load
      if t > 1 then
        sfx(snd["nope"])
        music(-1)
      end
    end
  end
  
end

function update_gameplay()
  get_gameplay_input()
  update_all_animals()
  update_door()
  t += 1
end

function update_won_stage()
  t += 1

  if t > 100 then
    gs.mode = 1
    load_map(gs.map)
  end
end

function draw_gameplay()
  cls()
  palt(0, true)
  palt(11, false)
  map(position_x, position_y, 0, 0, 16, 16)
  -- spr(p1.s, p1.x * 8, p1.y * 8)

  palt(0, false)
  palt(11, true)

  for i,item in ipairs(items) do
    if item.name == "door" then
      local offset = 0
      if gs.door_open then
        offset = 1
        offset += (t/4) % 3
      end
      spr(item.s + offset, item.x * 8, item.y * 8)
    else
      spr(item.s, item.x * 8, item.y * 8)
    end
  end

  for i,actor in ipairs(actors) do
    if actor.controlled then
      spr(actor.s - 16, actor.x * 8, actor.y * 8)
    else
      spr(actor.s, actor.x * 8, actor.y * 8)
    end
  end

  if ctrl.out then
    spr(library["demon"].s, ctrl.x * 8, ctrl.y * 8 + sin(t/60)*1.25)
  end

  color(3)
  local a = actor_at_cell(ctrl.x, ctrl.y)
  if a and ctrl.out then
    print("z/\142 possess", 4, 119)
  end
  if not ctrl.out then
    print("z/\142 out", 4, 119)
  end
  
  print("❎ reset", 92, 119)

  if gs.door_open then
    color(8 + (t/4)%3)
  end
  
  print(get_num_sheep_in_pit().."/"..#actors, 2,2)

  if dbg then
    color(8)
    -- print("time: "..t)
    print("",0,0)
    print("num sheep: "..#actors)
    print("num sheep in pit: "..get_num_sheep_in_pit())
    print("num items: "..#items)
    print("door_open:"..tostring(gs.door_open))
    -- print("mget: "..asdf)
    if ctrl.out then
      print("ctrl x: "..ctrl.x)
      print("ctrl y: "..ctrl.y)

      local a = actor_at_cell(ctrl.x, ctrl.y)
      if a then
        print(a.name)
      end
    end
  end
end

function string_center(s)
  return 64-#s*2
end

function draw_won_stage()
  cls(0)

  local message = levels[gs.map].message
  color(7)
  center_print(message)
end

function draw_end()
  cls()
  if show_msg then
    color(t/4)
    center_print("you beat the game")
  else
    palt(0, true)
    palt(11, false)
    map(112,32,0,0,16,16)
    color(11)
     print("\n thank you for playing\n")
    color(7)
     print(" made by\n ethan muller +\n brian wo +\n meidie lo\n\n in 48 hours\n for #gmtk2020\n")
    color(1)
     print(" press z to restart")
    -- draw art
  end
  
end

function reset_game()
  t=0
  gs = {}
  gs.map = 1
  gs.mode = 1
  load_map(gs.map)
  reset_stage()
end

function update_end()
  show_msg = true

  if t > 100 then
    show_msg = false

    if btnp(4) then
      reset_game()
    end
  end
  
  t += 1
end

function _init()
  load_map(gs.map)
end

function _draw()
  if gs.mode == 1 then draw_gameplay() end
  if gs.mode == 2 then draw_won_stage() end
  if gs.mode == 3 then draw_end() end
end

function _update60()
  if gs.mode == 1 then update_gameplay() end
  if gs.mode == 2 then update_won_stage() end
  if gs.mode == 3 then update_end() end
end

function clone_table(t)
  local new_t = {}

  for key, value in pairs(t) do
    new_t[key] = value
  end

  return new_t
end

function center_print(txt)
  print(txt, 64-#txt*2, 61)
end

__gfx__
00000000555555551111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bb3bbb3bbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
00000000555555551111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbb3b33b3bb333bbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
00700700555555551111111111666611bbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3b33b3b3b3bbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
00077000555555551111111111666611bbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bb3bbb3bbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
00077000555555551111111111666611bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
00700700555555551111111111555511bbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333bbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
00000000555555551111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
00000000555555551111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
11111111111111111111111111111111bbbbbbbbbb3bb3bbbbbbbbbbb33333bbbbbbbbbbbbbbbbbbbbbbbbbb33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
11111111111111111111711111117111bbbbbbbbb333333bbbbbbbbb3333333bbb1111111b111111111111bb33333333b33333333333333b3333333b3333333b
11177711111771111117171111171711bbbbbbbbb333333b333bbbbb33333333b1333333313333333333331b3333333333bbbbb3333bb33333bb333333bbb333
11171711111171111111171111111711bbbbbbbbb333333b3b3bbbbb3333333bb3333333333333333333333b3333333333bbbbbb3333b3333333b3333333b333
11177711111171111111711111117111bbbbbbbbb333333b333b333b3333333bb333333333333333333333bb3333333333bbbbb33333b33333b33333333bb333
11171111111171111117111111111711bbbbbbbbbb3333bbbbbbb33bb33333bbb3333333333333333333333b33333333333b33b33333b33333bbb33333bbb333
11171111111777111117771111177111bbbbbbbbb3333bbb3bbb3b3bbb3bb3bbbb333333333333333333333b33333333b33333333333333b3333333b3333333b
11111111111111111111111111111111bbbbbbbbbbbbbbbbb333bbbbbbbbbbbbb3333333333333333333333b33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333ddd3333333333b33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333ddddd333333333b33333333b33333333333333b3333333b3333333b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333d5d5d3d3333333b333333333333bb3333b3b33333bbb33333bbb333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bb3bb3bb3bbbbbb3bb333b33333333dd5dd3d3333333b333333333333bbb333bbb33333b3333333b33333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bb3b3bb3bbb3bb3b3bbb333333333ddd33d3333333b33d3333333bbbb333333b333333bb33333bbb333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3b3b3b3bb3bb3bb3bb3333333333333333333333b333d333333bbbb333333b33333bbb33333bbb333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333d333333333333bb33333333b33333333333333b3333333b3333333b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333d333333333333b33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb2bb2bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333b33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b222222bb77bb77bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333b33333333b33333333333333b3333333b3333333b
b227272bb7bbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333b333ddd3333bbbbbb33bbb333333bb33333bbb333
b227272bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333b33ddddd333bbbbbb3333b33333bbb33333bbb333
b222222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333b335d5dd333bbbbbb3333b33333b3b3333333b333
bb2222bbb7bbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333b33d5ddd333b333b33333b33333bbb33333bbb333
b2222bbbb77bb77bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333b333333333b33bb333ddd33b33333333333333b3333333b3333333b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb2bb2bbdddddddddddddddddddddddddddddddddddddddddd2dddddddddddddddddddddb33333bbb22222bbb88888bbbdddddbbdddddddd2222222222333333
b222222bddddddd1dddddddd22ddddddddddddddddddddddd22ddddddddddddddddddddd3bb3bb3b2000002b8000008bd11111dbdddddddd2222222222333333
b227272bdddddddddddddddd222dddddddddddddddddddddd1222ddddddddddddddddddd3bb3bb3b2111112b8000008bd00000dbdddddddd2222222222333333
b227272bdddddddddddd11dd1222ddddddddddddddddddddd52222dddddddddddddddddd3bb3bb3b2000002b8111118bd00000dbdddddddd2222222222333333
b222222bdddddddddd111111d62222dddddddddddddddddddd2222dddddddddddddddddd3bb3bb3b2000002b8000008bd11111dbdddddddd2222222222233333
bb2222bbdddddddddd111151dd22222dddddddddddddddddddd2222ddddddddddddddddd3bb3bb3b2111112b8000008bd00000dbdd15dddd2222222222213333
b2222bbbdddddddd11111551dd6222226dddddddddddddddddd22222dddddddddddddddd3bb3bb3b2000002b8111118bd00000dbdd11dddd2222222222222222
bbbbbbbbdddddddd11d11555ddd122222dddddddddddddddddd222222ddddddddddddddd3333333b2222222b8888888bdddddddbd11111dd2222222202222222
b72772bbb72772bb11555555dd1222222ddddddddd222252222222222ddd111dddddddd111111111322222222222777772f66677777777770000000012222222
7722227b7722227b55555555ddd2222222212222222222222222222222dd11155111111115111155352222222200777770777706777700f20000000012222222
7227272272272722bbbbbbb5ddd12222222222222222222222222222222211551111111555511155332222222220077500077d00d77000000000000012222222
7722222b7722222bbbbbbbbbdd5d2222222222222222222222222222222222551155555555551155332222222222222220222222222000000000000111122222
7777777b7777777b33333333dddd22222222222222222222222222222222222555555555555511dd333222222222222222222222222222220000001111122222
b77777bbb777777b333333331155222222222222222222222222222222222225555555555555511d333222222222222222222222222222222000011111122222
33f33f333f3333f333333333115222222222222222222222222222222222222555dddddd5555511d333222222222222222222222222222222221111333322222
b333333bb333333b33333333552222222222222222222222222222222222222255dddddd55555bbb333222222222222222222222222222222221153333332222
b77777bbb77777bb3333333356222222222222222222222222222222222222222551dddd33333333331222222222222111111122222222222222333333335222
77ffff7b77ffff7b3333333366222222222222222222222222227777222222222555bbbb33333352222222222222222111111111122222222222333333332222
7ff0f0ff7ff0f0ff33353333662222222222227722222222222e7777722222222253333333111122222222222222222221111111122222222222533333335222
77fffffb77fffffb33555553bb22222222222e7772222222222e77777222222222b3333333311112222222222222222222222111122222222222233333333222
7777777b7777777b333555533bb2222222222e7777222222222e7777722222222233333333331111222222222222222222222222222222222222533333333333
b77777bbb777777b3333553322b2222222222e7777722222222e7777722222222233333333333111222222222222222222222222222222222222333333333333
33f33f333f3333f3333335333222222222222e7777722222222e7777722222222233333333333321222222222222222222222222222222222222333333333333
b333333bb333333b333333333222222222222e7777722222222e7777722222222223333333333333222222222222222222222222222222222222333333333333
bbffffbbb66666bb333333333522222222222e777772222222227777722222222233333333333333331111122222222222223333333222222223333333333333
bff44ffb66667766333333333522222222222e777772222222222777722222222233333333333333333351111122222222533333333322222233333535533333
ff4ff4ff66666666333333333222222222222e7777722222222226772222222222333333333333333333333333222222333333333333333333333335555533bb
4ff44ff466666666333333333222222222222e777772222222222222222225722233333333333333333333333331333333333333333333333333333555bbbbbb
44ffff446555666533333333322222222222227777622222222222222222777222233333333333353333333333333333333333333333333333333333333bbbb3
44444444555556553333333332222222222222267722222222222222577777722221333333333335555533333333333333333333333333333333333333333bbb
34444443355555533333333332222222222222222222222222222257777777702222222233333335555533333333333333333333333333333333333333333333
b333333bb333333b3333333332222222222222222222222222f777777d0060000222222233333333335333333333333333333333333333333333333333333333
bbbb7bbbbbb77bbbbbb7bbbbbbbbbbbbbbbbbbbb88b88b88bbbbbbbbfffbffbfffbffbffd555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb767bbbb7667bbbb767bbbbbbbbbbbbbbbbbbb88b88b88bbbbbbbbbfffffffffffffffbbbb3333bbbbbbbbbbbbbbbb84848484848484848484848484848484
bbb766bbbb6666bbbb667bbbb888888bbbbbbbbb22b22b22bbbbbbbbfffffffffffffffb33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb766777766667777667bbb88777788b888888b22222222bbbbbbbbffffffffffffffff33333333bbbbbbbbbbbbbbbb84848484848484848484848484848484
bbb766666666666666667bbb887887888877778822222222bbbbbbbbbfffffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb766bbbb6666bbbb667bbb288888828878878822b22b2288b88b88fffffffffffffffb33333333bbbbbbbbbbbbbbbb84848484848484848484848484848484
bbb766bbbb6666bbbb667bbb322222233888888322b22b2288b88b88ffffffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb763bbbb3333bbbb367bbbb333333bb333333b33b33b3333b33b33ffffffffffffffff333332eebbbbbbbbbbbbbbbb84848484848484848484848484848484
bbb76bbbbbbbbbbbbbb67bbbbbbbbbbbbbbbbbbbaabaabaabbbbbbbbfffffffffffbffbf33eeeeeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbbbbbbbbbbbb67bbbbbbbbbbbbbbbbbbbaabaabaabbbbbbbbbfffffffffffffff332eeeeebbbbbbbbbbbbbbbb4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c
bbb76bbbbbbbbbbbbbb67bbbbaaaaaabbbbbbbbb99b99b99bbbbbbbbfffffffbffffffff3322eee2bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbbbbbbbbbbbb67bbbaa7aa7aabaaaaaab99999999bbbbbbbbffffffffffffffff33335555bbbbbbbbbbbbbbbb4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c
bbb76bbbbbbbbbbbbbb67bbbaa7777aaaa7aa7aa99999999bbbbbbbbbfffffffffffffff33333355bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbb3b3bbbbbbb67bbb9aaaaaa9aa7777aa99b99b99aabaabaafffffffbffffffff33333155bbbbbbbbbbbbbbbb4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c
bbb76bbbbb3bbbbbbbb67bbb399999933aaaaaa399b99b99aabaabaaffffffffffffffff33333311bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbbbbbbbbbbbb67bbbb333333bb333333b33b33b3333b33b33ffffffffffbffbff33333511bbbbbbbbbbbbbbbb4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c
bbb77bbbbbbbbbbbbbb77bbbbbbbbbbbbbbbbbbbccbccbccbbbbbbbbffffffffffffffff22222333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb767bbbbbbbbbbbb767bbbbbbbbbbbbbbbbbbbccbccbccbbbbbbbbbfffffffffffffff22223333bbbbbbbbbbbbbbbb4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c
bbb666bbbbbbbbbbbb666bbbbccccccbbbbbbbbb11b11b11bbbbbbbbfffffffffffffffb22133333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb66677bbbbbbbb77666bbbcc7777ccbccccccb11111111bbbbbbbbffffffffffffffff25333333bbbbbbbbbbbb505014344454647484d46c2d3d4d5d6d7d8d
bbb66666bbbbb9bb66666bbbccc77ccccc7cc7cc11111111bbbbbbbbbfffffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb666bbbbbb9b9bbb666bbb1cccccc1cc7777cc11b11b11ccbccbccfffffffffffffffb33333333bbbbbbbbbbbbbbbb24354555657585957c2e3e4e5e6e7e8e
bbb666bbbbbbb9bbbb666bbb311111133cccccc311b11b11ccbccbccffffffffffffffff33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb333bbbbbbbbbbbb333bbbb333333bb333333b33b33b3333b33b33ffbffbffffbffbff33333333bbbbbbbbbbbbbbbb25364656667686988c2f3f4f5f6f7f8f
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb77777777bbbbbbbb33333344bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb9bbbbbbbbbbb3b3bbbbb7bbbbbb3b3bbbbbbbb3bbbbbbbbbbbb7bbbbbb7bbbbbbbb33333349bbbbbbbbbbbbbbbb26374757677787999cacbcccdcecfc5c
bbbb9b9bbbbbbbbbbb3bbbbb7b7bbbbbb3bbbbbbbb333bbbbbbbbbbb7bbbbbb7bbbbbbbb33333359bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb9bbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbb7bbbbbbbbb3349994bbbbbbbbbbbbbbbb27a5b5c5d5e5e4f49dadbdcdddedfdee
bbbbbbbbbbbbbabbbbbbbbbbbbbbbbbbbbbbbdbbbbbbbbbbbbbbbbbb7bbbbbb7bbbbbbbbbb344991bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbababbbbbbbbbbbbbbbbbbbbbdbdbbbbbbbbbbbbbbbbb7bbbbbb7bbbbbbbbb3334995bbbbbbbbbbbbbbbb96a6a6b6c6e6f69a9eaebecedefefefe
bbbbbbbbbbbbbabbbbbbbbbbbbbbb3bbbbbbbdbbbbbbbbbbbbbbbbbb7bbbbbb7bbbbbbbb33334445bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbb77777777bbbbbbbb33333333bbbbbbbbbbbbbbbb97a7b7c7d7e7f79b9fafbfcfdffeefff
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddd33333333dddddddd11111555333333332ee23ee333336666666633666666366335553333333344aaa5555555
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddd33333333dddddddd55555555333333335ee3eee3333336666663333666663355335533333333344445511111
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddd33333333dddddddd5555555533333335353eeee533333d666663333655563155115133333333333331111111
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddd33333333dddddddd5ddddddd33333555553eee33333333d55553115555551111111533333333333355131133
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddd33333333dddddddddddddddd3333355355333333333333355551111555511111113333333333333555533333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddd33333333dddddddddddddddd3333333355553333333333355551111111111111333d66333333355555533333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddd33333333ddddd151dbb333bb3ee2333311111333333333315551111111153367777777666655555555333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddd33333333d1111111b33333333ee2333311115333335555331111111bbb336667777777766666555553333333
bbbbbbbbbbbbbbbbdddddddddddddddddddddddddddddddddddddddddddddddddddddddd1133333333355333333333333336666777777766666665533333bbbb
bbbbbbbbbbbbbbbbdddddddddddddddddddddddddddddddddddddddddddddddddddddddd333333333333333333333b3333b66667777776666666666d33333333
bbbbbbbbbbbbbbbbdddddddddddddddddddd1ddddddddddddd5ddddddddddddddd511ddd33333333333333333333333333336667766666666666666663666666
bbbbbbbbbbbbbbbbdd51dddddddddddddd5511ddddddddddd5551dddddddddddd55115dd33333333333333333333333333336666666666666666666666666666
bbbbbbbbbbbbbbbbd5511dddddddddddd55511dddddddddd555111dddddddddd555111dd33333333333333333333335555336666666666666666666666666666
bbbbbbbbbbbbbbbb555111ddddddddd115551111111111111555115ddddddddd555111dd33333333333333355555555555556666666666666666666666666666
bbbbbbbbbbbbbbbb5555111111111115555511155555555555551111111111115551111d33333333333335555555555555556666666666666666666666666666
bbbbbbbbbbbbbbbb551111111111111555551115166666d555551111111111115551111133333555333355555555555555556666666666666666666666666666
bbbbbbbbbbbbbbbb555511155555555555551116666666665555115555555555555111553333355553335555555555555555666666666666b333333366666666
bbbbbbbbbbbbbbbb55551151dddddddd555611166666657665551155555555555551111533333555533335555555555555556666666666663333333366666666
bbbbbbbbbbbbbbbb55551151666666666676666666755557677511ddddddddd55551111533333353333333555555555555555666666666666666666666666666
bbbbbbbbbbbbbbbb55551166666666666666666666655566777511dddddddddd5551111d33333333333333333555555555555666666666666666666666666666
bbbbbbbbbbbbbbbb55551666666666666666666666667566665551dddddddddd555111dd33333333333333333355555555555666666666666666666666666666
bbbbbbbbbbbbbbbb555566666666666666666666666667666d5551ddddbbbddbbbb11bbb33333333333333333335555555555d66666666666666666666666666
bbbbbbbbbbbbbbbbbb556666666666666666666666666666615bb1ddbb333333333133bb333333333333333333555555555555d5666666666666666666666666
bbbbbbbbbbbbbbbb3bb6666666666666666666666666666633bbb333333333333333333333333333333333335555551111155555556655666666666666666666
bbbbbbbbbbbbbbbb33366666767777666666666666666d333b333333333333333333333333543333333333555555551d66515555555555566666666666666666
bbbbbbbbbbbbbbbb33366666677777776666666766666333333555333333333333333333939933333333555555555516666155555555555d6666666666666666
bbbbbbbbbbbbbbbb53366666666667666676666676666d3355555333333333333333333399993333333555555555551d66615555555555566666666666666666
bbbbbbbbbbbbbbbb53366666666667666666666666666c33555533333aa3333aaa33333399949443333555555555551111115555555555d66666666777776666
bbbbbbbbbbbbbbbb55366666666667666666666666666333333333333aaa333aaa33333353449443333355555555555111555555555555666666666777766666
bbbbbbbbbbbbbbbb3336666666666666666666666666633333333333aaaa3344a533333355539433333355555555555555555555555555666666666666666666
bbbbbbbbbbbbbbbb3336666666666666666636666666d33333333aaa44aa334443333333555143333333355555555555555555555555d6666666666666666666
bbbbbbbbbbbbbbbb3333666666666666666636663655333333333aaa335151433333333355553333333333555555555555555555555566666666666666666666
__label__
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb333bbb3b33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb3b3bb3bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb3b3bb3bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb3b3bb3bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb333b3bbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bb3bb3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bb3b3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3b3b3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbb3bb3bbbbbbbbbbb33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbb333333bbbbbbbbb3333333bbb1111111b1111111b1111111b1111111b1111111b111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbb333333b333bbbbb33333333b133333331333333313333333133333331333333313333333333331bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbb333333b3b3bbbbb3333333bb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbb333333b333b333b3333333bb33333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbb3333bbbbbbb33bb33333bbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbb3333bbb3bbb3b3bbb3bb3bbbb33333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333ddd3333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333ddddd333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333d5d5d3d3333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333dd5dd3d3333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333ddd33d3333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333d333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333d333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333d33333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333d3333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbb3bb3bbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbb3bb3bbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333b3333333b3333333b3333333b3333333b333333333b33bbbbbbbbbbbbbbbbbbb3b3b3bbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2bb2bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb222222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb227272bbbbbbbbbbbbbbbbbbbbbbbbbb77777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb227272bbbbbbbbbbbbbbbbbbbbbbbbb77ffff7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb222222bbbbbbbbbbbbbbbbbbbbbbbbb7ff0f0ffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2222bbbbbbbbbbbbbbbbbbbbbbbbbb77fffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2222bbbbbbbbbbbbbbbbbbbbbbbbbbb7777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb77777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33f33f33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bb3bb3bb3bbbbbb3bb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bb3b3bb3bbb3bb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3b3b3b3bb3bb3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333bbbbbb333b333bb33b333b333bbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33b3b33bbbbb3b3b3bbb3bbb3bbbb3bbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b333bbbbb33bb33bb333b33bbb3bbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33b3b33bbbbb3b3b3bbbbb3b3bbbb3bbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333bbbbbb3b3b333b33bb333bb3bbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

__gff__
0001000000000000000000000000000000000000000000008080808000000000000000000000000080808080000000000000000000000000808080800000000000000000000000000000000000000000000002020202000000000000000000000000000002020000000000000000000001070700020000000000000000000000
01010108000100000000000000000000010001090001000000000000000000000100010b0001000000000000000000000204000000030002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b60505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
b6b6b6b6808181818181818182b6b6b6b6b6b6b6050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
b6b6b6b6901819191919191a92b6b6b6b6b6b6b605050518191a050505050505050505400505050505050505050505050505054805050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
b6b6b6b690281b291b1b1b2a92b6b6b6b6b6b6b6050505283b2a050505050505050505050505050505050548050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
b6b6b6b690281b1b1b2b1b2a92b6b6b6b6b6b6b605050538393a050505050505050505050505050505050505050505050505050505050505400505050560050505808181818181818181818182050505058081818181818181818181818205050505050505050505050505050505050505050505050505050505050505050505
b6b6b6b6a03839393939393aa2b6b6b6b6b6b6b6050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505900505050571050518191a920505050590057105050505050518191a9205050505050505050505050505050505050505050505050505050505050505050505
b6b60505060708b6b6b62526b6b6b6b6b6b605050505050505050505050505050505050505050505050505050505050505050505056005050505050505050505059060050505710505283b2a9205480505906071057105050505283b2a9205050505050505050505050505050505050505050505050505050505050505050505
b6b605151617b6b6b6b6b6b6b6b6b6b6b6b605050505b6b60505050505050505050505050580818181818205050505050505050505050505050505050505050505900505050571050538393a920505050590057105050505050538393a9205050505050505050505050505050505050505050505050505050505050505050505
b6b605b6b6b6b6b6b6b6b6b6b6b6b6b6b6b605b6b6b6b6b60505050505050505050505050590050560059205050505050505050505058081818181818181820505a081818181818181818181a205050505a08181818181818181818181a205050505050505050505050505050505050505050505050505050505050505050505
b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6050505050505050505050505059005050505920505050505050505050505901819191919191a92050505050505050505050505050505050505050505050505050505050505050505050505050505050505b605050505050505050505050505050505050505050505
b6b6b6b6b6b640b6b6b660b6b6b6b6b6b6b6b6b6b6b640b605056005050505050505050505900505050592050505050505050505050590281b291b1b1b2a92050505050505050505050505050505050505050505050505050505054805050505050505050505050505b605050505050505050505050505050505050505050505
b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b605050505050505050505050505900505050592050505050505050505050590281b1b1b2b1b2a92050505050505050505050505050505050505050505050505050505050505050505050505050505050505b605050505050505050505050505050505050505050505
b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6050505050505901819191a9205050505b6050505050505a03839393939393aa205050505050505050505050505050505b6050505050505050505050505050505b6b6b6b6b6b6b6b6b6b60505050505050505050505050505050505050505050505
b6b6b6b6b6b6b6b6482526b6b6b6b6b6b6b6b6b6b6b6b6b648b6b6b6b6b6b6050505050505903839393a9205050505b60505050505050505050505050505050505050505050505054005050505050505050505050505050540050505050505050505050505050505050505050505050505050505050505050505050505050505
b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6050505050505a081818181a205050505b60505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b6b60505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
808181818181818182aaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
901819191919191a92aaaaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
90281b291b1b1b2a92aa18191aaa181919191a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
90281b1b1b2b1b2a92aa283b2aaa28291b1b2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
a03839393939393aa2aa38393aaa281b1b2b2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
aaaaaaaaaaaaaaaaaaaaaaaaaaaa383939393a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
aaaaaaaaaaaaaaaaaaaaaaaab5aaa99200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
aaaaaaaaaaaaaaaaaaaa18191919191a001819191a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505
aaaaaaaaaaaaaaaaaab438393939393a003839393a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000505050505050505050505050505050505050505050505050505050505050000000000000000000000000000000000000000000000000000000000000000000000
90aa60aaaaaaaaaab3aab4aa2baaa99200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90aaaaaaaa60aab3aaaab4aaaaaaa99200181a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90aaaaaa71aaaaaaaaaaaaaa71aaa99200282a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90aaaaaaaaaaaaaaaab5aaaab4aa649200282a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
909191a1aaaa3baaaaaaaaaaaaaaa99200383a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9040aaaaaaaab1aaaaaaaa1c2daaa99200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a08181818181818181818181818181a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010300000064500600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000000000000
010400001103300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
010700001d11528111301110010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500000
0108000024125281211f1210010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500100001000010000100
010500001801024011000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
010a000024055280552b0553705500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500000000000000000000
010400000e25500000000000725500205002050020500205002050020500205002050020500205002050020500205002050020500205002050020500205002050020500205002050020500205002050020500205
010500000063400630006350060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500600
010900003063024630186300c63000630006300063000630006300062000610006100060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000000
01050000061510000100151011510115101151011510115101151011510115101151011510115101151011510115101151011510115101151011510015100151021012b0502b0412b0312b0212b0101d3011d301
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000010061000600006000060000600006000c60000600136000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
011000000c23500205002050020500205002050c2350020507235002050020500205002050020507235002050c235002050020500205002050020500205002050020500205002050020500205002050020500205
0110000005235002050020500205002050020505235002050c23500000002050020500205002050c2350020505235002050020500205002050020500205002050020500205002050020500205002050020500205
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c04300003000000000330615000030c025000030c0430000330615000030000300000306150000300003000030c02500003306150000313025000030c04300003000030000330615000030000300000
011000000c04300003000000000330615000030c025000030c0430000330615000030000300000306150000300003000030c02500003306150000313025000030c0430000324035230001f035000001d03500000
011000000c043000030000000003306150000305025000030c0430000330615000030000300000306150000300003000030c02500003306150000305025000030c04300003000030000329123000030000300000
010c00001102500005000050000515025000050000500005180250000500005000051c0250000500005000051102500005000050000515025000050000500005180250000500005000051c025000050000500005
011000001f235000051f205000051c20521200000001c2000000500000152050000521235212001c235212001c2001c200000051c205000051a20500005182050000515205000051820518005000050000500005
011000001a235000051f205000051c20521200000001c20000005000001520500005182352120015235212001c2001c200000051c205000051a20500005182050000515205000051820518005000050000500005
011000001a235000051f205000051c20521200000001c200000050000015205000051c2352120015235212001c2001c200000051c205000051a20500005182050000515205000051820518005000050000500005
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b000024173181730c1730017300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
010a00001805300000180230000018653000001805300000000000000018053000001865318023000000000018053000000000000000186530000018053000001800000000180530000018653000000000000000
010a00000c1100c2200c1100c2200c3300c3300c1100c2200c3300c2300c2300c2300c2300c2300c2300c23006130062300633006230062300623006230062300623006230062300623006230062300623006230
010a00000511005220051100522005330053300511005220053300523005230052300523005230052300523001130012300133001230012300123001230012300123001230012300123001230012300123001230
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b00002b0502b0402b0302b0202b0102b0012b0010000100611006110c6210c6211863118631246412464130651306510000100001000010000100001000010000100001000010000100001000010000100001
__music__
03 0b424344
01 4c504610
00 0c144310
00 0c144311
00 0d154312
02 0d164310
01 191a4344
02 191b4344
04 24424344

