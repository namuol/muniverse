html ->
  head ->
    script type:'text/javascript', src:'akihabara/gbox.js'
    script type:'text/javascript', src:'akihabara/iphopad.js'
    script type:'text/javascript', src:'akihabara/trigo.js'
    script type:'text/javascript', src:'akihabara/toys.js'
    script type:'text/javascript', src:'akihabara/help.js'
    script type:'text/javascript', src:'akihabara/tool.js'
    script type:'text/javascript', src:'akihabara/gamecycle.js'
    script type:'text/javascript', src:'seedrandom-min.js'
    link rel:'stylesheet', href:'style.css'
    
    meta
      name:'viewport'
      content:'width:device-width; initial-scale:1.0; maximum-scale:1.0; user-scalable:0;'
  body ->
    div class:'directions', ->
      text ''
    canvas width:327, height:1, style:'display:none', id:'starcolors'
    canvas width:16, height:3, style:'display:none', id:'planetcolors'
    canvas width:320, height:320, style:'display:none', id:'starmap'

  coffeescript ->
    BASE_SEED = 'WEEEEE'
    Math.seedrandom BASE_SEED

    window.clamp = (num, min, max) ->
      Math.min(Math.max(num, min), max)

    frand = (min, max) -> min + Math.random()*(max-min)
    rand = (min, max) -> Math.round(frand(min, max))
    choose = (array) -> array[rand(0,array.length-1)]

    rgba = (c) -> "rgba(#{c[0]},#{c[1]},#{c[2]},#{c[3]})"
    getPixel = (img, x,y) ->
      pos = (x + y * img.width) * 4
      r = img.data[pos]
      g = img.data[pos+1]
      b = img.data[pos+2]
      a = img.data[pos+3]
      return [r,g,b,a]

    setPixel = (imageData, x, y, r, g, b, a) ->
      index = (x + y * imageData.width) * 4
      imageData.data[index + 0] = r
      imageData.data[index + 1] = g
      imageData.data[index + 2] = b
      imageData.data[index + 3] = a

    circle = (c, strokeStyle, x,y, radius) ->
      c.strokeStyle = strokeStyle
      c.beginPath()
      c.arc(
        Math.round(x),
        Math.round(y),
        radius,
        0, 2*Math.PI, false
      )
      c.stroke()


    maingame = undefined
    starcolors = []
    planetcolors = []

    loadColors = ->
      starcolors_el = gbox.getImage 'starcolors'
      starcolors_canvas = document.getElementById 'starcolors'
      starcolors_ctx = starcolors_canvas.getContext '2d'
      starcolors_ctx.drawImage starcolors_el, 0,0
      starcolors_img = starcolors_ctx.getImageData 0,0,
                       starcolors_canvas.width, starcolors_canvas.height

      starcolors = []
      idx=0
      while idx < starcolors_el.width
        starcolors.push getPixel starcolors_img, idx,0
        ++idx

      planetcolors_el = gbox.getImage 'planetcolors'
      planetcolors_canvas = document.getElementById 'planetcolors'
      planetcolors_ctx = planetcolors_canvas.getContext '2d'
      planetcolors_ctx.drawImage planetcolors_el, 0,0
      planetcolors_img = planetcolors_ctx.getImageData 0,0,
                       planetcolors_canvas.width, planetcolors_canvas.height

      planetcolors = []
      idy=0
      while idy < planetcolors_el.height
        planetcolors.push []
        idx=0
        while idx < planetcolors_el.width
          planetcolors[idy].push getPixel planetcolors_img, idx,idy
          ++idx
        ++idy

    W = 320
    H = 320

    groupCollides = (obj, group, callback) ->
      for own id,gobj of gbox.getGroup group
        if gbox.collides obj, gobj
          if callback
            callback(gobj)
          else
            return true

    loadResources = ->
      help.akihabaraInit
        title: 'MICROVERSE (working title)'
        width: W
        height: H
        zoom: 2

      gbox.setFps 60

      gbox.addImage 'starcolors', 'starcolors.png'
      gbox.addImage 'planetcolors', 'planetcolors.png'

      gbox.addImage 'starmap_gui', 'starmap_gui.png'
      gbox.addImage 'starmap_gui_cursors', 'starmap_gui_cursors.png'
      gbox.addTiles
        id: 'cursors'
        image: 'starmap_gui_cursors'
        tileh: 9
        tilew: 9
        tilerow: 1
        gapx: 0
        gapy: 0

      gbox.addImage 'bg', 'bg.png'
      gbox.addImage 'logo', 'logo.png'

      gbox.addImage 'ship0', 'ship0.png'
      gbox.addTiles
        id: 'ship0_tiles'
        image: 'ship0'
        tileh: 8
        tilew: 8
        tilerow: 16
        gapx: 0
        gapy: 0

      gbox.addImage 'bad0', 'bad0.png'
      gbox.addImage 'planet0', 'planet0.png'

      gbox.addImage 'drones', 'drones.png'
      gbox.addTiles
        id: 'drones_tiles'
        image: 'drones'
        tileh: 5
        tilew: 5
        tilerow: 3
        gapx: 0
        gapy: 0

      gbox.addImage 'stations', 'stations.png'
      gbox.addTiles
        id: 'stations_tiles'
        image: 'stations'
        tileh: 32
        tilew: 32
        tilerow: 4
        gapx: 0
        gapy: 0

      gbox.addImage 'peoples', 'peoples.png'
      gbox.addTiles
        id: 'peoples_tiles'
        image: 'peoples'
        tileh: 16
        tilew: 16
        tilerow: 16
        gapx: 0
        gapy: 0

      gbox.addImage 'resources', 'resources.png'
      gbox.addTiles
        id: 'resources_tiles'
        image: 'resources'
        tileh: 1
        tilew: 1
        tilerow: 8
        gapx: 0
        gapy: 0

      gbox.addImage 'particles', 'particles.png'
      gbox.addTiles
        id: 'particles_tiles'
        image: 'particles'
        tileh: 1
        tilew: 1
        tilerow: 16
        gapx: 0
        gapy: 0

      gbox.addImage 'shots', 'shots.png'
      gbox.addTiles
        id: 'shots_tiles'
        image: 'shots'
        tileh: 3
        tilew: 3
        tilerow: 9
        gapx: 0
        gapy: 0

      gbox.addImage 'font', 'font.png'
      gbox.addFont
        id: 'small'
        image: 'font'
        firstletter: '!'
        tileh: 8
        tilew: 8
        tilerow: 20
        gapx: 0
        gapy: 0

      gbox.loadAll main

    stationMode = (station) ->

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
      ]
      for g in stopGroups
        gbox.stopGroup g

      stationscreen = new StationScreen station
      gbox.addObject stationscreen

      groups = [
        'stationscreen'
      ]
      for g in groups
        gbox.stopGroup g
        gbox.toggleGroup g

      player.skip = true

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

   
    flightMode = (reset) ->
      if reset
        gbox.clearGroup 'friend_shots'
        gbox.clearGroup 'foe_shots'
        gbox.clearGroup 'particles'
      gbox.clearGroup 'planet'
      gbox.clearGroup 'resources'
      gbox.clearGroup 'stations'
      gbox.addObject player
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
      ]
      for g in groups
        gbox.stopGroup g
        gbox.toggleGroup g
      player.skip = true

    cam = {
      x:0
      y:0
    }
    
    class Menu
      constructor: ->
        @selected = 0
        @items = []

      up: ->
        return if @items.length is 0
        @selected = (@selected - 1) % @items.length
        if @selected < 0
          @selected = @items.length - 1
        while @items[@selected].disabled
          @selected = (@selected - 1) % @items.length
      down: ->
        return if @items.length is 0
        @selected = (@selected + 1) % @items.length
        while @items[@selected].disabled
          @selected = (@selected + 1) % @items.length
      a: ->
        if @items[@selected]
          @items[@selected].a()
      b: ->
        if @items[@selected]
          @items[@selected].b()
      c: ->
        if @items[@selected]
          @items[@selected].c()
      update: ->
        if gbox.keyIsHit 'a'
          @a()
        if gbox.keyIsHit 'b'
          @b()
        if gbox.keyIsHit 'c'
          @c()

        if gbox.keyIsHit 'up'
          @up()
        else if gbox.keyIsHit 'down'
          @down()

      render: (x,yoff) ->
        height = 17 * @items.length
        top = H/2 - height/2 + yoff
        top -= 17
        num = 0
        for item in @items
          top += 17
          
          if !item.disabled
            if @selected == num
              alpha = 1
            else
              alpha = 0.5
          else
            alpha = 0.25
          ++num
          item.render x, top, alpha

    class MenuItem
      constructor: (@text) ->
      a: -> # TODO SOUNDS HERE
      b: ->
      c: ->
      render: (x, top, alpha) ->
        gbox.blitText gbox.getBufferContext(),
          font: 'small'
          text: @text()
          dx:x
          dy:top
          dw:W
          dh:16
          halign: gbox.ALIGN_LEFT
          valign: gbox.ALIGN_TOP
          alpha:alpha



    addCamera = ->
      gbox.addObject
        id: 'cam_id'
        x:0
        y:0
        vx:0
        vy:0
        group: 'game'
        init: ->
          @x = 100
          @y = 100
          @vx = 0
          @vy = 0

        first: ->
          @vx = (player.x+player.vx*60 - (@x+160)) * 0.05
          @vy = (player.y+player.vy*60 - (@y+160)) * 0.05
          @x += @vx
          @y += @vy

    
    BASE_THRUST = 0.025
    BASE_SHIELDS = 3
    BASE_WCHARGE_RATE = 0.05
    BASE_WCHARGE_CAP = 2
    BASE_WSPEED = 2
    BASE_WPOWER = 1
    BASE_WSPAN = 80
    TURN_SPEED = 0.1
    player = undefined
    class Player
      constructor: (name) ->
        @available_cabins = 3
        @wcharge_cap = BASE_WCHARGE_CAP
        @wcharge_rate = BASE_WCHARGE_RATE
        @wcharge = @wcharge_cap
        @wspeed = BASE_WSPEED
        @wpower = BASE_WPOWER
        @wspan = BASE_WSPAN
        @thrust = BASE_THRUST
        @afterburn = 0.025
        @shields = BASE_SHIELDS

        @cargo =
          fuel: 4
        @init()

      fuel: ->
        return @cargo.fuel

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

        going = false
        if gbox.keyIsPressed 'up'
          going = true
          @vx += @ax
          @vy += @ay
        else if gbox.keyIsPressed('down') or gbox.keyIsPressed('b')
          @vx *= 1-@afterburn
          @vy *= 1-@afterburn

        if gbox.keyIsPressed 'right'
          @ang += TURN_SPEED
          @ax = Math.cos(@ang) * @thrust
          @ay = Math.sin(@ang) * @thrust
        else if gbox.keyIsPressed 'left'
          @ang -= TURN_SPEED
          @ax = Math.cos(@ang) * @thrust
          @ay = Math.sin(@ang) * @thrust

        if @ang < 0
          @ang = Math.PI*2 - @ang

        @x += @vx
        @y += @vy

        @frame = Math.round(((@ang+(Math.PI/2)) / (Math.PI*2)) * 16) % 16
        if going
          @frame += 16
          if ++@particle_tick % 4 is 0
            addParticle 'fire', @x+@w/2,@y+@h/2,
              @vx-@ax*40*frand(0.5,1),@vy-@ay*40*frand(0.5,1)

        if gbox.keyIsHit('a') and (@wcharge >= @wpower)
          @wcharge -= @wpower
          addShot @x+@w/2,@y+@h/2,
            @x+@w/2+(@ax/@thrust)*20000,
            @y+@h/2+(@ay/@thrust)*20000,
            @wpower,
            @wspeed, 4, 'friend_shots', @wspan,
            @vx, @vy

        if @wcharge < @wcharge_cap
          @wcharge += @wcharge_rate

        groupCollides @, 'foe_shots', (shot) =>
          i=0
          while i < 3
            addParticle 'fire', @x+@w/2,@y+@h/2,
              @vx+frand(-.5,.5),@vy+frand(-.5,.5)
            ++i
          @shields -= shot.power
          shot.die()
        
        if not going
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

    addBaddie = (planet, profile) ->
      gbox.addObject
        group: 'baddies'
        init: ->
          @num = 0
          @frame = 0
          @image = gbox.getImage('bad'+@num)
          @w = 8
          @h = 8
          @x = Math.random() * gbox.getScreenW()
          @y = Math.random() * gbox.getScreenH()
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
          @hostile = true
          @ang = 0
          @thrust = 0.006
          @afterburn = 0.005
          @shields = 3
          @cargo_cap = 10
          @cargo = {}

        first: ->
          if @hostile
            dx = player.x - @x
            dy = player.y - @y
            d = Math.sqrt(dx*dx + dy*dy)

            if @wcharge >= @wcost and d < @attack_dist
              @tsx = player.x + player.vx + @vx
              @tsy = player.y + player.vy + @vy
              @wcharge -= @wcost
              addShot @x+@w/2,@y+@h/2,
                @tsx,
                @tsy,
                @wpower,
                @wspeed, 1, 'foe_shots', @wspan,
                @vx, @vy
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

          groupCollides @, 'friend_shots', (shot) =>
            @shields -= shot.power
            i=0
            while i < 3
              addParticle 'fire', @x+@w/2,@y+@h/2,
                @vx+frand(-0.5,0.5),@vy+frand(-.5,.5)
              ++i
            addParticle 'wreckage', @x+@w/2,@y+@h/2,
              @vx+frand(-0.5,0.5),@vy+frand(-.5,.5)

            if @shields < 0
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

        initialize: ->
          @init()

        die: ->
          gbox.trashObject @

        blit: ->
          gbox.blitAll gbox.getBufferContext(), @image,
            dx: Math.round(@x-cam.x)
            dy: Math.round(@y-cam.y)

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

    addShot = (x,y, tx,ty, power, speed, frame, group, lifespan, vx,vy) ->
      gbox.addObject
        group: group
        w:0.1
        h:0.1
        init: ->
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

        initialize: ->
          @init()

        blit: ->
          gbox.blitTile gbox.getBufferContext(),
            tileset: @tileset
            tile: @frame
            dx: Math.round(@x-cam.x)
            dy: Math.round(@y-cam.y)
    
    MIN_STAR_COUNT = 800
    MAX_STAR_COUNT = 1100
    MIN_STAR_RAD = 900
    MAX_STAR_RAD = 40000
    MAX_STAR_PLANETS = 15

    class Star
      constructor: (sector, x,y, color, itg, piracy) ->
        @sector = sector
        @x = x
        @y = y
        @color = color
        @pcount = rand 1,MAX_STAR_PLANETS
        @itg = itg
        @pirate = piracy

      generate_planets: ->
        Math.seedrandom BASE_SEED+'.'+@sector.x+'.'+@sector.y+'.'+@x+'.'+@y
        @radius = frand MIN_STAR_RAD, MAX_STAR_RAD
        @planets = []
        p=0
        while p < @pcount
          @planets.push new Planet @, p, false
          ++p

      planet_count: ->
        return undefined if @planets is undefined
        count = 0
        for planet in @planets
          count += planet.count()
        return count
    
    MAX_ITG_REGIONS = 3
    MIN_ITG_REGION_RADIUS = 10
    MAX_ITG_REGION_RADIUS = 50
    MAX_PIRATE_REGIONS = 3
    MIN_PIRATE_REGION_RADIUS = 10
    MAX_PIRATE_REGION_RADIUS = 50
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
        count=rand 0, MAX_ITG_REGIONS
        while i < count
          radius = frand MIN_ITG_REGION_RADIUS, MAX_ITG_REGION_RADIUS
          @itg_regions.push
            x: rand radius,W-radius
            y: rand radius,H-radius-16
            radius: radius
          ++i
        @pirate_regions = []
        i=0
        count=rand 0, MAX_PIRATE_REGIONS
        while i < count
          radius = frand MIN_PIRATE_REGION_RADIUS, MAX_PIRATE_REGION_RADIUS
          @itg_regions.push
            x: rand radius,W-radius
            y: rand radius,H-radius-16
            radius: radius
          ++i

        # Generate stars!
        @stars = []
        # And render the starmap (just once)
        el = document.getElementById('starmap')
        c = document.getElementById('starmap').getContext '2d'
        c.drawImage gbox.getImage('starmap_gui'), 0,0
        @starmap = c.getImageData 0,0, W,H

        i = 0
        starcount = MAX_STAR_COUNT * density
        while i < starcount
          color = choose starcolors
          x = frand 1, W-1
          y = frand 1, H-16-1
          star = new Star @sector, x,y, color, @itg_factor(x,y), @pirate_factor(x,y)
          star.sid = i
          @stars.push star
          setPixel @starmap, Math.round(x),Math.round(y), color[0],color[1],color[2],color[3]
          ++i
        c.putImageData @starmap, 0,0
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
          @skip = false
          return

        y=@cursor.y
        x=@cursor.x
        if gbox.keyIsPressed 'up'
          @cursor.y -= 0.5
        else if gbox.keyIsPressed 'down'
          @cursor.y += 0.5
        if gbox.keyIsPressed 'left'
          @cursor.x -= 0.5
        else if gbox.keyIsPressed 'right'
          @cursor.x += 0.5

        if @closest_star and gbox.keyIsHit 'a'
          gbox.clearGroup 'planetmap'
          @closest_star.generate_planets()
          window.planetmap = new Planetmap @closest_star
          window.planetmap.skip = true
          gbox.addObject planetmap
          planetmapMode()
          return

        if current_planet and gbox.keyIsHit 'c'
          flightMode()

        if !@closest_star or @cursor.x != x or @cursor.y != y
          @closest_star = @closest(@cursor.x,@cursor.y)
          dx = @current_star.x-@closest_star.x
          dy = @current_star.y-@closest_star.y
          @closest_star.dist = Math.sqrt(dx*dx+dy*dy)*LY_SCALE

      blit: ->
        c = gbox.getBufferContext()
        if c
          c.putImageData @starmap, 0, 0

          for r in @itg_regions
            circle c, 'blue',
              Math.round(r.x),
              Math.round(r.y),
              r.radius
          for r in @pirate_regions
            circle c, 'red',
              Math.round(r.x),
              Math.round(r.y),
              r.radius

          if @current_star
            gbox.blitText c,
              font: 'small'
              text:"LY: #{Math.round(@closest_star.dist*100)/100}"
              dx:1
              dy:H-12
              dw:64
              dh:16

            gbox.blitTile c,
              tileset: 'cursors'
              tile: 0
              dx: Math.round(@current_star.x)-4
              dy: Math.round(@current_star.y)-4
            gbox.blitTile c,
              tileset: 'cursors'
              tile: 1
              dx: Math.round(@cursor.x)-4
              dy: Math.round(@cursor.y)-4
            gbox.blitTile c,
              tileset: 'cursors'
              tile: 2
              dx: Math.round(@closest_star.x)-4
              dy: Math.round(@closest_star.y)-4
            circle c, '#d97777',
              Math.round(@current_star.x),
              Math.round(@current_star.y),
              player.fuel()/LY_SCALE

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
      constructor: (star, num, moon) ->
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
        for own name,res of RESOURCES
          @resources[name] = []
          count = Math.round(frand(0,res[@ptype+'_prob']) * max_resource_count)
          c=0
          while c < count
            ang = Math.PI*2 * Math.random()
            r=@radius*Math.random()
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
        if Math.random() < itg_station_prob
          r = MIN_STATION_DIST + @radius * 2
          ang = Math.random() * 2*Math.PI
          x = @_x + r*Math.cos ang
          y = @_y + r*Math.sin ang
          @itg_station = new Station @, 'itg', x,y
          @itg_station.new_missions()

        if Math.random() < pirate_station_prob
          r =MIN_STATION_DIST + @radius * 4
          ang = Math.random() * 2*Math.PI
          x = @_x + r*Math.cos ang
          y = @_y + r*Math.sin ang
          @pirate_station = new Station @, 'pirate', x,y
          @pirate_station.new_missions()

        @moons = []
        return if moon
        mcount = Math.round(rand(cls.min_moons, cls.max_moons)*(@radius/120))
        m=0
        while m < mcount
          @moons.push new Planet star, 0, true
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
          @positions[p].push planet.cursorpos
          m=0
          for moon in planet.moons
            moon.cursorpos =
              x:x
              y:y+(planet.radius*0.5+(m+1)*PLANET_CLASSES.moon.max_radius)*0.5

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
          if @cursor.y
            current_planet = @star.planets[@cursor.x].moons[@cursor.y-1]
          else
            current_planet = @star.planets[@cursor.x]
          current_planet.init()
          starmap.current_star = current_planet.star
          player.vx = 0
          player.vy = 0
          player.x = 0
          player.y = 0
          flightMode(true)

        return if @positions.length is 0
        if gbox.keyIsHit 'up'
          @cursor.y -= 1
        else if gbox.keyIsHit 'down'
          @cursor.y += 1
        if gbox.keyIsHit 'left'
          @cursor.x -= 1
        else if gbox.keyIsHit 'right'
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
         

          if current_planet and current_planet.star is @star
            gbox.blitTile c,
              tileset: 'cursors'
              tile: 3
              dx: Math.round(current_planet.cursorpos.x)
              dy: Math.round(current_planet.cursorpos.y)-4
          gbox.blitTile c,
            tileset: 'cursors'
            tile: 4
            dx: Math.round(@positions[@cursor.x][@cursor.y].x)
            dy: Math.round(@positions[@cursor.x][@cursor.y].y)-4

    STATIONS = {
      'itg':
        num:0
        frame_length:60/2
        fugitive_rate: 0.1
      'pirate':
        num:1
        frame_length:60/2
        fugitive_rate: 0.4
    }

    class Person
      constructor: (role, fugitive) ->
        @parts = []
        @parts.push rand 0, 16
        @parts.push rand 0, 16
        if rand(0,1)
          @parts.push @parts[1]
        @role = role
        @fugitive = fugitive

      render: (x,y, alpha) ->
        n=0
        for partNum in @parts
          gbox.blitTile gbox.getBufferContext(),
            tileset: 'peoples_tiles'
            tile: n*16 + partNum
            dx: Math.round(x)
            dy: Math.round(y)
          ++n

    class Mission extends MenuItem
      constructor: (@person) ->
        @accepted = false
      a: ->
        dq = @doesnt_qualify()
        if dq
          # TODO message protocol..
          console.log dq
          return false
        @accepted = !@accepted
        return true
      doesnt_qualify: ->
        false
      text: ->
        if @accepted
          '[X]'
        else
          '[ ]'
      render: (x, top, alpha) ->
        @person.render(x,top,alpha)
        super(x+24, top+4, alpha)

    class CabinDweller extends Mission
      constructor: (@person, @star) ->
      a: ->
        if super()
          if @accepted
            console.log 'Accepted Taxi Mission!'
            --player.available_cabins
          else
            console.log 'Abandoned Taxi Mission!'
            ++player.available_cabins
      doesnt_qualify: ->
        return false if @accepted

        if player.available_cabins <= 0
          'No available cabins.'
        else
          false

    class TaxiMission extends CabinDweller
      text: ->
        super() + 'Taxi'
    class CrewMission extends CabinDweller
      text: ->
        super() + 'Crew'

    DOCKING_DURATION = 80
    class Station
      new_missions: ->
        max_count = PLANET_CLASSES[@planet.ptype].max_mission_count
        activity = (@planet.star.itg+@planet.star.pirate)
        mission_count = Math.round(frand(0,1)*activity*max_count)
        @missions = []
        i=0
        while i < mission_count
          person = new Person 'passenger', frand(0,1)<STATIONS[@name].fugitive_rate
          mission = undefined
          switch rand(0,4)
            when 0
              mission = new TaxiMission person
            else
              mission = new CrewMission person

          @missions.push mission
          ++i
        console.log @missions

      group: 'stations'
      constructor: (planet, name, x,y) ->
        @planet = planet
        @name = name
        @x = x
        @y = y
        @num = STATIONS[@name].num
        @frame_length = STATIONS[@name].frame_length
        @next_frame = @frame_length
        @frame = @num*4
        @tileset = 'stations_tiles'
        @ang = 0
        @docking_count = 0
      
      w:32
      h:32
      die: ->
        gbox.trashObject @

      first: ->
        --@next_frame
        if @next_frame < 0
          @frame = @num*4 + ((@frame%4) + 1)%4
          @next_frame = @frame_length
        @ang += 0.034
        @yoff = 2*Math.sin @ang

        if !player.going and gbox.collides @, player
          ++@docking_count
        else
          @docking_count = 0

        if @docking_count > DOCKING_DURATION
          stationMode @
          @docking_count = -DOCKING_DURATION

      blit: ->
        gbox.blitTile gbox.getBufferContext(),
          tileset: @tileset
          tile: @frame
          #dx:current_planet.x
          #dy:current_planet.y
          dx: Math.round(@x-cam.x)
          dy: Math.round(@y+@yoff-cam.y)


    STATION_SUB_SCREENS = [
        name:'Cargo'
        bg:'starmap_gui'
      ,
        name:'Missions'
        bg:'starmap_gui'
      ,
        name:'Hangar'
        bg:'starmap_gui'
    ]

    class StationScreen extends Menu
      group: 'stationscreen'
      constructor: (station) ->
        super()
        @station = station
        @skip = false
        @sub_screen = 0
        @sub_items = []
        i=0
        for scr in STATION_SUB_SCREENS
          @sub_items.push []
          switch scr.name
            when 'Cargo'
              false
            when 'Missions'
              @sub_items[i] = @station.missions
            when 'Hangar'
              false

          ++i

      c: ->
        gbox.trashObject @
        flightMode()

      first: ->
        if @skip
          @skip = false
          return
        
        if gbox.keyIsHit 'left'
          @sub_screen -= 1
          console.log 'l'
        else if gbox.keyIsHit 'right'
          @sub_screen += 1
          console.log 'r'

        if @sub_screen < 0
          @sub_screen = STATION_SUB_SCREENS.length-1
        @sub_screen = @sub_screen % STATION_SUB_SCREENS.length
        @items = @sub_items[@sub_screen]
        @update()

      blit: ->
        c = gbox.getBufferContext()
        return if not c
        gbox.blitAll c, gbox.getImage(STATION_SUB_SCREENS[@sub_screen].bg),
          dx:0
          dy:0
        @render(0,0)

    PARTICLES = {
      fire:
        num:0
        lifespan:60
        randomframe:false
        frame_length:60/16
      wreckage:
        num:1
        lifespan:200
        frame_length:4
        randomframe:true
    }

    addParticle = (name, x,y, vx,vy) ->
      gbox.addObject
        group: 'particles'
        num:PARTICLES[name].num
        lifespan:PARTICLES[name].lifespan
        w:0.1
        h:0.1
        vx:0
        vy:0
        init: ->
          @frame_length = PARTICLES[name].frame_length
          @next_frame = @frame_length
          @frame = @num*16
          if PARTICLES[name].randomframe
            @frame += rand(0,15)
          @tileset = 'particles_tiles'
          @w = 3
          @h = 3
          if vx and vy
            @vx = vx
            @vy = vy
          @tick = 0
          @x = x
          @y = y

        die: ->
          gbox.trashObject @

        first: ->
          @x += @vx
          @y += @vy
          --@next_frame
          if @next_frame < 0
            @frame = @num*16 + ((@frame%16) + 1)%16
            @next_frame = @frame_length
          ++@tick

          if @tick > @lifespan
            @die()

        initialize: ->
          @init()

        blit: ->
          gbox.blitTile gbox.getBufferContext(),
            tileset: @tileset
            tile: @frame
            dx: Math.round(@x-cam.x)
            dy: Math.round(@y-cam.y)

    RESOURCES =
      'scrap metal':
        num:0
        tons_per_unit:1
        gas_giant_prob: 0.1
        rocky_prob: 0.5
        moon_prob: 0.75
      'lifeforms':
        num:1
        tons_per_unit:0.05
        gas_giant_prob: 0.05
        rocky_prob: 0.2
        moon_prob: 0.1
      'fuel':
        num:2
        tons_per_unit:0.25
        gas_giant_prob: 0.25
        rocky_prob: 0.1
        moon_prob: 0.1
      'minerals':
        num:3
        tons_per_unit:0.5
        gas_giant_prob: 0.05
        rocky_prob: 0.5
        moon_prob: 0.2
      'narcotics':
        num:4
        tons_per_unit:0.01
        gas_giant_prob: 0
        rocky_prob: 0
        moon_prob: 0

    class Resource
      group: 'resources'
      constructor: (name, x,y, vx,vy, planet) ->
        @planet = planet
        @num = RESOURCES[name].num
        @next_frame = @frame_length
        @frame = rand @num*8, @num*8 + 8
        @tileset = 'resources_tiles'
        @w = 3
        @h = 3
        if vx and vy
          @vx = vx
          @vy = vy
        @tick = 0
        @xoff = x
        @yoff = y
        @x = 0
        @y = 0
        @active = true

      frame_length: 4
      vx:0
      vy:0
      die: ->
        @active = false
        gbox.trashObject @

      first: ->
        return if !@active

        if @planet
          @x = @planet.x + @xoff
          @y = @planet.y + @yoff
        else
          @x += @vx
          @y += @vy
          @vx *= 0.005
          @vy *= 0.005

        --@next_frame

        if @next_frame < 0
          @frame = @num*8 + ((@frame%8) + 1)%8
          @next_frame = @frame_length

      blit: ->
        return if !@active
        gbox.blitTile gbox.getBufferContext(),
          tileset: @tileset
          tile: @frame
          dx: Math.round(@x-cam.x)
          dy: Math.round(@y-cam.y)

    main = ->
      gbox.setGroups [
        'background'
        'game'
        'starmap'
        'planetmap'
        'stationscreen'
        'planet'
        'stations'
        'resources'
        'particles'
        'player'
        'friend_shots'
        'baddies'
        'drones'
        'foe_shots'
        'pause'
      ]
      
      loadColors()

      maingame = gamecycle.createMaingame('game', 'game')
      maingame.gameMenu = -> true
 
      maingame.gameIntroAnimation = -> true

      maingame.gameTitleIntroAnimation = ->
        gbox.blitFade gbox.getBufferContext(),
          alpha:1
        gbox.blitAll gbox.getBufferContext(), gbox.getImage('logo'),
          dx:1
          dy:1

        gbox.keyIsHit 'a'

      maingame.pressStartIntroAnimation = (reset) ->
        gbox.keyIsHit 'a'

      maingame.initializeGame = ->
        #addPauseScreen()
        player = new Player
        starmap = new Starmap 5,34,0.6
        starmap.current_star = choose starmap.stars
        starmap.cursor =
          x: starmap.current_star.x
          y: starmap.current_star.y
        starmap.current_star.generate_planets()
        current_planet = choose starmap.current_star.planets
        window.planetmap = new Planetmap starmap.current_star

        gbox.addObject starmap

        cam = addCamera()

        gbox.addObject
          id: 'bg_id'
          group: 'background'
          color: 'rgb(0,0,0)'
          blit: ->
            gbox.blitFade gbox.getBufferContext(),
              color:'#000510'
              alpha:1

            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:Math.round -cam.x % W
              dy:Math.round -cam.y % H

            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:Math.round -cam.x % W - W
              dy:Math.round -cam.y % H - H
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:Math.round -cam.x % W
              dy:Math.round -cam.y % H - H
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:Math.round -cam.x % W + W
              dy:Math.round -cam.y % H - H
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:Math.round -cam.x % W + W
              dy:Math.round -cam.y % H
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:Math.round -cam.x % W + W
              dy:Math.round -cam.y % H + H
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:Math.round -cam.x % W
              dy:Math.round -cam.y % H + H
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:Math.round -cam.x % W - W
              dy:Math.round -cam.y % H + H
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:Math.round -cam.x % W - W
              dy:Math.round -cam.y % H

      gbox.go()
    window.addEventListener 'load', loadResources, false
