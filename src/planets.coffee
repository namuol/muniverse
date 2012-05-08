planetmapMode = ->
  stopGroups = [
    'background'
    'planet'
    'player'
    'baddies'
    'drones'
    'friend_shots'
    'foe_shots'
    'resources'
    'particles'
    'starmap'
    'stations'
    'radar'
    'hud'
  ]
  for g in stopGroups
    gbox.stopGroup g

  groups = [
    'planetmap'
  ]
  for g in groups
    gbox.stopGroup g
    gbox.toggleGroup g

  player.skip = true
  if not gbox.getObject 'planetmap', 'pmap'
    gbox.addObject window.planetmap

GAS_GIANT_MIN_ORBIT = 0.5
PLANET_CLASSES =
  gas_giant:
    prob: 0.5
    min_radius: 60
    max_radius: 120
    min_moons: 0
    max_moons: 8
    min_orbit: 0.5
    max_orbit: 1.0
    station_prob: 0.5
    max_mission_count: 5
    ring_prob: 0.25

  rocky:
    prob: 0.5
    min_radius: 20
    max_radius: 60
    min_orbit: 0.15
    max_orbit: 1.0
    min_moons: 0
    max_moons: 3
    station_prob: 0.75
    max_mission_count: 10
    ring_prob: 0.1

  moon:
    min_radius: 10
    max_radius: 20
    station_prob: 0.25
    max_mission_count: 7
    ring_prob: 0

