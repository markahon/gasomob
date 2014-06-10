# Couldn't come up with a better name for a business logic handling / helper controller...
class Gaso.Helper

  constructor: (@user, @stations, @searchContext) ->
    # @stations.on 'add', @setDistanceToUser
    @user.on 'change:position', @updateStationDistancesToUser
    @user.on 'reCenter', @getStationsDataNearby


  calculateDistanceToUser: (loc) =>
    userpos = @user.get 'position'
    # Don't do anything if user geolocation is not set.
    return if not (userpos.lat? and userpos.lon?)
    distMeters = Gaso.geo.calculateDistanceBetween userpos, loc
    distFloat = (distMeters / 1000).toFixed(1)


  setDistanceToUser: (station) =>
    dist = @calculateDistanceToUser station.get 'location'
    station.set 'directDistance', dist


  distancesLastUpdatedAt = null
  updateStationDistancesToUser: =>
    shouldUpdateDistances = true
    userpos = @user.get 'position'
    if distancesLastUpdatedAt?
      distMeters = Gaso.geo.calculateDistanceBetween distancesLastUpdatedAt, userpos
      shouldUpdateDistances = distMeters >= 100
      Gaso.log "Should we update station distances? Distance from last update spot: ", distMeters
    if shouldUpdateDistances
      for station in @stations.models
        dist = @setDistanceToUser station
      distancesLastUpdatedAt = _.extend {}, userpos


  findStationByOsmId: (osmId, callback) =>
    @stations.fetch
      add: true
      data:
        osmId: osmId
      success: (collection, response) ->
        callback null, response
      error: (collection, response) ->
        callback response


  getStationsDataWithinBounds: (bounds) =>
    @stations.fetch
      add : true
      data:
        bounds: bounds


  getStationsDataNearby: =>
    userpos = @user.get 'position'
    @stations.fetch
      add : true
      data:
        point: [userpos.lon, userpos.lat]
        radius: 10


  findStationsWithinGMapBounds: (mapBounds) ->
    # Search from own db.
    @getStationsDataWithinBounds Gaso.geo.gMapBoundsToArray mapBounds
    # Search from cloudmade.
    # UPDATE: Service is N/A these days, so don't do it.
    # Gaso.geo.findOsmStations mapBounds, (response, a) =>
    #   Gaso.log "CloudMade API response", response
    #   if response.features?
    #     for feature in response.features
    #       @addStationToCollection _convertCMFeatureToModelData(feature)
    #   else
    #     Gaso.log "No 'features' in CM response", response

    # Search from google.
    Gaso.geo.findGoogleStations mapBounds, (results, status) =>
      Gaso.log "Google API results", results
      if status == google.maps.places.PlacesServiceStatus.OK
        for place, i in results
          @addStationToCollection _convertGooglePlaceToModelData(place)
      else if status == google.maps.places.PlacesServiceStatus.ZERO_RESULTS
        Gaso.log "No results from Google API fuel stations request."
      else
        Gaso.error "Google API fuel stations request failed with status:", status


  addStationToCollection: (stationData, options) =>
    defaults =
      update: true
    settings = _.extend {}, defaults, options
    existingModel = @stations.get stationData.osmId

    if existingModel?
      if settings.update
        Gaso.trace "TODO update/merge station model with possible new/extra data we don't have yet"
    else
      station = new Gaso.Station(stationData)
      if @isStationValid station
        @stations.add station
      else
        Gaso.trace "Ignore station", station.get('name'), station if Gaso.loggingEnabled
        station.clear()


  # Show only search results that are most certainly real gas stations, behaviour can be toggled in user settings.
  isStationValid: (stationModel) ->
    stationModel.isValid() or @user.getToggleSetting('allowUncertainSearchResults')


  message: (msg, options) =>
    new Gaso.FeedbackMessage(msg, options).render()


  ###
    Private methods and other stuff
  ###

  # Helper method to convert CloudMade feature to Station model data format.
  _convertCMFeatureToModelData = (feature) ->
    stationdata = feature.properties

    # Address data might be missing completely for many stations, but lets use it if it exists.
    sStreet = stationdata['addr:street']
    sNum = stationdata['addr:housenumber']

    modelData =
      osmId: "o#{stationdata.osm_id}"
      name: stationdata.name or "Unknown"
      address: {
        street: "#{sStreet} #{sNum}" if sNum and sStreet
        city: stationdata['addr:city']
        zip: stationdata['addr:postcode']
        country: stationdata['addr:country']
      }
      location: [
        # centroid is in the order [lat, lon], we require [lon, lat].
        feature.centroid.coordinates[1]
        feature.centroid.coordinates[0]
      ]

    return modelData

  # Helper method to convert a Place from Google API to Station model data format.
  # See https://developers.google.com/maps/documentation/javascript/places#place_search_responses
  _convertGooglePlaceToModelData = (place) ->
    addressparts = place.vicinity.split ','

    modelData =
      osmId: "g#{place.id}"
      name: place.name or "Unknown"
      address: {
        street: addressparts[0]
        city: addressparts[1].replace(/\ /g, "")
      } if addressparts?
      location: [
        # centroid is in the order [lat, lon], we require [lon, lat].
        place.geometry.location.lng()
        place.geometry.location.lat()
      ]

    return modelData

