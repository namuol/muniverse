SECONDS = 1000
MINUTES = 60 * SECONDS
HOURS = 60 * MINUTES
DAYS = 24 * HOURS
YEARS = 356 * DAYS
startDate = ->
  y = rand 3000,4000
  (y-1970) * YEARS + rand(0,365) * DAYS

formatDate = (ms) ->
  d = new Date ms
  y = d.getUTCFullYear()
  m = d.getUTCMonth() + 1
  if m < 10
    m = '0' + m
  dt = d.getUTCDate()
  if dt < 10
    dt = '0' + dt
  "#{y}/#{m}/#{dt}"

formatDateShort = (ms) ->
  d = new Date ms
  y = d.getUTCFullYear()
  m = d.getUTCMonth() + 1
  if m < 10
    m = '0' + m
  dt = d.getUTCDate()
  if dt < 10
    dt = '0' + dt
  "#{m}/#{dt}"
