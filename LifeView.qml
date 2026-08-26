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
  property bool expanded: false
  property int compactRowCount: 24
  property int windowRowStart: 0

  readonly property var stats: Model.lifeStats(birthKey, today, horizonWeeks)
  readonly property int totalRows: Math.max(1, Math.ceil((cells ? cells.length : 0) / columns()))
  readonly property int visibleRowCount: expanded || projection === "years"
    ? totalRows
    : Math.min(compactRowCount, totalRows)
  readonly property int visibleRowStart: expanded || projection === "years"
    ? 0
    : Math.max(0, Math.min(totalRows - visibleRowCount, windowRowStart))
  readonly property bool canPanEarlier: !expanded && projection !== "years" && visibleRowStart > 0
  readonly property bool canPanLater: !expanded && projection !== "years"
    && visibleRowStart + visibleRowCount < totalRows

  property var cells: []
  property int hoveredIndex: -1

  signal backRequested()

  clip: true
  boundsBehavior: Flickable.StopAtBounds
  contentWidth: width
  contentHeight: contentColumn.implicitHeight
  interactive: expanded && contentHeight > height

  function refreshCells() {
    cells = Model.projectionCells(projection, birthKey, today, horizonWeeks)
    hoveredIndex = -1
    resetToNow()
    lifeCanvas.requestPaint()
  }

  function columns() {
    return projection === "weeks" ? 52 : projection === "months" ? 12 : 10
  }

  function gap() {
    return projection === "years" ? Style.space(5) : projection === "months" ? Style.space(2) : Style.space(1)
  }

  function weekCellSize() {
    var available = Math.max(Style.space(260), lifeCanvas.width - lifeCanvas.leftGutter - lifeCanvas.rightGutter)
    return Math.max(Style.space(3), (available - 51 * Style.space(1)) / 52)
  }

  function cellSize() {
    return projection === "years" ? Math.max(Style.space(22), weekCellSize() * 2.5) : weekCellSize()
  }

  function gridWidth() {
    return columns() * cellSize() + Math.max(0, columns() - 1) * gap()
  }

  function gridHeight() {
    return visibleRowCount * cellSize() + Math.max(0, visibleRowCount - 1) * gap()
  }

  // The compact frame is projection-independent. Months and Years collapse
  // inside it instead of changing the panel's geometry under the pointer.
  function compactGridHeight() {
    var size = weekCellSize()
    return compactRowCount * size + Math.max(0, compactRowCount - 1) * Style.space(2)
  }

  function gridOriginX() {
    var available = lifeCanvas.width - lifeCanvas.leftGutter - lifeCanvas.rightGutter
    return lifeCanvas.leftGutter + Math.max(0, (available - gridWidth()) / 2)
  }

  function gridOriginY() {
    if (expanded) return lifeCanvas.topGutter
    return lifeCanvas.topGutter + Math.max(0, (compactGridHeight() - gridHeight()) / 2)
  }

  function currentRow() {
    for (var i = 0; i < cells.length; i++) {
      if (cells[i].status === "current") return Math.floor(i / columns())
    }
    return cells.length > 0 ? totalRows - 1 : 0
  }

  function defaultWindowStart() {
    return Model.temporalViewportStart(currentRow(), totalRows, compactRowCount)
  }

  function resetToNow() {
    windowRowStart = defaultWindowStart()
    contentY = 0
    hoveredIndex = -1
    lifeCanvas.requestPaint()
  }

  function panRows(delta) {
    if (expanded || projection === "years") return
    windowRowStart = Math.max(0, Math.min(totalRows - visibleRowCount, visibleRowStart + delta))
    hoveredIndex = -1
    lifeCanvas.requestPaint()
  }

  function toggleExpanded() {
    if (projection === "years") return
    expanded = !expanded
    contentY = 0
    hoveredIndex = -1
    lifeCanvas.requestPaint()
  }

  function setProjection(value) {
    if (projection === value) return
    if (value === "years") expanded = false
    projection = value
  }

  function hitTest(x, y) {
    var localX = x - gridOriginX()
    var localY = y - gridOriginY()
    if (localX < 0 || localY < 0 || localX >= gridWidth() || localY >= gridHeight()) return -1
    var stride = cellSize() + gap()
    var column = Math.floor(localX / stride)
    var localRow = Math.floor(localY / stride)
    if (localX - column * stride > cellSize() || localY - localRow * stride > cellSize()) return -1
    var index = (visibleRowStart + localRow) * columns() + column
    return index >= 0 && index < cells.length ? index : -1
  }

  function currentCell() {
    if (hoveredIndex >= 0 && hoveredIndex < cells.length) return cells[hoveredIndex]
    for (var i = 0; i < cells.length; i++) if (cells[i].status === "current") return cells[i]
    return cells.length > 0 ? cells[cells.length - 1] : null
  }

  function axisMarks() {
    var marks = []
    if (projection === "weeks") {
      // Twelve proportional life-month landmarks orient the 52-week row;
      // exact calendar intervals remain in the canonical hover readout.
      for (var month = 0; month < 12; month++)
        marks.push({ position: (month + 0.5) * 52 / 12 - 0.5, label: "M" + (month + 1) })
    } else if (projection === "months") {
      for (var quarter = 0; quarter < 4; quarter++)
        marks.push({ position: quarter * 3 + 1, label: "Q" + (quarter + 1) })
    } else {
      for (var year = 0; year < 10; year++)
        marks.push({ position: year, label: "Y" + (year + 1) })
    }
    return marks
  }

  onProjectionChanged: refreshCells()
  onBirthKeyChanged: refreshCells()
  onTodayChanged: refreshCells()
  onHorizonWeeksChanged: refreshCells()
  onExpandedChanged: {
    hoveredIndex = -1
    contentY = 0
    lifeCanvas.requestPaint()
  }
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

      PanelActionButton {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.projection !== "years"
        iconText: root.expanded ? "󰁄" : "󰁌"
        tooltipText: root.expanded ? "Return to current view" : "Show the whole horizon"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.toggleExpanded()
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
      onChanged: function(value) { root.setProjection(value) }
    }

    Item {
      width: parent.width
      height: Math.max(cellReadout.implicitHeight, nowButton.implicitHeight, Style.space(18))

      Text {
        id: cellReadout
        readonly property var cell: root.currentCell()
        anchors.left: parent.left
        anchors.right: nowButton.visible ? nowButton.left : parent.right
        anchors.rightMargin: nowButton.visible ? Style.space(8) : 0
        anchors.verticalCenter: parent.verticalCenter
        text: cell ? cell.primary + " · " + cell.secondary : ""
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
      }

      PanelActionButton {
        id: nowButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.expanded && root.projection !== "years" && root.visibleRowStart !== root.defaultWindowStart()
        iconText: "󰑐"
        tooltipText: "Return to now"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.resetToNow()
      }
    }

    Canvas {
      id: lifeCanvas
      readonly property real leftGutter: Style.space(30)
      readonly property real rightGutter: Style.space(14)
      readonly property real topGutter: Style.space(20)

      width: parent.width
      height: topGutter + (root.expanded ? root.gridHeight() : root.compactGridHeight()) + Style.space(2)

      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)
        if (!root.cells || root.cells.length === 0) return

        var size = root.cellSize()
        var stride = size + root.gap()
        var columns = root.columns()
        var axis = root.axisMarks()
        var originX = root.gridOriginX()
        var originY = root.gridOriginY()

        ctx.font = Style.font.caption + "px " + root.fontFamily
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillStyle = Qt.darker(root.foreground, 1.8)
        for (var a = 0; a < axis.length; a++) {
          var markX = originX + axis[a].position * stride + size / 2
          ctx.fillText(axis[a].label, markX, originY - Style.space(10))
          ctx.fillRect(markX, originY - Style.space(4), Style.spacing.hairline, Style.space(3))
        }

        ctx.textAlign = "right"
        var rowStep = root.projection === "years" ? 1 : 5
        for (var localRow = 0; localRow < root.visibleRowCount; localRow++) {
          var absoluteRow = root.visibleRowStart + localRow
          var age = root.projection === "years" ? absoluteRow * 10 : absoluteRow
          if (absoluteRow % rowStep === 0)
            ctx.fillText(String(age), originX - Style.space(6), originY + localRow * stride + size / 2)
        }

        // The current row is the viewport's attention band. It remains quiet
        // enough to preserve the one-cell accent while making "now" legible
        // as the default focal depth of the sliding window.
        var nowRow = root.currentRow() - root.visibleRowStart
        if (nowRow >= 0 && nowRow < root.visibleRowCount) {
          var bandAccent = Style.selectedStateColor(root.foreground, Color.accent)
          ctx.fillStyle = Qt.rgba(bandAccent.r, bandAccent.g, bandAccent.b, 0.055)
          ctx.fillRect(originX - Style.space(2), originY + nowRow * stride - Style.space(1),
            root.gridWidth() + Style.space(4), size + Style.space(2))
        }

        var firstIndex = root.visibleRowStart * columns
        var lastIndex = Math.min(root.cells.length, (root.visibleRowStart + root.visibleRowCount) * columns)
        for (var i = firstIndex; i < lastIndex; i++) {
          var cell = root.cells[i]
          var column = i % columns
          var cellRow = Math.floor(i / columns) - root.visibleRowStart
          var x = originX + column * stride
          var y = originY + cellRow * stride
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

        // Small edge cues disclose that compact Weeks/Months is a movable
        // viewport rather than a cropped dataset. Absolute ages stay the
        // primary orientation; these only indicate continuation.
        ctx.textAlign = "center"
        ctx.fillStyle = Qt.darker(root.foreground, 1.9)
        if (root.canPanEarlier)
          ctx.fillText("↑", width - rightGutter / 2, originY + size / 2)
        if (root.canPanLater)
          ctx.fillText("↓", width - rightGutter / 2, originY + root.gridHeight() - size / 2)
      }

      WheelHandler {
        enabled: !root.expanded && root.projection !== "years"
        onWheel: function(event) {
          if (event.angleDelta.y === 0) return
          root.panRows(event.angleDelta.y > 0 ? -3 : 3)
        }
      }

      MouseArea {
        id: gridMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: function(mouse) {
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
