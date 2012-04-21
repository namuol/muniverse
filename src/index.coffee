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

      gbox.addImage 'drones', 'drones.png'
      gbox.addTiles
        id: 'drones_tiles'
        image: 'drones'
        tileh: 5
        tilew: 5
        tilerow: 3
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
    
    TURN_SPEED = 0.05
    ACC = 0.005
    DEC = 0.004

    player = undefined

    addPlayer = ->
      gbox.addObject
        id: 'player_id'
        group: 'player'
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

        first: ->
          going = false
          if gbox.keyIsPressed 'up'
            going = true
            @vx += Math.cos(@ang) * ACC
            @vy += Math.sin(@ang) * ACC

          if gbox.keyIsPressed 'right'
            @ang += TURN_SPEED
          else if gbox.keyIsPressed 'left'
            @ang -= TURN_SPEED
          if @ang < 0
            @ang = Math.PI*2 - @ang
          @x += @vx
          @y += @vy

          @vx *= 1-DEC
          @vy *= 1-DEC
          @frame = Math.round(((@ang+(Math.PI/2)) / (Math.PI*2)) * 16) % 16
          @frame += 16 if going

        initialize: ->
          @init()

        blit: ->
          gbox.blitTile gbox.getBufferContext(),
            tileset: @tileset
            tile: @frame
            dx: Math.round @x
            dy: Math.round @y
    addDrone = ->
      gbox.addObject
        group: 'drones'
        init: ->
          @frame = 0
          @tileset = 'drones_tiles'
          @w = 5
          @h = 5
          @x = gbox.getScreenW()/2 - @w/2 - 100
          @y = gbox.getScreenH()/2 - @h/2 - 100
          @vx = 0
          @vy = 0
          @ang = Math.random() * Math.PI*2
          @xoff = Math.cos @ang
          @yoff = Math.sin @ang
          @dist = 20

        first: ->
          #if Math.random() < 0.02
          @ang += 0.02 #Math.random() * Math.PI*2
          @xoff = Math.cos @ang
          @yoff = Math.sin @ang
          #console.log @yoff

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
            dx: Math.round @x
            dy: Math.round @y


    main = ->
      gbox.setGroups ['background', 'game', 'drones', 'player']
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
        addDrone()

        gbox.addObject
          id: 'bg_id'
          group: 'background'
          color: 'rgb(0,0,0)'
          blit: ->
            gbox.blitFade gbox.getBufferContext(),
              color:'#002233'
              alpha:1
      gbox.go()

    window.addEventListener 'load', loadResources, false
