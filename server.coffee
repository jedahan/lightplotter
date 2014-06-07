express = require 'express.io'
app = express().http().io()
pigpio = require 'pigpio.js'
RaspiCam = require "raspicam"
fs = require 'fs'

# 30 fps
camera = new RaspiCam mode: "video", output: "test.mov"
camera.on "read", (err, filename) ->
  im.convert [ filename, '-evaluate-sequence', 'mean', '-alpha', 'off', "images/#{Date.now()}.tif" ], (err, stdout) ->
    if err throw err
    console.log 'stdout:', stdout
    fs.unlink filename, (err) ->
      if err throw err
      console.log "#{filename} deleted"

drawing = []
xPin = 22
yPin = 27
lPin = 17
msDelay = 300 # how many milliseconds to delay between each move

set = (x,y) ->
  ->
    pigpio.setPwm xPin, x
    pigpio.setPwm yPin, y

pigpio.setPwmFrequency xPin, 8000
pigpio.setPwmFrequency yPin, 8000
pigpio.setPwmFrequency lPin, 8000

# Broadcast all draw clicks.
app.io.route 'drawClick', (req) ->
  drawing.push req.data
  req.io.broadcast 'draw', req.data

app.io.route 'draw', (req) ->
  time = 0
  camera.start()
  setTimeout camera.stop, msDelay * drawing.length
  for {x,y,type} in drawing
    if type is 'drag'
      setTimeout set(x,y), time+=msDelay
    else
      pigpio.setPwm lPin, type is 'dragStart'

# Send client html.
app.get '/', (req, res) ->
  res.sendfile __dirname + '/client.html'

app.listen 7076
