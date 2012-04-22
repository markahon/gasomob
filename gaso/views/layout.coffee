###
  Coffeekup template for default page layout.
###

productionEnv = process.env.NODE_ENV is 'production'

# Format Coffeekup's html-output to human-readable form with indents and line breaks.
@.format = true unless productionEnv

templatesversion = if productionEnv then 4 else 0

doctype 5
html ->
  head ->
    meta charset: 'utf-8'

    title "#{@title} | Gaso" if @title?
    meta(name: 'description', content: @description) if @description?
    meta name: 'viewport', content:'width=device-width, initial-scale=1'
    meta name: 'apple-mobile-web-app-capable', content: 'yes'
    
    link(rel: 'canonical', href: @canonical) if @canonical?

    # Lib styles
    if productionEnv
      link rel: 'stylesheet', href: 'http://code.jquery.com/mobile/1.1.0-rc.1/jquery.mobile-1.1.0-rc.1.min.css'
    else
      link rel: 'stylesheet', href: '/lib/jquery.mobile-1.1.0-rc.2.css'

    #link rel: 'icon', href: '/favicon.png'
    link rel: 'stylesheet', href: '/stylesheets/style.css'

    # Libs: CloudMade maps for stations data, maybe later use only this for visual maps, too.
    script src: "http://tile.cloudmade.com/wml/latest/web-maps-lite.js"
    # Libs: Google Maps + geometry library
    script src: 'http://maps.googleapis.com/maps/api/js?key=AIzaSyDcg6vsxZ6HaI32Nn24kAzrclo9SL3Rz7M&sensor=true'
    script src: "http://maps.googleapis.com/maps/api/js?libraries=geometry&sensor=true"

    # Libs: Socket.io for websockets
    script src: '/socket.io/socket.io.js'

    # Other libs
    if productionEnv
      script src: 'http://cdnjs.cloudflare.com/ajax/libs/json2/20110223/json2.js'
      script src: 'http://code.jquery.com/jquery-1.7.1.min.js'
      script src: 'http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.3.1/underscore-min.js'
      script src: 'http://cdnjs.cloudflare.com/ajax/libs/backbone.js/0.9.1/backbone-min.js'
    else 
      script src: '/javascripts/lib/json2.js'
      script src: '/javascripts/lib/jquery-1.7.1.js'
      script src: '/javascripts/lib/underscore.js'
      script src: '/javascripts/lib/backbone.js'

    script src: '/javascripts/lib/backbone.iosync.js'
    script src: '/javascripts/lib/backbone.iobind.js'

    # FIXME Can't atm use a minimified cdn version of backbone.localstorage in production,
    # because it clashes with our own minimified code.
    # How can we prevent the variable clash during js minimization?
    # if productionEnv
    #   script src: 'http://cdnjs.cloudflare.com/ajax/libs/backbone-localstorage.js/1.0/backbone.localStorage-min.js'
    # else
    #   script src: '/javascripts/lib/backbone.localStorage.js'
    script src: '/javascripts/lib/backbone.localStorage.js'

    # More libs: jQuery Mobile
    # ...but override some own initialization stuff before jQuery mobile is included.
    text assets.js 'mobileinit'
    text '\n'
    if productionEnv
      script src: 'http://code.jquery.com/mobile/1.1.0-rc.1/jquery.mobile-1.1.0-rc.1.js'
    else
      script src: '/lib/jquery.mobile-1.1.0-rc.2.js'

    script -> "productionEnv = #{productionEnv}; tmplVer = #{templatesversion};"
    
    # Include rest of own scripts, ie. other but 'mobileinit'
    text assets.js 'application' # See /assets/application.coffee

  body ->
    # No body content, content will be rendered on client using client-side templates.
    # @body
