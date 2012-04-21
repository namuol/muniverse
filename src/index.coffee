html ->
  head ->
    script type:'text/javascript', src:'akihabara/gbox.js'
    script type:'text/javascript', src:'akihabara/iphopad.js'
    script type:'text/javascript', src:'akihabara/trigo.js'
    script type:'text/javascript', src:'akihabara/toys.js'
    script type:'text/javascript', src:'akihabara/help.js'
    script type:'text/javascript', src:'akihabara/tool.js'
    script type:'text/javascript', src:'akihabara/gamecycle.js'
    link rel:'stylesheet', href:'style.css'
    
    meta
      name:'viewport'
      content:'width:device-width; initial-scale:1.0; maximum-scale:1.0; user-scalable:0;'
  body ->
    div class:'directions', ->
      text ''
  coffeescript ->
    frand = (min, max) -> min + Math.random()*(max-min)
    window.rand = (min, max) -> Math.round(frand(min, max))
    choose = (array) -> array[rand(0,array.length-1)]

    maingame = undefined

    loadResources = ->
      help.akihabaraInit
        title: 'TINY UNIVERSE (working title)'
        width: 320
        height: 320
        zoom: 2

      gbox.setFps 60

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
        tileh: 16
        tilew: 16
        tilerow: 20
        gapx: 0
        gapy: 0
      gbox.loadAll main
    
    TURN_SPEED = 0.1
    ACC = 0.01
    DEC = 0.01

    player = undefined
    cam = {
      x:0
      y:0
    }

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
          @vx = (player.x+player.vx*6 - (@x+160)) * 0.05
          @vy = (player.y+player.vy*6 - (@y+160)) * 0.05
          @x += @vx
          @y += @vy

    addPlayer = ->
      gbox.addObject
        id: 'player_id'
        group: 'player'
        x:0
        y:0
        vx:0
        vy:0
        init: ->
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
          @wcharge_cap = 100
          @wcharge = @wcharge_cap
          @wspeed = 2
          @wcost = 50
          @wspan = 80

        first: ->
          going = false
          if gbox.keyIsPressed 'up'
            going = true
            @vx += @ax
            @vy += @ay
          else
            @vx *= 1-DEC
            @vy *= 1-DEC

          if gbox.keyIsPressed 'right'
            @ang += TURN_SPEED
            @ax = Math.cos(@ang) * ACC
            @ay = Math.sin(@ang) * ACC
          else if gbox.keyIsPressed 'left'
            @ang -= TURN_SPEED
            @ax = Math.cos(@ang) * ACC
            @ay = Math.sin(@ang) * ACC

          if @ang < 0
            @ang = Math.PI*2 - @ang

          @x += @vx
          @y += @vy

          @frame = Math.round(((@ang+(Math.PI/2)) / (Math.PI*2)) * 16) % 16
          @frame += 16 if going

          if gbox.keyIsHit('a') and (@wcharge >= @wcost)
            console.log 'SHOT'
            @wcharge -= @wcost
            addShot @x+@w/2,@y+@h/2,
              @x+@w/2+(@ax/ACC)*20000,
              @y+@h/2+(@ay/ACC)*20000,
              @wspeed, 4, 'friend_shots', @wspan,
              @vx, @vy

          if @wcharge < @wcharge_cap
            @wcharge += 1

        initialize: ->
          @init()

        blit: ->
          gbox.blitTile gbox.getBufferContext(),
            tileset: @tileset
            tile: @frame
            dx: Math.round(@x-cam.x)
            dy: Math.round(@y-cam.y)

          ### DEBUG
          gbox.blitTile gbox.getBufferContext(),
            tileset: 'shots_tiles'
            tile: 3
            dx: (@x+@w/2)+@ax*20000
            dy: (@y+@h/2)+@ay*20000
          gbox.blitTile gbox.getBufferContext(),
            tileset: 'shots_tiles'
            tile: 7
            dx: @x+@w/2
            dy: @y+@h/2
          ###

    addBaddie = ->
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

        initialize: ->
          @init()

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

    addShot = (x,y, tx,ty, speed, frame, group, lifespan, vx,vy) ->
      gbox.addObject
        group: group
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
          console.log @vx + ', ' + @vy
          @lifespan = lifespan or 99999
          @tick = 0

        die: ->
          console.log 'shotdie'
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


    addPlanet = ->
      gbox.addObject
        group: 'planet'
        init: ->
          @tileset = 'drones_tiles'
          @w = 100
          @h = 100
          @x = gbox.getScreenW()/2 - @w/2
          @y = gbox.getScreenH()/2 - @h/2
          @ang = 0
          @xoff = 0
          @yoff = 0
          @dist = 3

        first: ->
          @ang += 0.02 #Math.random() * Math.PI*2
          #@xoff = Math.cos @ang
          @yoff = Math.sin @ang

        initialize: ->
          @init()

        blit: ->
          gbox.blitAll gbox.getBufferContext(), gbox.getImage('planet0'),
            dx: Math.round(@x + @xoff - cam.x)
            dy: Math.round(@y + @yoff - cam.y)


    main = ->
      gbox.setGroups [
        'background'
        'game'
        'planet'
        'player'
        'baddies'
        'drones'
        'friend_shots'
        'foe_shots'
      ]
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
        player = addPlayer()
        cam = addCamera()
        addDrone()
        addDrone()
        addPlanet()
        addBaddie()

        gbox.addObject
          id: 'bg_id'
          group: 'background'
          color: 'rgb(0,0,0)'
          blit: ->
            gbox.blitFade gbox.getBufferContext(),
              color:'#000510'
              alpha:1

            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:-cam.x % 320
              dy:-cam.y % 320

            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:-cam.x % 320 - 320
              dy:-cam.y % 320 - 320
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:-cam.x % 320
              dy:-cam.y % 320 - 320
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:-cam.x % 320 + 320
              dy:-cam.y % 320 - 320
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:-cam.x % 320 + 320
              dy:-cam.y % 320
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:-cam.x % 320 + 320
              dy:-cam.y % 320 + 320
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:-cam.x % 320
              dy:-cam.y % 320 + 320
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:-cam.x % 320 - 320
              dy:-cam.y % 320 + 320
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
              dx:-cam.x % 320 - 320
              dy:-cam.y % 320

      gbox.go()

    window.addEventListener 'load', loadResources, false
