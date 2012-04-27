html ->
  head ->
    script type:'text/javascript', src:'akihabara/gbox.js'
    script type:'text/javascript', src:'akihabara/iphopad.js'
    script type:'text/javascript', src:'akihabara/trigo.js'
    script type:'text/javascript', src:'akihabara/toys.js'
    script type:'text/javascript', src:'akihabara/help.js'
    script type:'text/javascript', src:'akihabara/tool.js'
    script type:'text/javascript', src:'akihabara/gamecycle.js'
    script type:'text/javascript', src:'seedrandom.js'
    script type:'text/javascript', src:'game.js'
    link rel:'stylesheet', href:'style.css'
    
    meta
      name:'viewport'
      content:'width:device-width; initial-scale:1.0; maximum-scale:1.0; user-scalable:0;'
  body ->
    div id:'instructions', ->
      h3 -> 'Instructions:'
      h4 -> 'Star Map:'
      ul ->
        li -> "Arrow Keys move cursor to select star system, highlighted with green circle."
        li -> "Large turquoise circle is the range of your FTL fuel."
        li -> "'Z' selects star system"
        li -> "'C' returns to Flight Mode"

      h4 -> "Planet Map:"
      ul ->
        li -> "Arrow Keys move cursor to select a planet you wish to visit."
        li -> "'Z' travels to that planet (instantaneously) and puts you in Flight Mode"
        li -> "'C' returns to Star Map"

      h4 -> "Flight Mode:"
      ul ->
        li ->
          text "Arrow Keys -- control is much like classic Asteroids."
          ul ->
            li -> "Down is afterburner ('brake')."
        li -> "'Z' -- Fire weapon."
        li -> "\"Park\" over a space station for a few seconds to enter the Station Screen"
        li -> "Blinking pixels on and around planets are resources -- fly into them to collect them."

      h4 -> "Station Screen:"
      ul ->
        li -> "'C' to exit the Station."
        li -> "Up/Down to select different items on current screen."
        li ->
          text "Left/Right change screen (Cargo[trade], Missions, Hangar)"
          h5 -> 'Cargo'
          ul ->
            li -> "'Z' - Buy selected good"
            li -> "'X' - Sell selected good"
          h5 -> "Missions"
          ul ->
            li -> "'Z' - Accept/Abandon selected mission"
          h5 -> "Hangar"
          ul ->
            li -> "'Z' - Purchase selected upgrade"
    canvas width:327, height:1, style:'display:none', id:'starcolors'
    canvas width:16, height:3, style:'display:none', id:'planetcolors'
    canvas width:320, height:320, style:'display:none', id:'starmap'

  coffeescript ->
    body = document.getElementsByTagName('body')[0]
    body.setAttribute('class','instructions-visible')
