pico-8 cartridge // http://www.pico-8.com
version 18
__lua__


local keys = {
    left = 0,
    right = 1,
    up = 2,
    down = 3,
    z = 4,
    x = 5,
}

local consts = {
    gravity = .3001,
    jumpvel = 3,
    horiz_speed = .9,
    copyframes = 180,
    gateclosed = 16,
    gateopen = 17,
}

local flags = {
    collide = 0,
    button = 1,
    door = 2,
}
local spritedata = {
    x_start = 0,
    x_end = 6,
    y_start = 1,
    y_end = 7,
}

local world = {
    mapx = 0,
    mapy = 0,
    level = 0,
}

local gamestate = "m"

local buttons = {
    -- button x, y (on level)
    -- door x, y (on map)
    {
        level = 0,
        btnx = 15,
        btny = 14, 
        gatex = 10, 
        gatey = 10,
        default = false,
    },
    {
        level = 1,
        btnx = 3,
        btny = 14, 
        gatex = 27, 
        gatey = 10,
        default = false,
    },
    {
        level = 1,
        btnx = 7,
        btny = 14, 
        gatex = 28, 
        gatey = 10,
        default = false,
    },
    {
        level = 2,
        btnx = 2,
        btny = 14,
        gatex = 44,
        gatey = 14,
        default = true,
    },
    {
        level = 2,
        btnx = 3,
        btny = 14,
        gatex = 43,
        gatey = 14,
        default = false,
    },
    {
        level = 2,
        btnx = 4,
        btny = 14,
        gatex = 45,
        gatey = 14,
        default = false,
    },
    {
        level = 3,
        btnx = 2,
        btny = 7,
        gatex = 54,
        gatey = 5,
        default = false,
    },
    {
        level = 3,
        btnx = 3,
        btny = 8,
        gatex = 55,
        gatey = 5,
        default = false,
    },
    {
        level = 3,
        btnx = 4,
        btny = 9,
        gatex = 56,
        gatey = 5,
        default = false,
    },
    {
        level = 3,
        btnx = 5,
        btny = 10,
        gatex = 57,
        gatey = 5,
        default = false,
    },
    {
        level = 4,
        btnx = 5,
        btny = 5,
        gatex = 70,
        gatey = 12,
        default = false,
    },
    {
        level = 4,
        btnx = 5,
        btny = 8,
        gatex = 70,
        gatey = 13,
        default = false,
    },
    {
        level = 4,
        btnx = 5,
        btny = 11,
        gatex = 70,
        gatey = 14,
        default = false,
    },
    {
        level = 5,
        btnx = 3,
        btny = 9,
        gatex = 82,
        gatey = 8,
        default = true,
    },
    {
        level = 5,
        btnx = 3,
        btny = 9,
        gatex = 83,
        gatey = 8,
        default = true,
    },
    {
        level = 5,
        btnx = 3,
        btny = 9,
        gatex = 84,
        gatey = 8,
        default = true,
    },
    {
        level = 5,
        btnx = 3,
        btny = 9,
        gatex = 88,
        gatey = 8,
        default = false,
    },
    {
        level = 5,
        btnx = 3,
        btny = 9,
        gatex = 89,
        gatey = 8,
        default = false,
    },
    {
        level = 5,
        btnx = 3,
        btny = 9,
        gatex = 90,
        gatey = 8,
        default = false,
    },
    {
        level = 6,
        btnx = 0,
        btny = 14,
        gatex = 102,
        gatey = 12,
        default = true,
    },
    {
        level = 6,
        btnx = 8,
        btny = 14,
        gatex = 106,
        gatey = 11,
        default = true,
    },
    {
        level = 7,
        btnx = 11,
        btny = 14,
        gatex = 121,
        gatey = 13,
        default = true,
    },
    {
        level = 7,
        btnx = 11,
        btny = 14,
        gatex = 122,
        gatey = 12,
        default = true,
    },
    {
        level = 8,
        btnx = 5,
        btny = 3,
        gatex = 8,
        gatey = 22,
        default = false,
    },
}

