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
  dialog.items.push new DialogChoice '[OKAY]'
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

# NOTE: Menu items need to be extended and have first/blit functions to be used...
class Menu
  _held: (key) ->
    gbox.keyIsHit(key) or (gbox.keyIsHeldForAtLeast(key,15) and gbox.keyHeldTime(key)%5==0)
  constructor: ->
    @selected = 0
    @items = []

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

class VMenu extends Menu
  update: ->
    super()
    if @_held 'up'
      @prev()
    else if @_held 'down'
      @next()

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

class HMenu extends Menu
  update: ->
    super()
    if @_held 'left'
      @prev()
    else if @_held 'right'
      @next()

  render: (xoff,y) ->
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

class MenuItem
  constructor: (@name) ->
  text: -> @name
  a: -> sounds.select.play()
  b: -> sounds.cancel.play()
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

class Dialog extends HMenu
  group: 'dialog'
  constructor: (@msg) ->
    super()
  first: ->
    @update()

  pre_blit: (c) ->
    # Override me
    c.fillStyle = 'rgba(0,0,0, 0.85)'
    c.fillRect 0,0, W,H

  blit: () ->
    c = gbox.getBufferContext()
    return if not c

    @pre_blit(c)

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
    @render(0,0)

    @post_blit(c)

  post_blit: (c) ->
    # Override me

class DialogChoice extends MenuItem
  a: ->
    super()
    closeDialog()
  b: ->
  c: ->
    closeDialog()


