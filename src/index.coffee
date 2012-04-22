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
    canvas width:320, height:320, style:'display:none', id:'starmap'

  coffeescript ->
    BASE_SEED = 'WEEEEE'
    Math.seedrandom BASE_SEED

    window.clamp = (num, min, max) ->
      Math.min(Math.max(num, min), max)

    frand = (min, max) -> min + Math.random()*(max-min)
    rand = (min, max) -> Math.round(frand(min, max))
    choose = (array) -> array[rand(0,array.length-1)]

    rgba = (r,g,b,a) -> "rgba(#{r},#{g},#{b},#{a}"
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


    starcolors_el = new Image()
    starcolors_el.onload = ->

      maingame = undefined
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
          title: 'TINYVERSE (working title)'
          width: W
          height: H
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
          firstletter: 'A'
          tileh: 8
          tilew: 8
          tilerow: 13
          gapx: 0
          gapy: 0

        gbox.loadAll main
      
      TURN_SPEED = 0.1
      ACC = 0.01
      DEC = 0.01
      
      paused = false
      menuVisible = false
      player = undefined
      cam = {
        x:0
        y:0
      }
      
      togglePause = ->
        paused = !paused
      

      class Menu
        constructor: ->
          @selected = 0
          @items = []

        up: ->
          @selected = (@selected - 1) % @items.length
          if @selected < 0
            @selected = @items.length - 1
          while !@items[@selected].enabled
            @selected = (@selected - 1) % @items.length
        down: ->
          @selected = (@selected + 1) % @items.length
          while !@items[@selected].enabled
            @selected = (@selected + 1) % @items.length
        select: ->
          console.log @items[@selected].name
          @items[@selected].select()

      starmapMenu = new Menu
      starmapMenu.items = [
          name: 'RETURN TO BRIDGE'
          enabled: true
          select: ->
            togglePause()
            window.currentMenu = rootMenu
            menuVisible = false
            groups = [
              'planet'
              'player'
              'baddies'
              'drones'
              'friend_shots'
              'foe_shots'
            ]
            for g in groups
              gbox.stopGroup g
              gbox.toggleGroup g
            gbox.stopGroup 'starmap'

      ]


      rootMenu = new Menu
      rootMenu.items = [
          name: 'DROP PROBE'
          enabled: true
          select: ->
            menuVisible = false
            togglePause()
        ,
          name: 'STARMAP'
          enabled: true
          select: ->
            menuVisible = false
            groups = [
              'planet'
              'player'
              'baddies'
              'drones'
              'friend_shots'
              'foe_shots'
            ]
            for g in groups
              gbox.stopGroup g
            gbox.stopGroup 'starmap'
            gbox.toggleGroup 'starmap'
            window.currentMenu = starmapMenu
            togglePause()
        ,
          name: 'FLEE'
          enabled: true
          select: ->
            menuVisible = false
            togglePause()
      ]

      window.currentMenu = rootMenu

      addPauseScreen = ->
        gbox.addObject
          x:0
          y:0
          vx:0
          vy:0
          group: 'pause'
          first: ->
            if gbox.keyIsHit 'c'
              menuVisible = !menuVisible
              togglePause()

            return if not menuVisible

            if gbox.keyIsHit 'a'
              currentMenu.select()
              return

            if gbox.keyIsHit 'up'
              currentMenu.up()
            else if gbox.keyIsHit 'down'
              currentMenu.down()

          blit: ->
            return if not menuVisible

            gbox.blitFade gbox.getBufferContext(),
              alpha:0.5

            height = 9 * currentMenu.items.length
            top = H/2 - height/2
            top -= 9
            num = 0
            for item in currentMenu.items
              top += 9
              
              if item.enabled
                if currentMenu.selected == num
                  alpha = 1
                else
                  alpha = 0.5
              else
                alpha = 0.25

              ++num
              gbox.blitText gbox.getBufferContext(),
                font: 'small'
                text: item.name
                dx:0
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
            return if paused
            @vx = (player.x+player.vx*60 - (@x+160)) * 0.05
            @vy = (player.y+player.vy*60 - (@y+160)) * 0.05
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
            @wpower = 1
            @wcost = 50
            @wspan = 80
            @thrust = 0.01
            @afterburn = 0.01
            @shields = 5
            @particle_tick=0

          first: ->
            return if paused
            going = false
            if gbox.keyIsPressed 'up'
              going = true
              @vx += @ax
              @vy += @ay
            else if gbox.keyIsPressed 'down'
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
                addParticle 'fire', @x+@w/2,@y+@h/2, @vx-@ax*40*frand(0.5,1),@vy-@ay*40*frand(0.5,1)

            if gbox.keyIsHit('a') and (@wcharge >= @wcost)
              @wcharge -= @wcost
              addShot @x+@w/2,@y+@h/2,
                @x+@w/2+(@ax/@thrust)*20000,
                @y+@h/2+(@ay/@thrust)*20000,
                @wpower,
                @wspeed, 4, 'friend_shots', @wspan,
                @vx, @vy

            if @wcharge < @wcharge_cap
              @wcharge += 1

            groupCollides @, 'foe_shots', (shot) =>
              i=0
              while i < 3
                addParticle 'fire', @x+@w/2,@y+@h/2,
                  @vx+frand(-.5,.5),@vy+frand(-.5,.5)
                ++i
              @shields -= shot.power
              shot.die()

          initialize: ->
            @init()

          blit: ->
            gbox.blitTile gbox.getBufferContext(),
              tileset: @tileset
              tile: @frame
              dx: Math.round(@x-cam.x)
              dy: Math.round(@y-cam.y)

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

          first: ->
            return if paused
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
            return if paused
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
            return if paused
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

      GRID_W = 40
      GRID_H = 40
      OFF_RADIUS = 4
      MIN_STAR_RAD = 900
      MAX_STAR_RAD = 40000
      addStarmap = (x,y, density) ->
        Math.seedrandom BASE_SEED+x+','+y

        gbox.addObject
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

          init: ->
            gbox.stopGroup 'starmap'

            # Generate stars!
            @stars = []
            # And render the starmap (just once)
            c = document.getElementById('starmap').getContext '2d'
            #@starmap = gbox.getBufferContext().createImageData W, H
            @starmap = c.createImageData W, H

            i = 0
            while i < GRID_W
              @stars[i] = []
              j = 0
              while j < GRID_H
                off_ang = Math.PI*2 * Math.random()
                off_mag = Math.random() * OFF_RADIUS
                if Math.random() < density
                  color = choose starcolors
                  xoff = Math.cos(off_ang) * off_mag
                  yoff = Math.sin(off_ang) * off_mag
                  x = i * 2*OFF_RADIUS + xoff
                  y = j * 2*OFF_RADIUS + yoff
                  x = clamp(x, 0, W)
                  y = clamp(y, 0, H)
                  @stars[i].push
                    radius: frand MIN_STAR_RAD, MAX_STAR_RAD
                    xoff: xoff
                    yoff: yoff
                    x: x
                    y: y
                    color: color
                  setPixel @starmap, Math.round(x),Math.round(y), color[0],color[1],color[2],color[3]
                ++j
              ++i
            c.putImageData @starmap, 0,0

          first: ->
            return if paused

          initialize: ->
            @init()

          blit: ->
            c = gbox.getBufferContext()
            if c
              c.putImageData @starmap, 0, 0

      addPlanetMap = (star) ->
        gbox.addObject
          group: 'starmap'
          init: ->


          first: ->

          initialize: ->
            @init()

          blit: ->
            c = gbox.getBufferContext()
            if c
              c.putImageData @map, 0, 0

      addPlanet = (radius) ->
        gbox.addObject
          group: 'planet'
          radius: radius or 50
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

            # Sunlight direction:
            @dirx = frand(-@radius,@radius)
            @diry = frand(-@radius*.1,@radius*.1)

          first: ->
            return if paused
            @ang += 0.02 #Math.random() * Math.PI*2
            #@xoff = Math.cos @ang
            @yoff = 3*Math.sin @ang

          initialize: ->
            @init()

          blit: ->
            ctx = gbox.getBufferContext()
            return if not ctx
            x = Math.round @x+@xoff-cam.x
            y = Math.round @y+@yoff-cam.y
            ctx.beginPath()
            grd = ctx.createRadialGradient x+@dirx,y+@diry, 0, x+@dirx,y+@diry, @radius*1.4
            grd.addColorStop 0, '#224455'
            grd.addColorStop 1, '#000510'
            ctx.fillStyle = grd
            ctx.arc x,y, @radius, 0, 2*Math.PI, false
            ctx.fill()
            ctx.closePath()
            ###
            gbox.blitAll gbox.getBufferContext(), gbox.getImage('planet0'),
              dx: Math.round(@x + @xoff - cam.x)
              dy: Math.round(@y + @yoff - cam.y)
            ###

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
            return if paused
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

      RESOURCES = {
        'SCRAP METAL':
          num:0
          tons_per_unit:1
        'LIFEFORMS':
          num:1
          tons_per_unit:0.05
        'FUEL':
          num:2
          tons_per_unit:0.25
        'MINERALS':
          num:3
          tons_per_unit:0.1
        'NARCOTICS':
          num:4
          tons_per_unit:0.01
      }

      addResource = (name, x,y, vx,vy, planet) ->
        num = RESOURCES[name].num

        gbox.addObject
          group: 'resources'
          num:num
          w:0.1
          h:0.1
          vx:0
          vy:0
          frame_length: 4
          init: ->
            @next_frame = @frame_length
            @frame = rand @num*8, @num*8 + 8
            @tileset = 'resources_tiles'
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
            return if paused

            if planet
              @x = planet.x + x
              @y = planet.y + y
            else
              @x += @vx
              @y += @vy
              @vx *= 0.005
              @vy *= 0.005

            --@next_frame

            if @next_frame < 0
              @frame = @num*8 + ((@frame%8) + 1)%8
              @next_frame = @frame_length

          initialize: ->
            @init()

          blit: ->
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
          'planet'
          'resources'
          'particles'
          'player'
          'friend_shots'
          'baddies'
          'drones'
          'foe_shots'
          'pause'
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
          addPauseScreen()
          addStarmap(5,34,0.2)

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
        gbox.stopGroup 'starmap'
      window.addEventListener 'load', loadResources, false

    starcolors_el.src = 'star_color_distr.png'

