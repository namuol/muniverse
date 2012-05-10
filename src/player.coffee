flightMode = (reset) ->
  if reset
    gbox.clearGroup 'friend_shots'
    gbox.clearGroup 'foe_shots'
    gbox.clearGroup 'particles'
    gbox.clearGroup 'baddies'
    baddy_count = rand 0, 6
    i=0
    while i<baddy_count
      addBaddie()
      ++i
  gbox.clearGroup 'planet'
  gbox.clearGroup 'resources'
  gbox.clearGroup 'stations'
  gbox.clearGroup 'radar'
  gbox.clearGroup 'hud'
  gbox.addObject new Radar
  gbox.addObject new Hud
  gbox.addObject player
  
  if current_planet
    gbox.addObject current_planet
    if current_planet.itg_station
      gbox.addObject current_planet.itg_station
    if current_planet.pirate_station
      gbox.addObject current_planet.pirate_station

    current_planet.addResources()

  stopGroups = [
    'starmap'
    'planetmap'
  ]
  for g in stopGroups
    gbox.stopGroup g

  groups = [
    'background'
    'planet'
    'player'
    'baddies'
    'drones'
    'friend_shots'
    'foe_shots'
    'resources'
    'particles'
    'stations'
    'radar'
    'hud'
  ]
  for g in groups
    gbox.stopGroup g
    gbox.toggleGroup g
  player.skip = true
  if current_planet
    cam.x = current_planet._x-cam.w/2
    cam.y = current_planet._y-cam.h/2
    cam.reset = true

  current_station = undefined

GAME_OVER_MSGS = [
  'GAME IS OVER'
  'DERP! You died.'
  'Losing is fun.'
]

