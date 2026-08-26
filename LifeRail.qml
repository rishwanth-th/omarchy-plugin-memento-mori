import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property real progress: 0
  property real percent: 0
  property bool interactive: false
  property string tooltipText: "Memento Mori"

  signal activated()

  implicitHeight: Math.max(lifeLabel.implicitHeight, Style.space(16))

  Text {
    id: lifeLabel
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
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
    anchors.verticalCenter: parent.verticalCenter
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
    anchors.verticalCenter: parent.verticalCenter
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
