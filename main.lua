﻿baton = require 'lib.Baton.baton' --BATON INPUT
Camera = require 'lib.Camera.camera'  --STALKERX CAMERA
bump = require 'lib.bump.bump'
require'f'
require'loadmusic'
require'chunk-generator'

gameName="CaveDig"
version=21
ru=false
cheat=false

local input = baton.new {
  controls = {
    left = {'key:left', 'key:a', 'axis:leftx-', 'button:dpleft'},
    right = {'key:right', 'key:d', 'axis:leftx+', 'button:dpright'},
    up = {--[['key:up', 'key:w', 'axis:lefty-', 'button:dpup']]},
    down = {--[['key:down', 'key:s', 'axis:lefty+', 'button:dpdown']]},
    jump = {'key:space','button:a'},
  },
  pairs = {
    move = {'left', 'right','up','down'}
  },
  joystick = love.joystick.getJoysticks()[1],
}

if(rus)then
rtxt={"Не копай под себя","Также попробуйте Minecraft и Terraria","Постоянные вылеты!",
"OwO","Без ГМО","Что это за игра?","Скидка 100%","Красивые блоки","Не содержит сахар!",
"РACCKA3 O ПTNЦAX БE3 ГОЛ0СА","Привет, <ваше имя>.","Шоу русалок:15423","Баги везде!"}
else
rtxt={"Do not dig for yourself", "Also try Minecraft and Terraria", "Constant crashes!",
"OwO", "Non-GMO", "What kind of game is this?", "100% discount", "Beautiful blocks", "Sugar free!",
"tpt", "Hello, <your name>.", "Mermaid show: 15423", "Bugs everywhere!"}
end

texture_dir="textures/world/"
brk_texture_dir="textures/destroy/"
events={}
player={x=0,y=0,brk=0,jump=false}

player.inventory={}
player.inventory.slots=5
player.hp = 20
player.maxhp = 20

world={chunk={},tile={}}
world.tile.textures={}

world.tile.destroy_textures={}
world.tile.brktxt_count=10
world.tile.strength={20,20,100,10,50,10,50,10}

world.tile.texture_files={"dirt.png","grass.png","stone.png","sand.png","wood.png","leaves.png","sandstone.png","cactus.png"}
world.w=64
world.h=64
world.name="World"
world.chunk.data=table.fill(world.h*world.w,0) -- blocks data
world.chunk.id={x=0,y=0}
world.tile.h=32
world.tile.w=32

require'font'
require'physics'
require'chunk-loader'
require'menu'

function initGame(wn)
  world.name=wn or world.name
  inGame=true
  if not(gameInit)then
    chl.f.init()
    phy.init()
    gameInit=true
  end
end

function closeGame()
  if(gameInit)then chl.f.saveChunk() end
  love.window.close()
  love.event.quit()
end

function XYtoBlock(mx,my)
  local x=math.ceil(mx/world.w*2)
  local y=math.ceil(my/world.h*2)
  return x,y
end

function love.threaderror(thread, errorstr)
  print("Thread error!\n"..errorstr)
end

function love.keypressed(key,scancode,isrepeat) --DEBUG
  if(key=="k")then chl.f.saveChunk() end

  print(key.." "..tostring(isrepeat))
  if(key=="e")then inGame=false end

  if(cheat) then
    if(key=="q")then world.tile.strength={0,0,0,0,0,0} end
    if(key=="g")then player.weight=-player.weight end
    if(key=="v")then world.tile.h=world.tile.h+1;world.tile.w=world.tile.h end
    if(key=="b")then world.tile.h=world.tile.h-1;world.tile.w=world.tile.h end
    if(key=="m")then if(world.w<64)then world.w=world.w+1;world.h=world.h+1 end; end
    if(key=="n")then world.w=world.w-1;world.h=world.h-1; end
  end


end



function love.load()
  love.window.setVSync(-1) --11,3 only
  love.window.setTitle(gameName.." v."..version.." - "..rtxt[love.math.random(1,table.count(rtxt))])
  h=love.graphics.getHeight()
  w=love.graphics.getWidth()
  for i=1,table.count(world.tile.texture_files) do
    world.tile.textures[i]=love.graphics.newImage(texture_dir..world.tile.texture_files[i])
  end
  for i=1,world.tile.brktxt_count do
    world.tile.destroy_textures[i]=love.graphics.newImage(brk_texture_dir..i..".png")
  end

  ------------------------------------------------------------------------------
  --initGame()
  ------------------------------------------------------------------------------

  camera = Camera()
  camera:setBounds(0,0,(world.w-1)*world.tile.w, (world.h-1)*world.tile.h)
  camera:setFollowStyle('PLATFORMER')

  print("res w:"..w.." h:"..h)

  menu.init()
