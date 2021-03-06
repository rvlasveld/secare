Sense = require 'commonsense'

# Default segment action
# segment?sensor=1[&start=milliseconds timestamp&end=milliseconds timestamp]
exports.index = (req, res) ->
  sensor = req.query.sensor
  start = req.query.start / 1000.0
  end = req.query.end / 1000.0
  console.log 'Start:', start, ', End:', end
  
  session_id = req.headers.session_id

  sense = new Sense session_id

  sense.sensorData sensor, {start_date: start, end_date: end, per_page: 1000}, (err, resp) ->
    console.log('Error:', err) if err?

    # Return an array of data range objects
    number_of_segments = 5

    data = resp.object.data
    
    [first, last] = [data[0], data[data.length-1]]

    range = last.date - first.date
    per_segment = range / number_of_segments

    running_start = first
    return_data = []
    number_of_segments += 1
    return_data = while number_of_segments -= 1
      running_start.date += per_segment
      {date: running_start.date * 1000}

    res.json return_data