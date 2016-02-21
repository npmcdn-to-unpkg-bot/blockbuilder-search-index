fs = require 'fs'
d3 = require 'd3'
async = require 'async'
request = require 'request'

gh = require './github'

parse = (err, body) ->
  return null if err
  try
    return JSON.parse body
  catch e
    return null

username = process.argv[2]
if username
  gh.getUser username, (err, response, body) ->
    u = parse(err, body)
    console.log u.login, u.public_gists
else
  usersString = fs.readFileSync('data/users-combined.csv').toString()
  users = d3.csv.parse usersString
  usables = []
  async.eachLimit users, 5, (user, userCb) ->
    gh.getUser user.username, (err, response, body) ->
      console.log user.username, err if err
      u = parse(err, body)
      console.log user.username, u?.public_gists
      console.log "x-ratelimit-remaining:", response?.headers['x-ratelimit-remaining']
      return userCb() unless u
      #console.log err, response, u
      if u.public_gists > 0
        usables.push u.login
      #if u.public_gists == 0
      #  console.log "no gists", u.login
      setTimeout ->
        userCb()
      , 100
  , ->
    usables = usables.sort()
    str = "username\n" + usables.join("\n")
    console.log "#{usables.length} have at least 1 gist"
    fs.writeFileSync "data/usables.csv", str