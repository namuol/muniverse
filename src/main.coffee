BASE_SEED = 'WEEEEE'
Math.seedrandom BASE_SEED

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

  #gbox.addAudio 'blip', ['blip0.0.wav'], {channel:'sfx'}
  #gbox.addAudio 'select', ['select0.0.wav'], {channel:'sfx'}
  #gbox.addAudio 'cancel', ['cancel0.0.wav'], {channel:'sfx'}
  #gbox.setAudioChannels
  #  sfx:
  #    volume: 1.0
  #  music:
  #    volume: 0.75

  gbox.loadAll main

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
    initialize: ->
      @max_dist = 100
      @max_dist2 = @max_dist*@max_dist
      @x = 100
      @y = 100
      @vx = 0
      @vy = 0
      @w = W
      @h = H
      @shake = 0

    first: ->
      @vx = (player.x+player.vx*60 - (@x+160)) * 0.05
      @vy = (player.y+player.vy*60 - (@y+160)) * 0.05
      @x += @vx
      @y += @vy

      if @shake > 0.5
        @x += @shake * rand(-1,1)
        @y += @shake * rand(-1,1)
        @shake *= 0.95

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

maingame = undefined

main = ->
  gbox.setGroups [
    'background'
    'game'
    'starmap'
    'planetmap'
    'menustack'
    'planet'
    'stations'
    'resources'
    'particles'
    'player'
    'friend_shots'
    'baddies'
    'drones'
    'foe_shots'
    'hud'
    'radar'
    'message'
    'dialog'
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
    date = startDate()
    console.log formatDate date
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
    gbox.addObject new MissionTicker
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

        x = -cam.x / 2
        y = -cam.y / 2

        gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
          dx:Math.round x % W
          dy:Math.round y % H
        gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
          dx:Math.round x % W - W
          dy:Math.round y % H - H
        gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
          dx:Math.round x % W
          dy:Math.round y % H - H
        gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
          dx:Math.round x % W + W
          dy:Math.round y % H - H
        gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
          dx:Math.round x % W + W
          dy:Math.round y % H
        gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
          dx:Math.round x % W
          dy:Math.round y % H + H
        gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
          dx:Math.round x % W - W
          dy:Math.round y % H + H
        gbox.blitAll gbox.getBufferContext(), gbox.getImage('bg'),
          dx:Math.round x % W - W
          dy:Math.round y % H

  gbox.go()
window.addEventListener 'load', loadResources, false
