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
    'hud'
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
      player.vx *= 0.95
      player.vy *= 0.95
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
    player.y = @station.y - (player.h+2)
    player.x = @station.x + @station.w/2
    player.vy = -0.199999999
    player.setAng(1.5*Math.PI)
    flightMode()

  first: ->
    if @skip
      @skip = false
      return
    
    if gbox.keyIsHit 'left'
      sounds.blip.play()
      @sub_screen -= 1
    else if gbox.keyIsHit 'right'
      sounds.blip.play()
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