local clones = {}

leveldialog={
    -- "hello my little squirrel,",
    "we have blessed you with ",
    "the ability to diverge.",
    "this allows you to clone ",
    "the last 6 seconds of your ",
    "actions.",--" now, to test your ",
    -- "intelligence, go find your ",
    -- "acorns! if you can succeed, ",
    -- "we might release you.  ",
    "good luck.",
    "'x' to diverge, 'z' to reset",
}
credits = {
    "credits",
    "",
    "artists",
    "-------",
    "jessica hofmeister",
    "caitlin gaff",
    "",
    "developers",
    "----------",
    "benjamin ryker",
    "jessica hofmeister",
    "",
    "thank you for playing"
}

local Class = {}
function Class:Subclass(object)
    object = object or {}
    setmetatable(object, self)
    self.__index = self
    return object
end

function Class:init(args)
    return self:Subclass(args)
end

local Dude = Class:Subclass()
local Clone = Dude:Subclass()

function Dude:initialize(args)
    self.x = args.x or 0
    self.y = args.y or 0
    self.vx = args.vx or 0
    self.vy = args.vy or 0
    self.startindex = args.startindex or 0
    self.historyindex = args.historyindex or 0
    self.history = args.history or {}
    if (self.history == {}) then 
        for i=0, consts.copyframes do
            self.history[i] = 0
        end
    end
end

function Dude:sprite_at(x, y)
    return mget(flr(x/8 + world.mapx), flr(y/8 + world.mapy))
end

function Dude:check_buttons()
    local cur_sprite = Dude:sprite_at(self.x + 4, self.y + 4)
    if (fget(cur_sprite, flags.button)) then
        sfx(8)
        for i in all(buttons) do
            if (i.btnx == flr((self.x + 4)/8) and i.btny == flr((self.y + 4)/8)) then
                i.open = not i.default
            end
        end
    end
end

function Dude:hold_gates()
    local cur_sprite = Dude:sprite_at(self.x + 4, self.y + 4)
    if (cur_sprite == consts.gateopen) then
        for i in all(buttons) do
            if (i.gatex == flr((self.x + 4)/8 + world.mapx) and i.gatey == flr((self.y + 4)/8 + world.mapy)) then
                i.open = true
            end
        end
    end
end

function Dude:check_door()
    if (fget(Dude:sprite_at(self.x + 4, self.y + 4), flags.door)) then
        world.level += 1
        world.mapx = (world.level % 8) * 16
        world.mapy = (flr(world.level / 8)) * 16
        clones = {}
        world.player:initialize({})
        sfx(10)
    end
end

function Dude:check_input()
    local keycode = 0

    self.vx = 0
    if (btn(keys.left)) then
        keycode += 2^keys.left
        self.vx -= consts.horiz_speed
    end
    if (btn(keys.right)) then
        keycode += 2^keys.right
        self.vx += consts.horiz_speed
    end
    if (btnp(keys.up)) then
        keycode += 2^keys.up
        if (self.vy == 0) then
            self.vy = -consts.jumpvel
        end

        --jump validation
    end
    -- if (btn(keys.down)) then
    --     keycode = bor(keycode, 2^keys.down)
    -- end
    if (btnp(keys.x)) then
        sfx(12)
        keycode = bor(keycode, 2^keys.x)
        local newclone = Clone:init()
        newclone:initialize({
            x = self.x,
            y = self.y,
            vx = self.vx,
            vy = self.vy,
            historyindex = self.historyindex + 2,
            startindex = self.historyindex + 1,
            history = self.history,
        })
        add(clones, newclone)

        -- splitting
    end
    self.history[self.historyindex] = keycode
    self.historyindex += 1
    -- print(self.historyindex)
    self.historyindex %= consts.copyframes
end

