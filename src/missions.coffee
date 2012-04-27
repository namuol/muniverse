ACCEPT_MESSAGES = [
  'You won\'t regret it.'
  'Okay!'
  'Excellent!'
  'Wise choice.'
]
ABANDON_MESSAGES = [
  'I thought we had a deal!'
  'Oh well, your loss.'
  'Why the sudden change of heart?'
  'Can\'t make up your mind, can you?'
]
SUCCESS_MESSAGES = [
  'Pleasure doing business with you.'
  'Thank you!'
  'Thank you so much!'
  'Keep up the good work.'
]
FAILURE_MESSAGES = [
  'What a waste of time!'
  'Worthless! You will not be paid.'
  'Ugh. Goodbye.'
]
class Mission extends MenuItem
  constructor: (@person) ->
    @accepted = false
  success: ->
    idx = player.missions.indexOf @
    player.missions.splice(idx,1)
    message.set choose(SUCCESS_MESSAGES),240,@person
    if @price
      player.funds += @price
  failure: ->
    idx = player.missions.indexOf @
    player.missions.splice(idx,1)
    message.set choose(FAILURE_MESSAGES),240,@person
  onaccept: ->
    message.set choose(ACCEPT_MESSAGES),240,@person
  onabandon: ->
    message.set choose(ABANDON_MESSAGES),240,@person
  a: ->
    dq = @doesnt_qualify()
    if dq
      message.set dq, 240, @person
      return false

    @accepted = !@accepted
    if @accepted
      player.missions.push(@)
      @onaccept()
    else
      idx = player.missions.indexOf @
      player.missions.splice(idx,1)
      @onabandon()
    return true
  doesnt_qualify: ->
    false
  text: ->
    if @accepted
      '[X]'
    else
      '[ ]'
  render: (x, top, alpha) ->
    @person.render(x,top,alpha)
    super(x+24, top+4, alpha)

NO_CABINS_MESSAGES = [
  'That\'s a bit too cozy for my taste.'
  'It looks like you\'re full.'
  'You\'ll need to make room for me.'
]
class CabinDweller extends Mission
  constructor: (@person, @star) ->
  success: ->
    super()
    idx = player.cabins.indexOf @person
    player.cabins.splice(idx,1)
  a: ->
    if super()
      if @accepted
        player.cabins.push(@person)
      else
        idx = player.cabins.indexOf @person
        player.cabins.splice(idx,1)
  doesnt_qualify: ->
    return false if @accepted

    if player.cabins.length >= player.available_cabins
      choose NO_CABINS_MESSAGES
    else
      false

FUGITIVE_TAXI_BONUS = 1.25
class TaxiMission extends CabinDweller
  type:'taxi'
  constructor: (@person) ->
    super(@person)
    @price = RESOURCES.fuel.mean_price * 1.25
    if @person.fugitive
      @price *= FUGITIVE_TAXI_BONUS
      @loc_name = 'Pirate st.'
      station = (choose starmap.known_pirate_stations)
    else
      @loc_name = 'ITG st.'
      station = (choose starmap.known_itg_stations)

    @star = station.star
    @price *= starmap.current_star.distance_to @star
    @price = Math.round(@price*100)/100
    @location =
      star: @star
      pnum: station.planet
  text: ->
    super() + 'Taxi-' + @loc_name + '-$'+@price
class CrewMission extends CabinDweller
  type:'crew'
  text: ->
    super() + 'Crew'


