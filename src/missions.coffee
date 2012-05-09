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
    super 'MISSION'
    @accepted = false
  success: ->
    idx = player.missions.indexOf @
    player.missions.splice(idx,1)
    message.set choose(SUCCESS_MESSAGES),240,@person, 'pop_up'
    if @price
      player.funds += @price
  failure: ->
    idx = player.missions.indexOf @
    player.missions.splice(idx,1)
    message.set choose(FAILURE_MESSAGES),240,@person, 'pop_up'
  onaccept: ->
    message.set choose(ACCEPT_MESSAGES),240,@person, 'pop_up'
  onabandon: ->
    message.set choose(ABANDON_MESSAGES),240,@person, 'pop_up'

  accept_or_abandon: ->
    dq = @doesnt_qualify()
    if dq
      message.set dq, 240, @person
      return false

    @accepted = !@accepted
    if @accepted
      player.missions.push(@)
      @onaccept()
      sounds.select.play()
    else
      idx = player.missions.indexOf @
      player.missions.splice(idx,1)
      @onabandon()
      sounds.cancel.play()
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

  tick: ->
    # Override me!

class MissionTicker
  group: 'game'
  first: ->
    tmp = player.missions.slice(0)
    for mission in tmp
      mission.tick()

NO_CABINS_MESSAGES = [
  'That\'s a bit too cozy for my taste.'
  'It looks like you\'re full.'
  'You\'ll need to make room for me.'
]
class CabinDweller extends Mission
  constructor: (@person) ->
    super @person
  success: ->
    super()
    idx = player.cabins.indexOf @person
    player.cabins.splice(idx,1)

  failure: ->
    super()
    idx = player.cabins.indexOf @person
    player.cabins.splice(idx,1)

  accept_or_abandon: ->
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

class BriefingDialog extends Dialog
  pre_render: ->

class MissionStarmap extends Dialog
  constructor: (@mission) ->
    super('')

  pre_render: (c) ->
    starmap.render_itg_regions c
    starmap.render_pirate_regions c
    starmap.render_fuel_range c
    starmap.render_current_star c
    starmap.render_current_missions c
    starmap.render_selected_star c, @mission.location.star
    starmap.render_star_info c, @mission.location.star
    starmap.render_travel_path_to c, @mission.location.star
    starmap.render_map c

FUGITIVE_TAXI_BONUS = 1.25
class TaxiMission extends CabinDweller
  type:'taxi'
  constructor: (@person) ->
    super @person

    if @person.fugitive
      @loc_name = 'Pirate st.'
      station = (choose starmap.known_pirate_stations)
    else
      @loc_name = 'ITG st.'
      station = (choose starmap.known_itg_stations)
    
    @star = station.star
    @dist = starmap.current_star.distance_to @star
    @lvl = choose [0,0,0,1,1,2]
    @ms_per_ly = EQUIPMENT.ftl_ms_per_ly.levels[@lvl].val
    @hurry = Math.random()
    @deadline = date + @dist * @ms_per_ly * (2.25 - @hurry)
    @price = RESOURCES.fuel.mean_price * 4
    @price *= @dist
    @price += @price * @hurry * 0.5
    @price *= (@lvl+1)
    @price *= FUGITIVE_TAXI_BONUS if @person.fugitive
    @price = Math.round(@price*100)/100
    @location =
      star: @star
      pnum: station.planet
  a: ->
    menu = new MultiMenu
    menu.pushItem new MenuItem 'Starmap'
    map = new MissionStarmap @
    #brief.pushItem new DialogChoice '[Press C to Return to Station Screen]'
    menu.sub_menus.push map

    menu.pushItem new MenuItem 'Brief'
    brief = new BriefingDialog 'This is placeholder text for brief'
    #brief.pushItem new DialogChoice '[Press C to Return to Station Screen]'
    menu.sub_menus.push brief

    menu.a = =>
      if !@accepted
        @accept_or_abandon()
    menu.b = =>
      if @accepted
        @accept_or_abandon()

    menustack.pushMenu menu

  text: ->
    super() + 'Taxi lvl'+(@lvl+1)+' by '+formatDateShort(@deadline)+' $' + @price

  tick: ->
    #if date > @deadline
    #  @failure()
    return if not current_station
    if current_station.planet.num is @location.pnum and
       current_station.planet.star is @location.star
      if date > @deadline
        @failure()
      else
        @success()

class CrewMission extends CabinDweller
  type:'crew'
  text: ->
    super() + 'Crew'