function Dude:update_pos()
    self.vy += consts.gravity
    self.x += self.vx
    


    if (self.x + spritedata.x_end > 127) then
        self.x = 127 - spritedata.x_end
    end
    if (self.x + spritedata.x_start < 0) then
        self.x = 0 - spritedata.x_start
    end

    if (fget(self:sprite_at(flr(self.x) + spritedata.x_start, ceil(self.y) + spritedata.y_end), flags.collide)) then -- lower left
        self.x = flr((flr(self.x) + spritedata.x_start) / 8 + 1) * 8 - spritedata.x_start
    end

    if (fget(self:sprite_at(ceil(self.x) + spritedata.x_end, ceil(self.y) + spritedata.y_end), flags.collide)) then -- lower right
        self.x = flr((ceil(self.x) + spritedata.x_end) / 8) * 8 - spritedata.x_end - 1 
    end

    if (fget(self:sprite_at(flr(self.x) + spritedata.x_start, flr(self.y) + spritedata.y_start), flags.collide)) then -- upper left
        self.x = flr((flr(self.x) + spritedata.x_start) / 8 + 1) * 8 - spritedata.x_start
    end

    if (fget(self:sprite_at(ceil(self.x) + spritedata.x_end, flr(self.y) + spritedata.y_start), flags.collide)) then -- upper right
        self.x = flr((ceil(self.x) + spritedata.x_end) / 8) * 8 - spritedata.x_end - 1 
    end



    self.y += self.vy

    if (self.y + spritedata.y_end > 127) then
        self.y = 127 - spritedata.y_end
        self.vy = 0
    end
    if (self.y + spritedata.y_start < 0) then
        self.y = 0 - spritedata.y_start
        self.vy = .1
    end

    if (fget(self:sprite_at(flr(self.x) + spritedata.x_start, ceil(self.y) + spritedata.y_end), flags.collide)) then -- lower left
        self.y = flr((ceil(self.y) + spritedata.y_end) / 8) * 8 - spritedata.y_end - 1 
        self.vy = 0
    end

    if (fget(self:sprite_at(ceil(self.x) + spritedata.x_end, ceil(self.y) + spritedata.y_end), flags.collide)) then -- lower right
        self.y = flr((ceil(self.y) + spritedata.y_end) / 8) * 8 - spritedata.y_end - 1 
        self.vy = 0
    end

    if (fget(self:sprite_at(flr(self.x) + spritedata.x_start, flr(self.y) + spritedata.y_start), flags.collide)) then -- upper left
        self.y = flr((flr(self.y) + spritedata.y_start) / 8 + 1) * 8 - spritedata.y_start
        self.vy = .1
    end

    if (fget(self:sprite_at(ceil(self.x) + spritedata.x_end, flr(self.y) + spritedata.y_start), flags.collide)) then -- upper right
        self.y = flr((flr(self.y) + spritedata.y_start) / 8 + 1) * 8 - spritedata.y_start
        self.vy = .1
    end

end

function Dude:draw()
    if(self.vx < 0) then
        spr(1, self.x, self.y)
        spr(2, self.x + 8, self.y)
    else
        spr(1, self.x, self.y, 1, 1, true, false)
        spr(2, self.x - 8, self.y, 1, 1, true, false)
    end
end

function Clone:draw()
    if(self.vx < 0) then
        spr(13, self.x, self.y)
        spr(14, self.x + 8, self.y)
    else
        spr(13, self.x, self.y, 1, 1, true, false)
        spr(14, self.x - 8, self.y, 1, 1, true, false)
    end
end


function Clone:check_input()
    self.historyindex += 1
    self.historyindex %= consts.copyframes

    self.vx = 0
    keycode = self.history[self.historyindex]
    -- print(keycode)
    -- print(self.historyindex)
    if (band(keycode, 2^keys.left) != 0) then
        self.vx -= consts.horiz_speed
    end
    if (band(keycode, 2^keys.right) != 0) then
        self.vx += consts.horiz_speed
    end
    if (band(keycode, 2^keys.up) != 0) then
        if (self.vy == 0) then
            self.vy = -consts.jumpvel
        end
    end

    if (self.historyindex == self.startindex) do
        del(clones, self)
    end

    -- if (btnp(keys.x)) then
    --     keycode = bor(keycode, 2^keys.x)
    --     -- splitting
    -- end
    
    
