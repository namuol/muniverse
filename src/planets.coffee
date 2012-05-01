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

current_planet = undefined
MIN_ITG_STATION_PROB = 0.1
MIN_PIRATE_STATION_PROB = 0.1
MIN_STATION_DIST = 100
class Planet
  constructor: (@star, @pid, @num, moon, itg, pirate) ->
    console.log itg
    @_x = 0#gbox.getScreenW()/2 - @w/2
    @_y = 0#gbox.getScreenH()/2 - @h/2

    @star = star
    @num = num
    @orbit = @star.pcount / @num
    if moon
      @ptype = 'moon'
      @color = rgba choose planetcolors[2]
    else if @orbit > GAS_GIANT_MIN_ORBIT and Math.random() < PLANET_CLASSES.gas_giant.prob
      @ptype = 'gas_giant'
      @color = rgba choose planetcolors[1]
    else
      @ptype = 'rocky'
      @color = rgba choose planetcolors[0]

    cls = PLANET_CLASSES[@ptype]
    @radius = frand cls.min_radius, cls.max_radius

    @wealth = Math.random()
    max_resource_count = ((Math.PI * @radius*@radius) / 50) * @wealth
    @resources = {}
    @prices = {}
    for own name,res of RESOURCES
      @resources[name] = []
      @prices[name] = gaus res.mean_price, res.price_stdv
      if res.pirate_mod_min
        @prices[name] *= frand res.pirate_mod_min,res.pirate_mod_max
      @prices[name] = Math.max(1,@prices[name])
      resource_wealth = res[@ptype+'_prob']
      count = Math.round(frand(0, resource_wealth * max_resource_count))
      c=0
      while c < count
        ang = Math.PI*2 * Math.random()
        r=@radius*frand(res.min_dist,res.max_dist)
        x=r*Math.cos(ang)
        y=r*Math.sin(ang)
        @resources[name].push new Resource name, x,y, 0,0, @
        ++c

    @itg_station = null
    @pirate_station = null
    itg_station_prob = cls.station_prob * @star.itg + MIN_ITG_STATION_PROB
    pirate_station_prob = cls.station_prob * @star.pirate + MIN_PIRATE_STATION_PROB
    #console.log itg_station_prob
    #console.log pirate_station_prob
    if (itg is @num) or Math.random() < itg_station_prob
      r = MIN_STATION_DIST + @radius * 2
      ang = Math.random() * 2*Math.PI
      x = @_x + r*Math.cos ang
      y = @_y + r*Math.sin ang
      @itg_station = new Station @, 'itg', x,y
      @itg_station.new_missions()

    if (pirate is @num) or Math.random() < pirate_station_prob
      r =MIN_STATION_DIST + @radius * 4
      ang = Math.random() * 2*Math.PI
      x = @_x + r*Math.cos ang
      y = @_y + r*Math.sin ang
      @pirate_station = new Station @, 'pirate', x,y
      @pirate_station.new_missions()

    @moons = []
    return if moon
    mcount = Math.round(rand(cls.min_moons, cls.max_moons)*(@radius/120))
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

    # Sunlight direction:
    @dirx = frand(-@radius,@radius)
    @diry = frand(-@radius*.1,@radius*.1)

  first: ->
    @ang += 0.02
    @xoff = 0
    @yoff = 3*Math.sin @ang
    @x = Math.round @_x + @xoff
    @y = Math.round @_y + @yoff

  render: (scale, x,y, dirx,diry) ->
    ctx = gbox.getBufferContext()
    return if not ctx
    radius = @radius * scale
    dirx *= scale
    diry *= scale
    ctx.beginPath()
    grd = ctx.createRadialGradient x+dirx,y+diry, 0, x+dirx,y+diry, radius*1.4
    grd.addColorStop 0, @color
    grd.addColorStop 1, '#000510'
    ctx.fillStyle = grd
    ctx.arc x,y, radius, 0, 2*Math.PI, false
    ctx.fill()
    ctx.closePath()

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
      x = W*0.1 + (W*0.8) * ((p+1)/@star.planets.length)
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
          planet.render 0.25, x,y, -planet.radius,0
          m=0
          for moon in planet.moons
            x = @positions[p][m+1].x
            y = @positions[p][m+1].y
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

      planet.render 0.25, x,y, -planet.radius*0.5,0
      m=0
      for moon in planet.moons
        x = @positions[p][m+1].x
        y = @positions[p][m+1].y
        moon.render 0.25,
          x,
          y,
          -moon.radius*0.5,0
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
