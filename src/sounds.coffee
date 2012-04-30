# It's a real shame that HTML5 <audio> just doesn't cut it and Akihabara is therefore
#  kinda broken in this regard. I'm using soundmanager2 which uses Flash as a failsafe
#  fallback for playing lots of short sound samples. Maybe some day...

window.sounds = {}
soundManager.url = 'swf'
soundManager.flashVersion = 9
soundManager.useHighPerformance = true
soundManager.useFastPolling = true
soundManager.useHTML5Audio = true
#soundManager.preferFlash = true
soundManager.onready ->
  soundManager.defaultOptions.autoLoad = true
  soundManager.defaultOptions.onload = ->
    console.log 'sound loaded!'

  sounds_to_load = [
      id: 'blip'
      url: 'blip1.wav'
      volume: 50
    ,
      id: 'select'
      url: 'select0.wav'
      volume: 50
    ,
      id: 'cancel'
      url: 'cancel0.wav'
      volume: 50
    #,
    #  id: 'thruster'
    #  url: 'thruster.wav'
    #  volume: 15
    ,
      id: 'explode'
      url: 'explode0.wav'
      volume: 25
    ,
      id: 'hit0'
      url: 'hit00.wav'
      volume: 50
    ,
      id: 'hit1'
      url: 'hit01.wav'
      volume: 50
    ,
      id: 'hit2'
      url: 'hit02.wav'
      volume: 50
    ,
      id: 'hit3'
      url: 'hit03.wav'
      volume: 50
    ,
      id: 'shot0'
      url: 'shot0.wav'
      volume: 30
    ,
      id: 'shot1'
      url: 'shot1.wav'
      volume: 30
  ]
  for sound in sounds_to_load
    sounds[sound.id] = soundManager.createSound sound
