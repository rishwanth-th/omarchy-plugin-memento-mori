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
  readonly property int chromeHeight: titleBar.height + lifeRail.height
    + readoutRow.height + legendRow.implicitHeight + contentColumn.spacing * 4
  readonly property int compactCanvasHeight: Math.max(Style.space(128),
    Math.floor(root.height - chromeHeight))
  readonly property int compactYearSpan: fittedCompactYearSpan()
  property int windowYearStart: 0
  property bool horizontalAxisHovered: false
  property bool verticalAxisHovered: false
  property bool projectionToggleHovered: false
  property string morphFromProjection: ""
  property var morphFromCells: []
  property var morphSegments: []
  property var morphGeometry: []
  property var morphSourceRects: []
  property var morphTargetRects: []
  property real morphProgress: 1
  property bool preparingMorph: false
  property bool reducedMotion: false
  property bool dateOverlapEnabled: true
  readonly property int projectionMorphDuration: dateOverlapEnabled ? 520 : 360
  readonly property bool projectionMorphing: morphFromProjection !== "" && morphProgress < 1

  readonly property var stats: Model.lifeStats(birthKey, today, horizonWeeks)
  readonly property var projectionStats: Model.projectionStats(cells, projection)
  readonly property int presentCellIndex: findPresentIndex()
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
    if (!preparingMorph) finishProjectionMorph()
    cells = Model.projectionCells(projection, birthKey, today, horizonWeeks)
    hoveredIndex = -1
    if (resetWindow) resetToNow()
    else windowYearStart = Math.max(0,
      Math.min(totalLifeYears - visibleYearCount, windowYearStart))
    lifeCanvas.requestPaint()
  }

  function columnsFor(mode) {
    return mode === "months" ? 12 : 52
  }

  function columns() {
    return columnsFor(projection)
  }

  function columnGapFor(mode) {
    return mode === "months" ? Style.space(2) : Style.space(1)
  }

  function columnGap() {
    return columnGapFor(projection)
  }

  function rowGap() {
    return Style.space(1)
  }

  function quarterGapFor(mode) {
    return mode === "months" ? Style.space(4) : 0
  }

  function quarterGap() {
    return quarterGapFor(projection)
  }

  function weekCellSize() {
    var available = Math.max(Style.space(260), lifeCanvas.width - lifeCanvas.leftGutter - lifeCanvas.rightGutter)
    return Math.max(Style.space(3), (available - 51 * Style.space(1)) / 52)
  }

  function cellWidthFor(mode) {
    if (mode === "months") {
      var available = Math.max(Style.space(260), lifeCanvas.width - lifeCanvas.leftGutter - lifeCanvas.rightGutter)
      return Math.max(Style.space(14),
        (available - 11 * columnGapFor(mode) - 3 * quarterGapFor(mode)) / 12)
    }
    return weekCellSize()
  }

  function cellWidth() {
    return cellWidthFor(projection)
  }

  function cellHeight() {
    return weekCellSize()
  }

  function columnOffsetFor(mode, column) {
    var offset = column * (cellWidthFor(mode) + columnGapFor(mode))
    if (mode === "months") offset += Math.floor(column / 3) * quarterGapFor(mode)
    return offset
  }

  function columnOffset(column) {
    return columnOffsetFor(projection, column)
  }

  function rowOffset(row) {
    return row * (cellHeight() + rowGap())
  }

  function gridWidthFor(mode) {
    return columnsFor(mode) * cellWidthFor(mode)
      + Math.max(0, columnsFor(mode) - 1) * columnGapFor(mode)
      + (mode === "months" ? 3 * quarterGapFor(mode) : 0)
  }

  function gridWidth() {
    return gridWidthFor(projection)
  }

  function gridHeight() {
    return visibleRowCount * cellHeight() + Math.max(0, visibleRowCount - 1) * rowGap()
  }

  function compactGridHeight() {
    return Math.max(cellHeight(), compactCanvasHeight - lifeCanvas.topGutter - Style.space(2))
  }

  function fittedCompactYearSpan() {
    return Math.max(3, Math.min(totalLifeYears,
      Math.floor((compactGridHeight() + rowGap()) / (cellHeight() + rowGap()))))
  }

  function gridOriginXFor(mode) {
    var available = lifeCanvas.width - lifeCanvas.leftGutter - lifeCanvas.rightGutter
    return lifeCanvas.leftGutter + Math.max(0, (available - gridWidthFor(mode)) / 2)
  }

  function gridOriginX() {
    return gridOriginXFor(projection)
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
    finishProjectionMorph()
    windowYearStart = defaultWindowStart()
    contentY = 0
    hoveredIndex = -1
    lifeCanvas.requestPaint()
  }

  function panRows(delta) {
    finishProjectionMorph()
    windowYearStart = Math.max(0, Math.min(totalLifeYears - visibleYearCount, visibleYearStart + delta))
    hoveredIndex = -1
    lifeCanvas.requestPaint()
  }

  function clearProjectionMorph() {
    morphFromProjection = ""
    morphFromCells = []
    morphSegments = []
    morphGeometry = []
    morphSourceRects = []
    morphTargetRects = []
    lifeCanvas.requestPaint()
  }

  function finishProjectionMorph() {
    if (projectionMorphAnimation.running) projectionMorphAnimation.stop()
    morphProgress = 1
    clearProjectionMorph()
  }

  function setProjection(value) {
    if (value !== "weeks" && value !== "months") return
    if (projection === value) return

    finishProjectionMorph()
    var sourceProjection = projection
    var sourceCells = cells
    preparingMorph = true
    projection = value
    preparingMorph = false

    if (reducedMotion) return

    var sourceColumns = columnsFor(sourceProjection)
    var targetColumns = columnsFor(projection)
    var sourceFirst = Math.max(0,
      firstVisibleIndexFor(sourceProjection) - sourceColumns)
    var sourceLast = Math.min(sourceCells.length,
      firstVisibleIndexFor(sourceProjection) + (visibleRowCount + 1) * sourceColumns)
    var targetFirst = Math.max(0,
      firstVisibleIndexFor(projection) - targetColumns)
    var targetLast = Math.min(cells.length,
      firstVisibleIndexFor(projection) + (visibleRowCount + 1) * targetColumns)
    var segments = Model.projectionOverlapSegments(sourceCells, cells,
      sourceFirst, sourceLast, targetFirst, targetLast)

    if (segments.length === 0) return
    morphFromProjection = sourceProjection
    morphFromCells = sourceCells
    morphSegments = segments
    morphGeometry = buildMorphGeometry(sourceProjection, sourceCells, segments)
    morphSourceRects = visibleRectsFor(sourceProjection, sourceCells)
    morphTargetRects = visibleRectsFor(projection, cells)
    morphProgress = 0
    projectionMorphAnimation.start()
  }

  function toggleProjection() {
    setProjection(projection === "weeks" ? "months" : "weeks")
  }

  function firstVisibleIndexFor(mode) {
    return visibleYearStart * columnsFor(mode)
  }

  function firstVisibleIndex() {
    return firstVisibleIndexFor(projection)
  }

  function lastVisibleIndexFor(mode, intervalCells) {
    var values = intervalCells || []
    return Math.min(values.length,
      firstVisibleIndexFor(mode) + visibleYearCount * columnsFor(mode))
  }

  function lastVisibleIndex() {
    return lastVisibleIndexFor(projection, cells)
  }

  function segmentRect(mode, index, startFraction, endFraction) {
    var columnsInMode = columnsFor(mode)
    var localIndex = index - firstVisibleIndexFor(mode)
    var row = Math.floor(localIndex / columnsInMode)
    var column = localIndex - row * columnsInMode
    var width = cellWidthFor(mode)
    var start = Math.max(0, Math.min(1, startFraction))
    var end = Math.max(start, Math.min(1, endFraction))
    return {
      x: gridOriginXFor(mode) + columnOffsetFor(mode, column) + width * start,
      y: gridOriginY() + rowOffset(row),
      width: Math.max(Style.spacing.hairline, width * (end - start)),
      height: cellHeight()
    }
  }

  function visibleRectsFor(mode, intervalCells) {
    var rects = []
    var first = firstVisibleIndexFor(mode)
    var last = lastVisibleIndexFor(mode, intervalCells)
    for (var index = first; index < last; index++)
      rects.push(segmentRect(mode, index, 0, 1))
    return rects
  }

  function buildMorphGeometry(sourceProjection, sourceCells, segments) {
    var geometry = []
    for (var i = 0; i < segments.length; i++) {
      var segment = segments[i]
      var sourceCell = sourceCells[segment.sourceIndex]
      var targetCell = cells[segment.targetIndex]
      if (!sourceCell || !targetCell) continue
      geometry.push({
        sourceCell: sourceCell,
        targetCell: targetCell,
        sourceRect: segmentRect(sourceProjection, segment.sourceIndex,
          segment.sourceStart, segment.sourceEnd),
        targetRect: segmentRect(projection, segment.targetIndex,
          segment.targetStart, segment.targetEnd)
      })
    }
    return geometry
  }

  function currentGridRow() {
    var first = firstVisibleIndex()
    var last = lastVisibleIndex()
    for (var i = first; i < last; i++) {
      if (cells[i].status === "current") return Math.floor((i - first) / columns())
    }
    return -1
  }

  function currentGridColumn() {
    var first = firstVisibleIndex()
    var last = lastVisibleIndex()
    for (var i = first; i < last; i++) {
      if (cells[i].status === "current") return (i - first) % columns()
    }
    return -1
  }

  function findPresentIndex() {
    for (var i = 0; i < cells.length; i++) if (cells[i].status === "current") return i
    return -1
  }

  function inspectedIndex() {
    if (hoveredIndex >= firstVisibleIndex() && hoveredIndex < lastVisibleIndex())
      return hoveredIndex
    var present = presentCellIndex
    if (present >= firstVisibleIndex() && present < lastVisibleIndex()) return present
    return firstVisibleIndex() < lastVisibleIndex() ? firstVisibleIndex() : -1
  }

  function inspectedGridRow() {
    var index = inspectedIndex()
    return index >= firstVisibleIndex() && index < lastVisibleIndex()
      ? Math.floor((index - firstVisibleIndex()) / columns())
      : -1
  }

  function inspectedGridColumn() {
    var index = inspectedIndex()
    return index >= firstVisibleIndex() && index < lastVisibleIndex()
      ? (index - firstVisibleIndex()) % columns()
      : -1
  }

  function hitTest(x, y) {
    var localX = x - gridOriginX()
    var localY = y - gridOriginY()
    if (localX < 0 || localY < 0 || localX >= gridWidth() || localY >= gridHeight()) return -1
    var rowStride = cellHeight() + rowGap()
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

  function gridContains(x, y) {
    var localX = x - gridOriginX()
    var localY = y - gridOriginY()
    return localX >= 0 && localX < gridWidth()
      && localY >= 0 && localY < gridHeight()
  }

  function inspectedCell() {
    var index = inspectedIndex()
    return index >= 0 && index < cells.length ? cells[index] : null
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
    return position * (cellWidth() + columnGap()) + cellWidth() / 2
  }

  function horizontalAxisContains(x, y) {
    var originX = gridOriginX()
    var originY = gridOriginY()
    return x >= originX - Style.space(20) && x <= originX + gridWidth()
      && y >= originY - Style.space(18) && y <= originY - Style.space(2)
  }

  function projectionToggleContains(x, y) {
    var originX = gridOriginX()
    var originY = gridOriginY()
    return x >= originX - Style.space(20) && x <= originX - Style.space(2)
      && y >= originY - Style.space(18) && y <= originY - Style.space(2)
  }

  function verticalAxisContains(x, y) {
    var originX = gridOriginX()
    var originY = gridOriginY()
    var overLabel = x >= originX - lifeCanvas.leftGutter
      && x <= originX - Style.space(20)
      && y >= originY - Style.space(18) && y < originY
    var overScale = x >= originX - lifeCanvas.leftGutter
      && x <= originX - Style.space(2)
      && y >= originY && y <= originY + gridHeight()
    return overLabel || overScale
  }

  function verticalMarks() {
    var nowRow = currentGridRow()
    var inspectedRow = inspectedGridRow()
    var candidates = [0, nowRow, inspectedRow, visibleRowCount - 1]
    var firstMultiple = Math.ceil(visibleYearStart / 5) * 5
    for (var age = firstMultiple; age < visibleYearStart + visibleYearCount; age += 5)
      candidates.push(age - visibleYearStart)
    var marks = []
    var seen = {}
    for (var i = 0; i < candidates.length; i++) {
      var row = candidates[i]
      if (row < 0 || row >= visibleRowCount || seen[row]) continue
      seen[row] = true
      var markAge = visibleYearStart + row
      marks.push({ row: row, age: markAge,
        current: row === nowRow, inspected: row === inspectedRow,
        fiveYear: markAge % 5 === 0 })
    }
    marks.sort(function(a, b) { return a.row - b.row })
    return marks
  }

  onProjectionChanged: refreshCells(false)
  onBirthKeyChanged: refreshCells(true)
  onTodayChanged: refreshCells(true)
  onHorizonWeeksChanged: refreshCells(true)
  onWidthChanged: lifeCanvas.requestPaint()
  onMorphProgressChanged: lifeCanvas.requestPaint()
  Component.onCompleted: refreshCells(true)

  NumberAnimation {
    id: projectionMorphAnimation
    target: root
    property: "morphProgress"
    from: 0
    to: 1
    duration: root.projectionMorphDuration
    easing.type: root.dateOverlapEnabled ? Easing.Linear : Easing.InOutCubic
    onFinished: root.clearProjectionMorph()
  }

  Column {
    id: contentColumn
    width: root.width
    spacing: Style.space(6)

    Item {
      id: titleBar
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

      PanelActionButton {
        id: nowButton
        visible: root.visibleYearStart !== root.defaultWindowStart()
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        iconText: "󰑐"
        tooltipText: "Return to now"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.resetToNow()
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
      id: lifeRail
      width: parent.width
      foreground: root.foreground
      fontFamily: root.fontFamily
      progress: root.stats.progress
      percent: root.stats.percent
      horizonWeeks: root.horizonWeeks
      showYearScale: true
      showSegmentLabels: true
      livedLabel: root.projectionStats.lived.toLocaleString(Qt.locale("en_US"), "f", 0)
        + " " + root.projectionStats.unit + " lived"
      remainingLabel: root.projectionStats.remaining.toLocaleString(Qt.locale("en_US"), "f", 0)
        + " remaining"
    }

    Item {
      id: readoutRow
      width: parent.width
      height: Math.max(dateReadout.implicitHeight, Style.space(18))

      readonly property var cell: root.inspectedCell()
      readonly property var readout: Model.projectionReadoutParts(cell, root.projection, root.today)

      Text {
        id: dateRangeMeasure
        visible: false
        text: "31–2099 DEC 31"
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        id: dateMonthMeasure
        visible: false
        text: "SEP"
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        id: dateYearMeasure
        visible: false
        text: "2099"
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Row {
        id: dateReadout
        anchors.centerIn: parent
        spacing: Style.space(6)

        Item {
          width: dateYearMeasure.implicitWidth
          height: dateYear.implicitHeight

          Text {
            id: dateYear
            anchors.left: parent.left
            text: readoutRow.readout ? readoutRow.readout.dateYear : ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        Item {
          width: dateMonthMeasure.implicitWidth
          height: dateMonth.implicitHeight

          Text {
            id: dateMonth
            anchors.horizontalCenter: parent.horizontalCenter
            text: readoutRow.readout ? readoutRow.readout.dateMonth : ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        Item {
          width: dateRangeMeasure.implicitWidth
          height: dateRange.implicitHeight

          Text {
            id: dateRange
            anchors.left: parent.left
            text: readoutRow.readout ? readoutRow.readout.dateRange : ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
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

      function paintCell(ctx, cell, rect, opacity, hovered) {
        if (!cell || !rect || opacity <= 0) return
        var alpha = Math.max(0, Math.min(1, opacity))
        var accent = Color.accent

        if (cell.status === "lived") {
          ctx.fillStyle = Qt.rgba(root.foreground.r, root.foreground.g,
            root.foreground.b, 0.34 * alpha)
          ctx.fillRect(rect.x, rect.y, rect.width, rect.height)
        } else if (cell.status === "current") {
          ctx.fillStyle = Qt.rgba(accent.r, accent.g, accent.b, alpha)
          ctx.fillRect(rect.x, rect.y, rect.width, rect.height)
        } else {
          ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g,
            root.foreground.b, 0.22 * alpha)
          ctx.lineWidth = Style.spacing.hairline
          ctx.strokeRect(rect.x + 0.5, rect.y + 0.5,
            Math.max(0, rect.width - 1), Math.max(0, rect.height - 1))
        }

        if (hovered && alpha >= 0.99) {
          ctx.strokeStyle = root.foreground
          ctx.lineWidth = Math.max(1, Style.spacing.hairline * 2)
          var inset = ctx.lineWidth / 2
          ctx.strokeRect(rect.x + inset, rect.y + inset,
            Math.max(0, rect.width - ctx.lineWidth),
            Math.max(0, rect.height - ctx.lineWidth))
        }
      }

      function paintProjection(ctx, mode, intervalCells, opacity, hoveredIndex) {
        if (!intervalCells || opacity <= 0) return
        var first = root.firstVisibleIndexFor(mode)
        var last = root.lastVisibleIndexFor(mode, intervalCells)
        for (var index = first; index < last; index++)
          paintCell(ctx, intervalCells[index], root.segmentRect(mode, index, 0, 1),
            opacity, index === hoveredIndex)
      }

      function clampUnit(value) {
        return Math.max(0, Math.min(1, value))
      }

      function smoothUnit(value) {
        var x = clampUnit(value)
        return x * x * (3 - 2 * x)
      }

      function paintProjectionSeam(ctx, t) {
        var sourceLeft = root.gridOriginXFor(root.morphFromProjection)
        var targetLeft = root.gridOriginXFor(root.projection)
        var sourceRight = sourceLeft + root.gridWidthFor(root.morphFromProjection)
        var targetRight = targetLeft + root.gridWidthFor(root.projection)
        var left = sourceLeft + (targetLeft - sourceLeft) * t
        var right = sourceRight + (targetRight - sourceRight) * t
        var seamX = left + (right - left) * t

        // The two resolutions never overlap: superimposing 52 and 12 columns
        // creates a moire fan even when every cell is stationary.
        ctx.save()
        ctx.beginPath()
        ctx.rect(0, 0, Math.max(0, seamX), height)
        ctx.clip()
        paintProjection(ctx, root.projection, root.cells, 1, -1)
        ctx.restore()

        ctx.save()
        ctx.beginPath()
        ctx.rect(seamX, 0, Math.max(0, width - seamX), height)
        ctx.clip()
        paintProjection(ctx, root.morphFromProjection, root.morphFromCells, 1, -1)
        ctx.restore()

        // Mark the local change in resolution without implying that a week
        // has one spatial destination inside a calendar month.
        var seamAlpha = Math.sin(Math.PI * t) * 0.22
        ctx.fillStyle = Qt.rgba(root.foreground.r, root.foreground.g,
          root.foreground.b, seamAlpha)
        ctx.fillRect(seamX, root.gridOriginY() - Style.space(2),
          Style.spacing.hairline, root.gridHeight() + Style.space(4))
      }

      function paintProjectionWireframe(ctx, rects, opacity) {
        if (!rects || opacity <= 0) return
        ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g,
          root.foreground.b, opacity)
        ctx.lineWidth = Style.spacing.hairline
        for (var index = 0; index < rects.length; index++) {
          var rect = rects[index]
          ctx.strokeRect(rect.x + 0.5, rect.y + 0.5,
            Math.max(0, rect.width - 1), Math.max(0, rect.height - 1))
        }
      }

      function paintOverlapFragment(ctx, sourceCell, targetCell, rect, opacity) {
        if (!sourceCell || !targetCell || opacity <= 0) return
        var isPresent = sourceCell.status === "current" && targetCell.status === "current"
        var color = isPresent ? Color.accent : root.foreground
        var alpha = isPresent ? Math.min(1, opacity * 1.18) : opacity

        if (isPresent || targetCell.status === "lived") {
          ctx.fillStyle = Qt.rgba(color.r, color.g, color.b,
            alpha * (isPresent ? 0.92 : 0.24))
          ctx.fillRect(rect.x, rect.y, rect.width, rect.height)
        } else {
          ctx.strokeStyle = Qt.rgba(color.r, color.g, color.b, alpha * 0.28)
          ctx.lineWidth = Style.spacing.hairline
          ctx.strokeRect(rect.x + 0.5, rect.y + 0.5,
            Math.max(0, rect.width - 1), Math.max(0, rect.height - 1))
        }
      }

      function paintDateOverlapMorph(ctx, t) {
        var arrivalEnd = 0.40
        var resolveStart = 0.60
        var geometryProgress
        if (t < arrivalEnd)
          geometryProgress = 0.5 * smoothUnit(t / arrivalEnd)
        else if (t <= resolveStart)
          geometryProgress = 0.5
        else
          geometryProgress = 0.5 + 0.5 * smoothUnit((t - resolveStart)
            / (1 - resolveStart))

        var sourceSettled = 1 - smoothUnit(t / 0.30)
        var targetSettled = smoothUnit((t - 0.70) / 0.30)
        var interference
        if (t < arrivalEnd) interference = smoothUnit(t / arrivalEnd)
        else if (t <= resolveStart) interference = 1
        else interference = 1 - smoothUnit((t - resolveStart) / (1 - resolveStart))
        var wireOpacity = 0.09 * interference
        var fragmentOpacity = 0.66 * interference

        paintProjection(ctx, root.morphFromProjection, root.morphFromCells,
          sourceSettled, -1)

        // At the midpoint the two exact sampling grids coexist only as quiet
        // outlines. Their beat pattern is real 52-week versus calendar-month
        // interference, not an independently drawn decorative texture.
        paintProjectionWireframe(ctx, root.morphSourceRects, wireOpacity)
        paintProjectionWireframe(ctx, root.morphTargetRects, wireOpacity)

        for (var i = 0; i < root.morphGeometry.length; i++) {
          var geometry = root.morphGeometry[i]
          var sourceRect = geometry.sourceRect
          var targetRect = geometry.targetRect
          var rect = {
            x: sourceRect.x + (targetRect.x - sourceRect.x) * geometryProgress,
            y: sourceRect.y + (targetRect.y - sourceRect.y) * geometryProgress,
            width: sourceRect.width + (targetRect.width - sourceRect.width)
              * geometryProgress,
            height: sourceRect.height + (targetRect.height - sourceRect.height)
              * geometryProgress
          }
          paintOverlapFragment(ctx, geometry.sourceCell, geometry.targetCell,
            rect, fragmentOpacity)
        }

        paintProjection(ctx, root.projection, root.cells, targetSettled, -1)
      }

      function paintProjectionMorph(ctx) {
        var t = clampUnit(root.morphProgress)
        if (root.dateOverlapEnabled) paintDateOverlapMorph(ctx, t)
        else paintProjectionSeam(ctx, t)
      }

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
        ctx.fillStyle = root.verticalAxisHovered ? Color.accent : Qt.darker(root.foreground, 1.8)
        ctx.fillText("Y ↓", originX - Style.space(24), originY - Style.space(10))
        ctx.fillStyle = root.horizontalAxisHovered ? Color.accent : Qt.darker(root.foreground, 1.8)
        ctx.fillText("M →", originX - Style.space(4), originY - Style.space(10))

        ctx.textAlign = "center"
        for (var a = 0; a < axis.length; a++) {
          var markX = originX + root.axisMarkX(axis[a].position)
          ctx.fillText(axis[a].label, markX, originY - Style.space(10))
          var tickHeight = axis[a].major ? Style.space(5) : Style.space(3)
          ctx.fillRect(markX, originY - tickHeight, Style.spacing.hairline, tickHeight)
        }

        var vertical = root.verticalMarks()
        var inspectedColor = root.hoveredIndex >= 0 ? root.foreground : Color.accent
        ctx.textAlign = "right"
        for (var v = 0; v < vertical.length; v++) {
          ctx.fillStyle = vertical[v].current
            ? Color.accent
            : (vertical[v].inspected
              ? inspectedColor
              : (root.verticalAxisHovered
                ? Color.accent
                : Qt.darker(root.foreground, 1.8)))
          ctx.fillText(String(vertical[v].age), originX - Style.space(4),
            originY + root.rowOffset(vertical[v].row) + cellHeight / 2)
          ctx.fillRect(originX - (vertical[v].fiveYear ? Style.space(3) : Style.space(1)),
            originY + root.rowOffset(vertical[v].row) + cellHeight / 2,
            vertical[v].fiveYear ? Style.space(3) : Style.space(1),
            Style.spacing.hairline)
        }

        // The inspected interval reads directly on its axes. The base M scale
        // remains the overview; this precise W/M marker appears only at the
        // selected column and the age marker above appears at its selected row.
        var horizontalTicks = []
        var presentColumn = -1
        if (root.presentCellIndex >= root.firstVisibleIndex()
            && root.presentCellIndex < root.lastVisibleIndex()) {
          presentColumn = (root.presentCellIndex - root.firstVisibleIndex()) % columns
          horizontalTicks.push({ index: root.presentCellIndex, current: true })
        }
        if (root.hoveredIndex >= root.firstVisibleIndex()
            && root.hoveredIndex < root.lastVisibleIndex()
            && (root.hoveredIndex - root.firstVisibleIndex()) % columns !== presentColumn)
          horizontalTicks.push({ index: root.hoveredIndex, current: false })

        for (var h = 0; h < horizontalTicks.length; h++) {
          var tickColumn = (horizontalTicks[h].index - root.firstVisibleIndex()) % columns
          var tickCell = root.cells[horizontalTicks[h].index]
          var tickX = originX + root.columnOffset(tickColumn) + cellWidth / 2
          var tickParts = Model.projectionReadoutParts(tickCell, root.projection, root.today)
          var tickLabel = root.projection === "months"
            ? tickParts.position.replace("MONTH ", "M ")
            : tickParts.position.replace("WEEK ", "W ")
          var tickWidth = ctx.measureText(tickLabel).width + Style.space(6)
          ctx.fillStyle = Color.popups.background
          ctx.fillRect(tickX - tickWidth / 2, originY - Style.space(17),
            tickWidth, Style.space(12))
          ctx.fillStyle = horizontalTicks[h].current ? Color.accent : root.foreground
          ctx.textAlign = "center"
          ctx.fillText(tickLabel, tickX, originY - Style.space(10))
          ctx.fillRect(tickX, originY - Style.space(6),
            Style.spacing.hairline, Style.space(6))
        }

        // Present and hover use the same directional grammar: each point
        // reaches only upward to X and leftward to Y. The present guide stays
        // accented while hover adds a foreground inspection guide.
        var guides = []
        if (root.presentCellIndex >= root.firstVisibleIndex()
            && root.presentCellIndex < root.lastVisibleIndex())
          guides.push({ index: root.presentCellIndex, current: true })
        if (root.hoveredIndex >= root.firstVisibleIndex()
            && root.hoveredIndex < root.lastVisibleIndex()
            && root.hoveredIndex !== root.presentCellIndex)
          guides.push({ index: root.hoveredIndex, current: false })

        for (var g = 0; g < guides.length; g++) {
          var guideLocal = guides[g].index - root.firstVisibleIndex()
          var guideRow = Math.floor(guideLocal / columns)
          var guideColumn = guideLocal % columns
          var guideX = originX + root.columnOffset(guideColumn) + cellWidth / 2
          var guideY = originY + root.rowOffset(guideRow) + cellHeight / 2
          var guideColor = guides[g].current ? Color.accent : root.foreground
          ctx.fillStyle = Qt.rgba(guideColor.r, guideColor.g, guideColor.b,
            guides[g].current ? 0.32 : 0.26)
          ctx.fillRect(originX - Style.space(3), guideY,
            Math.max(0, guideX - originX + Style.space(3)), Style.spacing.hairline)
          ctx.fillRect(guideX, originY - Style.space(6), Style.spacing.hairline,
            Math.max(0, guideY - originY + Style.space(6)))
        }

        if (root.projectionMorphing) paintProjectionMorph(ctx)
        else paintProjection(ctx, root.projection, root.cells, 1, root.hoveredIndex)

        // Small edge cues disclose that compact mode is a movable viewport
        // rather than a cropped dataset.
        ctx.textAlign = "center"
        ctx.fillStyle = Qt.darker(root.foreground, 1.9)
        if (root.canPanEarlier)
          ctx.fillText("↑", width - rightGutter / 2, originY + cellHeight / 2)
        if (root.canPanLater)
          ctx.fillText("↓", width - rightGutter / 2, originY + root.gridHeight() - cellHeight / 2)
      }

      MouseArea {
        id: gridMouse
        anchors.fill: parent
        enabled: !root.projectionMorphing
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: root.projectionToggleHovered ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPositionChanged: function(mouse) {
          var overHorizontal = root.horizontalAxisContains(mouse.x, mouse.y)
          var overVertical = root.verticalAxisContains(mouse.x, mouse.y)
          var overToggle = root.projectionToggleContains(mouse.x, mouse.y)
          if (overHorizontal !== root.horizontalAxisHovered
              || overVertical !== root.verticalAxisHovered
              || overToggle !== root.projectionToggleHovered) {
            root.horizontalAxisHovered = overHorizontal
            root.verticalAxisHovered = overVertical
            root.projectionToggleHovered = overToggle
            lifeCanvas.requestPaint()
          }
          var next = root.hitTest(mouse.x, mouse.y)
          if (next >= 0 && next !== root.hoveredIndex) {
            root.hoveredIndex = next
            lifeCanvas.requestPaint()
          } else if (next < 0 && !root.gridContains(mouse.x, mouse.y)
                     && root.hoveredIndex !== -1) {
            root.hoveredIndex = -1
            lifeCanvas.requestPaint()
          }
        }
        onExited: {
          root.horizontalAxisHovered = false
          root.verticalAxisHovered = false
          root.projectionToggleHovered = false
          root.hoveredIndex = -1
          lifeCanvas.requestPaint()
        }
        onClicked: function(mouse) {
          if (root.projectionToggleContains(mouse.x, mouse.y)) root.toggleProjection()
        }
        onWheel: function(wheel) {
          if (wheel.angleDelta.y === 0) return
          root.panRows(wheel.angleDelta.y > 0 ? -1 : 1)
          wheel.accepted = true
        }
      }
    }

    Row {
      id: legendRow
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(18)

      Repeater {
        model: [
          { label: "PAST", opacity: 0.34, accent: false },
          { label: "PRESENT", opacity: 1, accent: true },
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