end

function love.update(dt)
  collectgarbage("collect")

  udt=dt
  fps=love.timer.getFPS()

  m1, m2 = love.mouse.isDown(1),love.mouse.isDown(2)
  mx, my = love.mouse.getPosition()

  input:update()

  if not(inGame) then
    menu.loop()
  else
    if(input:pressed 'jump') and phy.player.isOnGround() then
      player.jump=true
    end

    inputx,inputy=input:get 'move';
    px,py= inputx*(4)+(rpx or w/2),inputy*(4)+(rpy or h/2)

    camera:update(dt)
    camera:follow((rpx or 0)-4-world.tile.w/2,(rpy or 0)+4-world.tile.h/2)

    mxw,myw=camera:toWorldCoords(mx,my)
    mxb,myb=XYtoBlock(mxw,myw)
    mouseBlock=world.chunk.data[t1d2d(mxb,myb,world.w)]

    if(m1 and mouseBlock>0 and (player.prevBlock==t1d2d(mxb,myb,world.w) or player.brk==0))then
      player.prevBlock=t1d2d(mxb,myb,world.w)
      player.brk=player.brk+1
      if(player.brk>world.tile.strength[mouseBlock])then
        world.chunk.data[t1d2d(mxb,myb,world.w)]=0
      end
    else
      player.brk=0
    end
    if(m2 and world.chunk.data[t1d2d(mxb,myb,world.w)]==0)then
      world.chunk.data[t1d2d(mxb,myb,world.w)]=3
    end

    local function movp(x,y)
      if x then px=x*world.tile.w end
      if y then py=y*world.tile.h end
      if x or y then phy.world:update(phy.player,px,py) end
    end

    if(px<0)then
      chl.f.moveToChunk(world.chunk.id.x-1,world.chunk.id.y)
      movp(world.w-2,-16)
      phy.player.dropOnGround()
    end
    if(px>world.w*world.tile.w)then
      chl.f.moveToChunk(world.chunk.id.x+1,world.chunk.id.y)
      movp(2,-16)
      phy.player.dropOnGround()
    end

    phy.loop()
  end
end

function love.draw()

  love.graphics.setBackgroundColor(0,0,0)
  if not(inGame) then
    menu.draw()
  else
    love.graphics.setBackgroundColor(0.5,0.5,1)

    camera:attach()

    for i=1,world.w-1 do
      for j=1,world.h-1 do
        rangex=2*world.tile.h
        rangey=2*world.tile.w
        local tmpx=(i*world.tile.w)-camera.x+w/2
        local tmpy=(j*world.tile.h)-camera.y+h/2
        if(tmpx>0-rangex and tmpx<w+rangex and tmpy>0-rangey and tmpy<h+rangey)then
          local texture_id=world.chunk.data[t1d2d(i,j,world.w)]
          if(texture_id>0)then
            love.graphics.draw(world.tile.textures[texture_id],(i-1)*world.tile.h,(j-1)*world.tile.w)
          end
        end
      end
    end

    if(player.brk>0)then
      local txtid=math.min(math.floor(player.brk/world.tile.strength[mouseBlock]*world.tile.brktxt_count)+1,10)
      love.graphics.draw(world.tile.destroy_textures[txtid],(mxb-1)*world.tile.h,(myb-1)*world.tile.h)
    end

    --player (white rect)
    love.graphics.rectangle('fill',(rpx or 0)-world.tile.h,(rpy or 0)-world.tile.w,world.tile.w-4,(world.tile.h*2)-4)

    --hp bar
    love.graphics.setColor(255,0,0)

    love.graphics.rectangle('fill',(rpx or 0)-world.tile.h-15,(rpy or 0)-world.tile.w-35,60,10)
    love.graphics.setColor(0,255,0)
    love.graphics.rectangle('fill',(rpx or 0)-world.tile.h-15,(rpy or 0)-world.tile.w-35,math.min(math.max(60-(player.maxhp-player.hp),0),60),10)
    love.graphics.setColor(255,255,255)


    camera:detach()
    camera:draw()
  end
  love.graphics.print("FPS:"..fps.." dt:"..udt,0,0)
end