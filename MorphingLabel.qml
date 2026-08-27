import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string currentText: ""
  property string previousText: ""
  property real progress: 1
  property bool active: false
  property color textColor: Color.accent
  property color shimmerColor: Color.foreground
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.caption

  readonly property real clampedProgress: Math.max(0, Math.min(1, progress))
  readonly property real envelopeWidth: Math.min(width,
    Math.max(currentMeasure.implicitWidth, previousMeasure.implicitWidth)
      + Style.space(4))

  implicitHeight: Math.max(currentMeasure.implicitHeight,
    previousMeasure.implicitHeight)
  clip: true

  Text {
    id: currentMeasure
    visible: false
    text: root.currentText
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
  }

  Text {
    id: previousMeasure
    visible: false
    text: root.previousText
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
  }

  Text {
    anchors.fill: parent
    visible: !root.active
    horizontalAlignment: Text.AlignHCenter
    text: root.currentText
    color: root.textColor
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    elide: Text.ElideRight
  }

  Item {
    id: morphField
    visible: root.active
    anchors.horizontalCenter: parent.horizontalCenter
    width: root.envelopeWidth
    height: parent.height
    clip: true

    Item {
      id: previousClip
      x: morphField.width * root.clampedProgress
      width: Math.max(0, morphField.width - x)
      height: parent.height
      clip: true

      Text {
        x: -previousClip.x
        width: morphField.width
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        text: root.previousText
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        elide: Text.ElideRight
      }
    }

    Item {
      width: morphField.width * root.clampedProgress
      height: parent.height
      clip: true

      Text {
        width: morphField.width
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        text: root.currentText
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        elide: Text.ElideRight
      }
    }

    Rectangle {
      visible: root.clampedProgress > 0 && root.clampedProgress < 1
      x: Math.round(morphField.width * root.clampedProgress - width / 2)
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(Style.space(24), Math.max(Style.space(12), morphField.width / 3))
      height: Math.max(Style.space(6), Math.min(parent.height, root.fontSize))
      opacity: 4 * root.clampedProgress * (1 - root.clampedProgress)

      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
          position: 0
          color: Qt.rgba(root.shimmerColor.r, root.shimmerColor.g,
            root.shimmerColor.b, 0)
        }
        GradientStop {
          position: 0.5
          color: Qt.rgba(root.shimmerColor.r, root.shimmerColor.g,
            root.shimmerColor.b, 0.34)
        }
        GradientStop {
          position: 1
          color: Qt.rgba(root.shimmerColor.r, root.shimmerColor.g,
            root.shimmerColor.b, 0)
        }
      }
    }
  }
}
