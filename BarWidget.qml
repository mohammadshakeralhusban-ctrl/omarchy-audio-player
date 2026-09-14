import QtQuick
import qs.Ui
import qs.Commons
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "mohammad284284.caelestia-audio"

  readonly property var svc: bar?.shell?.firstPartyServiceFor("mohammad284284.caelestia-audio")
  readonly property var player: svc ? svc.activePlayer : null
  readonly property bool hasMedia: svc ? svc.hasMedia : false

  readonly property string playIcon: (player && player.isPlaying) ? "󰏤" : "󰐊"
  readonly property bool hasSticky: svc ? !!(svc.stickyTitle || svc.stickyArtist) : false
  readonly property string stickyTitle: svc && svc.stickyTitle ? svc.stickyTitle : ""
  readonly property string stickyArtist: svc && svc.stickyArtist ? svc.stickyArtist : ""
  readonly property string stickyArtUrl: svc && svc.stickyArtUrl ? svc.stickyArtUrl : ""
  readonly property string barLabel: hasMedia || hasSticky
    ? ((stickyTitle || "") + (stickyArtist ? "  ·  " + stickyArtist : ""))
    : "No audio"

  property bool popupOpen: false
  property real maxLabelWidth: Math.min(220, Math.max(120, bar ? bar.barSize * 2 : 220))

  function close() { popupOpen = false }

  readonly property real labelRegion: scrollClip.visible ? scrollClip.width : 0
  readonly property real arrowPad: Style.space(14)
  readonly property bool hasContext: hasMedia || hasSticky
  implicitWidth: arrowPad + Style.space(6)
    + glyphLabel.implicitWidth
    + (labelRegion > 0 ? Style.space(6) + labelRegion : 0)
    + Style.space(6) + arrowPad
    + Style.space(16)
  implicitHeight: barSize

  Row {
    id: barRow
    anchors.centerIn: parent
    spacing: Style.space(6)

    Item {
      id: prevBtn
      width: root.arrowPad
      height: glyphLabel.height
      anchors.verticalCenter: parent.verticalCenter
      opacity: root.hasContext && player && player.canGoPrevious ? 1.0 : 0.45

      Text {
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: "󰓛"
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body

        Behavior on color {
          enabled: !root.bar || root.bar.foregroundAnimationEnabled
          ColorAnimation { duration: 160 }
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: root.hasContext ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: function(mouse) {
          if (root.hasContext && root.svc) root.svc.runAction("previous")
          mouse.accepted = true
        }
      }
    }

    Text {
      id: glyphLabel
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: (hasMedia || hasSticky) ? root.playIcon : "󰝚"
      color: (hasMedia || hasSticky) ? root.bar.barForeground : Qt.darker(root.bar.barForeground, 1.5)
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body

      Behavior on color {
        enabled: !root.bar || root.bar.foregroundAnimationEnabled
        ColorAnimation { duration: 160 }
      }
    }

    Item {
      id: scrollClip
      width: Math.min(root.maxLabelWidth, labelText.implicitWidth)
      height: glyphLabel.height
      clip: true
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.bar.vertical

      Text {
        id: labelText
        textFormat: Text.PlainText
        text: root.barLabel
        color: (hasMedia || hasSticky) ? root.bar.barForeground : Qt.darker(root.bar.barForeground, 1.5)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        anchors.verticalCenter: parent.verticalCenter

        property bool needsScroll: implicitWidth > scrollClip.width

        NumberAnimation on x {
          running: labelText.needsScroll && !root.popupOpen && !root.bar.vertical
          loops: Animation.Infinite
          duration: Math.max(6000, labelText.implicitWidth * 25)
          from: scrollClip.width
          to: -labelText.implicitWidth
          easing.type: Easing.Linear
        }

        Behavior on color {
          enabled: !root.bar || root.bar.foregroundAnimationEnabled
          ColorAnimation { duration: 160 }
        }
      }
    }

    Item {
      id: nextBtn
      width: root.arrowPad
      height: glyphLabel.height
      anchors.verticalCenter: parent.verticalCenter
      opacity: root.hasContext && player && player.canGoNext ? 1.0 : 0.45

      Text {
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: "󰓞"
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body

        Behavior on color {
          enabled: !root.bar || root.bar.foregroundAnimationEnabled
          ColorAnimation { duration: 160 }
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: root.hasContext ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: function(mouse) {
          if (root.hasContext && root.svc) root.svc.runAction("next")
          mouse.accepted = true
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: (root.hasMedia || root.hasSticky) ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (!root.svc) return
      if (mouse.button === Qt.MiddleButton) root.svc.runAction("next")
      else if (mouse.button === Qt.RightButton) root.popupOpen = !root.popupOpen
      else if (root.hasMedia || root.hasSticky) root.svc.runAction("playPause")
    }
    onWheel: function(wheel) {
      if (!root.svc || !(root.hasMedia || root.hasSticky)) return
      if (wheel.angleDelta.y > 0) root.svc.runAction("previous")
      else if (wheel.angleDelta.y < 0) root.svc.runAction("next")
    }
    onEntered: {
      if (!root.bar) return
      if (root.hasMedia || root.hasSticky) root.bar.showTooltip(root, root.barLabel)
    }
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(300))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        spacing: Style.space(10)
        width: parent.width

        BorderSurface {
          width: Style.space(64)
          height: Style.space(64)
          radius: Style.spacing.labelGap
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

          Image {
            anchors.fill: parent
            anchors.margins: Style.space(2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: root.stickyArtUrl
            visible: source !== ""
          }

          Text {
            anchors.centerIn: parent
            visible: root.stickyArtUrl === ""
            text: "󰝚"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
          }
        }

        Column {
          spacing: Style.space(4)
          width: parent.width - Style.space(74)

          Text {
            textFormat: Text.PlainText
            text: root.stickyTitle !== "" ? root.stickyTitle : "Nothing playing"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            textFormat: Text.PlainText
            text: root.stickyArtist
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }

          Text {
            textFormat: Text.PlainText
            text: root.svc && root.svc.stickyAlbum ? root.svc.stickyAlbum : ""
            color: Qt.darker(root.bar.foreground, 1.6)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }
        }
      }

      BorderSurface {
        id: genreBadge
        anchors.horizontalCenter: parent.horizontalCenter
        width: genreText.implicitWidth + Style.space(14)
        height: Style.space(22)
        radius: Math.max(1, Style.space(11))
        visible: genreText.text !== ""
        color: root.svc && root.svc.genreSearching
          ? Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.08)
          : Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.16)
        borderSpec: Border.none()

        Text {
          id: genreText
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: {
            if (!root.svc) return ""
            if (root.svc.genreSearching) return "Looking up..."
            return Model.formatBadge(root.svc.genre, root.svc.vocalLoaded ? root.svc.vocal : null)
          }
          color: root.svc && root.svc.genreSearching ? Qt.darker(root.bar.foreground, 1.5) : Color.accent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)

        Button {
          iconText: "󰒮"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          enabled: root.player && root.player.canGoPrevious
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.svc) root.svc.runAction("previous")
        }

        Button {
          iconText: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.panelGap
          verticalPadding: Style.spacing.controlPaddingY
          iconSize: Style.font.iconLarge
          enabled: root.player && (root.player.canTogglePlaying || root.player.canPlay || root.player.canPause)
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.svc) root.svc.runAction("playPause")
        }

        Button {
          iconText: "󰒭"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          enabled: root.player && root.player.canGoNext
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.svc) root.svc.runAction("next")
        }
      }
    }
  }
}
