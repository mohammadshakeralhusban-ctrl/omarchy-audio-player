import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "Model.js" as Model

Item {
  id: root

  property var shell: null

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: selectActivePlayer()
  readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle || activePlayer.trackArtist)
  readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""
  readonly property string album: activePlayer && activePlayer.trackAlbum ? activePlayer.trackAlbum : ""
  readonly property string artUrl: activePlayer && activePlayer.trackArtUrl ? activePlayer.trackArtUrl : ""

  property string genre: ""
  property bool genreLoaded: false
  property bool genreSearching: false
  property bool vocal: false
  property bool vocalLoaded: false

  property string lastQueryedSignature: ""

  property string lastTitle: ""
  property string lastArtist: ""
  property string lastAlbum: ""
  property string lastArtUrl: ""

  readonly property string stickyTitle: title || lastTitle
  readonly property string stickyArtist: artist || lastArtist
  readonly property string stickyAlbum: album || lastAlbum
  readonly property string stickyArtUrl: artUrl || lastArtUrl

  function snapshotSticky() {
    if (!hasMedia) return
    if (title) lastTitle = title
    if (artist) lastArtist = artist
    if (album) lastAlbum = album
    if (artUrl) lastArtUrl = artUrl
  }

  function isProxyPlayer(player) {
    return Model.isProxyPlayer(player)
  }

  function hasTrackMetadata(player) {
    return !!(player && (player.trackTitle || player.trackArtist || player.trackAlbum || player.trackArtUrl))
  }

  function playerCanControl(player) {
    return !!(player && (player.canTogglePlaying || player.canPlay || player.canPause || player.canGoNext || player.canGoPrevious))
  }

  function playerKey(player) {
    if (!player) return ""
    return String(player.dbusName || player.desktopEntry || player.identity || "")
  }

  property var activityPositions: ({})
  property string preferredKey: ""
  property int _activityTick: 0

  Timer {
    id: activityTimer
    interval: 1000
    repeat: true
    running: true
    onTriggered: root.scanActivity()
  }

  function scanActivity() {
    var now = Date.now()
    for (var i = 0; i < players.length; i++) {
      var p = players[i]
      if (!p) continue
      var key = playerKey(p)
      if (!key) continue
      var sig = Model.trackSignature(p.trackTitle, p.trackArtist) + "\x1e" + (p.trackAlbum || "")
      var entry = root.activityPositions[key]
      if (!entry) {
        root.activityPositions[key] = { sig: sig, time: now }
      } else if (entry.sig !== sig) {
        entry.sig = sig
        entry.time = now
      }
    }
    root._activityTick++
  }

  function recencyTime(player) {
    if (!player) return 0
    var e = root.activityPositions[playerKey(player)]
    return e ? e.time : 0
  }

  function browserLike(player) {
    var s = String(playerKey(player) + " " + (player.desktopEntry || "") + " " + (player.identity || "")).toLowerCase()
    return s.indexOf("chromium") !== -1 || s.indexOf("chrome") !== -1 || s.indexOf("firefox") !== -1
  }

  function betterCandidate(a, b) {
    var ta = root.recencyTime(a)
    var tb = root.recencyTime(b)
    if (ta !== tb) return ta > tb
    var ba = root.browserLike(a)
    var bb = root.browserLike(b)
    return !ba && bb
  }

  function selectActivePlayer() {
    var tick = root._activityTick
    var bestPlaying = null
    var bestAny = null
    var controllable = null
    var playing = null
    var last = null

    for (var i = 0; i < players.length; i++) {
      var p = players[i]
      if (!p || isProxyPlayer(p)) continue

      if (!bestAny || betterCandidate(p, bestAny)) bestAny = p
      if (p.isPlaying && (!bestPlaying || betterCandidate(p, bestPlaying))) bestPlaying = p
      if (p.isPlaying && !playing) playing = p
      if (playerCanControl(p) && !controllable) controllable = p
      if (hasTrackMetadata(p)) last = p
    }

    if (preferredKey) {
      for (var j = 0; j < players.length; j++) {
        var q = players[j]
        if (!q || isProxyPlayer(q)) continue
        if (playerKey(q) === preferredKey && hasTrackMetadata(q)) return q
      }
    }

    return bestPlaying || bestAny || playing || controllable || last || null
  }

  function playerForAction(action) {
    if (activePlayer && playerCanControl(activePlayer)) return activePlayer
    for (var i = 0; i < players.length; i++) {
      var p = players[i]
      if (!p || isProxyPlayer(p)) continue
      if (playerCanControl(p)) return p
    }
    return activePlayer
  }

  function runAction(action) {
    var player = playerForAction(action)
    if (!player) return false
    if (playerKey(player)) root.preferredKey = playerKey(player)
    if (action === "playPause") {
      if (player.isPlaying && player.canPause) { player.pause(); return true }
      if (!player.isPlaying && player.canPlay) { player.play(); return true }
      if (player.canTogglePlaying) { player.togglePlaying(); return true }
    } else if (action === "next" && player.canGoNext) {
      player.next(); return true
    } else if (action === "previous" && player.canGoPrevious) {
      player.previous(); return true
    }
    return false
  }

  onActivePlayerChanged: {
    snapshotSticky()
    genre = ""
    vocal = false
    genreLoaded = false
    genreSearching = false
    vocalLoaded = false
    lastQueryedSignature = ""
    lookupGenre()
  }

  onTitleChanged: { snapshotSticky(); lookupGenre() }
  onArtistChanged: { snapshotSticky(); lookupGenre() }

  function lookupGenre() {
    if (!activePlayer || !title) return
    var sig = Model.trackSignature(title, artist)
    if (sig === lastQueryedSignature) return
    lastQueryedSignature = sig

    var cachedGenre = Model.genreCacheGet(title, artist)
    if (cachedGenre !== null) {
      genre = cachedGenre
      genreLoaded = true
      genreSearching = false
    } else {
      genre = ""
      genreLoaded = false
      genreSearching = true
    }

    var cachedVocal = Model.vocalCacheGet(title, artist)
    if (cachedVocal !== null) {
      vocal = cachedVocal
      vocalLoaded = true
    } else {
      vocal = false
      vocalLoaded = false
    }

    var searchUrl = Model.buildSearchUrl(title, artist)
    if (searchUrl) {
      searchProc.command = ["/usr/bin/curl", "-fsS", "--max-time", "8",
        "--max-filesize", "2097152",
        "-H", "User-Agent: CaelestiaAudioPlayer/1.0",
        searchUrl]
      searchProc.running = true
    } else {
      genreLoaded = true
      genreSearching = false
    }
  }

  Process {
    id: searchProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (root.lastQueryedSignature !== Model.trackSignature(root.title, root.artist)) return
        var parsed = Model.parseRecordingSearch(text)
        if (!parsed || !parsed.mbid) {
          root.genreLoaded = true
          root.genreSearching = false
          return
        }
        var lookupUrl = Model.buildLookupUrl(parsed.mbid)
        if (lookupUrl) {
          lookupProc.command = ["/usr/bin/curl", "-fsS", "--max-time", "8",
            "--max-filesize", "2097152",
            "-H", "User-Agent: CaelestiaAudioPlayer/1.0",
            lookupUrl]
          lookupProc.running = true
        } else {
          root.genreLoaded = true
          root.genreSearching = false
        }
      }
    }
  }

  Process {
    id: lookupProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (root.lastQueryedSignature !== Model.trackSignature(root.title, root.artist)) return
        var parsed = Model.parseRecordingLookup(text)
        if (!parsed) {
          root.genreLoaded = true
          root.genreSearching = false
          return
        }

        var newGenre = parsed.genre || ""
        Model.genreCachePut(root.title, root.artist, newGenre)
        root.genre = newGenre
        root.genreLoaded = true
        root.genreSearching = false

        var newVocal = parsed.vocal !== null ? parsed.vocal : true
        Model.vocalCachePut(root.title, root.artist, newVocal)
        root.vocal = newVocal
        root.vocalLoaded = true
      }
    }
  }

  IpcHandler {
    target: "caelestia-audio"

    function status(): string {
      var p = activePlayer
      return JSON.stringify({
        hasPlayer: p !== null,
        hasMedia: root.hasMedia,
        playing: p ? !!p.isPlaying : false,
        title: p ? (p.trackTitle || "") : "",
        artist: p ? (p.trackArtist || "") : "",
        album: p && p.trackAlbum ? p.trackAlbum : "",
        artUrl: p && p.trackArtUrl ? p.trackArtUrl : "",
        genre: root.genre,
        vocal: root.vocal,
        genreLoaded: root.genreLoaded,
        genreSearching: root.genreSearching,
        vocalLoaded: root.vocalLoaded,
        stickyTitle: root.stickyTitle,
        stickyArtist: root.stickyArtist,
        stickyAlbum: root.stickyAlbum,
        stickyArtUrl: root.stickyArtUrl,
        canGoNext: p ? !!p.canGoNext : false,
        canGoPrevious: p ? !!p.canGoPrevious : false,
        canTogglePlaying: p ? !!p.canTogglePlaying : false,
        playerIdentity: p ? (p.identity || p.desktopEntry || "") : ""
      })
    }

    function playPause(): string {
      return root.runAction("playPause") ? "ok" : "unhandled"
    }

    function next(): string {
      return root.runAction("next") ? "ok" : "unhandled"
    }

    function previous(): string {
      return root.runAction("previous") ? "ok" : "unhandled"
    }

    function ping(): string {
      return "ok"
    }
  }
}
