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
    script type:'text/javascript', src:'soundmanager2.js'
    script type:'text/javascript', src:'game.js'
    link rel:'stylesheet', href:'style.css'
    meta charset:'utf-8'
    
    meta
      name:'viewport'
      content:'width:device-width; initial-scale:1.0; maximum-scale:1.0; user-scalable:0;'
  body ->
    div id:'links', ->
      a href:'http://namuol.github.com/', 'namuol.github.com'
      text ' &ndash; '
      a href:'http://muniverse-game.tumblr.com/', 'devlog'
      text ' &ndash; '
      a href:'http://twitter.com/louroboros/', '@louroboros'
    div id:'instructions', ->
      h3 -> 'Instructions:'
      p 'This is a sandbox, open-world game. There is no "win" condition.'
      p 'Please don\'t be horrified by the wall of text below. These are detailed instructions for your reference, not something you need to read all-at-once. Thanks!'
      ul ->
        li -> 'Travel from star system to star system via the Star Map.'
        li -> 'Selecting a star opens the Planet Map, where you choose your specific destination within that system (a planet or moon).'
        li ->
          text 'Planets/moons may have Space Stations; here you can:'
          ul ->
            li -> 'Buy/Sell goods'
            li -> 'Pick up Taxi Passengers'
            li -> 'Upgrade your ship'
        li -> 'You can also encounter other ships. Be aware that not all ships will attack you unless provoked.'
      h4 -> 'Star Map:'
      ul ->
        li -> "Arrow Keys move crosshair that highlights the nearest star system."
        li -> "'Z' selects the highlighted star system and enters Planet Map"
        li -> "'C' returns to Flight Mode"
        li -> "Large turquoise circle is the range of your FTL fuel. Buy or collect more fuel to expand your flight-range."
        li -> "Small pink circle is your current star system."
        li -> "Small light-green circle is your destination star system."
        li -> "Small yellow circles represent Taxi Passenger destinations."
        li -> "Large blue circles are 'protected' zones. Less likely to encounter hostiles here, but also less likely to find Pirate stations."
        li -> "Large red circles are 'piracy' zones. More likely to encounter hostiles here, but also more likely to find Pirate stations."

      h4 -> "Planet Map:"
      ul ->
        li -> "Arrow Keys move cursor to select a planet or moon you wish to visit."
        li -> "'Z' travels to that planet (instantaneously) and puts you in Flight Mode"
        li -> "'C' opens Star Map"
        li -> "Yellow triangles represent Taxi Passenger destinations."
        li -> "Pink triangle represents your current location, if any."
        li -> "Light-green represents your destination planet/moon."

      h4 -> "Flight Mode:"
      ul ->
        li -> "Arrow Keys -- control is much like classic Asteroids."
        li -> "'Z' -- Fire weapon."
        li -> "Grey space stations are ITG (Intergalactic Trade Guard) compliant -- narcotics *may* be detected and confiscated if you bring them here."
        li -> "Brown space stations are Pirate stations -- anything goes, and narcotics have lower prices."
        li -> "\"Park\" over a space station for a few seconds to enter the Station Screen"
        #li -> "Blinking pixels on and around planets are resources -- fly into them to collect them."

      h4 -> "Station Screen:"
      ul ->
        li -> "'C' to exit the Station."
        li -> "Up/Down to select different items on current screen."
        li ->
          text "Left/Right change screen (Cargo[trade], Missions, Hangar)"
          h5 -> 'Cargo'
          ul ->
            li -> "'Z' - Buy unit of selected good"
            li -> "'X' - Sell unit of selected good"
          h5 -> "Missions"
          ul ->
            li ->
              text "'Z' - View mission details (starmap and briefing screens)"
              ul ->
                li "'Z' - Accept mission"
                li "'X' - Abandon mission"
                li "'C' - Return to Missions"
            li -> 'Open the star map and look for yellow circles to locate your passengers\'s destinations.'
          h5 -> "Hangar"
          ul ->
            li -> "'Z' - Purchase selected upgrade"

    canvas width:327, height:1, style:'display:none', id:'starcolors'
    canvas width:16, height:3, style:'display:none', id:'planetcolors'
    canvas width:320, height:320, style:'display:none', id:'starmap'

  coffeescript ->
    body = document.getElementsByTagName('body')[0]
    body.setAttribute('class','instructions-visible')
