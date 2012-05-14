###
Map page
###
class Gaso.MapPage extends Backbone.View


  constructor: (@stations, @user) ->
    @stationMarkers = []
    @template = _.template Gaso.util.getTemplate 'map-page'

    # TODO for some reason we must explicitly call setElement, otherwise view.el property doesn't exist?
    @setElement $('<div id="page-map"/>')


  render: =>
    @$el.html @template @stations.toJSON()

    @map = new google.maps.Map @$el.find("#map-canvas")[0], @getInitialMapSettings()

    # New marker for user position as View.
    @userMarker = new Gaso.UserMarker(@user, @map).render()

    # New markers for stations.
    for station in @stations.models
      @addStationMarker station

    @bindEvents()

    return @
    

  bindEvents: ->
    Gaso.log "Bind events to", @

    # Save new zoom level to user model when map zoom has changed.
    google.maps.event.addListener @map, 'zoom_changed', _.debounce =>
      prevZoom = @user.get 'mapZoom'
      newZoom = @map.getZoom()
      Gaso.log "Zoom level set to", newZoom
      @user.set 'mapZoom', newZoom
      @user.save()
      if newZoom < prevZoom 
        @findNearbyStations()
    , 300

    # Save new location and fetch stations when map bounds change.
    google.maps.event.addListener @map, 'bounds_changed', _.debounce =>
      if Gaso.loggingEnabled()
        Gaso.log "Map bounds changed to", @map.getBounds()?.toString()
      # TODO don't look for nearby stations if new bounds are completely within the bounds where we searched last time
      # We can use LatLngBounds.union(oldBounds).equals(newBounds) for this, then we can also forget finding
      # the stations on user zoom change.
      # See https://developers.google.com/maps/documentation/javascript/reference#LatLngBounds
      @saveMapLocation()
      @findNearbyStations()
    , 300

    # Redraw map on jQM page change, otherwise it won't fill the screen.
    @$el.off 'pageshow.mappage'
    @$el.on 'pageshow.mappage', (event) =>
      Gaso.log "Resize map"
      google.maps.event.trigger @map, 'resize'
      coords = @user.get 'mapCenter'
      # return object in google.maps options format, see https://developers.google.com/maps/documentation/javascript/reference#MapOptions
      @map.setCenter new google.maps.LatLng(coords.lat, coords.lon)
      @findNearbyStations()

    @stations.on 'add', @addStationMarker
    # TODO handle station remove
    @user.on 'reCenter', @changeMapLocation

  close: =>
    google.maps.event.clearInstanceListeners @map
    @off()
    @$el.off 'pageshow.mappage'
    @stations.off 'add', @addStationMarker
    @user.off 'reCenter', @changeMapLocation
    @userMarker.close()
    for marker in @stationMarkers
      marker.close()

  getInitialMapSettings: =>
    zoom: @user.get 'mapZoom'
    mapTypeId: google.maps.MapTypeId[@user.get 'mapTypeId']
    disableDefaultUI: productionEnv

  changeMapLocation: =>
    coords = @user.get 'mapCenter'
    Gaso.log "Pan map to", coords
    @map.panTo new google.maps.LatLng(coords.lat, coords.lon)
    # @findNearbyStations()


  saveMapLocation: =>
    currCenter = @map.getCenter()
    @user.set 'mapCenter'
      lat: currCenter.lat()
      lon: currCenter.lng()
    @user.save()


  addStationMarker: (station) =>
    @stationMarkers.push new Gaso.StationMarker(station, @map).render()


  findNearbyStations: =>
    mapBounds = @map.getBounds()

    if Gaso.loggingEnabled()
      Gaso.log "Find stations within", mapBounds?.toString()

    #Try again after a moment if map is not yet ready.
    if not mapBounds?
      setTimeout =>
        @findNearbyStations()
      , 2000
      return

    if @user.get('mapZoom') >= 7
      Gaso.helper.findStationsWithinGMapBounds mapBounds
    else
      Gaso.log "Zoomed too far out, not fetching stations"

