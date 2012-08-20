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
      min_count: 10
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
      min_count: 0
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
      min_count: 20
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
      min_count: 0
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
      min_count: 0

class CargoItem
  constructor: (@origin) ->

class Resource extends CargoItem
  group: 'resources'
  constructor: (@name, @x,@y, @vx,@vy, @planet) ->
    @num = RESOURCES[name].num
    @next_frame = @frame_length
    @frame = rand @num*8, @num*8 + 8
    @tileset = 'resources_tiles'
    @w = 3
    @h = 3
    @tick = 0
    @xoff = x
    @yoff = y
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
      @vx *= 0.99
      @vy *= 0.99

    if gbox.collides player,@
      sounds.blip.play()
      if !player.cargo[@name]
        player.cargo[@name] = []
      player.cargo[@name].push @
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

class ResourceExchanger extends MenuItem
  constructor: (@name, @station) ->
    super @name
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
    sounds.blip.play()
  b: ->
    return if not player.cargo[@name] or player.cargo[@name].length <= 0
    player.funds += @price
    if not @station.cargo[@name]
      @station.cargo[@name] = []
    @station.cargo[@name].push player.cargo[@name].pop()
    sounds.blip.play()
  
  render: (x, y, alpha) ->
    c = gbox.getBufferContext()
    return if not c

    lamt = ramt = 0
    if player.cargo[@name]
      lamt = player.cargo[@name].length
    if @station.cargo[@name]
      ramt = @station.cargo[@name].length

    gbox.blitText c,
      font: 'small'
      text: @name
      dx:x + 16
      dy:y
      alpha: alpha
      dw:W
      dh:LINE_HEIGHT
      halign: gbox.ALIGN_LEFT
      valign: gbox.ALIGN_TOP

    gbox.blitText c,
      font: 'small'
      text: "[#{lamt}]"
      dx:x + 128
      dy:y
      alpha: alpha
      dw:W - 128
      dh:LINE_HEIGHT
      halign: gbox.ALIGN_LEFT
      valign: gbox.ALIGN_TOP

    gbox.blitText c,
      font: 'small'
      text: "<-$#{@price}->"
      dx:x + 128
      dy:y
      alpha: alpha
      dw:W - 128
      dh:LINE_HEIGHT
      halign: gbox.ALIGN_CENTER
      valign: gbox.ALIGN_TOP

    gbox.blitText c,
      font: 'small'
      text: "[#{ramt}]"
      dx:x + 128
      dy:y
      alpha: alpha
      dw:W - 128
      dh:LINE_HEIGHT
      halign: gbox.ALIGN_RIGHT
      valign: gbox.ALIGN_TOP
