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
  readonly property int compactCanvasHeight: Style.space(128)
  readonly property int compactYearSpan: fittedCompactYearSpan()
  property int windowYearStart: 0
  property bool axisToggleHovered: false

  readonly property var stats: Model.lifeStats(birthKey, today, horizonWeeks)
  readonly property int totalLifeYears: Math.max(1, Math.ceil(horizonWeeks / 52))
  readonly property int visibleYearCount: Math.min(compactYearSpan, totalLifeYears)
  readonly property int visibleYearStart: Math.max(0,
    Math.min(totalLifeYears - visibleYearCount, windowYearStart))
  readonly property int visibleRowCount: visibleYearCount
  readonly property bool canPanEarlier: visibleYearStart > 0
  readonly property bool canPanLater: visibleYearStart + visibleYearCount < totalLifeYears

  property var cells: []
  property int hoveredIndex: -1

  signal backRequested()

  clip: true
  boundsBehavior: Flickable.StopAtBounds
  contentWidth: width
  contentHeight: contentColumn.implicitHeight
  interactive: false

  function refreshCells(resetWindow) {
    cells = Model.projectionCells(projection, birthKey, today, horizonWeeks)
    hoveredIndex = -1
    if (resetWindow) resetToNow()
    else windowYearStart = Math.max(0,
      Math.min(totalLifeYears - visibleYearCount, windowYearStart))
    lifeCanvas.requestPaint()
  }

  function columns() {
    return projection === "months" ? 12 : 52
  }

  function gap() {
    return projection === "months" ? Style.space(2) : Style.space(1)
  }

  function quarterGap() {
    return projection === "months" ? Style.space(4) : 0
  }

  function weekCellSize() {
    var available = Math.max(Style.space(260), lifeCanvas.width - lifeCanvas.leftGutter - lifeCanvas.rightGutter)
    return Math.max(Style.space(3), (available - 51 * Style.space(1)) / 52)
  }

  function cellWidth() {
    if (projection === "months") {
      var available = Math.max(Style.space(260), lifeCanvas.width - lifeCanvas.leftGutter - lifeCanvas.rightGutter)
      return Math.max(Style.space(14),
        (available - 11 * gap() - 3 * quarterGap()) / 12)
    }
    return weekCellSize()
  }

  function cellHeight() {
    return weekCellSize()
  }

  function columnOffset(column) {
    var offset = column * (cellWidth() + gap())
    if (projection === "months") offset += Math.floor(column / 3) * quarterGap()
    return offset
  }

  function rowOffset(row) {
    return row * (cellHeight() + gap())
  }

  function gridWidth() {
    return columns() * cellWidth() + Math.max(0, columns() - 1) * gap()
      + (projection === "months" ? 3 * quarterGap() : 0)
  }

  function gridHeight() {
    return visibleRowCount * cellHeight() + Math.max(0, visibleRowCount - 1) * gap()
  }

  function compactGridHeight() {
    return Math.max(cellHeight(), compactCanvasHeight - lifeCanvas.topGutter - Style.space(2))
  }

  function fittedCompactYearSpan() {
    var conservativeGap = Style.space(2)
    return Math.max(3, Math.min(totalLifeYears,
      Math.floor((compactGridHeight() + conservativeGap) / (cellHeight() + conservativeGap))))
  }

  function gridOriginX() {
    var available = lifeCanvas.width - lifeCanvas.leftGutter - lifeCanvas.rightGutter
    return lifeCanvas.leftGutter + Math.max(0, (available - gridWidth()) / 2)
  }

  function gridOriginY() {
    return lifeCanvas.topGutter + Math.max(0, (compactGridHeight() - gridHeight()) / 2)
  }

  function currentLifeYear() {
    return Math.max(0, Math.min(totalLifeYears - 1, Math.floor(stats.currentWeek / 52)))
  }

  function defaultWindowStart() {
    return Model.temporalViewportStart(currentLifeYear(), totalLifeYears, compactYearSpan)
  }

  function resetToNow() {
    windowYearStart = defaultWindowStart()
    contentY = 0
    hoveredIndex = -1
    lifeCanvas.requestPaint()
  }

  function panRows(delta) {
    windowYearStart = Math.max(0, Math.min(totalLifeYears - visibleYearCount, visibleYearStart + delta))
    hoveredIndex = -1
    lifeCanvas.requestPaint()
  }

  function setProjection(value) {
    if (value !== "weeks" && value !== "months") return
    if (projection === value) return
    projection = value
  }

  function toggleProjection() {
    setProjection(projection === "weeks" ? "months" : "weeks")
  }

  function firstVisibleIndex() {
    if (projection === "weeks") return visibleYearStart * 52
    return visibleYearStart * 12
  }

  function lastVisibleIndex() {
    var count = projection === "weeks"
      ? visibleYearCount * 52
      : visibleYearCount * 12
    return Math.min(cells.length, firstVisibleIndex() + count)
  }

  function currentGridRow() {
    var first = firstVisibleIndex()
    var last = lastVisibleIndex()
    for (var i = first; i < last; i++) {
      if (cells[i].status === "current") return Math.floor((i - first) / columns())
    }
    return -1
  }

  function hitTest(x, y) {
    var localX = x - gridOriginX()
    var localY = y - gridOriginY()
    if (localX < 0 || localY < 0 || localX >= gridWidth() || localY >= gridHeight()) return -1
    var rowStride = cellHeight() + gap()
    var localRow = Math.floor(localY / rowStride)
    if (localY - localRow * rowStride > cellHeight()) return -1
    var column = -1
    for (var candidate = 0; candidate < columns(); candidate++) {
      var start = columnOffset(candidate)
      if (localX >= start && localX <= start + cellWidth()) {
        column = candidate
        break
      }
    }
    if (column < 0) return -1
    var index = firstVisibleIndex() + localRow * columns() + column
    return index >= firstVisibleIndex() && index < lastVisibleIndex() ? index : -1
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
        marks.push({ position: (month + 0.5) * 52 / 12 - 0.5,
          label: String(month + 1), major: (month + 1) % 3 === 0 })
    } else {
      for (var exactMonth = 0; exactMonth < 12; exactMonth++)
        marks.push({ position: exactMonth, label: String(exactMonth + 1),
          major: (exactMonth + 1) % 3 === 0 })
    }
    return marks
  }

  function axisMarkX(position) {
    if (projection === "months") return columnOffset(position) + cellWidth() / 2
    return position * (cellWidth() + gap()) + cellWidth() / 2
  }

  function axisToggleContains(x, y) {
    var originX = gridOriginX()
    var originY = gridOriginY()
    return x >= originX - Style.space(20) && x <= originX - Style.space(2)
      && y >= originY - Style.space(18) && y <= originY - Style.space(2)
  }

  function verticalMarks() {
    var candidates = [0, currentGridRow(), visibleRowCount - 1]
    var marks = []
    var seen = {}
    for (var i = 0; i < candidates.length; i++) {
      var row = candidates[i]
      if (row < 0 || row >= visibleRowCount || seen[row]) continue
      seen[row] = true
      marks.push({ row: row, age: visibleYearStart + row,
        current: row === currentGridRow() })
    }
    return marks
  }

  onProjectionChanged: refreshCells(false)
  onBirthKeyChanged: refreshCells(true)
  onTodayChanged: refreshCells(true)
  onHorizonWeeksChanged: refreshCells(true)
  onWidthChanged: lifeCanvas.requestPaint()
  Component.onCompleted: refreshCells(true)

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
      horizonWeeks: root.horizonWeeks
      showYearScale: true
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

    Item {
      width: parent.width
      height: Math.max(cellReadout.implicitHeight, readoutActions.implicitHeight, Style.space(18))

      Text {
        id: cellReadout
        readonly property var cell: root.currentCell()
        anchors.left: parent.left
        anchors.right: readoutActions.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        text: Model.projectionReadout(cell, root.projection, root.today)
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
      }

      Row {
        id: readoutActions
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        PanelActionButton {
          id: nowButton
          visible: root.visibleYearStart !== root.defaultWindowStart()
          iconText: "󰑐"
          tooltipText: "Return to now"
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.resetToNow()
        }

      }
    }

    Canvas {
      id: lifeCanvas
      readonly property real leftGutter: Style.space(42)
      readonly property real rightGutter: Style.space(14)
      readonly property real topGutter: Style.space(20)

      width: parent.width
      height: root.compactCanvasHeight

      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)
        if (!root.cells || root.cells.length === 0) return

        var cellWidth = root.cellWidth()
        var cellHeight = root.cellHeight()
        var columns = root.columns()
        var axis = root.axisMarks()
        var originX = root.gridOriginX()
        var originY = root.gridOriginY()

        ctx.font = Style.font.caption + "px " + root.fontFamily
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillStyle = Qt.darker(root.foreground, 1.8)
        ctx.textAlign = "right"
        ctx.fillStyle = Qt.darker(root.foreground, 1.8)
        ctx.fillText("Y ↓", originX - Style.space(24), originY - Style.space(10))
        ctx.fillStyle = root.axisToggleHovered ? Color.accent : Qt.darker(root.foreground, 1.8)
        ctx.fillText("M →", originX - Style.space(4), originY - Style.space(10))

        ctx.textAlign = "center"
        for (var a = 0; a < axis.length; a++) {
          var markX = originX + root.axisMarkX(axis[a].position)
          ctx.fillText(axis[a].label, markX, originY - Style.space(10))
          var tickHeight = axis[a].major ? Style.space(5) : Style.space(3)
          ctx.fillRect(markX, originY - tickHeight, Style.spacing.hairline, tickHeight)
        }

        var vertical = root.verticalMarks()
        ctx.textAlign = "right"
        for (var v = 0; v < vertical.length; v++) {
          ctx.fillStyle = vertical[v].current
            ? Color.accent
            : Qt.darker(root.foreground, 1.8)
          ctx.fillText(String(vertical[v].age), originX - Style.space(4),
            originY + root.rowOffset(vertical[v].row) + cellHeight / 2)
        }

        // The current row is the viewport's attention band. It remains quiet
        // enough to preserve the one-cell accent while making "now" legible
        // as the default focal depth of the sliding window.
        var nowRow = root.currentGridRow()
        if (nowRow >= 0 && nowRow < root.visibleRowCount) {
          var bandAccent = Color.accent
          ctx.fillStyle = Qt.rgba(bandAccent.r, bandAccent.g, bandAccent.b, 0.055)
          ctx.fillRect(originX - Style.space(2), originY + root.rowOffset(nowRow) - Style.space(1),
            root.gridWidth() + Style.space(4), cellHeight + Style.space(2))
        }

        var firstIndex = root.firstVisibleIndex()
        var lastIndex = root.lastVisibleIndex()
        for (var i = firstIndex; i < lastIndex; i++) {
          var cell = root.cells[i]
          var localIndex = i - firstIndex
          var column = localIndex % columns
          var cellRow = Math.floor(localIndex / columns)
          var x = originX + root.columnOffset(column)
          var y = originY + root.rowOffset(cellRow)
          var accent = Color.accent

          if (cell.status === "lived") {
            ctx.fillStyle = Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.34)
            ctx.fillRect(x, y, cellWidth, cellHeight)
          } else if (cell.status === "current") {
            ctx.fillStyle = accent
            ctx.fillRect(x, y, cellWidth, cellHeight)
          } else {
            ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22)
            ctx.lineWidth = Style.spacing.hairline
            ctx.strokeRect(x + 0.5, y + 0.5, Math.max(0, cellWidth - 1), Math.max(0, cellHeight - 1))
          }

          if (i === root.hoveredIndex) {
            ctx.strokeStyle = root.foreground
            ctx.lineWidth = Math.max(1, Style.spacing.hairline)
            ctx.strokeRect(x, y, cellWidth, cellHeight)
          }
        }

        // Small edge cues disclose that compact mode is a movable viewport
        // rather than a cropped dataset.
        ctx.textAlign = "center"
        ctx.fillStyle = Qt.darker(root.foreground, 1.9)
        if (root.canPanEarlier)
          ctx.fillText("↑", width - rightGutter / 2, originY + cellHeight / 2)
        if (root.canPanLater)
          ctx.fillText("↓", width - rightGutter / 2, originY + root.gridHeight() - cellHeight / 2)
      }

      WheelHandler {
        onWheel: function(event) {
          if (event.angleDelta.y === 0) return
          root.panRows(event.angleDelta.y > 0 ? -1 : 1)
        }
      }

      MouseArea {
        id: gridMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: root.axisToggleHovered ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPositionChanged: function(mouse) {
          var overToggle = root.axisToggleContains(mouse.x, mouse.y)
          if (overToggle !== root.axisToggleHovered) {
            root.axisToggleHovered = overToggle
            lifeCanvas.requestPaint()
          }
          var next = root.hitTest(mouse.x, mouse.y)
          if (next !== root.hoveredIndex) {
            root.hoveredIndex = next
            lifeCanvas.requestPaint()
          }
        }
        onExited: {
          root.axisToggleHovered = false
          root.hoveredIndex = -1
          lifeCanvas.requestPaint()
        }
        onClicked: function(mouse) {
          if (root.axisToggleContains(mouse.x, mouse.y)) root.toggleProjection()
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
              ? Color.accent
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
