DIALOG_MAX_WIDTH = 40
LINE_HEIGHT = 16
split_to_lines = (str, max_width) ->
  lines = []
  words = str.split(' ')
  current_line = ''
  for word in words
    if current_line.length + word.length > max_width
      lines.push current_line
      current_line = word + ' '
    else
      current_line += word + ' '
  lines.push current_line
  return lines

testDialog = ->
  dialog = new Dialog 'This is a very long string with lots off words that should probably wrap around the screen if we were to attempt to display it with our dialog class.'
  dialog.pushItem new DialogChoice '[OKAY]'
  setDialog(dialog)

setDialog = (d) ->
  gbox.clearGroup 'dialog'

  gbox.pauseAllGroups()
  gbox.addObject d
  gbox.unpauseGroup 'dialog'

closeDialog = ->
  gbox.clearGroup 'dialog'
  gbox.unpauseAllGroups()

class Message
  group: 'message'
  constructor: ->
    @visible = false
    @msgs = []
  add: (str, lifespan=240, person, effect, effect_params) ->
    @msgs.push
      str: str
      lifespan: lifespan
      person: person
      effect: effect
      effect_params: effect_params
    @visible = true

  set: (str, lifespan=240, person, effect, effect_params) ->
    @tick = 0
    @msgs = []
    @add str, lifespan, person, effect, effect_params

  first: ->
    return if not @visible
    ++@tick
    if @msgs[0].lifespan != undefined
      if --@msgs[0].lifespan < 0
        @msgs.splice 0,1
        @tick = 0
        if @msgs.length is 0
          @visible = false

  _fx_y_sin: (params) ->
    if not params
      params =
        dist: 4
        speed: 0.1
    yoff = params.dist*Math.sin @tick*params.speed
    fx =
      tx: 18
      ty: H-28 + yoff
      ta: 1
      px: 1
      py: H-33 + yoff
      pa: 1
    return fx

  _fx_pop_up: ->
    if @tick == 1
      @tvy = -5
      @ty = H
      @pvy = -5
      @py = H
      @tabove = false
      @pabove = false

    @tvy += 0.3
    @ty += @tvy
    if @ty < H-28
      @tabove = true

    if @tabove
      if @ty >= H-28
        @tvy *= -0.8
        @ty = H-28

    if @tick >= 10
      @pvy += 0.3
      @py += @pvy
      if @py < H-33
        @pabove = true
      if @pabove
        if @py >= H-33
          @pvy *= -0.8
          @py = H-33

    fx =
      tx: 18
      ty: @ty
      ta: 1
      px: 1
      py: @py
      pa: 1
    return fx

  blit: ->
    return if not @visible
    fx =
      tx: 18    # text X
      ty: H-28  # text Y
      ta: 1     # text alpha
      px: 1     # person X
      py: H-33  # person Y
      pa: 1     # person alpha

    if @msgs[0].effect
      fx = @['_fx_'+@msgs[0].effect](@msgs[0].effect_params)

    c = gbox.getBufferContext()
    return if not c
    c.fillStyle = 'rgba(0,0,0, 0.5)'
    c.fillRect 0,H-34, W,18
    if @msgs[0].person
      @msgs[0].person.render_face(fx.px,fx.py, fx.pa, true)
    gbox.blitText c,
      font: 'small'
      text: @msgs[0].str
      dx:Math.round(fx.tx)
      dy:Math.round(fx.ty)
      dw:W
      dh:16
      halign: gbox.ALIGN_LEFT
      valign: gbox.ALIGN_TOP
      alpha: fx.ta

message = new Message

# NOTE: Menu items need to be extended and have first/blit functions to be used...
class Menu
  bg: 'starmap_gui'
  _held: (key) ->
    gbox.keyIsHit(key) or (gbox.keyIsHeldForAtLeast(key,15) and gbox.keyHeldTime(key)%5==0)
  constructor: () ->
    @selected = 0
    @items = []
    @bg_was_rendered = false

  pushItem: (item) ->
    @items.push item
    item.parent = @

  prev: ->
    return if @items.length is 0
    sounds.blip.play() if @items.length > 1
    @selected = (@selected - 1) % @items.length
    if @selected < 0
      @selected = @items.length - 1
    while @items[@selected].disabled
      @selected = (@selected - 1) % @items.length
  next: ->
    return if @items.length is 0
    sounds.blip.play() if @items.length > 1
    @selected = (@selected + 1) % @items.length
    while @items[@selected].disabled
      @selected = (@selected + 1) % @items.length
  a: ->
    if @items[@selected]
      @items[@selected].a()
  b: ->
    if @items[@selected]
      @items[@selected].b()
  render_bg: (c) ->
    if @bg and not @bg_was_rendered
      @bg_was_rendered = true
      gbox.blitAll c, gbox.getImage(@bg),
        dx:0
        dy:0

  render: (x,y, a) ->

  update: ->
    @bg_was_rendered = false
    if @_held 'a'
      @a()
    if @_held 'b'
      @b()

