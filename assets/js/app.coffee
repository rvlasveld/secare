#= require ../components/commonsense/lib/commonsense.js
#= require ../components/JavaScript-MD5/md5.min.js
#= require graph-1.3.0/graph-min.js

sense = null
graph = null

checkForSenseSession = (reinitiate = true) ->
  if $.cookie('session_id')?
    correct_credentials = true
    
    if reinitiate
      sense = new Sense $.cookie('session_id')
      
      # Check if credentials are still valid
      sense.currentUser (error, response) ->
        if response.status is not 200
          correct_credentials = false
  else
    sense = new Sense

  if correct_credentials
    showDevices()
    $('#sign_in').closest('li').hide()
    $('#sign_out').closest('li').show()
  else
    $('#sign_out').closest('li').hide()
    $('#sign_in').closest('li').show()

signOut = () ->
  sense.deleteSession()
  $.removeCookie 'session_id'
  $('#sign_out').closest('li').hide()
  $('#sign_in').closest('li').show()


showDevices = (list) ->
  fillDevices list, ->
      $('#devices').fadeIn()

fillDevices = (list, cb) ->
  if typeof list is 'function'
    cb = list
    list = null
  list ||= '#devices ul'

  sense.devices (err, resp) ->
    list_html = ''
    list_html += "<li><a href='' data-id='#{device.id}' data-display='#{device.type}'>#{device.type} (#{device.id})</a></li>" for device in resp.object.devices
    $(list).html list_html

    # Simulate click of only a single device
    if resp.object.devices.length == 1
      $(list).find('a').click()

    cb() if cb?

showSensors = (device, list) ->
  fillSensors device, list, ->
    $('#sensors').fadeIn()

fillSensors = (device, list, cb) ->
  if typeof list is 'function'
    cb = list
    list = null
  list ||= '#sensors ul'

  sense.deviceSensors device, (err, resp) ->
    sorted_sensors = resp.object.sensors.sortBy (sensor) -> sensor.display_name
    list_html = ''
    list_html += "<li><a href='' data-id='#{sensor.id}' data-display='#{sensor.display_name}'>#{sensor.display_name} (#{sensor.id})</a></li>" for sensor in sorted_sensors
    $(list).html list_html

    # Simulate click, for dev purposes
    $(list).find('a').first().click()

    cb() if cb?


retrieveSensorTimespan = (id, cb) ->

  first_datapoint_call = ->
    defer = $.Deferred()
    sense.sensorData id, {per_page: 1}, (err, resp) ->
      defer.resolve resp.object.data[0]
    return defer.promise()

  last_datapoint_call = ->
    defer = $.Deferred()
    sense.sensorData id, {last: true}, (err, resp) ->
      defer.resolve resp.object.data[0]
    return defer.promise()

  $.when(first_datapoint_call(), last_datapoint_call()).done (first, last) ->
    cb(first, last) if cb?

getSensorData = (id, options, cb) ->
  sense.sensorData id, options, (err, res) ->
    cb(err, res.object.data) if cb?


plotSensorData = (sensor_data) ->
    datasets = []

    # Check for single or multi-valued data points
    first_object = JSON.parse(sensor_data[0].value)
    
    if typeof first_object is "object"
      # Multiple values, assume numeric
      for key of first_object

        data = []
        data.push {date: new Date(datum.date*1000), value: JSON.parse(datum.value)[key]} for datum in sensor_data
        datasets.push {label: key, data: data}

    else
      # Single value (assume numeric)
      data = []
      data.push {date: new Date(datum.date*1000), value: JSON.parse(datum.value)} for datum in sensor_data
      datasets.push {label: 'Sensor ' + id, data: data }

    graph.draw datasets, {min: data[0].date, max: data.last().date, legend: {toggleVisibility: true} }
    graph.setValueRangeAuto()
    $('#actions').fadeIn()

callSegmentation = (sensor, start, end, cb) ->

  $.ajax
    url: '/segment?sensor=' + sensor + '&start=' + start + '&end=' + end
    headers:
      session_id: $.cookie('session_id')
  .done (data) ->

    # Clear current segmentation
    graph_data = (dataset for dataset in graph.data when dataset.type isnt 'area' )

    # Add alternating background colors to data
    blue = 'rgba(51, 102, 204, 0.3)'
    red  = 'rgba(220, 57, 18, 0.3)'

    lines = []
    for datum, index in data
      data[index]['color'] = if index % 2 is 0 then blue else red
      lines.push {}

    lines.push {legend: false}
    graph_data.push type: 'area', data: data, label: 'Segments'

    graph.draw graph_data, {lines: lines}
    graph.setValueRangeAuto()



# When DOM is loaded...
$ ->

  container = document.getElementById 'graph_container'

  checkForSenseSession()

  $('#sign_out').on 'click', (e) ->
    e.preventDefault()
    signOut()
    $('#devices, #sensors, #actions, #visualization').hide()

  $('form#authenticate').submit (e) ->

    # TODO: ADD SPINNER
    form = @

    e.preventDefault()

    username = $('#username').val()
    password = md5 $('#password').val()

    sense.createSession username, password, (err, resp) ->
      $(form).parents('li').removeClass 'open'
      $.cookie 'session_id', resp.object.session_id

      checkForSenseSession false
      

  $('#devices .dropdown-menu').on 'click', 'a', (e) ->
    showSensors $(@).data('id')
    return false

  $('#sensors .dropdown-menu').on 'click', 'a', (e) ->
    $('#visualization').show()
    
    graph = new links.Graph container

    id = $(@).data('id')

    retrieveSensorTimespan id, (first, last) ->
      
      interval = Sense.optimalInterval first.date, last.date, 1000

      getSensorData id, {start_date: first.date, end_date: last.date, per_page:1000}, (err, resp) ->
        plotSensorData resp
      
    return false;


  $('#actions .segment').on 'click', () ->

    range = graph.getVisibleChartRange()
    window.range = range
    console.log 'Range:', range
    callSegmentation $('#sensors .sensor').data('id'), range.start.getTime(), range.end.getTime()
    return false


  # Replace dropdown value with selected value
  $('.dropdown-menu').on 'click', 'a', (e) ->
    button = $(@).closest('.btn-group').removeClass('open').find('button').not('.dropdown-toggle')
    button_childs = button.find('*')
    button.text($(@).data('display') + ' ').append button_childs
    button.data('id', $(@).data('id') )
    return false
