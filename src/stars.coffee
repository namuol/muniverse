starmapMode = ->
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
    'planetmap'
    'stations'
    'radar'
    'hud'
  ]
  for g in stopGroups
    gbox.stopGroup g

  groups = [
    'starmap'
  ]
  for g in groups
    gbox.stopGroup g
    gbox.toggleGroup g

  player.skip = true


MIN_STAR_COUNT = 800
MAX_STAR_COUNT = 1100
MIN_STAR_RAD = 900
MAX_STAR_RAD = 40000
MAX_STAR_PLANETS = 15
class Star
  distance_to: (other) ->
    dx = (other.x-@x)
    dy = (other.y-@y)
    LY_SCALE*Math.sqrt(dx*dx+dy*dy)
  constructor: (@sector, @num, @x,@y, @color, @itg, @pirate) ->
    @pcount = rand 1,MAX_STAR_PLANETS
    @sid = "S-#{@num}.#{Math.round @x}.#{Math.round @y}"
    @bg_color = '#000510'

  generate_planets: ->
    random = grand(Math.prng(BASE_SEED+'.'+@sector.x+'.'+@sector.y+'.'+@x+'.'+@y))
    @radius = random.frand MIN_STAR_RAD, MAX_STAR_RAD
    @planets = []
    p=0

    @prices = {}
    for own name,res of RESOURCES
      @prices[name] = gaus res.mean_price, res.price_stdv
      @prices[name] = Math.max(1,@prices[name])

    while p < @pcount
      @planets.push new Planet @,
        "#{@sid}.P-#{p}",
        p,
        false,
        @known_itg_station,
        @known_pirate_station
      ++p

  planet_count: ->
    return undefined if @planets is undefined
    count = 0
    for planet in @planets
      count += planet.count()
    return count

