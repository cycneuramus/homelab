[Server]
address = "0.0.0.0"
port = 8080
https = false  # disable to enable cookies when not using https
httpMaxConnections = 100
staticDir = "./public"
title = "nitter"
hostname = "nitter.example.com"

[Cache]
listMinutes = 240  # how long to cache list info (not the tweets, so keep it high)
rssMinutes = 10  # how long to cache rss queries
redisHost = {{ env "NOMAD_IP_redis" }}
redisPort = {{ env "NOMAD_HOST_PORT_redis" }}
redisPassword = ""
redisConnections = 20 # connection pool size
redisMaxConnections = 30
# max, new connections are opened when none are available, but if the pool size
# goes above this, they're closed when released. don't worry about this unless
# you receive tons of requests per second

[Config]
hmacKey = "" # random key for cryptographic signing of video urls
base64Media = false # use base64 encoding for proxied media urls
enableRss = false
enableDebug = false
proxy = ""
proxyAuth = ""
tokenCount = 10
# minimum amount of usable tokens. tokens are used to authorize API requests,
# but they expire after ~1 hour, and have a limit of 187 requests.
# the limit gets reset every 15 minutes, and the pool is filled up so there's
# always at least $tokenCount usable tokens. again, only increase this if
# you receive major bursts all the time

# Change default preferences here, see src/prefs_impl.nim for a complete list
[Preferences]
theme = "Nitter"
replaceTwitter = "nitter.example.com"
replaceYouTube = ""
replaceReddit = ""
replaceInstagram = ""
proxyVideos = true
hlsPlayback = true
infiniteScroll = false
