pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

dbg = true

ctrl = {
  out = false,
}

asdsad = 0

-- time
t = 0

-- game state
gs = {}
gs.map = 0

-- game mode
-- 0: title
-- 1: gameplay
-- 2: gameplay won stage
-- 3: ???
gs.mode = 1

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
}

tunes = {
  ambient=0,
  sheep_theme=1,
  b=2,
  c=3,
  d=4,
}

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

    music(tunes[a.music])
  else
    local a = actors[ctrl.target]

    ctrl.out = true
    ctrl.x = x or actors[ctrl.target].x
    ctrl.y = y or actors[ctrl.target].y

    if a then
      actors[ctrl.target].controlled = false
    end

    sfx(snd["out_of_control"])

    music(tunes["ambient"])
  end
end

function move_animal(a, x, y)
  a.time_at_last_move = t

  local target_x = a.x + (x or 0)
  local target_y = a.y + (y or 0)

  local map_sprite = mget(target_x, target_y)
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
    if actor_in_cell.s == library["chicken"].s then
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
  -- if player move item...
  -- if player move item...
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

  local map_sprite = mget(target_x, target_y)
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

function win_stage()
  gs.mode = 2
  ctrl.out = false
  sfx(snd["chime"])
  music(-1)
end

function get_input()
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

    if btnp(5) then
      -- reset any changes to map
      reload(0x2000, 0x2000, 0x1000)

      load_map(gs.map)
    end

    if btnp(🅾️) then
      local i = actor_i_at_cell(ctrl.x, ctrl.y)
      if i then
        -- if(actors[i].name == "sheep") then
          set_ctrl(i)
        -- end
      else
        sfx(snd["nope"])
      end
    end

    -- check for win
    if mget(ctrl.x, ctrl.y) == 12 and gs.gate_open then
      win_stage()
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
  },
  demon = {
    s=64,
  },
  grass = {
    s=182,
  },
  gate = {
    s=12,
  }
}

function load_map(i)
  -- clear out all actors
  actors = {}
  items = {}

  -- load map based on index
  gs.map = i

  for i=0,16 do
    for j=0,16 do
      local current_cell = mget(i,j)
            
      if current_cell == library["sheep"].s then
        local s = clone_table(library["sheep"])
        s.x = i
        s.y = j
        s.time_at_last_move=t

        add(actors, s)

        -- remove from map
        mset(i, j, library["grass"].s)
      end
             
      if current_cell == library["chicken"].s then
        local s = clone_table(library["chicken"])
        s.x = i
        s.y = j
        s.time_at_last_move=t

        add(actors, s)

        -- remove from map
        mset(i, j, library["grass"].s)
      end

             
      if current_cell == library["cow"].s then
        local s = clone_table(library["cow"])
        s.x = i
        s.y = j
        s.time_at_last_move=t

        add(actors, s)

        -- remove from map
        mset(i, j, library["grass"].s)
      end

      if current_cell == library["rock"].s then
        local r = clone_table(library["rock"])
        r.x = i
        r.y = j

        add(items, r)

        -- remove from map
        mset(i, j, library["grass"].s)
      end
      
      if current_cell == library["demon"].s then
        -- put demon here
        set_ctrl(0, i, j)

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

function should_gate_open()
  for i,a in ipairs(actors) do
    local animal_in_pit = fget(mget(a.x, a.y)) == 128
    if not animal_in_pit then
      return false
    end
  end
  return true
end

function update_gate()
  gs.gate_open = should_gate_open()
end

function update_gameplay()
  get_input()
  update_all_animals()
  update_gate()
  t += 1
end

function update_gameplay_won_stage()
  t += 1
end

