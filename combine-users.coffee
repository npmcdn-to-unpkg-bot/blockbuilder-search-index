###
This script draws in potential user names from several different sources and
combines them into one list of unique usernames
###

d3 = require 'd3'
request = require 'request'
fs = require 'fs'

userHash = {}

total = 0

parseBlockURL = (url) ->
  parts = url.split('//bl.ocks.org/')
  return if !parts[1]
  parts2 = parts[1].split('/')
  return if parts2.length == 1
  username = parts2[0]
  return if parseInt(username).toString() == username
  return if username.indexOf("#") >= 0
  return if username == "d"
  return username

# STACK OVERFLOW ---------------------------------------------------------------
# https://numeracy.co/projects/3PM9W1edMyC
# pull usernames out of block links found on StackOverflow, h/t @sirwart
blocksStr = fs.readFileSync('data/user-sources/bl.ocks.org-links.tsv').toString()
blocksLinks = d3.tsv.parse(blocksStr)
blocksLinks.forEach (d) ->
  username = parseBlockURL(d.url)
  userHash[username] = 1

blocksusers = Object.keys(userHash).length
total = blocksusers
console.log("#{blocksusers} users from blocks links in SO")



# KNIGHT EXAMPLES --------------------------------------------------------------
# pull usernames out of block links from the knight d3 course, h/t @micahstubbs
# https://docs.google.com/spreadsheets/d/1ByK9bGUrC-VT9xmdnHmrFMXZ-mEapCY2J6OlS1kf4eU/edit#gid=737064445
blocksStr = fs.readFileSync('data/user-sources/knight-d3-blocks-links.csv').toString()
blocksLinks2 = d3.csv.parse(blocksStr)
blocksLinks2.forEach (d) ->
  username = parseBlockURL(d.url)
  userHash[username] = 1
blocksusers2 = Object.keys(userHash).length
total += blocksusers2
console.log("#{blocksusers2} users from blocks links in knight course")


# BLOCKBUILDER USERS -----------------------------------------------------------
# collect the usernames found in a dump of the public github profiles stored in blockbuilder
string = fs.readFileSync('data/user-sources/blockbuilder-users.json').toString()
string.split("\n").forEach (userStr) ->
  try
    user = JSON.parse(userStr)
    return unless user?.login
    userHash[user.login] = 1
  catch e

bbusers = Object.keys(userHash).length - total
total += bbusers
console.log("#{bbusers} users added from bb")


# MANUALLY CURATED USERS -------------------------------------------------------
# a list of manually currated users, h/t @d3visualization
userscsv = fs.readFileSync('data/user-sources/manually-curated.csv').toString()
d3.csv.parse userscsv, (user) ->
  username = user["username"]?.toLowerCase()
  return unless username
  userHash[username] = 1

csvusers = Object.keys(userHash).length - total
total += csvusers
console.log("#{csvusers} added from manual list of users")


# BL.OCKSPLORER FORM SUBMISSIONS ------------------------------------------------
# pull from the Google form provided by @ireneros @bocoup for blockscanner & http://bl.ocksplorer.org/ 
# https://docs.google.com/forms/d/1VdDdycNuqJVw3Ik6-ZLj6v7X9g2vWlw_RCC3RCfD9-I/viewform
userDoc = "https://docs.google.com/spreadsheet/pub?key=0Al5UYaVoRpW3dE12bzRTVEp2RlJDQXdUYUFmODNiTHc&single=true&gid=0&output=csv";
column = 'Provide a github username to the person whose blocks (gists) we should scan for d3 API usage'
request.get userDoc, (err, response, body) ->
  d3.csv.parse body, (user) ->
    username = user[column]?.toLowerCase()
    return unless username
    userHash[username] = 1

  usernames = Object.keys(userHash)
  console.log("#{usernames.length - total} users added from blocksplorer")
  total += usernames.length - total
  console.log("#{usernames.length} users total")
  usernames = usernames.sort()

  users =  "username\n" + usernames.join("\n")

  fs.writeFileSync("data/users-combined.csv", users)
