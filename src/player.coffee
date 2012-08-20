flightMode = (reset) ->
  if reset
    gbox.clearGroup 'shots'
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
    'shots'
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
class Player extends Ship
  constructor: (name) ->
    super new Person
    @alive = true
    @missions = []
    @funds = 500
    @cabins = []
    @available_cabins = 3
    weapon_options =
      charge_cap: BASE_WCHARGE_CAP
      charge_rate: BASE_WCHARGE_RATE
      charge: BASE_WCHARGE_CAP
      speed: BASE_WSPEED
      power: BASE_WPOWER
      span: BASE_WSPAN
    @weapon = new ShipWeapon(@, weapon_options)
    @thrust = BASE_THRUST
    @afterburn = BASE_AFTERBURN
    @shields_max = BASE_SHIELDS
    @shields = @shields_max
    @itg_inspect_mod = 1
    @ftl_ms_per_ly = EQUIPMENT.ftl_ms_per_ly.levels[0].val

    @cargo =
      fuel: [
        new Resource 'fuel'
        new Resource 'fuel'
        new Resource 'fuel'
        new Resource 'fuel'
      ]
      narcotics: [
        new Resource 'narcotics'
        new Resource 'narcotics'
      ]
    @equipment = {}
    for own attr,eq of EQUIPMENT
      if not eq.no_default
        @equipment[eq.name] = 0
    @flee_groups = [
      'baddies'
      'planet'
      'stations'
    ]

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

  first: ->
    if @skip
      @skip = false
      return

    #if gbox.keyIsHit 'up'
    #  sounds.thruster.play()
    #else if gbox.keyIsReleased 'up'
    #  sounds.thruster.stop()
    if gbox.keyIsPressed 'up'
      @thrusting = true
    else
      @thrusting = false
      if not (gbox.keyIsPressed('down') or gbox.keyIsPressed('b'))
        @braking = true

    if gbox.keyIsPressed 'right'
      @turning = TURN_SPEED
    else if gbox.keyIsPressed 'left'
      @turning = -TURN_SPEED
    else
      @turning = 0

    if gbox.keyIsHit('a')
      @shot = true
    else
      @shot = false

    if gbox.keyIsHit 'c'
      planetmapMode()
    
    super()

  blit: ->
    @frame = Math.round(((@ang+(Math.PI/2)) / (Math.PI*2)) * 16) % 16
    if @thrusting
      @frame += 16
      if ++@particle_tick % 4 is 0
        addParticle 'fire', @x+@w/2,@y+@h/2,
          @vx-@ax*40*frand(0.5,1),@vy-@ay*40*frand(0.5,1)

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