end


function zspr(n,w,h,dx,dy,dz)

  sx = 8 * (n % 16)

  sy = 8 * flr(n / 16)

  sw = 8 * w

  sh = 8 * h

  dw = sw * dz

  dh = sh * dz



  sspr(sx,sy,sw,sh, dx,dy,dw,dh)
end

-- function _init()
world.player = Dude:init()
world.player:initialize({x=0, y=0})
-- end

function _update()
    cls(0)
    rectfill(0, 0, 127, 127, 0)
    if (gamestate == "m") then --menu
        cls(13)
        zspr(43, 4, 2, 16 + 32, 30, 1)
        zspr(6, 7, 2, 11, 45, 2)
        print("press x to start", 32, 100, 6)
        if (btnp(keys.x)) then
            gamestate = "g"
            world.level = 0
            world.mapx = (world.level % 8) * 16
            world.mapy = (flr(world.level / 8)) * 16
            clones = {}
            world.player:initialize({})
        end
    elseif (gamestate == "c") then --credits
        rectfill(0,0,127,127, 0)
        y = 16
        for i in all (credits) do
            y += 8
            print(i, 0, y, 7)
        end
        if (btnp(keys.x)) then
            gamestate = "m"
        end
    elseif (gamestate == "g") then --game
        rectfill(0,0,127,127)
        for i in all(buttons) do
            i.open = i.default
        end

        world.player:check_buttons()
        for i in all(clones) do
            i:check_buttons()
        end

        world.player:hold_gates()
        for i in all(clones) do
            i:hold_gates()
        end

        for i in all(buttons) do
            if (i.level == world.level) then
                if (i.open) then
                    mset(i.gatex, i.gatey, consts.gateopen)
                else
                    mset(i.gatex, i.gatey, consts.gateclosed)
                end
            end
        end


        map(world.mapx, world.mapy, 0, 0, 32, 32)


        for i in all(clones) do
            i:check_input()
            i:update_pos()
        end

        world.player:check_input()
        world.player:update_pos()
        world.player:draw()

        for i in all(clones) do
            i:draw()
        end

        world.player:check_door()
        for i in all(clones) do
            i:check_door()
        end

        if (btn(4)) then
            world.player:initialize({})
            clones = {}
        end

        if (world.level == 9) then
            gamestate = "c"
        end

        if (world.level == 0) then
            local y = 0
            for i in all(leveldialog) do

                print(i, 8, y, 15)
                y+=8
            end
        end
    end
end

function _init()
    music(0)
end


