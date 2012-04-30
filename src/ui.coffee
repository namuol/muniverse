DIALOG_MAX_WIDTH = 40
class Dialog
  group: 'dialog'
  constructor: ->
    @visible = false
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
dialog = new Dialog

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
    sounds.blip.play()
    @selected = (@selected - 1) % @items.length
    if @selected < 0
      @selected = @items.length - 1
    while @items[@selected].disabled
      @selected = (@selected - 1) % @items.length
  down: ->
    return if @items.length is 0
    sounds.blip.play()
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

