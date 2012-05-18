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

class Baddie
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

