# Script for transitioning between two scenes: config.fromSceneId to config.toSceneId.
# Note: both scenes must have exactly the same lights.
# Set your own configuration in config object.

_ = require('lodash')
Bacon = require('baconjs').Bacon
moment = require('moment')
request = require('request')
WebSocket = require('ws')

MS_IN_MINUTE = 1000*60

config =
  onHour: 0 # to scene activated fully at this hour
  onMinute: 27 # to scene activated fully at this hour
  fadeInMinutes: 1 # fade from zero to full in given mins
  sitekey: 'yoursecretsitekey'
  fromSceneId: 'xxx'
  toSceneId: 'yyy'

getStartAndEndTimesForDate = (config, date) ->
  endTime =  date.clone().hour(config.onHour).minute(config.onMinute).second(0).millisecond(0)
  startTime = endTime.clone().subtract(config.fadeInMinutes, 'minutes')
  {startTime, endTime}

scale = (lo, hi) -> (x) -> (x - lo) / (hi - lo)

{ startTime, endTime } = getStartAndEndTimesForDate config, moment()

unixStartTime = startTime.format("X")
unixEndTime = endTime.format("X")

pluckBri = (scene) ->
  _(scene.state)
    .sortBy '_id'
    .map (s) -> { _id: s._id, bri: s.bri }
    .value()

socket = new WebSocket("wss://houm.herokuapp.com")
socket.on 'open', ->
  socket.send JSON.stringify { command: "subscribe", sitekey: config.sitekey }
  request "https://houm.herokuapp.com/api/site/#{config.sitekey}/scene", (err, res, body) ->
    scenes = JSON.parse body
    fromScene = _.find scenes, _id: config.fromSceneId
    toScene = _.find scenes, _id: config.toSceneId
    fromSceneBris = pluckBri fromScene
    toSceneBris = pluckBri toScene
    zipped = _.zip(fromSceneBris, toSceneBris).map (x) -> { _id: x[0]._id, fromBri: x[0].bri, toBri: x[1].bri }
    Bacon
      .interval(1000, 'tick')
      .map -> moment().format("X")
      .filter (m) -> unixStartTime <= m <= unixEndTime
      .map scale(unixStartTime, unixEndTime)
      .skipDuplicates()
      .flatMap (factor) ->
        Bacon.fromArray zipped.map (z) ->
          _id: z._id
          on: true
          bri: Math.floor( z.fromBri + (z.toBri - z.fromBri) * factor )
      .onValue (v) ->
        socket.send JSON.stringify
          command: "set"
          data: v
