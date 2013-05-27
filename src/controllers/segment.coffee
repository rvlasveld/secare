Sense = require 'commonsense'

# Default segment action
# segment?sensor=1
exports.index = (req, res) ->
  sensor = req.query.sensor
  start = req.query.start
  end = req.query.end

  session_id = req.headers.session_id

  sense = new Sense session_id

  sense.sensorData sensor, {start: start, end: end, per_page: 1000}, (err, resp) ->
    console.log('Error:', err) if err?

    # Return an array of data range objects
    number_of_segments = 3

    data = resp.object.data
    
    [first, last] = [data[0], data[data.length-1]]

    range = last.date - first.date
    per_segmenet = range / number_of_segments

    running_start = first
    return_data = []
    number_of_segments += 1
    return_data = while number_of_segments -= 1
        segment = {start: running_start.date * 1000, end: (running_start.date + per_segmenet) * 1000 }
        running_start.date += per_segmenet
        segment

    res.json return_data
