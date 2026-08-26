import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property real progress: 0
  property real percent: 0
  property int horizonWeeks: 4000
  property bool showYearScale: false
  property bool interactive: false
  property string tooltipText: "Memento Mori"

  readonly property int horizonYears: Math.max(1, Math.ceil(horizonWeeks / 52))
  readonly property int yearTickCount: Math.floor(horizonYears / 5) + 1

  signal activated()

  implicitHeight: Math.max(lifeLabel.implicitHeight,
    Style.space(showYearScale ? 24 : 16))

  Text {
    id: lifeLabel
    anchors.left: parent.left
    y: root.showYearScale ? 0 : Math.round((root.height - height) / 2)
    text: "LIFE"
    color: root.interactive && lifeMouse.containsMouse
      ? Style.hoverStateColor(root.foreground, Color.accent)
      : Qt.darker(root.foreground, 1.5)
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    font.letterSpacing: 1
  }

  Text {
    id: lifePercent
    anchors.right: parent.right
    y: root.showYearScale ? 0 : Math.round((root.height - height) / 2)
    text: Number(root.percent).toFixed(1).replace(/\.0$/, "") + "%"
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  Rectangle {
    id: track
    anchors.left: lifeLabel.right
    anchors.right: lifePercent.left
    anchors.leftMargin: Style.space(12)
    anchors.rightMargin: Style.space(12)
    y: root.showYearScale
      ? Math.round((lifeLabel.implicitHeight - height) / 2)
      : Math.round((root.height - height) / 2)
    height: Style.space(6)
    radius: Style.cornerRadius > 0 ? height / 2 : 0
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

    Rectangle {
      width: Math.round(parent.width * Math.max(0, Math.min(1, root.progress)))
      height: parent.height
      radius: parent.radius
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.34)

      Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    Rectangle {
      // The rail mirrors the grid grammar: lived time is subdued, the exact
      // present is the sole accent, and the remaining horizon recedes.
      width: Math.max(Style.spacing.hairline * 2, Style.space(3))
      height: parent.height + Style.space(6)
      x: Math.round(Math.max(0, Math.min(parent.width - width,
        parent.width * Math.max(0, Math.min(1, root.progress)) - width / 2)))
      anchors.verticalCenter: parent.verticalCenter
      radius: width / 2
      color: Color.accent

      Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
  }

  Item {
    id: yearScale
    visible: root.showYearScale
    anchors.left: track.left
    anchors.right: track.right
    y: track.y + track.height + Style.space(2)
    height: Style.space(8)

    Repeater {
      model: root.yearTickCount

      Item {
        required property int index
        readonly property int year: index * 5
        readonly property bool decade: year % 10 === 0
        x: Math.round(yearScale.width * year / root.horizonYears)
        width: 1
        height: yearScale.height

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: Style.spacing.hairline
          height: parent.decade ? Style.space(2) : Style.spacing.hairline
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b,
            parent.decade ? 0.18 : 0.1)
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: Style.space(2)
          visible: parent.decade
          text: index === 0 ? "Y 0" : String(parent.year)
          color: Qt.darker(root.foreground, 2)
          font.family: root.fontFamily
          font.pixelSize: Math.max(7, Style.font.caption - 2)
        }
      }
    }
  }

  MouseArea {
    id: lifeMouse
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated()

    PanelToolTip {
      visible: lifeMouse.containsMouse && root.tooltipText !== ""
      text: root.tooltipText
      fontFamily: root.fontFamily
    }
  }
}