class VMenu extends Menu
  update: ->
    super()
    if @_held 'up'
      @prev()
    else if @_held 'down'
      @next()

  render: (x,yoff) ->
    c = gbox.getBufferContext()
    return if not c
    @render_bg(c)
    return if @items.length is 0

    height = 0
    for item in @items
      height += item.h + 1
    top = H/2 - height/2 + yoff
    top -= @items[0].h
    num = 0
    for item in @items
      top += item.h + 1
       
      if !item.disabled
        if @selected == num
          alpha = 1
        else
          alpha = 0.5
      else
        alpha = 0.25
      ++num
      item.render x, top, alpha

class HMenu extends Menu
  update: ->
    super()
    if @_held 'left'
      @prev()
    else if @_held 'right'
      @next()

  render: (xoff,y) ->
    c = gbox.getBufferContext()
    return if not c
    @render_bg(c)

    width = 0
    for item in @items
      width += 8 * item.text().length + 8
    left = W/2 - width/2 + xoff
    num = 0
    for item in @items
      if !item.disabled
        if @selected == num
          alpha = 1
        else
          alpha = 0.5
      else
        alpha = 0.25
      ++num

      item.render left, y, alpha
      left += 8*item.text().length + 8

class MultiMenu extends HMenu
  constructor: () ->
    super()
    @skip = false
    @sub_screen = 0
    @sub_menus = []
    i=0

  pushSubMenu: (menu) ->
    menu.parent = @
    @sub_menus.push menu

  update: ->
    return if @sub_menus.length is 0

    @current_sub_menu = @sub_menus[@selected]
    @current_sub_menu.update()
    super()

  render: (x,y, a) ->
    c = gbox.getBufferContext()
    return if not c
    @render_bg(c)
    return if not @current_sub_menu
    @current_sub_menu.render(x,y, a)
    super(x,y, a)

menustack = undefined
class MenuStack extends Menu
  group: 'menustack'
  constructor: ->
    super()
    @stack = []

  pushMenu: (menu) ->
    @stack.push menu

  update: ->
    super()

    if @stack.length > 0
      @stack[@stack.length-1].update()

    if gbox.keyIsHit('c') and @stack.length > 0
      @stack.pop()

  first: ->
    @update()

  render: (x,y, a) ->
    return if @stack.length is 0

    @stack[@stack.length-1].render(x,y, a)
  
  blit: ->
    @render(0,4,1)

class MenuItem
  constructor: (@name) ->
    @h = 16
  text: -> @name
  a: -> #sounds.select.play()
  b: -> #sounds.cancel.play()
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

class Dialog extends HMenu
  group: 'dialog'
  constructor: (@msg) ->
    super()
  first: ->
    @update()
    if gbox.keyIsHit 'c'
      closeDialog()

  blit: ->
    @render()

  pre_render: (c) ->
    # Override me
    c.fillStyle = 'rgba(0,0,0, 0.85)'
    c.fillRect 0,0, W,H

  render: () ->
    c = gbox.getBufferContext()
    return if not c
    @render_bg(c)

    @pre_render(c)

    n=0 # Row number
    lines = split_to_lines @msg, DIALOG_MAX_WIDTH
    height = lines.length*LINE_HEIGHT
    top = (H - height) / 2
    for line in lines
      gbox.blitText c,
        font: 'small'
        text: line
        dx:0
        dy:top + n*LINE_HEIGHT
        dw:W
        dh:LINE_HEIGHT
        halign: gbox.ALIGN_LEFT
        valign: gbox.ALIGN_TOP
      ++n
    super(0,H-12)

    @post_render(c)

  post_render: (c) ->
    # Override me

class DialogChoice extends MenuItem
  a: ->
    super()
    closeDialog()
  b: ->
  c: ->
    closeDialog()

