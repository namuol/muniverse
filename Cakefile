fs = require 'fs'
stylus = require 'stylus'

handle_errors = (err, stdout, stderr) ->
  throw err if err
  console.log stdout + stderr

task 'build', 'Create compiled HTML/CSS output', ->


fs = require 'fs'
ck = require 'coffeecup'
{exec} = require 'child_process'

BUILD_DIR = 'build/'

appFiles  = [
  'util'
  'ui'
  'entities'
  'equipment'
  'fx'
  'missions'
  'stars'
  'planets'
  'player'
  'radar'
  'resources'
  'stations'
  'main'
]

task 'build', 'Build single application file from source files', ->
  console.log 'build her a cake or something...'
  console.log 'building index.html'

  result = ck.render fs.readFileSync('src/index.coffee', 'utf-8')
  fs.writeFileSync BUILD_DIR + 'index.html', result


  appContents = new Array remaining = appFiles.length
  for file, index in appFiles then do (file, index) ->
    fs.readFile "src/#{file}.coffee", 'utf8', (err, fileContents) ->
      throw err if err
      appContents[index] = fileContents
      process() if --remaining is 0
  process = ->
    fs.writeFile 'build/game.coffee', appContents.join('\n\n'), 'utf8', (err) ->
      throw err if err
      exec 'coffee --compile build/game.coffee', (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
        fs.unlink 'build/game.coffee', (err) ->
          throw err if err
          console.log 'Done.'

  console.log 'building css'
  stylus.render fs.readFileSync('src/style.styl','utf-8'), {filename: 'build/style.css'}, (err, css) ->
    throw err if err
    fs.writeFileSync 'build/style.css', css

