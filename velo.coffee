# Description:
#   Shows how many velos are free on "nearby" Velo stations.
#
# Dependencies:
#   None
#
# Configuration:
#   VELO_STATIONS - A comma seperated list of station ID's
#   VELO_THRESHOLD
#
# Commands:
#   hubot is er nog een (velo|fiets) vrij
#	  hubot velo vrij?
#	  hubot is er nog een stalen ros beschikbaar?
#
# Author:
#   @pjaspers based on work by @inferis based on work by @ridingwolf based on work by @bobvanlooveren

postRequest = (msg, path, params, callback) ->
  stringParams = JSON.stringify params
  msg.http("#{URL}#{path}")
    .headers("Content-type": "application/x-www-form-urlencoded")
    .post(stringParams) (err, res, body) ->
      callback(err, res, body)

module.exports = (robot) ->

  if process.env.VELO_STATIONS
    stations = process.env.HUBOT_VELO.split ','
  else
    stations = [ 74, 72, 15, 76]
  threshold = process.env.VELO_TRESHOLD || 5

  robot.respond /(is er)? (nog)?\s?(een|ne)?\s?(fiets|velo|tweewieler|stalen ros)?(je|ke)?\s?(beschikbaar|vrij|aanwezig)?(\?)?$/i, (msg) ->
    status msg

  status = (msg) ->
    checkStatus msg, stations.slice(), false

  checkStatus = (msg, stations, found) ->
    station = stations.shift()
    unless station
      unless found
        msg.send "Neen. Het zal wandelen worden."
      return
    data = "idStation=#{station}"
    postRequest msg, 'https://www.velo-antwerpen.be/CallWebService/StationBussinesStatus.php', {idStation: station}, (err, res, body) ->
      matches = /bikes\s+(\d+)\s+slots\s+(\d+)/gi.exec body
      if matches.length is 3
        nrOfBikes = Number(matches[1])
        nrOfParking = Number(matches[2])
        if nrOfBikes > 0
          unless found
            msg.send "Ja. Er zijn nog #{nrOfBikes} fietskes vrij in station #{station}."
            if nrOfBikes <= threshold
              checkStatus msg, stations, true
            else if nrOfBikes > threshold
              msg.send "Er zijn ook nog #{nrOfBikes} fietskes vrij in station #{station}."
            else
              checkStatus msg, stations, true
        else
          checkStatus msg, stations, false
      else
        msg.send "Ik weet het niet."
