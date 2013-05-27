Sense = require 'commonsense'

# Default segment action
# segment?sensor=1
exports.index = (req, res) ->
  sensor = req.query.sensor
  session_id = req.headers.session_id

  sense = new Sense session_id

  sense.sensorData sensor, (err, resp) ->
    console.log('Error:', err) if err?
    data = []
    data.push {date: datum.date*1000, value: JSON.parse(datum.value)['x-axis']*3} for datum in resp.object.data
    res.json data
