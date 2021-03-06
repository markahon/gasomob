# Requiring express-resouce will "monkey-patc" Express server for using app.resource.
# See https://github.com/visionmedia/express-resource for documentation.
require('express-resource')
db     = require '../lib/persistence'
mock   = require '../dev/mockdata'
config = require '../config'

# Helper variables
productionEnv = config.env.production

sendError = (res) ->
  return res.send err unless productionEnv
  res send "Error occurred."

processCommonQueryParams = (q, req) ->
  q.skip req.query.skip if req.query.skip?
  q.limit 50 # Set hard limit for results

class StationResource

  type = 'station'

  index: (req, res) ->
    q = db.Station.find()
    processCommonQueryParams q, req
    q.run (err, result) ->
      return sendError(res) if err?
      res.send result

  new: (req, res) ->
    res.send "TODO new #{type}"

  create: (req, res) ->
    res.send "TODO create #{type}"

  show: (req, res) ->
    q = db.Station.findByOsmIds [req.params[type]]
    processCommonQueryParams q, req
    q.run (err, result) ->
      return sendError(res) if err?
      return res.send result[0] if result.length
      res.send {}

  edit: (req, res) ->
    res.send "TODO edit #{type} #{req.params[type]}"

  update: (req, res) ->
    res.send "TODO update #{type} #{req.params[type]}"

  destroy: (req, res) ->
    res.send "TODO destroy #{type} #{req.params[type]}"


class CommentResource

  type = 'comment'
  parentType = 'station'

  index: (req, res) ->
    res.send "TODO list #{type}s"

  new: (req, res) ->
    res.send "TODO new #{type}"

  create: (req, res) ->
    res.send "TODO create #{type}"

  show: (req, res) ->
    res.send "TODO show #{type} #{req.params[type]} of #{parentType} #{req.params[parentType]}"

  edit: (req, res) ->
    res.send "TODO edit #{type} #{req.params[type]}"

  update: (req, res) ->
    res.send "TODO update #{type} #{req.params[type]}"

  destroy: (req, res) ->
    res.send "TODO destroy #{type} #{req.params[type]}"


exports.init = (app) ->
  stations = app.resource 'stations', new StationResource()
  comments = app.resource 'comments', new CommentResource()
  # Make comments nested inside stations -> e.g. GET /stations/1/comments/3
  stations.add comments