function draw_gameplay()
  cls()
  palt(0, true)
  palt(11, false)
  map(0, 0, 0, 0, 16, 16)
  -- spr(p1.s, p1.x * 8, p1.y * 8)

  palt(0, false)
  palt(11, true)

  for i,item in ipairs(items) do
    spr(item.s, item.x * 8, item.y * 8)
  end

  for i,actor in ipairs(actors) do
    if actor.controlled then
      spr(actor.s - 16, actor.x * 8, actor.y * 8)
    else
      spr(actor.s, actor.x * 8, actor.y * 8)
    end
  end

  if ctrl.out then
    spr(48, ctrl.x * 8, ctrl.y * 8 + sin(t/60)*1.25)
  end

  if dbg then
    color(8)

    -- print("time: "..t)
    print("num actors: "..#actors)
    print("gate_open:"..tostring(gs.gate_open))
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

function draw_gameplay_won_stage()
  cls()
end

function _init()
  load_map(gs.map)
end

function _draw()
  if gs.mode == 1 then draw_gameplay() end
  if gs.mode == 2 then draw_gameplay_won_stage() end
end

function _update60()
  if gs.mode == 1 then update_gameplay() end
  if gs.mode == 2 then update_gameplay_won_stage() end
end

function clone_table(t)
  local new_t = {}

  for key, value in pairs(t) do
    new_t[key] = value
  end

  return new_t
end


__gfx__
00000000555555551111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333bbb22222bbb88888bbbdddddbb
00000000555555551111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3b2000002b8000008bd11111db
00700700555555551111111111666611bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3b2111112b8000008bd00000db
00077000555555551111111111666611bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3b2000002b8111118bd00000db
00077000555555551111111111666611bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbb3b3bb333bb3bb3bb3bbbbbbbbbbbb3bb3bb3b2000002b8000008bd11111db
00700700555555551111111111555511bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbb33bbbb3b3bb3b3bb3bbbbbbbbbbb3bb3bb3b2111112b8000008bd00000db
00000000555555551111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbb333bbb3bb3bb3b3b3b3bbbbbbbbbb3bb3bb3b2000002b8111118bd00000db
00000000555555551111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333b2222222b8888888bdddddddb
11111111111111111111111111111111bbbbbbbbbb3bb3bbbbbbbbbbb33333bbbbbbbbbbbbbbbbbbbbbbbbbbb11b111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
11111111111111111111711111117111bbbbbbbbb333333bbbbbbbbb3333333bbb1111111b111111111111bb13313331b33333333333333b3333333b3333333b
11177711111771111117171111171711bbbbbbbbb333333b333bbbbb33333333b1333333313333333333331b3333333333bbbbb3333bb33333bb333333bbb333
11171711111171111111171111111711bbbbbbbbb333333b3b3bbbbb3333333bb3333333333333333333333b3333333333bbbbbb3333b3333333b3333333b333
11177711111171111111711111117111bbbbbbbbb333333b333b333b3333333bb333333333333333333333bb3333333333bbbbb33333b33333b33333333bb333
11171111111171111117111111111711bbbbbbbbbb3333bbbbbbb33bb33333bbb3333333333333333333333b33333333333b33b33333b33333bbb33333bbb333
11171111111777111117771111177111bbbbbbbbb3333bbb3bbb3b3bbb3bb3bbbb333333333333333333333b33333333b33333333333333b3333333b3333333b
11111111111111111111111111111111bbbbbbbbbbbbbbbbb333bbbbbbbbbbbbb3333333333333333333333bb333b33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333ddd3333333333bb111b11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333ddddd333333333b13331331b33333333333333b3333333b3333333b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333d5d5d3d3333333b333333333333bb3333b3b33333bbb33333bbb333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333dd5dd3d3333333b333333333333bbb333bbb33333b3333333b33333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333ddd33d3333333b33d3333333bbbb333333b333333bb33333bbb333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333b333d333333bbbb333333b33333bbb33333bbb333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333d333333333333bb33333333b33333333333333b3333333b3333333b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333d333333333333bb333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb2bb2bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333bb111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b222222bb77bb77bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333b13333331b33333333333333b3333333b3333333b
b227272bb7bbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333b333ddd3333bbbbbb33bbb333333bb33333bbb333
b227272bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333b33ddddd333bbbbbb3333b33333bbb33333bbb333
b222222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333b335d5dd333bbbbbb3333b33333b3b3333333b333
bb2222bbb7bbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333b33d5ddd333b333b33333b33333bbb33333bbb333
b2222bbbb77bb77bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333b333333333b33bb333ddd33b33333333333333b3333333b3333333b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb2bb2bbbb22bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b222222bb222bbbb222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b227272bb22222bbb222bbbbbbbbb2b2bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b227272bb222222bb2222222bbb22222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b222222bb2222222b2222222bbb22222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb2222bbb2222222bb222222bb222222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b2222bbbbb222222bbb22222b2222222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbb3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b72772bbb72772bbbbb2bb2bbbb2bb2b0022222200222222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7722227b7722227bbbb2222bbbb2222b0022727200227272bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7227272272272722bbb27272bbb272720702222707022227bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7722222b7722222bb7b2222bb7b2222b7772222777722227bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7777777b7777777bb777777bb777777b7777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b77777bbb777777bb777666bb777666b7777777b7777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
33f33f333f3333f333a33a333a3333a33303303330333303bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b333333bb333333bb333333bb333333bb333333bb333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b77777bbb77777bbbbb888bbbbb888bb00ffffff00ffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
77ffff7b77ffff7bbbb7777bbbb7777b000f0f07000f0f07bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7ff0f0ff7ff0f0ffbbb7707abbb7707a070ffff7070ffff7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
77fffffb77fffffbb7b7777bb7b7777b777eeee7777eeee7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7777777b7777777bb777777bb777777b7777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b77777bbb777777bb777666bb777666b7777777b7777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
33f33f333f3333f333a33a333a3333a33303303330333303bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b333333bb333333bb333333bb333333bb333333bb333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbffffbbb66666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bff44ffb66667766bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ff4ff4ff66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
4ff44ff466666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
44ffff4465556665bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
4444444455555655bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
3444444335555553bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b333333bb333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb7bbbbbb77bbbbbb7bbbbbbbbbbbbbbbbbbbb88b88b88fffbffbfffbffbffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb767bbbb7667bbbb767bbbbbbbbbbbbbbbbbbb88b88b88bfffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb766bbbb6666bbbb667bbbb888888bbbbbbbbb22b22b22fffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb766777766667777667bbb88777788b888888b22222222ffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb766666666666666667bbb887887888877778822222222bfffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb766bbbb6666bbbb667bbb288888828878878822b22b22fffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb766bbbb6666bbbb667bbb322222233888888322b22b22ffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb763bbbb3333bbbb367bbbb333333bb333333b33b33b33ffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbbbbbbbbbbbb67bbbbbbbbbbbbbbbbbbbaabaabaafffffffffffbffbfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbbbbbbbbbbbb67bbbbbbbbbbbbbbbbbbbaabaabaabfffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbbbbbbbbbbbb67bbbbaaaaaabbbbbbbbb99b99b99fffffffbffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbbbbbbbbbbbb67bbbaa7aa7aabaaaaaab99999999ffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbbbbbbbbbbbb67bbbaa7777aaaa7aa7aa99999999bfffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbb3b3bbbbbbb67bbb9aaaaaa9aa7777aa99b99b99fffffffbffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbbb3bbbbbbbb67bbb399999933aaaaaa399b99b99ffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb76bbbbbbbbbbbbbb67bbbb333333bb333333b33b33b33ffffffffffbffbffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb77bbbbbbbbbbbbbb77bbbbbbbbbbbbbbbbbbbccbccbccffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb767bbbbbbbbbbbb767bbbbbbbbbbbbbbbbbbbccbccbccbfffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb666bbbbbbbbbbbb666bbbbccccccbbbbbbbbb11b11b11fffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb66677bbbbbbbb77666bbbcc7777ccbccccccb11111111ffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb66666bbbbb9bb66666bbbccc77ccccc7cc7cc11111111bfffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb666bbbbbb9b9bbb666bbb1cccccc1cc7777cc11b11b11fffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb666bbbbbbb9bbbb666bbb311111133cccccc311b11b11ffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb333bbbbbbbbbbbb333bbbb333333bb333333b33b33b33ffbffbffffbffbffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb77777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb9bbbbbbbbbbb3b3bbbbb7bbbbbb3b3bbbbbbbb3bbbbbbbbbbbb7bbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb9b9bbbbbbbbbbb3bbbbb7b7bbbbbb3bbbbbbbb333bbbbbbbbbbb7bbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb9bbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbabbbbbbbbbbbbbbbbbbbbbbbdbbbbbbbbbbbbbbbbbb7bbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbababbbbbbbbbbbbbbbbbbbbbdbdbbbbbbbbbbbbbbbbb7bbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbabbbbbbbbbbbbbbb3bbbbbbbdbbbbbbbbbbbbbbbbbb7bbbbbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbbbbbbbbbbbbbb77777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
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
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
__gff__
0001000000000000000000000000000000000000000000008080808000000000000000000000000080808080000000000000000000000000808080800000000000000000000000000000000000000000000002020202000000000000000000000200020202020000000000000000000001070000020000000000000000000000
0101010000000000000000000000000001000100000000000000000000000000010001000000000000000000000000000204000000030002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
8081818181818181818181818181818200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6b6b6b6b6b6b6b6b6b666b6b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6b6b6b6b6b618191ab6b691b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6717171b6b628292ab6b6b6b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6716471b6b638393ab6b6b6b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90407171717171b6b671717158b61d9200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b691b6716271b6b5716071b6b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6b6b6717171b6b6717171b6b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6b6b6b6b6b6b6b6b6b6b6b6b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6b6b6b4b6b6b60cb6b6b6b6b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6b6b6b6b6b6b6b6b6b6b6b6b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6b6b6b6b6b6b6b6b6b6b671b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6b6b6b6b6b6b6b6b6b6b6b6b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6b671b6b6b3b6b6b6b691b6b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90b6b6b6b6b6b6b6b6b6b6b6b6b6b69200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a08181818181818181818181818181a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010300000062500600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000000000000
010400001103300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
010700001d11528111301110010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500000
0108000024125281211f1210010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500100001000010000100
010500001801024011000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
010a000024055280552b0553705500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500000000000000000000
010400000e25500000000000725500205002050020500205002050020500205002050020500205002050020500205002050020500205002050020500205002050020500205002050020500205002050020500205
010500000063400630006350060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500600
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000010061000600006000060000600006000c60000600136000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
010c00000c0250000500005000051002500005000050000513025000050000500005170250000500005000050c025000050000500005100250000500005000051302500005000050000517025000050000500005
010c00000e0250000500005000051102500005000050000515025000050000500005180250000500005000050e025000050000500005110250000500005000051502500005000050000518025000050000500005
010c00001102500005000050000515025000050000500005180250000500005000051c0250000500005000051102500005000050000515025000050000500005180250000500005000051c025000050000500005
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b000024173181730c1730017300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
01100000071000710007100071000f1000f1000f1000f1000e1000e1000e1000e1000910009100091000910000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 50424310
03 41424311
03 41424312
03 41424313

