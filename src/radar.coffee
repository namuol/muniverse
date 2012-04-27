DEFAULT_RADAR_RENDER = (x,y, alpha) ->
  x = clamp(x, 4, cam.w-4)+0.5
  y = clamp(y, 4, cam.h-4)+0.5
  c = gbox.getBufferContext()
  if c
    circle c, 'yellow', Math.round(x),Math.round(y), 1

RADAR_ITEMS =
  'planet':
    min_dist: -> -1
    render: (x,y, alpha) ->
      r = 4/current_planet.radius
      current_planet.render r,
        Math.round(clamp(x, 4, W-4)),
        Math.round(clamp(y, 4, H-4)),
        current_planet.dirx,current_planet.diry
  'stations':
    min_dist: -> -1
class Radar
  group: 'radar'
  constructor: ->
  blit: ->
    c =
      x:(player.x-cam.x)
      y:(player.y-cam.y)

    for own group,item of RADAR_ITEMS
      for own id,obj of gbox.getGroup group
        dx = (obj.x-cam.x)-c.x
        dy = (obj.y-cam.y)-c.y
        d = Math.sqrt dx*dx+dy*dy
        if item.min_dist() < 0 or d < item.min_dist()
          _x=c.x+dx
          _y=c.y+dy

          x = clamp c.x+dx, 0,cam.w
          y = clamp c.y+dy, 0,cam.h
          continue if _x==x and _y==y
          if item.render
            item.render x,y, 1
          else
            DEFAULT_RADAR_RENDER x,y, 1