__gfx__
000000000000090000999900111111111111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd000005000055550000000000
000000000099900009999990111411111111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd005550000555555000000000
007007000909900009994440144444111111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddd050550000555666000000000
00077000499999000990004919999f111111111111111111ddd7777777777dd77dddddd77dd7777777777dd7777777777ddddddd655555000550006500000000
00077000000799900990004919999f011111111111111111ddd7777777777ed77dddddd77ed7777777777ed7777777777edddddd000655500550006500000000
0070070000999999090000901199f0111111111111111111ddd77eeeeee77ed77dddddd77eddeee77eeeeed77eeeeeeeeedddddd005555550500005000000000
000000000000669944000900110101011188821111111111ddd77eddddd77ed77dddddd77eddddd77eddddd77edddddddddddddd000066556600050000000000
000000000000999900000000111010111888882111888211ddd77eddddd77ed77dddddd77eddddd77eddddd7777777777ddddddd000055550000000000000000
666868666688886666666666611111165555555555555555ddd77eddddd77ed77dddddd77eddddd77eddddd7777777777edddddd000000000000000000000000
66878666111111116666666661111116555555d555555555ddd77eddddd77ed77dddddd77eddddd77eddddddeeeeeee77edddddd000000000000000000000000
666878661111111168686868811111185555555d55555555ddd77eddddd77ed77dddddd77eddddd77eddddddddddddd77edddddd000000000000000000000000
668786661111111187878786811111185555555555555555ddd77eddddd77ed7777777777eddddd77eddddd7777777777edddddd000000000000000000000000
666878661111111168787878811111185555555555555555ddd77eddddd77ed7777777777eddddd77eddddd7777777777edddddd000000000000000000000000
668786661111111186868686811111185555555555555555ddddeeddddddeeddeeeeeeeeeeddddddeeddddddeeeeeeeeeedddddd000000000000000000000000
666878661111111166666666611111165d55555555555555dddddddddddddddddddddddddddddddddddddddddddddddddddddddd000000000000000000000000
668686666688886666666666611111165555555555555555dddddddddddddddddddddddddddddddddddddddddddddddddddddddd000000000000000000000000
1777766117777777667777766666677667766661777777661111111111111111010101011111111111111111dddddddddddddddddddddddddddddddd00000000
7766666677777766666677666666666676666666577766661111111111111111101010101111111110111111dddddddddddddddddddddddddddddddd00000000
755555567655555555555555555555d555555556555555551111111111111111010101010111111101011111dddddddddddddddddddddddddddddddd00000000
55555555555555555d5555555555555d55555555555555551110111111011111101010101011111111111111ddfffffdddfffffddfdfffdddfffffdd00000000
5d55555555555dd5555555555555555555555555555555551111111111111111010101010111111111111111dfddddfddfddddfddffdddfddfddddfd00000000
5555555555555555555555555d555555d5555555555555551111111110111111111010101011111111101101dfddddfddfddddfddfddddfddfddddfd00000000
555555d5555555555555d55555555555555d5555555555551111111111111111111111010101111111111011dfddddfddfddddfddfddddfddfffffdd00000000
555555555555d555555555d55555555555555555555555551111101111111111111111101010111111111111dfddddfddfddddfddfddddfddfdddddd00000000
7777766617777766555555555555555566776661777766660101010101010101010111110101111111111111ddfffffddfffffdddfddddfdddffffdd00000000
577666657777766555d555555555555556666666776666651010101010101010101111111011111111111111ddddddfddddddddddddddddddddddddd00000000
55555555765555555d5555555555555555555556555555551111010101010101011111110101111111111111ddddddfddddddddddddddddddddddddd00000000
555555555555555555d55555555555d555555555555555551111111010111010101111111010111111111111ddddddfddddddddddddddddddddddddd00000000
5555555555555555555555555555555555555555555d55551111111111111111011111110101111111111111dfddddfddddddddddddddddddddddddd00000000
55555555555555555555555555555555d5555555555555551111111111111111111111111011111111111111dfffffdddddddddddddddddddddddddd00000000
55d55555555555d5555555555555d555555d555555d555551111111111111111111111110101111111111111dddddddddddddddddddddddddddddddd00000000
555555555d555555555555555555555555555555555555551111111111111111111111111011111111111111dddddddddddddddddddddddddddddddd00000000
00000004020200000000000000000000010001000101000000000000000000000101010101010000000000000000000001010101010100000000000000000000
__gff__
0000000402020000000000000000000001000100010100000000000000000000010101010101000000000000000000000101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
383a3a3a3a3a3a3a263a3a3a3a3a3a3a383a3a3a3a3a3a2a3a3a3a3a3a3a3a363a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a2a3a103a3a3a3a3a3a3a263a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a2a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3a3a3a3a3a273a3a3a3a3a3a273a3a3a3a3a3a2a26263a3a2a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a263a3a3a3a3a3a2a3a273a3a3a273a3a2a3a3a3a3a3a3a3a203a3a3a3a3a3a3a3a3a3a3a273a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3a3a3a3a3a3a3a3a3a3a263a3a3a3a2a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a273a3a3a3a3a3a3a3a3a3a3a3a3a3a2a3a3a3a3a3a3a3a3a3a273a3a3a3a3a3a3a3a3a3a3a323a3a263a3a263a3a3a3a3a3a3a3a3a3a2a3a3a3a3a263a3a3a2a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3a3a2a3a3a3a3a3a3a2a3a3a3a3a3a3a3a3a3a3a263a273a3a263a3a3a3a3a3a3a3a3a3a3a3a3a2a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a212222222224293a323a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a273a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
273a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a263a3a263a3a3a3a3a3a3a3a3a3a3a3a3a3a3a263a3a3a3a3a3a3a3a3a212323232224293a3a263a1415151514363831323a3a3a3a3a3a3a2a3a263a3a3a2a3a3a3a3a273a3a3a3a2a3a3a3a3a3a3a3a3a3a3a263a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a2a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a361010101028393a033a3a1433331514043a32143a3a3a3a263a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a263a3a3a3a3a3a3a3a3a3a3a3a3a3a3a273a3a3a2a3a3a3a263a
3a3a3a273a3a3a2a3a3a3a2627263a3a3a3a3a2a3a3a3a263a3a3a27263a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a212429212223222323232322232223351414151514342914143a2a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a263a3a3a3a3a3a263a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3a3a3a3a3a3a3a3a3a263a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a2a27263a3a3a3a3a3a263a3a263a3a3a3a3a3a3a3a141404363737373737281414141514151515321414363815143a3a3a273a3a3a3a3a3a3a3a3a3a3a263a3a3a3a3a3a033a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a263a2a3a3a
3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a273a3a3a3a3a141434043a3a273a2a3a2814151532141414151414043a15323a3a3a3a3a3a3a2123131313232223101010232222232429263a3a2a273a3a3a3a3a3a3a3a3a3a3a3a3a3a2a3a3a3a3a273a3a3a3a3a3a
3a3a3a263a3a3a3a3a3a212235232324293a3a273a3a3a273a212223232324293a3a273a3a3a3a3a3a3a3a3a3a3a3a3a14141434043a3a3a263a2714141515141414141514342932143a3a3a3a3a3a3a32383a043a3637383a3a3a3636283214393a3a3a273a3a273a3a3a3a033a3a3a3a3a3a3a3a3a3a2a3a3a3a3a3a3a3a20
3a3a3a3a3a3a3a3a3a3a103637370328393a3a3a3a3a3a3a3a363810100314393a3a3a3a3a3a3a3a3a3a3a3a3a3a2a3a1432151434043a273a3a2a14151514143214141514363833153a3a263a3a2a3a332522222222222323222224293a3628383a3a3a3a3a3a3a3a3a3a212324293a3a3a263a3a3a3a3a3a3a3a3a3a033a14
263a3a3a202921232223222223222322222324292123242921232222233514393a3a3a3a3a273a3a3a3a3a3a3a3a3a3a1515151414343a3a3a3a3a14141414143215141414043a33143a3a3a3a3a3a3a15143215323315151533321525232224293a3a3a3a3a3a3a3a3a11323214383a3a3a3a3a3a3a273a3a3a3a2122242914
3a3a3a31333936373737373737373728321532383215143814153215321515393a3a3a3a3a3a3a2a3a3a3a3a3a3a3a3a1415151433333a3a2a3a3a15141415151415141414341015323a3a3a3a3a3a3a1514153333153332153333153315321525222224293a11312323233214142324293a3a3a3a3a3a3a3a3a113637283832
3a3a211414393a3a3a273a3a3a273a3a151433273314142714151533153314383a3a3a3a3a3a3a3a3a3a3a21222323351515151514143a3a3a3a3a14141414151414141514141033143a3a3a3a3a3a3a1514141515153333331532153315153336373728382a3a363737373737373728383a3a3a3a3a3a3a3a113a20293a3a14
3a31333314383a2a3a3a3a263a3a3a0433153204153232041432151532153225243a0404043a3a3a3a3a3a10101003143314331415333a3a3a3a3a14141432141414141414141015143a3a3a3a3a3a3a33333333151515321515321533331533043a2a3a3a3a3a3a043a3a3a2a3a3a3a3a3a3a3a3a212222232324043a3a3a15
2232151533252322232322222323223515333230321514301414321433141414142523222223222323222322222335321433333314143a3a3a3a3a14141414141414141414140333323a3a3a3a3a3a3a141432141514321415151414143215332323222223222323222322222322222222222222353232323232322523233515
141415141432153214151432143333143a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3315323315323315333232333a20203a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a333333333333333a3a3a3a3a3a33333a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a33333333043a3a3a3a3a3a2a3a14333a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3315333a3a3a3a3a3a2a3a3a3a14143a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3315333a2123243a3a3a3a3a3a3a153a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3333333333333311202222203a3a143a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3a3a3a3a323a3a3a33333a3a3a20140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3a2a3a3a33033a3a33333a3a203a140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
2a3a3a3a3a332022203333343a3a3a320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
3a3a3a3a3a3a3a3a3a3a3a3a203a3a1400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3a3a3a3a3a3a3a3a3a3a3a3a3a313300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3a3a3a3a3a3a3a3a3a3a3a3a203a1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3a3a3a3a3a3a3a212323233532303300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2123222222232335153232323333331500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3215143215141532323215333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400000050201502025020350204502065020750208502095020b5020c5020e5021050211502005021550200502005020730207302005020440204402005020050200502005020050200502005020050200502
001e00001172214722167221b7221b722187121870200702167221872216722147221472211712167021b7021172214722167221b7221b7221871216702167021672214722187221672216722000000000000000
001e00001172214722167221b7221b7221871218702167021672218722167221472214722117121b7020070211722147221b72218722187221671203702007021672214722137221472200702007020000000000
001e0000115061450610723185061b114165060c723165061450613506107230000614114000060c72300006000060000610723000061b114000060c7230000600006141041811400006000060c722000060c722
001e00001d724207241d724207241d7241b7241b724187041d7241b7241872416724187241b7241b724007041d724207241d724207241d7241b7241b724007041d7241b724187241672416724167250070000700
001e00001d724207241d724207241d7241b7241b724007051d7241b7241872416724187241b7241b724007001172414724167241b7241b7241d7241d725167041672414724137241472414725007000070000700
001e00001d5031b503107231650316503165031872300003000030000310723000030000318723187230000300003000031072300003000031872318723000030000300003000030000300003187231872300003
001e00001055413554155541b5541b5441d5151650416554145541355414544145350000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004
010f00003a6113a6033a62316613116030f603026030e6030c6030b6030b603026030260300603006030160301603006030060300603006030060300600006000060000600006000060000600006000060000600
000d00000f5300e5300b5300653000530000000000000000000000000000000000000100001000020000200002000020000200002000000000200002000000000000001000010000000000000000000000000000
00030000250402504025040250402a0302a0302a030277102d0302d0302d0302d7102d0202d0202d0202d7102d0202d0202d7102d0102d0102d7102d7102d7102d7002d7002d7002d7002d7002d7002d7002d700
00030000285002850028500325003250032500335003d5003d5003d500005002c5000f50010500155001e5002d50011500115000f5001050010500105001150014500195001e500255002b500305000d5000e500
00050000195201c5301b5201a5201c53020540205401e500295002750022500000000100001000020000200002000020000200002000000000200002000000000000001000010000000000000000000000000000
001400001b7010a701000010000100001000010000100001000010000100001000010100101001020010200102001020010200102001000010200102001000010000101001010010000100001000010000100001
001000000000000000000000000000000000000000000000000000000000000000000100001000020000200002000020000200002000000000200002000000000000001000010000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000100001000020000200002000020000200002000000000200002000000000000001000010000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000100001000020000200002000020000200002000000000200002000000000000001000010000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000100001000020000200002000020000200002000000000200002000000000000001000010000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000100001000020000200002000020000200002000000000200002000000000000001000010000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000100001000020000200002000020000200002000000000200002000000000000001000010000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000000000240002500026000290002a0002b0002d0002d0002b000290002700024000210001f0001e0001e0001e0001d0001d0001f000230000000000000000000000000000000000000000000
__music__
00 01034844
00 02034844
00 04064844
00 05064844
00 41494844
00 41494844
00 41424344
00 41424344
00 41424344
00 4d4e4f50