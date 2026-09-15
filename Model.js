var _genreCache = ({})
var _vocalCache = ({})

function trackSignature(title, artist) {
  return (title || "") + "\x1f" + (artist || "")
}

function cacheGet(cache, key) {
  if (!key) return null
  return cache[key] !== undefined ? cache[key] : null
}

function cachePut(cache, key, value) {
  if (!key) return
  cache[key] = value
}

function isProxyPlayer(player) {
  var dbus = String(player && player.dbusName || "").toLowerCase()
  var desktop = String(player && player.desktopEntry || "").toLowerCase()
  return dbus.indexOf("playerctld") !== -1 || desktop === "playerctld"
}

function parseRecordingSearch(text) {
  var raw = String(text || "").trim()
  if (!raw) return null
  try {
    var data = JSON.parse(raw)
    var recs = data.recordings
    if (!recs || !recs.length) return { mbid: null, artistMbid: "" }
    var top = recs[0]
    var artistMbid = ""
    if (top["artist-credit"] && top["artist-credit"][0]) {
      var a = top["artist-credit"][0].artist
      if (a) artistMbid = a.id || ""
    }
    return { mbid: top.id || null, artistMbid: artistMbid }
  } catch (e) {
    return null
  }
}

function parseRecordingLookup(text) {
  var raw = String(text || "").trim()
  if (!raw) return null
  try {
    var data = JSON.parse(raw)
    if (data.error) return null
    var genres = data.genres || []
    var tags = data.tags || []
    var genre = extractTopGenre(genres, tags)
    var instrumental = isInstrumental(tags)
    var vocal = genre ? !instrumental : null
    return { genre: genre, vocal: vocal, isInstrumental: instrumental }
  } catch (e) {
    return null
  }
}

function extractTopGenre(genres, tags) {
  if (genres && genres.length) {
    var sorted = genres.slice().sort(function(a, b) {
      return (b.count || 0) - (a.count || 0)
    })
    var name = (sorted[0].name || "").trim()
    if (name) return name
  }
  if (tags && tags.length) {
    var sorted = tags.slice().sort(function(a, b) {
      return (b.count || 0) - (a.count || 0)
    })
    var name = (sorted[0].name || "").trim()
    if (name) return name
  }
  return ""
}

function isInstrumental(tags) {
  if (!tags || !tags.length) return false
  for (var i = 0; i < tags.length; i++) {
    var name = String(tags[i].name || "").toLowerCase()
    if (name === "instrumental" || name === "no vocals" || name === "no lyrics"
        || name === "instrumental rock" || name === "instrumental hip hop")
      return true
  }
  return false
}

function formatBadge(genre, isVocal) {
  var parts = []
  if (genre) parts.push(capitalize(genre))
  if (isVocal === true) parts.push("Vocal")
  else if (isVocal === false) parts.push("Instrumental")
  return parts.length ? parts.join(" \u00b7 ") : ""
}

function capitalize(str) {
  if (!str) return ""
  return str.charAt(0).toUpperCase() + str.slice(1)
}

function buildSearchUrl(title, artist) {
  if (!title || !artist) return ""
  var query = "recording:\"" + title + "\" AND artist:\"" + artist + "\""
  return "https://musicbrainz.org/ws/2/recording/"
    + "?query=" + encodeURIComponent(query)
    + "&limit=1&fmt=json"
}

function buildLookupUrl(mbid) {
  if (!mbid) return ""
  return "https://musicbrainz.org/ws/2/recording/" + mbid
    + "?inc=tags+genres&fmt=json"
}

function genreCacheGet(title, artist) {
  return cacheGet(_genreCache, trackSignature(title, artist))
}

function genreCachePut(title, artist, value) {
  cachePut(_genreCache, trackSignature(title, artist), value)
}

function vocalCacheGet(title, artist) {
  return cacheGet(_vocalCache, trackSignature(title, artist))
}

function vocalCachePut(title, artist, value) {
  cachePut(_vocalCache, trackSignature(title, artist), value)
}

if (typeof module !== "undefined") {
  module.exports = {
    trackSignature: trackSignature,
    cacheGet: cacheGet,
    cachePut: cachePut,
    isProxyPlayer: isProxyPlayer,
    parseRecordingSearch: parseRecordingSearch,
    parseRecordingLookup: parseRecordingLookup,
    extractTopGenre: extractTopGenre,
    isInstrumental: isInstrumental,
    formatBadge: formatBadge,
    capitalize: capitalize,
    buildSearchUrl: buildSearchUrl,
    buildLookupUrl: buildLookupUrl,
    genreCacheGet: genreCacheGet,
    genreCachePut: genreCachePut,
    vocalCacheGet: vocalCacheGet,
    vocalCachePut: vocalCachePut
  }
}
