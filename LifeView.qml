import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

Flickable {
  id: root

  property string birthKey: ""
  property date today: new Date()
  property int horizonWeeks: 4000
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property string projection: "weeks"

  readonly property var stats: Model.lifeStats(birthKey, today, horizonWeeks)
  property var cells: []
  property int hoveredIndex: -1
  property real hoverX: 0
  property real hoverY: 0

  signal backRequested()

  clip: true
  boundsBehavior: Flickable.StopAtBounds
  contentWidth: width
  contentHeight: contentColumn.implicitHeight
  interactive: contentHeight > height

  function refreshCells() {
    cells = Model.projectionCells(projection, birthKey, today, horizonWeeks)
    hoveredIndex = -1
    lifeCanvas.requestPaint()
  }

  function columns() {
    return projection === "weeks" ? 52 : projection === "months" ? 12 : 10
  }

  function rows() {
    var count = cells ? cells.length : 0
    return Math.max(1, Math.ceil(count / columns()))
  }

  function gap() {
    return projection === "years" ? Style.space(5) : projection === "months" ? Style.space(2) : Style.space(1)
  }

  function weekCellSize() {
    var available = Math.max(Style.space(260), lifeCanvas.width - lifeCanvas.leftGutter)
    return Math.max(Style.space(3), (available - 51 * Style.space(1)) / 52)
  }

  function cellSize() {
    return projection === "years" ? Math.max(Style.space(22), weekCellSize() * 2.5) : weekCellSize()
  }

  function gridWidth() {
    return columns() * cellSize() + Math.max(0, columns() - 1) * gap()
  }

  function gridHeight() {
    return rows() * cellSize() + Math.max(0, rows() - 1) * gap()
  }

  function hitTest(x, y) {
    var localX = x - lifeCanvas.leftGutter
    var localY = y - lifeCanvas.topGutter
    if (localX < 0 || localY < 0 || localX >= gridWidth() || localY >= gridHeight()) return -1
    var stride = cellSize() + gap()
    var column = Math.floor(localX / stride)
    var row = Math.floor(localY / stride)
    if (localX - column * stride > cellSize() || localY - row * stride > cellSize()) return -1
    var index = row * columns() + column
    return index >= 0 && index < cells.length ? index : -1
  }

  function currentCell() {
    if (hoveredIndex >= 0 && hoveredIndex < cells.length) return cells[hoveredIndex]
    for (var i = 0; i < cells.length; i++) if (cells[i].status === "current") return cells[i]
    return cells.length > 0 ? cells[Math.min(stats.livedWeeks, cells.length - 1)] : null
  }

  function axisColumns() {
    if (projection === "weeks") return [0, 12, 25, 38, 51]
    var values = []
    for (var i = 0; i < columns(); i++) values.push(i)
    return values
  }

  function axisLabel(column) {
    if (projection === "weeks") return String(column + 1)
    return String(column + 1)
  }

  onProjectionChanged: refreshCells()
  onBirthKeyChanged: refreshCells()
  onTodayChanged: refreshCells()
  onHorizonWeeksChanged: refreshCells()
  onWidthChanged: lifeCanvas.requestPaint()
  Component.onCompleted: refreshCells()

  Column {
    id: contentColumn
    width: root.width
    spacing: Style.space(10)

    Item {
      width: parent.width
      height: Math.max(backButton.implicitHeight, titleColumn.implicitHeight)

      PanelActionButton {
        id: backButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        iconText: "󰅁"
        tooltipText: "Back to calendar"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.backRequested()
      }

      Column {
        id: titleColumn
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(2)

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "MEMENTO MORI"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.subtitle
          font.bold: true
          font.letterSpacing: 1
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.horizonWeeks.toLocaleString(Qt.locale("en_US"), "f", 0) + "-WEEK HORIZON"
          color: Qt.darker(root.foreground, 1.6)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1
        }
      }
    }

    LifeRail {
      width: parent.width
      foreground: root.foreground
      fontFamily: root.fontFamily
      progress: root.stats.progress
      percent: root.stats.percent
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignRight
      text: root.stats.livedWeeks.toLocaleString(Qt.locale("en_US"), "f", 0)
        + " weeks lived · "
        + root.stats.remainingWeeks.toLocaleString(Qt.locale("en_US"), "f", 0)
        + " remaining"
      color: Qt.darker(root.foreground, 1.6)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    ButtonGroup {
      anchors.horizontalCenter: parent.horizontalCenter
      options: [
        { value: "weeks", label: "WEEKS" },
        { value: "months", label: "MONTHS" },
        { value: "years", label: "YEARS" }
      ]
      value: root.projection
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onChanged: function(value) { root.projection = value }
    }

    Text {
      readonly property var cell: root.currentCell()
      width: parent.width
      height: Math.max(implicitHeight, Style.space(18))
      text: cell ? cell.primary + " · " + cell.secondary : ""
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }

    Canvas {
      id: lifeCanvas
      readonly property real leftGutter: Style.space(30)
      readonly property real topGutter: Style.space(20)

      width: parent.width
      height: topGutter + root.gridHeight() + Style.space(2)

      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)
        if (!root.cells || root.cells.length === 0) return

        var size = root.cellSize()
        var stride = size + root.gap()
        var columns = root.columns()
        var axis = root.axisColumns()

        ctx.font = Style.font.caption + "px " + root.fontFamily
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillStyle = Qt.darker(root.foreground, 1.8)
        for (var a = 0; a < axis.length; a++) {
          var axisColumn = axis[a]
          ctx.fillText(root.axisLabel(axisColumn), leftGutter + axisColumn * stride + size / 2, topGutter / 2)
        }

        ctx.textAlign = "right"
        var rowStep = root.projection === "years" ? 1 : 5
        for (var row = 0; row < root.rows(); row += rowStep) {
          var age = root.projection === "years" ? row * 10 : row
          ctx.fillText(String(age), leftGutter - Style.space(6), topGutter + row * stride + size / 2)
        }

        for (var i = 0; i < root.cells.length; i++) {
          var cell = root.cells[i]
          var column = i % columns
          var cellRow = Math.floor(i / columns)
          var x = leftGutter + column * stride
          var y = topGutter + cellRow * stride
          var accent = Style.selectedStateColor(root.foreground, Color.accent)

          if (cell.status === "lived") {
            ctx.fillStyle = Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.34)
            ctx.fillRect(x, y, size, size)
          } else if (cell.status === "current") {
            ctx.fillStyle = accent
            ctx.fillRect(x, y, size, size)
          } else {
            ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22)
            ctx.lineWidth = Style.spacing.hairline
            ctx.strokeRect(x + 0.5, y + 0.5, Math.max(0, size - 1), Math.max(0, size - 1))
          }

          if (i === root.hoveredIndex) {
            ctx.strokeStyle = root.foreground
            ctx.lineWidth = Math.max(1, Style.spacing.hairline)
            ctx.strokeRect(x, y, size, size)
          }
        }
      }

      MouseArea {
        id: gridMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: function(mouse) {
          root.hoverX = mouse.x
          root.hoverY = mouse.y
          var next = root.hitTest(mouse.x, mouse.y)
          if (next !== root.hoveredIndex) {
            root.hoveredIndex = next
            lifeCanvas.requestPaint()
          }
        }
        onExited: {
          root.hoveredIndex = -1
          lifeCanvas.requestPaint()
        }

        PanelToolTip {
          readonly property var cell: root.hoveredIndex >= 0 ? root.cells[root.hoveredIndex] : null
          visible: cell !== null && gridMouse.containsMouse
          text: cell ? cell.primary + "\n" + cell.secondary : ""
          fontFamily: root.fontFamily
          x: Math.min(gridMouse.width - implicitWidth, Math.max(0, root.hoverX + Style.space(8)))
          y: Math.max(0, root.hoverY - implicitHeight - Style.space(8))
        }
      }
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(18)

      Repeater {
        model: [
          { label: "LIVED", opacity: 0.34, accent: false },
          { label: "NOW", opacity: 1, accent: true },
          { label: "FUTURE", opacity: 0.22, accent: false }
        ]

        Row {
          required property var modelData
          spacing: Style.space(6)

          Rectangle {
            width: Style.space(8)
            height: width
            anchors.verticalCenter: parent.verticalCenter
            radius: Style.cornerRadius > 0 ? 1 : 0
            color: modelData.accent
              ? Style.selectedStateColor(root.foreground, Color.accent)
              : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, modelData.opacity)
          }

          Text {
            text: modelData.label
            color: Qt.darker(root.foreground, 1.6)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.letterSpacing: 1
          }
        }
      }
    }
  }
}
