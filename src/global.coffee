# Hmm... maybe this should be called "universal.coffee" ;)
# This is a hack for certain global variables. I need them to be included in all 
# files but order matters with coffeescript, so there are times where it gets confused
# and declares these variables as local vars... So yeah, this is the first-rendered
# file that establishes variables as globals before anything else.
current_station = undefined
current_planet = undefined
