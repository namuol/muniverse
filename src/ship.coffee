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
    console.log 'boom'

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

  setAng: (val) ->
    @ang = val
    @ax = Math.cos(@ang) * @thrust
    @ay = Math.sin(@ang) * @thrust
    if @ang < 0
      @ang = Math.PI*2 - @ang

  first: ->

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
    
    if not @thrusting
      if Math.abs(@vx) < 0.2
        @vx = 0
      if Math.abs(@vy) < 0.2
        @vy = 0

class CargoBay
  constructor: (@capacity) ->

  canHold: (items) ->
    return true # TODO later? Not sure if this is something I even want.