MIN_ITG_STATION_PROB = 0.1
MIN_PIRATE_STATION_PROB = 0.1
MIN_STATION_DIST = 100
class Planet
  constructor: (@star, @pid, @num, moon, itg, pirate) ->
    @random = grand(Math.prng(@pid))
    @_x = 0#gbox.getScreenW()/2 - @w/2
    @_y = 0#gbox.getScreenH()/2 - @h/2

    @orbit = @star.pcount / @num
    if moon
      @ptype = 'moon'
      @c1 = @random.choose planetcolors[2]
      @c2 = [@random.choose(@c1), @random.choose(@c1), @random.choose(@c1)]
      @color = rgba @c1
      @atmosphere_size = 3
      @atmosphere_density = 0.25
    else if @orbit > GAS_GIANT_MIN_ORBIT and @random() < PLANET_CLASSES.gas_giant.prob
      @ptype = 'gas_giant'
      @c1 = @random.choose planetcolors[1]
      @c2 = [@random.choose(@c1), @random.choose(@c1), @random.choose(@c1)]
      @color = rgba @c1
      @atmosphere_size = 25
      @atmosphere_density = 0.5
    else
      @ptype = 'rocky'
      @c1 = @random.choose planetcolors[0]
      @c2 = [@random.choose(@c1), @random.choose(@c1), @random.choose(@c1)]
      @color = rgba @c1
      @atmosphere_size = 3
      @atmosphere_density = 0.3

    cls = PLANET_CLASSES[@ptype]
    @radius = @random.frand cls.min_radius, cls.max_radius

    @wealth = @random()
    max_resource_count = ((Math.PI * @radius*@radius) / 50) * @wealth
    @resources = {}
    @prices = {}
    for own name,res of RESOURCES
      @resources[name] = []
      @prices[name] = @random.gaus @star.prices[name], (RESOURCES[name].price_stdv/2.5)
      ###
      resource_wealth = res[@ptype+'_prob']
      count = Math.round(@random.frand(0, resource_wealth * max_resource_count))
      c=0
      while c < count
        ang = Math.PI*2 * @random()
        r=@radius*@random.frand(res.min_dist,res.max_dist)
        x=r*Math.cos(ang)
        y=r*Math.sin(ang)
        @resources[name].push new Resource name, x,y, 0,0, @
        ++c
      ###

    @itg_station = null
    @pirate_station = null
    itg_station_prob = cls.station_prob * @star.itg + MIN_ITG_STATION_PROB
    pirate_station_prob = cls.station_prob * @star.pirate + MIN_PIRATE_STATION_PROB

    if (itg is @num) or @random() < itg_station_prob
      r = MIN_STATION_DIST + @radius * 2
      ang = @random() * 2*Math.PI
      x = @_x + r*Math.cos ang
      y = @_y + r*Math.sin ang
      @itg_station = new Station @, 'itg', x,y
      @itg_station.new_missions()

    if (pirate is @num) or @random() < pirate_station_prob
      r =MIN_STATION_DIST + @radius * 4
      ang = @random() * 2*Math.PI
      x = @_x + r*Math.cos ang
      y = @_y + r*Math.sin ang
      @pirate_station = new Station @, 'pirate', x,y
      @pirate_station.new_missions()

    # Sunlight direction:
    @dirx = -@radius*0.25#frand(-@radius,@radius)
    @diry = 0#frand(-@radius*.1,@radius*.1)
    @pre_render @dirx, @diry

    @moons = []
    return if moon
    mcount = Math.round(@random.rand(cls.min_moons, cls.max_moons)*(@radius/120))
    letters='abcdefghijklmnopqrstuvqxyz'
    m=0
    while m < mcount
      @moons.push new Planet @star, @pid+letters[m], m, true
      ++m
    @init()

  addResources: ->
    for own k,v of @resources
      for r in v
        gbox.addObject r

  count: ->
    return 1 + @moons.length

  group: 'planet'
  init: ->
    @ang = 0
    @xoff = 0
    @yoff = 0
    @dist = 3

  first: ->
    @ang += 0.02
    @xoff = 0
    @yoff = 3*Math.sin @ang
    @x = Math.round @_x + @xoff
    @y = Math.round @_y + @yoff

  _render_pass: (ctx, radius, x, y, dirx, diry, s,w, a) ->
    ctx.beginPath()
    grd = ctx.createRadialGradient x+dirx,y+diry, 0, x+dirx,y+diry, radius*1.3
    grd.addColorStop 0, "rgba(#{@c1[0]},#{@c1[1]},#{@c1[2]},#{a})"
    grd.addColorStop s, "rgba(#{@c1[0]},#{@c1[1]},#{@c1[2]},#{(1-s)*a})"
    rn = lerp @c1[0],@c2[0], s+w
    gn = lerp @c1[1],@c2[1], s+w
    bn = lerp @c1[2],@c2[2], s+w
    grd.addColorStop s+w, rgba [rn,gn,bn, (1-(s+w))*a]
    grd.addColorStop Math.min(1,s+w+w), rgba [rn,gn,bn, 0]
    ctx.fillStyle = grd
    ctx.arc x,y, radius, 0, 2*Math.PI, false
    ctx.fill()
    ctx.closePath()
  
  pre_render: (dirx,diry) ->
    @el = document.createElement 'canvas'
    @el.setAttribute 'width', (@radius+@atmosphere_size)*2+1
    @el.setAttribute 'height', (@radius+@atmosphere_size)*2+1

    @w = @el.width
    @h = @el.height
    x = @w/2
    y = @h/2

    ctx = @el.getContext '2d'

    ctx.clearRect 0,0, @w,@h

    # Ambient light:
    ctx.beginPath()
    ctx.fillStyle = @star.bg_color
    if @ptype is 'gas_giant'
      ctx.arc x,y, @radius+@atmosphere_size, 0, 2*Math.PI, false
    else
      ctx.arc x,y, @radius, 0, 2*Math.PI, false

    ctx.fill()
    ctx.closePath()

    @_render_pass ctx, @radius, x, y, dirx, diry, 0.75, 0.2, 1
    i=0
    while i<(@atmosphere_size+1)
      @_render_pass ctx, @radius+i*1, x, y, dirx, diry, 0.75, 0.2, @atmosphere_density
      ++i
  
  render_outline: (scale, x,y) ->
    ctx = gbox.getBufferContext()
    return if not ctx

    ctx.beginPath()
    ctx.fillStyle = @star.bg_color
    if @ptype is 'gas_giant'
      ctx.arc x,y, (@radius+@atmosphere_size)*scale+1, 0, 2*Math.PI, false
    else
      ctx.arc x,y, @radius*scale+1.5, 0, 2*Math.PI, false
    ctx.fill()
    ctx.closePath()

  render: (scale, x,y) ->
    ctx = gbox.getBufferContext()
    return if not ctx
    w = @w*scale
    h = @h*scale
    ctx.drawImage @el, x-(w/2),y-(h/2), w,h

  blit: ->
    x = Math.round @x-cam.x
    y = Math.round @y-cam.y
    @render 1.0, x,y, @dirx, @diry

