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


