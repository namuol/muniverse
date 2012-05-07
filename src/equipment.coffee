EQUIPMENT =
  repair:
    name: 'Repair Shields'
    price: -> (player.shields_max - player.shields) * 100
    apply: ->
      player.shields = player.shields_max
  thrust:
    name: 'Thruster'
    levels: [
        price: -> 1500,
        val: 0.045*0.33
        desc: 'Standard introductory thruster.'
      ,
        price: -> 10000,
        val: 0.045*0.66
        desc: '2X the thrust as introductory thruster.'
      ,
        price: -> 40000
        val: 0.045
        desc: '3X the thrust as introductory thruster.'
    ]
  wpower:
    name: 'Plasma Cannon'
    levels: [
        price: -> 1000,
        val: 0.5
      ,
        price: -> 5000,
        val: 1
      ,
        price: -> 20000
        val: 2
    ]
  wcharge_rate:
    name: 'Weapon Charger'
    levels: [
        price: -> 10000,
        val: 0.025
      ,
        price: -> 20000,
        val: 0.07
      ,
        price: -> 60000
        val: 0.3
    ]
  afterburn:
    name: 'Afterburner'
    levels: [
        price: -> 2000,
        val: 0.005
      ,
        price: -> 15000,
        val: 0.01
      ,
        price: -> 60000
        val: 0.03
    ]
  shields_max:
    name: 'Shields'
    levels: [
        price: -> 2000,
        val: 3
      ,
        price: -> 25000,
        val: 10
      ,
        price: -> 90000
        val: 25
    ]
  ftl_ms_per_ly:
    name: 'FTL Drive'
    levels: [
        price: -> 4000,
        val: 2 * DAYS
      ,
        price: -> 10000,
        val: 1 * DAYS
      ,
        price: -> 50000
        val: 0.5 * DAYS
    ]

class Equipment extends MenuItem
  constructor: (@eq) ->
    super @eq
  a: ->
    if @eq.price
      if player.funds < @eq.price()
        message.set 'Insufficient funds.',120
        return
      @eq.apply()
      return

    lvl = player.equipment[@eq.name]
    if lvl >= 2
      return
    if player.funds < @eq.levels[lvl+1].price()
      message.set 'Insufficient funds.',120
      return
    player.funds -= @eq.levels[lvl+1].price()
    player[@eq.attr] = @eq.levels[lvl+1].val
    ++player.equipment[@eq.name]

  b: ->
    lvl = player.equipment[@eq.name]
    return if not @eq.levels or lvl is undefined
    ++lvl
    if @eq.levels[lvl].desc
      setDialog new Dialog @eq.levels[lvl].desc

  text: ->
    if @eq.price
      return @eq.name + ' $' + @eq.price()
    lvl = player.equipment[@eq.name]
    lvl_vis = lvl+2
    if lvl_vis >= 4
      return @eq.name + ' v3.0 - MAX'
    @eq.name + ' v' + (lvl_vis) + '.0 $'+@eq.levels[lvl+1].price()

class Shot
  constructor: (x,y, tx,ty, power, speed, frame, group, lifespan, vx,vy) ->
    @group = group
    @frame = frame
    @tileset = 'shots_tiles'
    @w = 3
    @h = 3
    @x = x - @w/2
    @y = y - @h/2
    @vx = (tx - @x)
    @vy = (ty - @y)
    len = Math.sqrt(@vx*@vx + @vy*@vy)
    @vx /= len
    @vy /= len
    @vx *= speed
    @vy *= speed
    if vx and vy
      @vx += vx
      @vy += vy
    @lifespan = lifespan or 99999
    @tick = 0
    @power = power

  die: ->
    gbox.trashObject @

  first: ->
    @x += @vx
    @y += @vy
    ++@tick
    if @tick > @lifespan
      @die()

  blit: ->
    gbox.blitTile gbox.getBufferContext(),
      tileset: @tileset
      tile: @frame
      dx: Math.round(@x-cam.x)
      dy: Math.round(@y-cam.y)

