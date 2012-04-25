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
    div id:'instructions', ->
      h3 -> 'Instructions:'
      h4 -> 'Star Map:'
      ul ->
        li -> "Arrow Keys move cursor to select star system, highlighted with green circle."
        li -> "Large turquoise circle is the range of your FTL fuel."
        li -> "'Z' selects star system"
        li -> "'C' returns to Flight Mode"

      h4 -> "Planet Map:"
      ul ->
        li -> "Arrow Keys move cursor to select a planet you wish to visit."
        li -> "'Z' travels to that planet (instantaneously) and puts you in Flight Mode"
        li -> "'C' returns to Star Map"

      h4 -> "Flight Mode:"
      ul ->
        li ->
          text "Arrow Keys -- control is much like classic Asteroids."
          ul ->
            li -> "Down is afterburner ('brake')."
        li -> "'Z' -- Fire weapon."
        li -> "\"Park\" over a space station for a few seconds to enter the Station Screen"
        li -> "Blinking pixels on and around planets are resources -- fly into them to collect them."

      h4 -> "Station Screen:"
      ul ->
        li -> "'C' to exit the Station."
        li -> "Up/Down to select different items on current screen."
        li ->
          text "Left/Right change screen (Cargo[trade], Missions, Hangar)"
          h5 -> 'Cargo'
          ul ->
            li -> "'Z' - Buy selected good"
            li -> "'X' - Sell selected good"
          h5 -> "Missions"
          ul ->
            li -> "'Z' - Accept/Abandon selected mission"
          h5 -> "Hangar"
          ul ->
            li -> "'Z' - Purchase selected upgrade"
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
    gaus = (mean, stdv) ->
      # approximates Box-Muller transform:
      rnd = (Math.random()*2-1)+(Math.random()*2-1)+(Math.random()*2-1)
      return rnd*stdv + mean
    dist = (a,b) ->
      dx=a.x-b.x
      dy=a.y-b.y
      Math.sqrt(dx*dx+dy*dy)

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
        title: 'μniverse'
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

      gbox.addImage 'fugitive_icon', 'fugitive_icon.png'
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
        'radar'
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
        'radar'
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
      gbox.addObject new Radar
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
        'radar'
      ]
      for g in groups
        gbox.stopGroup g
        gbox.toggleGroup g
      player.skip = true

    cam = {
      x:0
      y:0
    }

    class Message
      group: 'message'
      constructor: ->
        @visible = false
        @msgs = []
      add: (str, lifespan=240, person) ->
        @msgs.push
          str: str
          lifespan: lifespan
          person: person
        @visible = true

      set: (str, lifespan=240, person) ->
        @msgs = []
        @add str, lifespan, person
      first: ->
        return if not @visible

        if @msgs[0].lifespan != undefined
          if --@msgs[0].lifespan < 0
            @msgs.splice 0,1
            if @msgs.length is 0
              @visible = false

      blit: (x,y) ->
        return if not @visible
        if @msgs[0].person
          @msgs[0].person.render_face(1,1,1, true)
        gbox.blitText gbox.getBufferContext(),
          font: 'small'
          text: @msgs[0].str
          dx:17
          dy:5
          dw:W
          dh:16
          halign: gbox.ALIGN_LEFT
          valign: gbox.ALIGN_TOP
    message = new Message
    
    class Menu
      _held: (key) ->
        gbox.keyIsHit(key) or (gbox.keyIsHeldForAtLeast(key,15) and gbox.keyHeldTime(key)%5==0)
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
        if @_held 'a'
          @a()
        if @_held 'b'
          @b()
        if @_held 'c'
          @c()

        if @_held 'up'
          @up()
        else if @_held 'down'
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
          dx:Math.round x
          dy:Math.round top
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
        initialize: ->
          @max_dist = 100
          @max_dist2 = @max_dist*@max_dist
          @x = 100
          @y = 100
          @vx = 0
          @vy = 0
          @w = W
          @h = H

        first: ->
          @vx = (player.x+player.vx*60 - (@x+160)) * 0.05
          @vy = (player.y+player.vy*60 - (@y+160)) * 0.05
          @x += @vx
          @y += @vy
          c =
            x:@x + @w/2
            y:@y + @h/2
          dx = c.x-player.x
          dy = c.y-player.y
          d2 = dx*dx + dy*dy
          if d2 > @max_dist2
            d = Math.sqrt(d2)
            dr = (d-@max_dist)/d
            ddx = dr*dx
            ddy = dr*dy
            @x -= ddx
            @y -= ddy

    DEFAULT_RADAR_RENDER = (x,y, alpha) ->
      if x > cam.h-2
        x = cam.h-2
      c = gbox.getBufferContext()
      if c
        circle c, 'white', Math.round(x),Math.round(y), 2

    RADAR_ITEMS =
      'planet':
        min_dist: -> -1
        render: (x,y, alpha) ->
          current_planet.render 4/current_planet.radius,
            Math.round(x),Math.round(y),
            current_planet.dirx,current_planet.diry
      'stations':
        min_dist: -> -1
    class Radar
      group: 'radar'
      constructor: ->
      blit: ->
        c =
          x:(player.x-cam.x)
          y:(player.y-cam.y)

        for own group,item of RADAR_ITEMS
          for own id,obj of gbox.getGroup group
            dx = (obj.x-cam.x)-c.x
            dy = (obj.y-cam.y)-c.y
            d = Math.sqrt dx*dx+dy*dy
            if item.min_dist() < 0 or d < item.min_dist()
              _x=c.x+dx
              _y=c.y+dy

              x = clamp c.x+dx, 0,cam.w
              y = clamp c.y+dy, 0,cam.h
              continue if _x==x and _y==y
              if item.render
                item.render x,y, 1
              else
                DEFAULT_RADAR_RENDER x,y, 1

    GAME_OVER_MSGS = [
      'GAME IS OVER'
      'DERP! You died.'
      'Losing is fun.'
    ]

    EQUIPMENT = [
        name: 'Thruster'
        attr: 'thrust'
        levels: [
            price: -> 1500,
            val: 0.045*0.33
          ,
            price: -> 10000,
            val: 0.045*0.66
          ,
            price: -> 40000
            val: 0.045
        ]
      ,
        name: 'Plasma Cannon'
        attr: 'wpower'
        levels: [
            price: -> 1000,
            val: 0.5
          ,
            price: -> 5000,
            val: 1
          ,
            price: -> 20000
            val: 2
        ]
      ,
        name: 'Weapon Charger'
        attr: 'wcharge_rate'
        levels: [
            price: -> 10000,
            val: 0.025
          ,
            price: -> 20000,
            val: 0.07
          ,
            price: -> 60000
            val: 0.3
        ]
      ,
        name: 'Afterburner'
        attr: 'afterburn'
        levels: [
            price: -> 2000,
            val: 0.005
          ,
            price: -> 15000,
            val: 0.01
          ,
            price: -> 60000
            val: 0.03
        ]
      ,
        name: 'Shields'
        attr: 'afterburn'
        levels: [
            price: -> 2000,
            val: 3
          ,
            price: -> 25000,
            val: 10
          ,
            price: -> 90000
            val: 25
        ]
      ,
        name: 'Repair Shields'
        price: -> (player.shields_max - player.shields) * 100
        apply: ->
          player.shields = player.shields_max

    ]

    
    BASE_THRUST = EQUIPMENT[0].levels[0].val
    BASE_SHIELDS = 3
    BASE_WCHARGE_RATE = EQUIPMENT[2].levels[0].val
    BASE_WCHARGE_CAP = 2
    BASE_WSPEED = 2
    BASE_WPOWER = EQUIPMENT[1].levels[0].val
    BASE_WSPAN = 80
    TURN_SPEED = 0.1
    BASE_CARGO_CAP = 5
    BASE_AFTERBURN = EQUIPMENT[3].levels[0].val
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

        @cargo =
          fuel: [
            1,2,3,4
          ]
          narcotics: [
           'teehee',2
          ]
        @equipment = {}
        for eq in EQUIPMENT
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
          if @shields <= 0
            @die()
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

      die: ->
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


    addBaddie = (planet, profile) ->
      gbox.addObject
        group: 'baddies'
        init: ->
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
          @hostile = Math.random() < (0.25+current_planet.star.pirate-current_planet.star.itg)
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
      distance_to: (other) ->
        dx = (other.x-@x)
        dy = (other.y-@y)
        LY_SCALE*Math.sqrt(dx*dx+dy*dy)
      constructor: (@sector, @num, @x,@y, @color, @itg, @pirate) ->
        @pcount = rand 1,MAX_STAR_PLANETS
        @sid = "S-#{@num}.#{Math.round @x}.#{Math.round @y}"

      generate_planets: ->
        Math.seedrandom BASE_SEED+'.'+@sector.x+'.'+@sector.y+'.'+@x+'.'+@y
        @radius = frand MIN_STAR_RAD, MAX_STAR_RAD
        @planets = []
        p=0
        while p < @pcount
          @planets.push new Planet @, "#{@sid}.P-#{p}", p, false, @known_itg_station,@known_pirate_station
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
        c = document.getElementById('starmap').getContext '2d'
        c.drawImage gbox.getImage('starmap_gui'), 0,0
        @starmap = c.getImageData 0,0, W,H

        i = 0
        starcount = MAX_STAR_COUNT * density
        while i < starcount
          color = choose starcolors
          x = frand 1, W-1
          y = frand 1, H-16-1
          star = new Star @sector, i, x,y, color, @itg_factor(x,y), @pirate_factor(x,y)
          @stars.push star
          setPixel @starmap, Math.round(x),Math.round(y), color[0],color[1],color[2],color[3]
          ++i
        c.putImageData @starmap, 0,0

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
          if player.fuel() >= @closest_star.dist
            player.burn_fuel(@closest_star.dist)
            gbox.clearGroup 'planetmap'
            @closest_star.generate_planets()
            window.planetmap = new Planetmap @closest_star
            window.planetmap.skip = true
            gbox.addObject planetmap
            planetmapMode()
            return
          else
            message.set 'Insufficient fuel.', 90

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
              tile: 1
              dx: Math.round(@current_star.x)-4
              dy: Math.round(@current_star.y)-4
            gbox.blitTile c,
              tileset: 'cursors'
              tile: 0
              dx: Math.round(@cursor.x)-4
              dy: Math.round(@cursor.y)-4
            gbox.blitTile c,
              tileset: 'cursors'
              tile: 2
              dx: Math.round(@closest_star.x)-4
              dy: Math.round(@closest_star.y)-4
            circle c, '#33e5ff',
              Math.round(@current_star.x),
              Math.round(@current_star.y),
              player.fuel()/LY_SCALE

          for m in player.missions
            if m.location
              gbox.blitTile c,
                tileset: 'cursors'
                tile: 3
                dx: Math.round(m.location.star.x)-4
                dy: Math.round(m.location.star.y)-4

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

          for m in player.missions
            if m.location and m.location.star is @star
              pos=@positions[m.location.pnum][0]
              gbox.blitTile c,
                tileset: 'cursors'
                tile: 6
                dx: Math.round(pos.x+pos.r)-4
                dy: Math.round(pos.y)-4
        
          pos=@positions[@cursor.x][@cursor.y]
          gbox.blitTile c,
            tileset: 'cursors'
            tile: 5
            dx: Math.round(pos.x+pos.r)-4
            dy: Math.round(pos.y)-4

          if current_planet and current_planet.star is @star
            pos=current_planet.cursorpos
            gbox.blitTile c,
              tileset: 'cursors'
              tile: 4
              dx: Math.round(pos.x+pos.r)-4
              dy: Math.round(pos.y)-4


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
        @parts.push rand 0, 15
        @parts.push rand 0, 15
        if rand(0,1)
          @parts.push @parts[1]
        @role = role
        @fugitive = fugitive
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
    ACCEPT_MESSAGES = [
      'You won\'t regret it.'
      'Okay!'
      'Excellent!'
      'Wise choice.'
    ]
    ABANDON_MESSAGES = [
      'I thought we had a deal!'
      'Oh well, your loss.'
      'Why the sudden change of heart?'
      'Can\'t make up your mind, can you?'
    ]
    SUCCESS_MESSAGES = [
      'Pleasure doing business with you.'
      'Thank you!'
      'Thank you so much!'
      'Keep up the good work.'
    ]
    FAILURE_MESSAGES = [
      'What a waste of time!'
      'Worthless! You will not be paid.'
      'Ugh. Goodbye.'
    ]
    class Mission extends MenuItem
      constructor: (@person) ->
        @accepted = false
      success: ->
        idx = player.missions.indexOf @
        player.missions.splice(idx,1)
        message.set choose(SUCCESS_MESSAGES),240,@person
        if @price
          player.funds += @price
      failure: ->
        idx = player.missions.indexOf @
        player.missions.splice(idx,1)
        message.set choose(FAILURE_MESSAGES),240,@person
      onaccept: ->
        message.set choose(ACCEPT_MESSAGES),240,@person
      onabandon: ->
        message.set choose(ABANDON_MESSAGES),240,@person
      a: ->
        dq = @doesnt_qualify()
        if dq
          message.set dq, 240, @person
          return false

        @accepted = !@accepted
        if @accepted
          player.missions.push(@)
          @onaccept()
        else
          idx = player.missions.indexOf @
          player.missions.splice(idx,1)
          @onabandon()
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

    NO_CABINS_MESSAGES = [
      'That\'s a bit too cozy for my taste.'
      'It looks like you\'re full.'
      'You\'ll need to make room for me.'
    ]
    class CabinDweller extends Mission
      constructor: (@person, @star) ->
      success: ->
        super()
        idx = player.cabins.indexOf @person
        player.cabins.splice(idx,1)
      a: ->
        if super()
          if @accepted
            player.cabins.push(@person)
          else
            idx = player.cabins.indexOf @person
            player.cabins.splice(idx,1)
      doesnt_qualify: ->
        return false if @accepted

        if player.cabins.length >= player.available_cabins
          choose NO_CABINS_MESSAGES
        else
          false

    FUGITIVE_TAXI_BONUS = 1.25
    class TaxiMission extends CabinDweller
      type:'taxi'
      constructor: (@person) ->
        super(@person)
        @price = RESOURCES.fuel.mean_price * 1.25
        if @person.fugitive
          @price *= FUGITIVE_TAXI_BONUS
          @loc_name = 'Pirate st.'
          station = (choose starmap.known_pirate_stations)
        else
          @loc_name = 'ITG st.'
          station = (choose starmap.known_itg_stations)

        @star = station.star
        @price *= starmap.current_star.distance_to @star
        @price = Math.round(@price*100)/100
        @location =
          star: @star
          pnum: station.planet
      text: ->
        super() + 'Taxi-' + @loc_name + '-$'+@price
    class CrewMission extends CabinDweller
      type:'crew'
      text: ->
        super() + 'Crew'

    class ResourceExchanger extends MenuItem
      constructor: (@name, @station) ->
        @resource = RESOURCES[@name]
        @price = @station.prices[@name]
      a: ->
        return if not @station.cargo[@name] or @station.cargo[@name].length <= 0
        if player.funds < @price
          message.set 'Insufficient funds.',120
          return
        player.funds -= @price
        if not player.cargo[@name]
          player.cargo[@name] = []
        player.cargo[@name].push @station.cargo[@name].pop()
      b: ->
        return if not player.cargo[@name] or player.cargo[@name].length <= 0
        player.funds += @price
        if not @station.cargo[@name]
          @station.cargo[@name] = []
        @station.cargo[@name].push player.cargo[@name].pop()

      text: ->
        lamt = ramt = 0
        if player.cargo[@name]
          lamt = player.cargo[@name].length
        if @station.cargo[@name]
          ramt = @station.cargo[@name].length
        "#{@name}[#{lamt}] <-$#{@price}-> [#{ramt}]"

    DOCKING_DURATION = 80
    class Station
      new_missions: ->
        max_count = PLANET_CLASSES[@planet.ptype].max_mission_count
        activity = (@planet.star.itg+@planet.star.pirate)
        mission_count = Math.round(Math.min(max_count,frand(0,1)*activity*max_count))
        @missions = []
        i=0
        while i < mission_count
          person = new Person 'passenger', frand(0,1)<STATIONS[@name].fugitive_rate
          mission = undefined
          switch rand(0,0)
            when 0
              mission = new TaxiMission person
            else
              mission = new CrewMission person

          @missions.push mission
          ++i
        @cargo = {}
        max_resource_count = ((Math.PI * @planet.radius*@planet.radius) / 50) * @planet.wealth
        for own name,res of RESOURCES
          @cargo[name] = []
          resource_wealth = 0
          count = 0
          if res.natural
            resource_wealth = res[@planet.ptype+'_prob']
            count = 2*Math.round(frand(0, resource_wealth * max_resource_count))
          else
            resource_wealth = frand 0,1
            count = 50*frand(0,(@planet.star.itg+@planet.star.pirate))
          c=0
          while c < count
            @cargo[name].push new CargoItem @planet.pid
            ++c

      group: 'stations'
      constructor: (@planet, @name, @x,@y) ->
        @num = STATIONS[@name].num
        @frame_length = STATIONS[@name].frame_length
        @next_frame = @frame_length
        @frame = @num*4
        @tileset = 'stations_tiles'
        @ang = 0
        @docking_count = 0
        @cargo = {}

        @prices = {}
        for own n,p of @planet.prices
          @prices[n] = Math.round(gaus(p, (RESOURCES[n].price_stdv/2))*100)/100
      
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


    class Equipment extends MenuItem
      constructor: (@eq) ->
      a: ->
        if @eq.price
          if player.funds < @eq.price()
            message.set 'Insufficient funds.',120
            return
          @eq.apply()
          return

        lvl = player.equipment[@eq.name]
        if lvl >= 2
          return
        if player.funds < @eq.levels[lvl+1].price()
          message.set 'Insufficient funds.',120
          return
        player.funds -= @eq.levels[lvl+1].price()
        player[@eq.attr] = @eq.levels[lvl+1].val
        ++player.equipment[@eq.name]

      text: ->
        if @eq.price
          return @eq.name + ' $' + @eq.price()
        lvl = player.equipment[@eq.name]
        lvl_vis = lvl+2
        if lvl_vis >= 4
          return @eq.name + ' v3.0 - MAX'
        @eq.name + ' v' + (lvl_vis) + '.0 $'+@eq.levels[lvl+1].price()

    STATION_SUB_SCREENS = [
        name:'Cargo'
        bg:'starmap_gui'
        extra_blit: (c) ->
          gbox.blitText gbox.getBufferContext(),
            font: 'small'
            text: 'FUNDS: $' + Math.round(player.funds*100)/100
            dx:2
            dy:16
            dw:W
            dh:16
            halign: gbox.ALIGN_LEFT
            valign: gbox.ALIGN_TOP
      ,
        name:'Missions'
        bg:'starmap_gui'
      ,
        name:'Hangar'
        bg:'starmap_gui'
        extra_blit: (c) ->
          gbox.blitText gbox.getBufferContext(),
            font: 'small'
            text: 'FUNDS: $' + Math.round(player.funds*100)/100
            dx:2
            dy:16
            dw:W
            dh:16
            halign: gbox.ALIGN_LEFT
            valign: gbox.ALIGN_TOP

    ]
    ITG_INSPECT_PROB = 0.5
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
              for own name,r of RESOURCES
                @sub_items[i].push new ResourceExchanger name, @station
            when 'Missions'
              @sub_items[i] = @station.missions
            when 'Hangar'
              for eq in EQUIPMENT
                @sub_items[i].push new Equipment eq
          ++i
        tmp = player.missions.slice(0)
        for m in tmp
          switch m.type
            when 'taxi'
              if @station.planet.num is m.location.pnum and @station.planet.star is m.location.star
                m.success()

        if @station.name is 'itg' and (ITG_INSPECT_PROB*player.itg_inspect_mod>frand(0,1))
          if player.cargo.narcotics and player.cargo.narcotics.length > 0
            player.cargo.narcotics = []
            message.add 'Illegal narcotics were found...'
            message.add '...they have been confiscated.'



      c: ->
        gbox.trashObject @
        player.vx = 0
        player.vy = -0.5
        flightMode()

      first: ->
        if @skip
          @skip = false
          return
        
        if gbox.keyIsHit 'left'
          @sub_screen -= 1
        else if gbox.keyIsHit 'right'
          @sub_screen += 1

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

        extra = STATION_SUB_SCREENS[@sub_screen].extra_blit
        if extra
          extra c
        
        left = 2
        i=0
        for s in STATION_SUB_SCREENS
          n=s.name
          alpha = 0.5
          if @sub_screen is i
            alpha = 1
          w=(n.length+1)*8
          gbox.blitText gbox.getBufferContext(),
            font: 'small'
            text: n
            dx:left
            dy:H-12
            dw:w
            dh:16
            halign: gbox.ALIGN_LEFT
            valign: gbox.ALIGN_TOP
            alpha:alpha
          left += w
          ++i

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
        natural:true
        tons_per_unit:1
        gas_giant_prob: 0.1
        rocky_prob: 0.5
        moon_prob: 0.75
        mean_price: 20
        price_stdv: 2
        min_dist: 0.5
        max_dist: 3
      'lifeforms':
        num:1
        natural:true
        tons_per_unit:0.05
        gas_giant_prob: 0.05
        rocky_prob: 0.2
        moon_prob: 0.1
        mean_price: 30
        price_stdv: 4
        min_dist: 0
        max_dist: 1
      'fuel':
        num:2
        natural:true
        tons_per_unit:0.25
        gas_giant_prob: 0.25
        rocky_prob: 0.1
        moon_prob: 0.1
        mean_price: 5
        price_stdv: 0.5
        min_dist: 0
        max_dist: 1.25
      'minerals':
        num:3
        natural:true
        tons_per_unit:0.5
        gas_giant_prob: 0.05
        rocky_prob: 0.5
        moon_prob: 0.2
        mean_price: 5
        price_stdv: 1
        min_dist: 0
        max_dist: 1
      'narcotics':
        num:4
        natural:false
        tons_per_unit:0.01
        gas_giant_prob: 0
        rocky_prob: 0
        moon_prob: 0
        mean_price: 50
        price_stdv: 9
        pirate_mod_min: 0.66
        pirate_mod_max: 0.9
        min_dist: 4
        max_dist: 5

    class CargoItem
      constructor: (@origin) ->
    
    class Resource
      group: 'resources'
      constructor: (name, x,y, vx,vy, planet) ->
        @planet = planet
        @num = RESOURCES[name].num
        @name = name
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

        if gbox.collides player,@
          if !player.cargo[@name]
            player.cargo[@name] = []
          player.cargo[@name].push new CargoItem current_planet.pid
          message.set '+1 ' + @name, 60
          @die()

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
        'radar'
        'message'
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
        date = rand 3500000,4000000
        player = new Player
        starmap = new Starmap 5,34,0.6
        starmap.current_star = starmap.known_itg_stations[0].star
        starmap.cursor =
          x: starmap.current_star.x
          y: starmap.current_star.y
        starmap.current_star.generate_planets()
        current_planet = choose starmap.current_star.planets
        window.planetmap = new Planetmap starmap.current_star
        gbox.addObject message
        gbox.addObject starmap
        cam = addCamera()
        
        gbox.addObject
          id: 'bg_id'
          group: 'background'
          color: 'rgb(0,0,0)'
          tick:0
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
    body = document.getElementsByTagName('body')[0]
    body.setAttribute('class','instructions-visible')