BASE_THRUST = EQUIPMENT.thrust.levels[0].val
BASE_SHIELDS = 3
BASE_WCHARGE_RATE = EQUIPMENT.wcharge_rate.levels[0].val
BASE_WCHARGE_CAP = 2
BASE_WSPEED = 2
BASE_WPOWER = EQUIPMENT.wpower.levels[0].val
BASE_WSPAN = 80
TURN_SPEED = 0.1
BASE_CARGO_CAP = 5
BASE_AFTERBURN = EQUIPMENT.afterburn.levels[0].val
player = undefined
date = 0
class Player
  constructor: (name) ->
    @alive = true
    @missions = []
    @funds = 500
    @cabins = []
    @available_cabins = 3
    @wcharge_cap = BASE_WCHARGE_CAP
    @wcharge_rate = BASE_WCHARGE_RATE
    @wcharge = @wcharge_cap
    @wspeed = BASE_WSPEED
    @wpower = BASE_WPOWER
    @wspan = BASE_WSPAN
    @thrust = BASE_THRUST
    @afterburn = BASE_AFTERBURN
    @shields_max = BASE_SHIELDS
    @shields = @shields_max
    @itg_inspect_mod = 1
    @ftl_ms_per_ly = EQUIPMENT.ftl_ms_per_ly.levels[0].val

    @cargo =
      fuel: [
        1,2,3,4
      ]
      narcotics: [
       'teehee',2
      ]
    @equipment = {}
    for own attr,eq of EQUIPMENT
      if not eq.no_default
        @equipment[eq.name] = 0

    @init()

  burn_fuel: (dist) ->
    dist = Math.round dist
    while dist > 0
      @cargo.fuel.pop()
      --dist
  fuel: ->
    return @cargo.fuel.length

  id: 'player_id'
  group: 'player'
  x:0
  y:0
  vx:0
  vy:0
  init: ->
    @skip = false
    @frame = 0
    @tileset = 'ship0_tiles'
    @w = 8
    @h = 8
    @x = gbox.getScreenW()/2 - @w/2
    @y = gbox.getScreenH()/2 - @h/2
    @vx = 0
    @vy = 0
    @ang = 0
    @ax = 0
    @ay = 0
    @particle_tick=0

  setAng: (val) ->
    @ang = val
    @ax = Math.cos(@ang) * @thrust
    @ay = Math.sin(@ang) * @thrust

  first: ->
    if @skip
      @skip = false
      return

    @going = false
    #if gbox.keyIsHit 'up'
    #  sounds.thruster.play()
    #else if gbox.keyIsReleased 'up'
    #  sounds.thruster.stop()
    if gbox.keyIsPressed 'up'
      @going = true
      @vx += @ax
      @vy += @ay
    else
      if not (gbox.keyIsPressed('down') or gbox.keyIsPressed('b'))
        @vx *= 1-@afterburn
        @vy *= 1-@afterburn

    if gbox.keyIsPressed 'right'
      @setAng(@ang + TURN_SPEED)
    else if gbox.keyIsPressed 'left'
      @setAng(@ang - TURN_SPEED)

    if @ang < 0
      @ang = Math.PI*2 - @ang

    @x += @vx
    @y += @vy

    @frame = Math.round(((@ang+(Math.PI/2)) / (Math.PI*2)) * 16) % 16
    if @going
      @frame += 16
      if ++@particle_tick % 4 is 0
        addParticle 'fire', @x+@w/2,@y+@h/2,
          @vx-@ax*40*frand(0.5,1),@vy-@ay*40*frand(0.5,1)

    if gbox.keyIsHit('a') and (@wcharge >= @wpower)
      @wcharge -= @wpower
      sounds.shot0.play()
      gbox.addObject new Shot @x+@w/2,@y+@h/2,
        @x+@w/2+(@ax/@thrust)*20000,
        @y+@h/2+(@ay/@thrust)*20000,
        @wpower,
        @wspeed, 4, 'friend_shots', @wspan,
        @vx, @vy

    if @wcharge < @wcharge_cap
      @wcharge += @wcharge_rate

    groupCollides @, 'foe_shots', (shot) =>
      sounds['hit'+rand(0,3)].play()
      cam.shake += 5
      i=0
      while i < 3
        addParticle 'fire', @x+@w/2,@y+@h/2,
          @vx+frand(-.5,.5),@vy+frand(-.5,.5)
        ++i
      @shields -= shot.power
      if @shields <= 0
        @die()
      shot.die()
    
    if not @going
      if Math.abs(@vx) < 0.2
        @vx = 0
      if Math.abs(@vy) < 0.2
        @vy = 0

    if gbox.keyIsHit 'c'
      planetmapMode()

  blit: ->
    gbox.blitTile gbox.getBufferContext(),
      tileset: @tileset
      tile: @frame
      dx: Math.round(@x-cam.x)
      dy: Math.round(@y-cam.y)
    
  # Is the user out of range of enemy ships/planets/stations/objects?
  can_flee: ->
    MIN_DIST = 1200
    MIN_DIST2 = MIN_DIST*MIN_DIST

    groups = [
      'baddies'
      'planet'
      'stations'
    ]

    for groupname in groups
      group = gbox.getGroup groupname
      for own k,obj of group
        dst2 = dist2 @, obj
        if dst2 < MIN_DIST2
          return false
    return true

  die: ->
    sounds.explode.play()
    #sounds.thruster.stop()
    @alive = false
    gbox.trashObject @
    message.set choose GAME_OVER_MSGS
    i=0
    while i < 20
      addParticle 'fire', @x+@w/2,@y+@h/2,
        @vx+frand(-1,1),@vy+frand(-1,1)
      ++i
    i=0
    while i < 12
      addParticle 'wreckage', @x+@w/2,@y+@h/2,
        @vx+frand(-0.5,0.5),@vy+frand(-.5,.5)
      ++i


# TODO: Generalize this for any ship
addDrone = ->
  gbox.addObject
    group: 'drones'
    init: ->
      @deployed = false
      @frame = 0
      @tileset = 'drones_tiles'
      @w = 5
      @h = 5
      @x = player.x + player.h/2 - @w/2
      @y = player.y + player.h/2 - @h/2
      @vx = 0
      @vy = 0
      @ang = Math.random() * Math.PI*2
      @xoff = Math.cos @ang
      @yoff = Math.sin @ang
      @dist = 20

    first: ->
      @ang += 0.02 #Math.random() * Math.PI*2
      @xoff = Math.cos @ang
      @yoff = Math.sin @ang

      p=player
      tx = p.x + 4 + @dist*@xoff or 0
      ty = p.y + 4 + @dist*@yoff or 0

      @x += (tx - @x) * 0.025
      @y += (ty - @y) * 0.025

    initialize: ->
      @init()

    blit: ->
      gbox.blitTile gbox.getBufferContext(),
        tileset: @tileset
        tile: @frame
        dx: Math.round(@x-cam.x)
        dy: Math.round(@y-cam.y)

