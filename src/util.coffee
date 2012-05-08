clamp = (num, min, max) ->
  Math.min(Math.max(num, min), max)

grand = (random) ->
  funcs =
    frand: (min, max) ->
      min + random()*(max-min)
    rand: (min, max) ->
      Math.round(min + random()*(max-min))
    gaus: (mean, stdv) ->
      # approximates Box-Muller transform:
      rnd = (random()*2-1)+(random()*2-1)+(random()*2-1)
      return rnd*stdv + mean
    choose: (array) -> array[@rand(0,array.length-1)]

  for own n,f of funcs
    random[n] = f

  return random

frand = (min, max) -> min + Math.random()*(max-min)
rand = (min, max) -> Math.round(frand(min, max))
gaus = (mean, stdv) ->
  # approximates Box-Muller transform:
  rnd = (Math.random()*2-1)+(Math.random()*2-1)+(Math.random()*2-1)
  return rnd*stdv + mean

dist = (a,b) ->
  dx=a.x-b.x
  dy=a.y-b.y
  Math.sqrt(dx*dx+dy*dy)

choose = (array) -> array[rand(0,array.length-1)]

lerp = (a, b, x) ->
  return Math.round( (a*(1-x)+b*(1+x))/2 )

RGBColor = (color) ->
  rgb = undefined
  colorObj = undefined
  color = color.replace("0x", "")
  color = color.replace("#", "")
  rgb = parseInt(color, 16)
  colorObj = {}
  colorObj.r = (rgb & (255 << 16)) >> 16
  colorObj.g = (rgb & (255 << 8)) >> 8
  colorObj.b = (rgb & 255)
  colorObj

rgba = (c) -> "rgba(#{c[0]},#{c[1]},#{c[2]},#{c[3]})"
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

circle = (c, strokeStyle, x,y, radius) ->
  c.strokeStyle = strokeStyle
  c.beginPath()
  c.arc(
    Math.round(x),
    Math.round(y),
    radius,
    0, 2*Math.PI, false
  )
  c.stroke()

groupCollides = (obj, group, callback) ->
  for own id,gobj of gbox.getGroup group
    if gbox.collides obj, gobj
      if callback
        callback(gobj)
      else
        return true

