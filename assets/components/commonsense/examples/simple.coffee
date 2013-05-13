Sense = require '../src/commonsense'

sense = new Sense()

username = 'some_username'
password = 'md5_of_password'

sense.createSession username, password, (error, response) ->

  sense.devices (error, response) ->
    console.log 'Devices:', response.object
  sense.sensors (error, response) ->
    console.log 'Sensors:', response.object


session_id = 'some_id_e.g._from_database_or_cookie'
sense_by_token = new Sense(session_id)

sense_by_token.devices (error, response) ->
  console.log 'Devices by token:', response.object