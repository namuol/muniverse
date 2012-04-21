fs = require 'fs'
ck = require 'coffeecup'
stylus = require 'stylus'

task 'build', 'Create compiled HTML/CSS output', ->
  console.log 'build her a cake or something...'
  result = ck.render fs.readFileSync('src/index.coffee', 'utf-8')
  fs.writeFileSync 'index.html', result

  console.log 'building css'
  stylus.render fs.readFileSync('src/style.styl','utf-8'), {filename: 'style.css'}, (err, css) ->
    fs.writeFileSync 'style.css', css