MIN_ITG_REGIONS = 1
MAX_ITG_REGIONS = 3
MIN_ITG_REGION_RADIUS = 10
MAX_ITG_REGION_RADIUS = 60
MIN_PIRATE_REGIONS = 1
MAX_PIRATE_REGIONS = 5
MIN_PIRATE_REGION_RADIUS = 10
MAX_PIRATE_REGION_RADIUS = 30
LY_SCALE = 0.25
starmap = undefined
class Starmap
  constructor: (x,y, density) ->
    @skip = false
    @sector =
      x:x
      y:y
    @cursor =
      x:0
      y:0
    Math.seedrandom BASE_SEED+x+','+y
    @itg_regions = []
    i=0
    count=rand MIN_ITG_REGIONS, MAX_ITG_REGIONS
    while i < count
      radius = frand MIN_ITG_REGION_RADIUS, MAX_ITG_REGION_RADIUS
      @itg_regions.push
        x: rand radius,W-radius
        y: rand radius,H-radius-16
        radius: radius
      ++i
    @pirate_regions = []
    i=0
    count=rand MIN_PIRATE_REGIONS, MAX_PIRATE_REGIONS
    while i < count
      radius = frand MIN_PIRATE_REGION_RADIUS, MAX_PIRATE_REGION_RADIUS
      @pirate_regions.push
        x: rand radius,W-radius
        y: rand radius,H-radius-16
        radius: radius
      ++i

    # Generate stars!
    @stars = []
    # And render the starmap (just once)
    el = document.getElementById('starmap')
    @starmap = document.getElementById('starmap')
    console.log @starmap
    ctx = @starmap.getContext '2d'
    #@starmap.drawImage gbox.getImage('starmap_gui'), 0,0
    ctx.clearRect 0,0, W,H
    map = ctx.getImageData 0,0, W,H

    i = 0
    starcount = MAX_STAR_COUNT * density
    while i < starcount
      x = frand 1, W-1
      y = frand 17, H-17
      if getPixel(map, Math.round(x),Math.round(y))[3] <= 0
        color = choose starcolors
        star = new Star @sector, i, x,y, color, @itg_factor(x,y), @pirate_factor(x,y)
        setPixel map, Math.round(x),Math.round(y), color[0],color[1],color[2],color[3]
        @stars.push star
      ++i
    ctx.putImageData map, 0,0

    @known_itg_stations = []
    @known_pirate_stations = []
    i=0
    while i < 300
      star = choose @stars
      arr = @known_itg_stations
      planet = rand 0, star.pcount-1
      if star.pirate > star.itg
        arr = @known_pirate_stations
        star.known_pirate_station = planet
      else
        star.known_itg_station = planet
      arr.push
        star: star
        planet: planet
      ++i

  _factor: (x,y,pirate) ->
    regions = undefined
    if pirate
      regions = @pirate_regions
    else
      regions = @itg_regions

    fac = 0.0001
    for region in regions
      dx = (region.x-x)
      dy = (region.y-y)
      d = Math.sqrt(dx*dx + dy*dy)
      fac += 1/ (d / region.radius)
    return fac

  pirate_factor: (x,y) ->
    return @_factor(x,y,true)

  itg_factor: (x,y) ->
    return @_factor(x,y)

  first: ->
    if @skip
      console.log 'skipping!'
      @skip = false
      return

    y=@cursor.y
    x=@cursor.x
    vx = 0
    vy = 0
    if gbox.keyIsPressed 'up'
      vy -= 1
    else if gbox.keyIsPressed 'down'
      vy += 1
    if gbox.keyIsPressed 'left'
      vx -= 1
    else if gbox.keyIsPressed 'right'
      vx += 1

    if gbox.keyIsHeldForAtLeast('up',30) or
       gbox.keyIsHeldForAtLeast('down',30) or
       gbox.keyIsHeldForAtLeast('left',30) or
       gbox.keyIsHeldForAtLeast('right',30)
      @faster = true
    else if vx == 0 and vy == 0
      @faster = false

    if @faster
      vx *= 2
      vy *= 2
    @cursor.x += vx
    @cursor.y += vy
      

    if @closest_star and gbox.keyIsHit 'a'
      dist = @current_star.distance_to @closest_star
      if player.fuel() >= dist
        sounds.select.play()
        gbox.clearGroup 'planetmap'
        @closest_star.generate_planets()
        window.planetmap = new Planetmap @closest_star
        window.planetmap.skip = true
        gbox.addObject planetmap
        planetmapMode()
        if @current_star != @closest_star
          player.burn_fuel(dist)
          date += dist * player.ftl_ms_per_ly
          current_planet = undefined
          @current_star = @closest_star
        return
      else
        message.set 'Insufficient fuel.', 90

    if gbox.keyIsHit 'c'
      sounds.cancel.play()
      flightMode(current_planet is undefined)

    if !@closest_star or @cursor.x != x or @cursor.y != y
      previous = @closest_star
      @closest_star = @closest(@cursor.x,@cursor.y)
      dx = @current_star.x-@closest_star.x
      dy = @current_star.y-@closest_star.y

  render: (c) ->
    c.drawImage gbox.getImage('starmap_gui'), 0,0

    @render_fuel_range c
    @render_itg_regions c
    @render_pirate_regions c
    
    if @current_star
      @render_current_star c
      @render_cursor c
      @render_star_info c, @closest_star
    if @closest_star and @closest_star != @current_star
      @render_travel_path_to c, @closest_star
    @render_current_missions c
    @render_map c
  
  render_travel_path_to: (c, star) ->
    if star != @current_star
      fuel_diff = player.fuel() - @current_star.distance_to(star)
      if fuel_diff < 0
        col = rgba [255,70,70,0.5]
      else if fuel_diff < player.fuel()/2
        col = rgba [255,255,70,0.5]
      else
        col = rgba [70,255,70,0.5]
      @render_star_connections c, @current_star, star, col

  render_current_missions: (c) ->
    for m in player.missions
      @render_mission c, m

  render_map: (c) ->
    c.drawImage @starmap, 0, 0

  render_mission: (c, m) ->
    if m.location
      gbox.blitTile c,
        tileset: 'cursors'
        tile: 3
        dx: Math.round(m.location.star.x)-4
        dy: Math.round(m.location.star.y)-4

  render_itg_regions: (c) ->
    for r in @itg_regions
      circle c, 'blue',
        Math.round(r.x),
        Math.round(r.y),
        r.radius

  render_pirate_regions: (c) ->
    for r in @pirate_regions
      circle c, 'red',
        Math.round(r.x),
        Math.round(r.y),
        r.radius

  render_star_info: (c, star) ->
    dist = @current_star.distance_to star
    travel_time = player.ftl_ms_per_ly * dist
    gbox.blitText c,
      font: 'small'
      text:"ETA #{formatDateShort date + travel_time}(#{Math.round((travel_time/DAYS)*10)/10} days)"
      dx:1
      dy:H-12
      dw:64
      dh:16

  render_current_star: (c) ->
    gbox.blitTile c,
      tileset: 'cursors'
      tile: 1
      dx: Math.round(@current_star.x)-4
      dy: Math.round(@current_star.y)-4

  render_cursor: (c) ->
    gbox.blitTile c,
      tileset: 'cursors'
      tile: 0
      dx: Math.round(@cursor.x)-4
      dy: Math.round(@cursor.y)-4
    @render_selected_star c, @closest_star
  
  render_selected_star: (c, star) ->
    gbox.blitTile c,
      tileset: 'cursors'
      tile: 2
      dx: Math.round(star.x)-4
      dy: Math.round(star.y)-4

  render_fuel_range: (c) ->
    circle c, '#33e5ff',
      Math.round(@current_star.x),
      Math.round(@current_star.y),
      player.fuel()/LY_SCALE

  render_star_connections: (c, s1, s2, col) ->
    c.strokeStyle = col
    c.beginPath()
    c.moveTo s1.x+0.5, s1.y+0.5
    c.lineTo s2.x+0.5, s2.y+0.5
    c.stroke()

  blit: ->
    c = gbox.getBufferContext()
    return if not c
    @render(c)

  group: 'starmap'
  closest: (x,y) ->
    minD2 = 999999
    ret = undefined
    for star in @stars
      dx = x-star.x
      dy = y-star.y
      d2 = dx*dx + dy*dy
      if d2 < minD2
        minD2 = d2
        ret = star
    return ret