window.planetmap = undefined
class Planetmap
  id: 'pmap'
  group: 'planetmap'
  constructor: (star) ->
    @skip = false
    @star = star
    @tick = 0
    @cursor =
      x:0
      y:0

    @positions = []
    y = H/2
    p=0
    for planet in @star.planets
      @positions.push []
      x = (W*0.8) * ((p+1)/@star.planets.length)
      planet.cursorpos =
        x:x
        y:y
        r:planet.radius*0.25
      @positions[p].push planet.cursorpos
      m=0
      for moon in planet.moons
        moon.cursorpos =
          x:x
          y:y+(planet.radius*0.5+(m+1)*PLANET_CLASSES.moon.max_radius)*0.5
          r:moon.radius*0.25

        @positions[p].push moon.cursorpos
        ++m
      ++p


  first: ->
    if @skip
      @skip = false
      return

    if gbox.keyIsHit 'c'
      starmapMode()
      return

    if gbox.keyIsHit 'a'
      sounds.select.play()
      new_planet = undefined
      if @cursor.y
        new_planet = @star.planets[@cursor.x].moons[@cursor.y-1]
      else
        new_planet = @star.planets[@cursor.x]

      if new_planet != current_planet
        current_planet = new_planet
        current_planet.init()
        starmap.current_star = current_planet.star
        player.vx = 0
        player.vy = 0
        player.x = frand -W,W
        player.y = frand -W,W
        flightMode(true)

    return if @positions.length is 0
    if gbox.keyIsHit 'up'
      sounds.blip.play()
      @cursor.y -= 1
    else if gbox.keyIsHit 'down'
      sounds.blip.play()
      @cursor.y += 1
    if gbox.keyIsHit 'left'
      sounds.blip.play()
      @cursor.x -= 1
    else if gbox.keyIsHit 'right'
      sounds.blip.play()
      @cursor.x += 1

    if @cursor.x < 0
      @cursor.x = @positions.length - 1
    if @cursor.y < 0
      @cursor.y = @positions[@cursor.x].length - 1
    @cursor.x = @cursor.x % @positions.length
    @cursor.y = @cursor.y % @positions[@cursor.x].length

  blit: ->
    c = gbox.getBufferContext()
    if c
      gbox.blitAll c, gbox.getImage('starmap_gui'),
        dx:0
        dy:0

      gbox.blitText c,
        font: 'small'
        text: "PLANETS: #{@star.planet_count()}"
        dx:1
        dy:H-12
        dw:64
        dh:16

      return if @positions.length is 0

      p=0
      for planet in @star.planets
        if p != @cursor.x
          x = @positions[p][0].x
          y = @positions[p][0].y
          planet.render_outline 0.25, x,y
          planet.render 0.25, x,y
          m=0
          for moon in planet.moons
            x = @positions[p][m+1].x
            y = @positions[p][m+1].y
            moon.render_outline 0.25, x,y
            moon.render 0.25,
              x,
              y,
              -moon.radius,0
            ++m
        ++p

      p = @cursor.x
      planet = @star.planets[p]
      x = @positions[p][0].x
      y = @positions[p][0].y

      planet.render_outline 0.25, x,y
      planet.render 0.25, x,y
      m=0
      for moon in planet.moons
        x = @positions[p][m+1].x
        y = @positions[p][m+1].y
        moon.render_outline 0.25, x,y
        moon.render 0.25, x,y
        ++m

      for m in player.missions
        if m.location and m.location.star is @star
          pos=@positions[m.location.pnum][0]
          gbox.blitTile c,
            tileset: 'cursors'
            tile: 6
            dx: Math.round(pos.x)-4
            dy: Math.round(pos.y)-4
    
      pos=@positions[@cursor.x][@cursor.y]
      gbox.blitTile c,
        tileset: 'cursors'
        tile: 5
        dx: Math.round(pos.x)-4
        dy: Math.round(pos.y)-4

      if current_planet and current_planet.star is @star
        pos=current_planet.cursorpos
        gbox.blitTile c,
          tileset: 'cursors'
          tile: 4
          dx: Math.round(pos.x)-4
          dy: Math.round(pos.y)-4

