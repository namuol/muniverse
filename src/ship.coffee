class ShipWeapon
  constructor: (@ship, options) ->
    @charge = @charge_cap = options.charge_cap
    @charge_rate = options.charge_rate
    @speed = options.speed
    @power = options.power
    @span = options.span

  update: ->
    if @charge < @charge_cap
      @charge += @charge_rate

  fire: ->
    return if not (@charge >= @power)
    @charge -= @power
    sounds.shot0.play()

    shot = new Shot @ship.x+@ship.w/2,@ship.y+@ship.h/2,
      @ship.x+@ship.w/2+(@ship.ax/@ship.thrust)*20000,
      @ship.y+@ship.h/2+(@ship.ay/@ship.thrust)*20000,
      @power,
      @speed, 4, 'shots', @span,
      @ship.vx, @ship.vy
    shot.ship = @ship

    gbox.addObject shot

class Ship
  constructor: (@owner) ->
    @x = 0
    @y = 0
    @vx = 0
    @vy = 0
    @ax = 0
    @ay = 0
    @ang = 0
    @turning = 0
    @setAng(@ang)
    @flee_groups = []

  setAng: (val) ->
    @ang = val
    @ax = Math.cos(@ang) * @thrust
    @ay = Math.sin(@ang) * @thrust
    if @ang < 0
      @ang = Math.PI*2 - @ang

  first: ->
    return if not @alive

    if @thrusting # D'HURRR
      @vx += @ax
      @vy += @ay
    else
      if @braking
        @vx *= 1-@afterburn
        @vy *= 1-@afterburn

    if @turning != 0
      @setAng(@ang + @turning)

    @x += @vx
    @y += @vy

    if @shot
      @weapon.fire()
      @shot = false

    @weapon.update()

    groupCollides @, 'resources', (res) =>
      if @ is player
        message.set '+1 ' + res.name, 60
        sounds.blip.play()
      if !@cargo[res.name]
        @cargo[res.name] = []
      @cargo[res.name].push @
      res.die()
    
    if not @thrusting
      if Math.abs(@vx) < 0.2
        @vx = 0
      if Math.abs(@vy) < 0.2
        @vy = 0

    groupCollides @, 'shots', (shot) =>
      return if shot.ship is @

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


  # Is the ship out of range of enemy ships/planets/stations/objects?
  can_flee: ->
    MIN_DIST = 1200
    MIN_DIST2 = MIN_DIST*MIN_DIST

    for groupname in @flee_groups
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
    i=0
    while i < 20
      addParticle 'fire', @x+@w/2,@y+@h/2,
        @vx+frand(-1,1),@vy+frand(-1,1)
      ++i
    i=0
    while i < 6
      addParticle 'wreckage', @x+@w/2,@y+@h/2,
        @vx+frand(-0.5,0.5),@vy+frand(-.5,.5)
      ++i
    
    i=0
    while i < rand(6,12)
      gbox.addObject new Resource 'scrap metal', @x,@y, @vx+frand(-1,1),@vy+frand(-1,1)
      ++i

    for own resource_name,arr of @cargo
      for r in arr
        r.x = @x
        r.y = @y
        r.vx = @vx+frand(-.5,.5)
        r.vy = @vy+frand(-.5,.5)
        gbox.addObject r

class CargoBay
  constructor: (@capacity) ->

  canHold: (items) ->
    return true # TODO later? Not sure if this is something I even want.
