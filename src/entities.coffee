class Person
  constructor: (@role, @fugitive) ->
    @parts = []
    @parts.push rand 0, 15
    @parts.push rand 0, 15
    if rand(0,1)
      @parts.push @parts[1]
    @tick = 0

  render: (x,y, alpha, talking) ->
    @render_face(x,y,alpha, talking)
    return if not @fugitive
    gbox.blitAll gbox.getBufferContext(), gbox.getImage('fugitive_icon'),
      dx: Math.round(x+17)
      dy: Math.round(y+5)

  render_face: (x,y, alpha, talking) ->
    n=0
    for partNum in @parts
      yoff = 0
      #if talking and (n==2) and (Math.floor(++@tick/18)%2 == 0)
      #  yoff = -2
      gbox.blitTile gbox.getBufferContext(),
        tileset: 'peoples_tiles'
        tile: n*16 + partNum
        dx: Math.round(x)
        dy: Math.round(y+yoff)
      ++n

class Baddie extends Ship
  constructor: () ->
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
        1,2,3,4
      ]
      narcotics: [
       'teehee',2
      ]

    # TODO: Determine badassness of ship's equipment here.
    # What algorithm should we use? Should it be completely random, or
    # rubber-band based on player's ship's stats?
    @equipment = {}
    for own attr,eq of EQUIPMENT
      if not eq.no_default
        @equipment[eq.name] = 0

    @attack_dist = 90
    @orbit_radius = 60
    @hostile = Math.random() < (0.25+starmap.current_star.pirate-starmap.current_star.itg)

    @init()

  group: 'baddies'
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
    @x = frand(-gbox.getScreenW()*3, -gbox.getScreenW()*3)
    @y = frand(-gbox.getScreenH()*3, -gbox.getScreenH()*3)
    @vx = 0
    @vy = 0
    @ang = 0
    @ax = 0
    @ay = 0
    @particle_tick=0
    @flee_groups = [
      'player'
      'baddies'
      'planet'
      'stations'
    ]

  first: ->
    if @skip
      @skip = false
      return

    #if gbox.keyIsHit 'up'
    #  sounds.thruster.play()
    #else if gbox.keyIsReleased 'up'
    #  sounds.thruster.stop()
    ###
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
    ###
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
    
  die: ->
    sounds.explode.play()
    #sounds.thruster.stop()
    @alive = false
    gbox.trashObject @
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

class Baddie extends Ship
  group: 'baddies'
  constructor: () ->
    @num = 0
    @frame = 0
    @image = gbox.getImage('bad'+@num)
    @w = 8
    @h = 8
    @x = Math.random() * gbox.getScreenW()*3
    @y = Math.random() * gbox.getScreenH()*3
    @vx = 0
    @vy = 0
    @wcharge_cap = 50
    @wcharge = @wcharge_cap
    @wspeed = 1
    @wpower = 1
    @wcost = 50
    @wspan = 80
    @tx = @x
    @ty = @y
    @tsx = 0
    @tsy = 0
    @attack_dist = 90
    @orbit_radius = 60
    @hostile = Math.random() < (0.25+starmap.current_star.pirate-starmap.current_star.itg)
    @ang = 0
    @thrust = 0.006
    @afterburn = 0.005
    @shields = 3
    @cargo_cap = 10
    @cargo = {}

  first: ->
    @hostile = false if !player.alive
    if @hostile
      dx = player.x - @x
      dy = player.y - @y
      d = Math.sqrt(dx*dx + dy*dy)
      if d < W
        if @wcharge >= @wcost and d < @attack_dist
          sounds.shot1.play()
          @tsx = player.x + player.vx + @vx
          @tsy = player.y + player.vy + @vy
          @wcharge -= @wcost
          shot = new Shot @x+@w/2,@y+@h/2,
            @tsx,
            @tsy,
            @wpower,
            @wspeed, 1, 'shots', @wspan,
            @vx, @vy
          shot.ship = @
          gbox.addObject shot
      @ang += 0.005
      xoff = Math.cos @ang
      yoff = Math.sin @ang
      @tx = player.x + xoff*@orbit_radius
      @ty = player.y + xoff*@orbit_radius
    else
      if Math.random() < 0.01
        @tx = gbox.getScreenW()*Math.random()
        @ty = gbox.getScreenH()*Math.random()

    ax = @tx - @x
    ay = @ty - @y
    len = Math.sqrt(ax*ax + ay*ay)
    if len > 0
      ax /= len
      ay /= len
      ax *= @thrust
      ay *= @thrust
      @vx += ax
      @vy += ay

    @x += @vx
    @y += @vy


    @vx *= 1-@afterburn
    @vy *= 1-@afterburn

    if @wcharge < @wcharge_cap
      @wcharge += 1

    groupCollides @, 'shots', (shot) =>
      return if shot.ship is @
      sounds['hit'+rand(0,3)].play()
      @hostile = true
      @shields -= shot.power
      i=0
      while i < 3
        addParticle 'fire', @x+@w/2,@y+@h/2,
          @vx+frand(-0.5,0.5),@vy+frand(-.5,.5)
        ++i
      addParticle 'wreckage', @x+@w/2,@y+@h/2,
        @vx+frand(-0.5,0.5),@vy+frand(-.5,.5)

      if @shields < 0
        sounds.explode.play()
        @die()
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
      shot.die()
  die: ->
    gbox.trashObject @

  blit: ->
    gbox.blitAll gbox.getBufferContext(), @image,
      dx: Math.round(@x-cam.x)
      dy: Math.round(@y-cam.y)


addBaddie = ->
  gbox.addObject new Baddie

