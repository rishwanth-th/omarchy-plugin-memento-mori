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
  property string morphFromLivedLabel: ""
  property string morphFromRemainingLabel: ""
  property real morphProgress: 1
  property bool morphUsesDateOverlap: false
  property real entrancePassageProgress: 1
  property real entranceFocusProgress: 1
  property real entranceLabelProgress: 1
  property real entranceGuideProgress: 1
  property bool entranceAnimating: false
  property bool entranceFull: false
  property bool preparingMorph: false
  property bool reducedMotion: false
  property bool dateOverlapEnabled: false
  property int animationTapCount: 0
  property double lastAnimationTapAt: 0
  property real lastAnimationTapX: 0
  property real lastAnimationTapY: 0
  property string pinnedDateKey: ""
  property string keyboardDateKey: ""
  property bool keyboardInspecting: false
  property bool hoverArmed: false
  property bool hoverReferenceValid: false
  property real hoverReferenceX: 0
  property real hoverReferenceY: 0
  property double lastHorizontalMoveAt: 0
  property double lastHorizontalRequestAt: 0
  property real horizontalRepeatCadence: 30
  property double inspectionMoveBlockedUntil: 0
  property int pendingHorizontalDirection: 0
  property real pinBridgeProgress: 1
  property bool pinRulerHovered: false
  property bool pinPressActive: false
  property bool draggingPin: false
  property string dragOriginalPinnedDateKey: ""
  property real pinPressX: 0
  property real pinPressY: 0
  property string pinRetargetFromDateKey: ""
  property real pinRetargetProgress: 1
  readonly property int projectionMorphDuration: morphUsesDateOverlap ? 520 : 360
  readonly property bool projectionMorphing: morphFromProjection !== "" && morphProgress < 1

  readonly property var stats: Model.lifeStats(birthKey, today, horizonWeeks)
  readonly property var projectionStats: Model.projectionStats(cells, projection)
  readonly property int presentCellIndex: findPresentIndex()
  readonly property int pinnedIndex: Model.projectionIndexForDate(cells, pinnedDateKey)
  readonly property int keyboardIndex: Model.projectionIndexForDate(cells, keyboardDateKey)
  readonly property bool hasPin: pinnedDateKey !== "" && pinnedIndex >= 0
  readonly property var pinDelta: Model.projectionDelta(cells, projection, pinnedDateKey)
  readonly property var pinRulerDelta: Model.projectionRulerDelta(
    cells, projection, pinnedDateKey)
  readonly property real pinProgress: Model.lifeProgressForDate(
    birthKey, pinnedDateKey, horizonWeeks)
  readonly property real pinRetargetFromProgress: Model.lifeProgressForDate(
    birthKey, pinRetargetFromDateKey, horizonWeeks)
  readonly property bool pinRetargeting: pinRetargetFromDateKey !== ""
    && pinRetargetProgress < 1
  readonly property real displayedPinProgress: pinRetargeting
    && pinRetargetFromProgress >= 0
    ? pinRetargetFromProgress
      + (pinProgress - pinRetargetFromProgress) * pinRetargetProgress
    : pinProgress
  readonly property int activeInspectionIndex: hoveredIndex >= 0
    ? hoveredIndex
    : (keyboardInspecting ? keyboardIndex : -1)
  readonly property string activeInspectionDateKey: activeInspectionIndex >= 0
      && activeInspectionIndex < cells.length
    ? cells[activeInspectionIndex].startKey
    : ""
  readonly property var inspectionDelta: Model.projectionDelta(
    cells, projection, activeInspectionDateKey)
  readonly property bool pinMeasureHovered: hasPin
    && (lifeRail.pinHovered || pinRulerHovered)
  readonly property bool pinInspectionActive: hasPin
    && (pinMeasureHovered || activeInspectionIndex === pinnedIndex)
  property real pinTerminalLabelPresence: pinInspectionActive ? 0 : 1
  readonly property var visibleDelta: pinMeasureHovered
    ? pinDelta
    : inspectionDelta
  readonly property bool deltaVisible: (activeInspectionIndex >= 0
    || pinMeasureHovered) && visibleDelta.configured
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
  signal entranceCompleted(bool fullEntrance)

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

  function resetToNow(activateCursor) {
    if (entranceAnimating) cancelEntrance()
    finishProjectionMorph()
    cancelPendingInspectionMove()
    windowYearStart = defaultWindowStart()
    contentY = 0
    disarmHover()
    keyboardInspecting = activateCursor === true
    keyboardDateKey = keyboardInspecting && presentCellIndex >= 0
      ? cells[presentCellIndex].startKey
      : ""
    if (keyboardInspecting)
      inspectionMoveBlockedUntil = Date.now() + horizontalTraversalInterval()
    lifeCanvas.requestPaint()
  }

  function panRows(delta) {
    if (entranceAnimating) cancelEntrance()
    finishProjectionMorph()
    cancelPendingInspectionMove()
    windowYearStart = Math.max(0, Math.min(totalLifeYears - visibleYearCount, visibleYearStart + delta))
    disarmHover()
    keyboardInspecting = false
    keyboardDateKey = ""
    lifeCanvas.requestPaint()
  }

  function ensureIndexVisible(index) {
    if (index < 0 || index >= cells.length) return
    var row = Math.floor(index / columns())
    if (row < visibleYearStart) windowYearStart = row
    else if (row >= visibleYearStart + visibleYearCount)
      windowYearStart = row - visibleYearCount + 1
    windowYearStart = Math.max(0,
      Math.min(totalLifeYears - visibleYearCount, windowYearStart))
  }

  function disarmHover() {
    hoverArmed = false
    hoveredIndex = -1
    hoverReferenceValid = gridMouse.containsMouse
    if (hoverReferenceValid) {
      hoverReferenceX = gridMouse.mouseX
      hoverReferenceY = gridMouse.mouseY
    }
  }

  function hoverActivationDistance() {
    return Math.max(Style.space(5), Style.spacing.hairline * 6)
  }

  function armHoverFromMotion(x, y) {
    if (hoverArmed) return true
    if (!hoverReferenceValid) {
      hoverReferenceX = x
      hoverReferenceY = y
      hoverReferenceValid = true
      return false
    }
    var dx = x - hoverReferenceX
    var dy = y - hoverReferenceY
    if (Math.sqrt(dx * dx + dy * dy) < hoverActivationDistance()) return false
    hoverArmed = true
    return true
  }

  function horizontalTraversalInterval() {
    var weekStride = cellWidthFor("weeks") + columnGapFor("weeks")
    var activeStride = cellWidthFor(projection) + columnGapFor(projection)
    if (projection === "months") activeStride += quarterGapFor(projection) / 3
    return Math.max(horizontalRepeatCadence, Math.min(240,
      Math.round(horizontalRepeatCadence * activeStride / Math.max(1, weekStride))))
  }

  function noteHorizontalRequest(now) {
    if (lastHorizontalRequestAt > 0) {
      var gap = now - lastHorizontalRequestAt
      // Ignore deliberate taps and scheduler noise. Auto-repeat events form a
      // stable cadence that can be mapped through the rendered cell stride.
      if (gap >= 8 && gap <= 120)
        horizontalRepeatCadence = horizontalRepeatCadence * 0.65 + gap * 0.35
    }
    lastHorizontalRequestAt = now
  }

  function cancelPendingInspectionMove() {
    pendingHorizontalDirection = 0
    if (horizontalMoveTimer.running) horizontalMoveTimer.stop()
    lastHorizontalMoveAt = 0
  }

  function performInspectionMove(dx, dy) {
    if (entranceAnimating) cancelEntrance()
    finishProjectionMorph()
    var base = keyboardInspecting && keyboardIndex >= 0
      ? keyboardIndex
      : (hasPin ? pinnedIndex : presentCellIndex)
    if (base < 0) base = firstVisibleIndex()
    var target = Math.max(0, Math.min(cells.length - 1,
      base + dx + dy * columns()))
    if (target < 0 || target >= cells.length) return
    keyboardDateKey = cells[target].startKey
    keyboardInspecting = true
    disarmHover()
    ensureIndexVisible(target)
    lifeCanvas.requestPaint()
  }

  function moveInspection(dx, dy) {
    var now = Date.now()
    if (now < inspectionMoveBlockedUntil) return
    if (dx !== 0 && dy === 0) noteHorizontalRequest(now)
    if (projection !== "months" || dx === 0 || dy !== 0) {
      if (dy !== 0) cancelPendingInspectionMove()
      performInspectionMove(dx, dy)
      return
    }

    var interval = horizontalTraversalInterval()
    if (lastHorizontalMoveAt === 0 || now - lastHorizontalMoveAt >= interval) {
      pendingHorizontalDirection = 0
      if (horizontalMoveTimer.running) horizontalMoveTimer.stop()
      performInspectionMove(dx, 0)
      lastHorizontalMoveAt = now
      return
    }

    pendingHorizontalDirection = dx
    if (!horizontalMoveTimer.running) {
      horizontalMoveTimer.interval = Math.max(1,
        Math.round(interval - (now - lastHorizontalMoveAt)))
      horizontalMoveTimer.start()
    }
  }

  function clearPin() {
    cancelPendingInspectionMove()
    if (pinBridgeAnimation.running) pinBridgeAnimation.stop()
    if (pinRetargetAnimation.running) pinRetargetAnimation.stop()
    pinPressActive = false
    draggingPin = false
    dragOriginalPinnedDateKey = ""
    pinRetargetFromDateKey = ""
    pinRetargetProgress = 1
    pinRulerHovered = false
    pinnedDateKey = ""
    pinBridgeProgress = 1
    lifeCanvas.requestPaint()
  }

  function startPinBridge() {
    if (pinBridgeAnimation.running) pinBridgeAnimation.stop()
    if (pinRetargetAnimation.running) pinRetargetAnimation.stop()
    pinRetargetFromDateKey = ""
    pinRetargetProgress = 1
    if (reducedMotion) {
      pinBridgeProgress = 1
      return
    }
    pinBridgeProgress = 0
    pinBridgeAnimation.start()
  }

  function startPinRetarget(fromDateKey) {
    if (pinBridgeAnimation.running) pinBridgeAnimation.stop()
    if (pinRetargetAnimation.running) pinRetargetAnimation.stop()
    pinBridgeProgress = 1
    if (reducedMotion || fromDateKey === "") {
      pinRetargetFromDateKey = ""
      pinRetargetProgress = 1
      return
    }
    pinRetargetFromDateKey = fromDateKey
    pinRetargetProgress = 0
    pinRetargetAnimation.start()
  }

  function finishPinRetarget() {
    if (pinRetargetAnimation.running) pinRetargetAnimation.stop()
    pinRetargetProgress = 1
    pinRetargetFromDateKey = ""
  }

  function beginPinDrag(x, y) {
    if (!hasPin || pinnedIndex < 0) return false
    finishPinRetarget()
    pinPressActive = true
    draggingPin = false
    dragOriginalPinnedDateKey = pinnedDateKey
    pinPressX = x
    pinPressY = y
    return true
  }

  function updatePinDrag(x, y) {
    if (!pinPressActive) return false
    if (!draggingPin) {
      var dx = x - pinPressX
      var dy = y - pinPressY
      if (Math.sqrt(dx * dx + dy * dy) < hoverActivationDistance()) return false
      if (pinBridgeAnimation.running) pinBridgeAnimation.stop()
      pinBridgeProgress = 1
      draggingPin = true
    }
    var target = hitTest(x, y)
    if (target < 0 || target >= cells.length) return true
    if (target !== pinnedIndex) {
      pinnedDateKey = cells[target].startKey
      keyboardInspecting = false
      keyboardDateKey = ""
      hoveredIndex = -1
      pinRulerHovered = true
      lifeCanvas.requestPaint()
    }
    return true
  }

  function finishPinDrag() {
    if (!pinPressActive || !draggingPin) return false
    var landedOnPresent = pinnedIndex === presentCellIndex
    pinPressActive = false
    draggingPin = false
    dragOriginalPinnedDateKey = ""
    if (landedOnPresent) clearPin()
    else {
      pinBridgeProgress = 1
      pinRulerHovered = pinDragMouse.containsMouse
      lifeCanvas.requestPaint()
    }
    return true
  }

  function cancelPinDrag() {
    if (!pinPressActive) return false
    if (draggingPin && dragOriginalPinnedDateKey !== "")
      pinnedDateKey = dragOriginalPinnedDateKey
    pinPressActive = false
    draggingPin = false
    dragOriginalPinnedDateKey = ""
    pinBridgeProgress = 1
    pinRulerHovered = false
    lifeCanvas.requestPaint()
    return true
  }

  function clearTemporalSelection() {
    cancelPendingInspectionMove()
    clearPin()
    keyboardInspecting = false
    keyboardDateKey = ""
    disarmHover()
    lifeCanvas.requestPaint()
  }

  function togglePinAtIndex(index) {
    if (index < 0 || index >= cells.length) return false
    inspectionMoveBlockedUntil = Date.now()
      + Math.max(120, horizontalTraversalInterval())
    cancelPendingInspectionMove()
    if (cells[index].status === "current" || (hasPin && pinnedIndex === index)) {
      clearPin()
      return false
    }
    var previousPinDateKey = hasPin ? pinnedDateKey : ""
    pinnedDateKey = cells[index].startKey
    keyboardDateKey = cells[index].startKey
    if (previousPinDateKey !== "") startPinRetarget(previousPinDateKey)
    else startPinBridge()
    lifeCanvas.requestPaint()
    return true
  }

  function togglePinAtInspection() {
    return togglePinAtIndex(inspectedIndex())
  }

  function clearProjectionMorph() {
    morphFromProjection = ""
    morphFromCells = []
    morphSegments = []
    morphGeometry = []
    morphSourceRects = []
    morphTargetRects = []
    morphFromLivedLabel = ""
    morphFromRemainingLabel = ""
    morphUsesDateOverlap = false
    lifeCanvas.requestPaint()
  }

  function finishProjectionMorph() {
    if (projectionMorphAnimation.running) projectionMorphAnimation.stop()
    morphProgress = 1
    clearProjectionMorph()
  }

  function toggleAnimationStyle() {
    finishProjectionMorph()
    dateOverlapEnabled = !dateOverlapEnabled
  }

  function prepareEntrance(fullEntrance) {
    cancelEntrance()
    finishProjectionMorph()
    entranceFull = fullEntrance === true
    entrancePassageProgress = 0
    entranceFocusProgress = 0
    entranceLabelProgress = 0
    entranceGuideProgress = 0
    entranceAnimating = true
    lifeCanvas.requestPaint()
  }

  function startPreparedEntrance() {
    if (!entranceAnimating) return
    if (reducedMotion) {
      completeEntrance()
      return
    }
    if (entranceFull) fullEntranceAnimation.start()
    else repeatEntranceAnimation.start()
  }

  function completeEntrance() {
    var completedFullEntrance = entranceFull
    entrancePassageProgress = 1
    entranceFocusProgress = 1
    entranceLabelProgress = 1
    entranceGuideProgress = 1
    entranceAnimating = false
    entranceFull = false
    lifeCanvas.requestPaint()
    entranceCompleted(completedFullEntrance)
  }

  function cancelEntrance() {
    if (fullEntranceAnimation.running) fullEntranceAnimation.stop()
    if (repeatEntranceAnimation.running) repeatEntranceAnimation.stop()
    entrancePassageProgress = 1
    entranceFocusProgress = 1
    entranceLabelProgress = 1
    entranceGuideProgress = 1
    entranceAnimating = false
    entranceFull = false
    lifeCanvas.requestPaint()
  }

  function registerAnimationTap(x, y) {
    var now = Date.now()
    var dx = x - lastAnimationTapX
    var dy = y - lastAnimationTapY
    var radius = Style.space(24)
    var continuesSequence = now - lastAnimationTapAt <= 550
      && dx * dx + dy * dy <= radius * radius

    animationTapCount = continuesSequence ? animationTapCount + 1 : 1
    lastAnimationTapAt = now
    lastAnimationTapX = x
    lastAnimationTapY = y

    if (animationTapCount < 3) return false
    animationTapCount = 0
    lastAnimationTapAt = 0
    toggleAnimationStyle()
    return true
  }

  function projectionCountLabel(intervalCells, mode, remaining) {
    var intervalStats = Model.projectionStats(intervalCells, mode)
    var count = remaining ? intervalStats.remaining : intervalStats.lived
    var formattedCount = count.toLocaleString(Qt.locale("en_US"), "f", 0)
    return remaining
      ? formattedCount + " remaining"
      : formattedCount + " " + intervalStats.unit + " lived"
  }

  function setProjection(value) {
    if (value !== "weeks" && value !== "months") return
    if (projection === value) return

    if (entranceAnimating) cancelEntrance()

    finishProjectionMorph()
    var sourceProjection = projection
    var sourceCells = cells
    morphFromLivedLabel = projectionCountLabel(sourceCells, sourceProjection, false)
    morphFromRemainingLabel = projectionCountLabel(sourceCells, sourceProjection, true)
    preparingMorph = true
    projection = value
    preparingMorph = false

    if (reducedMotion) return

    morphFromProjection = sourceProjection
    morphFromCells = sourceCells

    if (dateOverlapEnabled) {
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

      morphUsesDateOverlap = segments.length > 0
      if (morphUsesDateOverlap) {
        morphSegments = segments
        morphGeometry = buildMorphGeometry(sourceProjection, sourceCells, segments)
        morphSourceRects = visibleRectsFor(sourceProjection, sourceCells)
        morphTargetRects = visibleRectsFor(projection, cells)
      }
    }

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

  function pinRulerGeometryForIndex(targetIndex) {
    var first = firstVisibleIndex()
    var last = lastVisibleIndex()
    if (!hasPin || presentCellIndex < first || presentCellIndex >= last
        || targetIndex < first || targetIndex >= last
        || targetIndex === presentCellIndex) return { visible: false }

    var presentRect = segmentRect(projection, presentCellIndex, 0, 1)
    var pinRect = segmentRect(projection, targetIndex, 0, 1)
    var presentCenterX = presentRect.x + presentRect.width / 2
    var presentCenterY = presentRect.y + presentRect.height / 2
    var pinCenterX = pinRect.x + pinRect.width / 2
    var pinCenterY = pinRect.y + pinRect.height / 2
    var horizontalDirection = pinCenterX === presentCenterX
      ? 0 : (pinCenterX > presentCenterX ? 1 : -1)
    var verticalDirection = pinCenterY === presentCenterY
      ? 0 : (pinCenterY > presentCenterY ? 1 : -1)
    var startX = presentCenterX
    var startY = presentCenterY
    var elbowX = pinCenterX
    var elbowY = presentCenterY
    var endX = pinCenterX
    var endY = pinCenterY

    // Center-to-center geometry keeps even adjacent intervals measurable.
    // The hairline passes through the two endpoint cells without recoloring
    // them, then crosses only the present row and the pin column.
    var horizontalLength = Math.abs(elbowX - startX)
    var verticalLength = Math.abs(endY - elbowY)
    return {
      visible: true,
      startX: startX,
      startY: startY,
      elbowX: elbowX,
      elbowY: elbowY,
      endX: endX,
      endY: endY,
      horizontalLength: horizontalLength,
      verticalLength: verticalLength,
      totalLength: horizontalLength + verticalLength,
      horizontalDirection: horizontalDirection,
      verticalDirection: verticalDirection
    }
  }

  function pinRulerGeometry() {
    return pinRulerGeometryForIndex(pinnedIndex)
  }

  function displayedPinRulerGeometry() {
    var target = pinRulerGeometry()
    if (!pinRetargeting) return target
    var previousIndex = Model.projectionIndexForDate(cells, pinRetargetFromDateKey)
    var source = pinRulerGeometryForIndex(previousIndex)
    if (!source.visible || !target.visible) return target
    var t = Math.max(0, Math.min(1, pinRetargetProgress))
    var geometry = {
      visible: true,
      startX: source.startX + (target.startX - source.startX) * t,
      startY: source.startY + (target.startY - source.startY) * t,
      elbowX: source.elbowX + (target.elbowX - source.elbowX) * t,
      elbowY: source.elbowY + (target.elbowY - source.elbowY) * t,
      endX: source.endX + (target.endX - source.endX) * t,
      endY: source.endY + (target.endY - source.endY) * t
    }
    geometry.horizontalLength = Math.abs(geometry.elbowX - geometry.startX)
    geometry.verticalLength = Math.abs(geometry.endY - geometry.elbowY)
    geometry.totalLength = geometry.horizontalLength + geometry.verticalLength
    geometry.horizontalDirection = geometry.elbowX === geometry.startX
      ? 0 : (geometry.elbowX > geometry.startX ? 1 : -1)
    geometry.verticalDirection = geometry.endY === geometry.elbowY
      ? 0 : (geometry.endY > geometry.elbowY ? 1 : -1)
    return geometry
  }

  function pinBridgeDuration() {
    var geometry = pinRulerGeometry()
    if (!geometry.visible || geometry.totalLength <= 0) return 220
    return Math.max(180, Math.min(280,
      Math.round(geometry.totalLength * 0.7)))
  }

  function pointSegmentDistance(x, y, x1, y1, x2, y2) {
    var dx = x2 - x1
    var dy = y2 - y1
    var lengthSquared = dx * dx + dy * dy
    if (lengthSquared <= 0) {
      var pointDx = x - x1
      var pointDy = y - y1
      return Math.sqrt(pointDx * pointDx + pointDy * pointDy)
    }
    var t = Math.max(0, Math.min(1,
      ((x - x1) * dx + (y - y1) * dy) / lengthSquared))
    var nearestX = x1 + t * dx
    var nearestY = y1 + t * dy
    var distanceX = x - nearestX
    var distanceY = y - nearestY
    return Math.sqrt(distanceX * distanceX + distanceY * distanceY)
  }

  function pinRulerContains(x, y) {
    if (projectionMorphing || pinRetargeting || pinBridgeProgress < 1) return false
    var geometry = pinRulerGeometry()
    if (!geometry.visible) return false
    var tolerance = Math.max(2, Style.spacing.hairline * 3)
    if (geometry.horizontalLength > 0
        && pointSegmentDistance(x, y, geometry.startX, geometry.startY,
          geometry.verticalLength > 0 ? geometry.elbowX : geometry.endX,
          geometry.verticalLength > 0 ? geometry.elbowY : geometry.endY) <= tolerance)
      return true
    return geometry.verticalLength > 0
      && pointSegmentDistance(x, y, geometry.elbowX, geometry.elbowY,
        geometry.endX, geometry.endY) <= tolerance
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
    if (keyboardInspecting && keyboardIndex >= firstVisibleIndex()
        && keyboardIndex < lastVisibleIndex()) return keyboardIndex
    if (hasPin && pinnedIndex >= firstVisibleIndex() && pinnedIndex < lastVisibleIndex())
      return pinnedIndex
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
    var inspectedRow = activeInspectionIndex >= firstVisibleIndex()
        && activeInspectionIndex < lastVisibleIndex()
        && (!hasPin || activeInspectionIndex !== pinnedIndex)
      ? Math.floor((activeInspectionIndex - firstVisibleIndex()) / columns())
      : -1
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
        current: row === nowRow,
        inspected: row === inspectedRow,
        fiveYear: markAge % 5 === 0 })
    }
    marks.sort(function(a, b) { return a.row - b.row })
    return marks
  }

  onProjectionChanged: {
    cancelPendingInspectionMove()
    finishPinRetarget()
    refreshCells(false)
    if (keyboardInspecting) ensureIndexVisible(keyboardIndex)
    else if (hasPin) ensureIndexVisible(pinnedIndex)
    lifeCanvas.requestPaint()
  }
  onBirthKeyChanged: {
    clearTemporalSelection()
    refreshCells(true)
  }
  onTodayChanged: refreshCells(true)
  onHorizonWeeksChanged: {
    clearTemporalSelection()
    refreshCells(true)
  }
  onWidthChanged: lifeCanvas.requestPaint()
  onMorphProgressChanged: lifeCanvas.requestPaint()
  onEntranceFocusProgressChanged: lifeCanvas.requestPaint()
  onEntranceGuideProgressChanged: lifeCanvas.requestPaint()
  onPinBridgeProgressChanged: lifeCanvas.requestPaint()
  onPinRetargetProgressChanged: lifeCanvas.requestPaint()
  onPinInspectionActiveChanged: lifeCanvas.requestPaint()
  onPinTerminalLabelPresenceChanged: lifeCanvas.requestPaint()
  onReducedMotionChanged: {
    if (reducedMotion && pinBridgeAnimation.running) {
      pinBridgeAnimation.stop()
      pinBridgeProgress = 1
    }
    if (reducedMotion && pinRetargetAnimation.running) finishPinRetarget()
  }
  Component.onCompleted: refreshCells(true)

  Behavior on pinTerminalLabelPresence {
    NumberAnimation {
      duration: root.reducedMotion ? 0 : 110
      easing.type: Easing.OutCubic
    }
  }

  Timer {
    id: horizontalMoveTimer
    repeat: false
    onTriggered: {
      var direction = root.pendingHorizontalDirection
      root.pendingHorizontalDirection = 0
      if (direction === 0 || root.projection !== "months"
          || Date.now() < root.inspectionMoveBlockedUntil) return
      root.performInspectionMove(direction, 0)
      root.lastHorizontalMoveAt = Date.now()
    }
  }

  ParallelAnimation {
    id: fullEntranceAnimation

    SequentialAnimation {
      PauseAnimation { duration: 60 }
      NumberAnimation {
        target: root
        property: "entrancePassageProgress"
        from: 0
        to: 1
        duration: 420
        easing.type: Easing.InOutCubic
      }
    }

    SequentialAnimation {
      PauseAnimation { duration: 160 }
      ParallelAnimation {
        NumberAnimation {
          target: root
          property: "entranceFocusProgress"
          from: 0
          to: 1
          duration: 320
          easing.type: Easing.InOutCubic
        }
        NumberAnimation {
          target: root
          property: "entranceLabelProgress"
          from: 0
          to: 1
          duration: 320
          easing.type: Easing.InOutCubic
        }
      }
    }

    SequentialAnimation {
      PauseAnimation { duration: 320 }
      NumberAnimation {
        target: root
        property: "entranceGuideProgress"
        from: 0
        to: 1
        duration: 160
        easing.type: Easing.OutCubic
      }
    }

    onFinished: root.completeEntrance()
  }

  ParallelAnimation {
    id: repeatEntranceAnimation

    SequentialAnimation {
      PauseAnimation { duration: 60 }
      NumberAnimation {
        target: root
        property: "entrancePassageProgress"
        from: 0
        to: 1
        duration: 320
        easing.type: Easing.InOutCubic
      }
    }

    SequentialAnimation {
      PauseAnimation { duration: 140 }
      ParallelAnimation {
        NumberAnimation {
          target: root
          property: "entranceFocusProgress"
          from: 0
          to: 1
          duration: 240
          easing.type: Easing.InOutCubic
        }
        NumberAnimation {
          target: root
          property: "entranceLabelProgress"
          from: 0
          to: 1
          duration: 240
          easing.type: Easing.InOutCubic
        }
      }
    }

    SequentialAnimation {
      PauseAnimation { duration: 220 }
      NumberAnimation {
        target: root
        property: "entranceGuideProgress"
        from: 0
        to: 1
        duration: 160
        easing.type: Easing.OutCubic
      }
    }

    onFinished: root.completeEntrance()
  }

  NumberAnimation {
    id: pinBridgeAnimation
    target: root
    property: "pinBridgeProgress"
    from: 0
    to: 1
    duration: root.pinBridgeDuration()
    easing.type: Easing.Linear
  }

  NumberAnimation {
    id: pinRetargetAnimation
    target: root
    property: "pinRetargetProgress"
    from: 0
    to: 1
    duration: 180
    easing.type: Easing.InOutCubic
    onFinished: root.pinRetargetFromDateKey = ""
  }

  NumberAnimation {
    id: projectionMorphAnimation
    target: root
    property: "morphProgress"
    from: 0
    to: 1
    duration: root.projectionMorphDuration
    easing.type: root.morphUsesDateOverlap ? Easing.Linear : Easing.InOutCubic
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
      animateProgressChanges: !root.entranceAnimating
      segmentProgress: root.stats.progress
      segmentOpacity: root.entranceLabelProgress
      labelMorphProgress: root.morphProgress
      labelMorphActive: root.projectionMorphing
      passageProgress: root.entrancePassageProgress
      passageActive: root.entranceAnimating
      pinActive: root.hasPin && root.pinProgress >= 0
      pinProgress: Math.max(0, root.displayedPinProgress)
      pinRevealProgress: root.pinRetargeting ? 1 : root.pinBridgeProgress
      previousLivedLabel: root.morphFromLivedLabel
      previousRemainingLabel: root.morphFromRemainingLabel
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

      Item {
        id: deltaReadout
        visible: root.deltaVisible
        anchors.right: parent.right
        anchors.rightMargin: Style.space(4)
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(150)
        height: deltaParts.implicitHeight

        Row {
          id: deltaParts
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(4)

          Text {
            text: root.deltaVisible
              ? root.visibleDelta.count + " " + root.visibleDelta.unit : ""
            color: Qt.rgba(root.foreground.r, root.foreground.g,
              root.foreground.b, 0.78)
            font.family: root.fontFamily
            font.pixelSize: Math.max(8, Style.font.caption - 1)
            font.letterSpacing: 0.5
          }

          Text {
            text: root.deltaVisible ? root.visibleDelta.direction : ""
            color: Qt.rgba(root.foreground.r, root.foreground.g,
              root.foreground.b, 0.48)
            font.family: root.fontFamily
            font.pixelSize: Math.max(8, Style.font.caption - 1)
            font.letterSpacing: 0.5
          }
        }
      }
    }

    Canvas {
      id: lifeCanvas
      readonly property real leftGutter: Style.space(48)
      readonly property real rightGutter: Style.space(14)
      readonly property real topGutter: Style.space(26)

      width: parent.width
      height: root.compactCanvasHeight

      function paintCell(ctx, cell, rect, opacity, hovered, pinned, keyboardFocused) {
        if (!cell || !rect || opacity <= 0) return
        var alpha = Math.max(0, Math.min(1, opacity))
        var accent = Color.accent

        if (cell.status === "lived") {
          ctx.fillStyle = Qt.rgba(root.foreground.r, root.foreground.g,
            root.foreground.b, 0.34 * alpha)
          ctx.fillRect(rect.x, rect.y, rect.width, rect.height)
        } else if (cell.status === "current") {
          // Calendar already establishes the global present. LIFE adds its
          // local coordinate, so the cell resolves from quiet to exact rather
          // than replaying time from birth.
          var presentAlpha = 0.35 + 0.65 * root.entranceFocusProgress
          ctx.fillStyle = Qt.rgba(accent.r, accent.g, accent.b,
            alpha * presentAlpha)
          ctx.fillRect(rect.x, rect.y, rect.width, rect.height)
        } else {
          ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g,
            root.foreground.b, 0.22 * alpha)
          ctx.lineWidth = Style.spacing.hairline
          ctx.strokeRect(rect.x + 0.5, rect.y + 0.5,
            Math.max(0, rect.width - 1), Math.max(0, rect.height - 1))
        }

        if (pinned && cell.status !== "current" && alpha >= 0.99) {
          ctx.fillStyle = Qt.rgba(root.foreground.r, root.foreground.g,
            root.foreground.b, (root.pinInspectionActive ? 0.18 : 0.12)
              * root.pinBridgeProgress)
          ctx.fillRect(rect.x, rect.y, rect.width, rect.height)
          ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g,
            root.foreground.b, (root.pinInspectionActive ? 0.92 : 0.72)
              * root.pinBridgeProgress)
          ctx.lineWidth = Math.max(1, Style.spacing.hairline * 2)
          var pinInset = ctx.lineWidth / 2
          ctx.strokeRect(rect.x + pinInset, rect.y + pinInset,
            Math.max(0, rect.width - ctx.lineWidth),
            Math.max(0, rect.height - ctx.lineWidth))
        }

        if (keyboardFocused && !hovered && alpha >= 0.99) {
          ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g,
            root.foreground.b, 0.9)
          ctx.lineWidth = Math.max(1, Style.spacing.hairline)
          var focusInset = Math.max(1, ctx.lineWidth)
          ctx.strokeRect(rect.x + focusInset, rect.y + focusInset,
            Math.max(0, rect.width - focusInset * 2),
            Math.max(0, rect.height - focusInset * 2))
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
        var currentProjection = mode === root.projection && intervalCells === root.cells
        for (var index = first; index < last; index++)
          paintCell(ctx, intervalCells[index], root.segmentRect(mode, index, 0, 1),
            opacity, index === hoveredIndex,
            currentProjection && root.hasPin && index === root.pinnedIndex,
            currentProjection && root.keyboardInspecting && index === root.keyboardIndex)
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
        if (root.morphUsesDateOverlap) paintDateOverlapMorph(ctx, t)
        else paintProjectionSeam(ctx, t)
      }

      function paintPinRuler(ctx) {
        var geometry = root.displayedPinRulerGeometry()
        if (!geometry.visible || geometry.totalLength <= 0) return
        var reveal = root.pinRetargeting ? 1
          : Math.max(0, Math.min(1, root.pinBridgeProgress))
        var revealedLength = geometry.totalLength * reveal
        var horizontalRevealed = Math.min(geometry.horizontalLength, revealedLength)
        var verticalRevealed = Math.max(0,
          Math.min(geometry.verticalLength, revealedLength - geometry.horizontalLength))
        var lineOpacity = root.pinInspectionActive ? 0.78 : 0.46
        var lineWidth = Math.max(Style.spacing.hairline,
          root.pinInspectionActive ? Style.spacing.hairline * 1.5 : Style.spacing.hairline)

        ctx.beginPath()
        ctx.moveTo(geometry.startX, geometry.startY)
        var headX = geometry.startX
        var headY = geometry.startY
        var headVertical = false
        if (horizontalRevealed > 0) {
          headX = geometry.startX
            + geometry.horizontalDirection * horizontalRevealed
          headY = geometry.startY
          ctx.lineTo(headX, headY)
        }
        if (verticalRevealed > 0) {
          if (horizontalRevealed >= geometry.horizontalLength)
            ctx.lineTo(geometry.elbowX, geometry.elbowY)
          headX = geometry.elbowX
          headY = geometry.elbowY
            + geometry.verticalDirection * verticalRevealed
          ctx.lineTo(headX, headY)
          headVertical = true
        }
        ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g,
          root.foreground.b, lineOpacity)
        ctx.lineWidth = lineWidth
        ctx.lineJoin = "miter"
        ctx.lineCap = "square"
        ctx.stroke()

        // A short advancing cap makes the one-time measurement legible. It is
        // a drawing head, not a third temporal marker, and disappears on land.
        if (reveal > 0 && reveal < 1) {
          var headHalf = Style.space(2)
          ctx.beginPath()
          if (headVertical) {
            ctx.moveTo(headX - headHalf, headY)
            ctx.lineTo(headX + headHalf, headY)
          } else {
            ctx.moveTo(headX, headY - headHalf)
            ctx.lineTo(headX, headY + headHalf)
          }
          ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g,
            root.foreground.b, 0.68 * Math.sin(Math.PI * reveal))
          ctx.lineWidth = Math.max(lineWidth, Style.spacing.hairline * 2)
          ctx.stroke()
        }
      }

      function paintBackedLabel(ctx, text, centerX, centerY, color, opacity) {
        if (!text || opacity <= 0.01) return 0
        var width = ctx.measureText(text).width + Style.space(6)
        var height = Style.space(12)
        var x = Math.max(width / 2 + Style.space(1),
          Math.min(lifeCanvas.width - width / 2 - Style.space(1), centerX))
        var y = Math.max(height / 2,
          Math.min(lifeCanvas.height - height / 2, centerY))
        var backgroundOpacity = Math.max(0, Math.min(1, opacity * 1.3))
        ctx.fillStyle = Qt.rgba(Color.popups.background.r,
          Color.popups.background.g, Color.popups.background.b,
          backgroundOpacity)
        ctx.fillRect(x - width / 2, y - height / 2, width, height)
        ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, opacity)
        ctx.textAlign = "center"
        ctx.fillText(text, x, y)
        return width
      }

      function labelFitProgress(available, required, transition) {
        return smoothUnit((available - required) / Math.max(1, transition))
      }

      function paintPinRulerLabels(ctx) {
        var geometry = root.displayedPinRulerGeometry()
        var delta = root.pinRulerDelta
        if (!geometry.visible || !delta.configured) return

        var reveal = root.pinRetargeting ? 1
          : Math.max(0, Math.min(1, root.pinBridgeProgress))
        var revealedLength = geometry.totalLength * reveal
        var horizontalRevealed = Math.min(geometry.horizontalLength, revealedLength)
        var verticalRevealed = Math.max(0,
          Math.min(geometry.verticalLength, revealedLength - geometry.horizontalLength))
        var componentOpacity = root.pinInspectionActive ? 0.92 : 0.70
        var totalOpacity = 0.82
        var horizontalOnlyTotalPainted = false

        // Engrave the week/month component into the horizontal leg only after
        // that leg has earned enough rendered room. Short geometry stays
        // silent instead of moving its measurement elsewhere.
        if (geometry.horizontalLength > 0
            && horizontalRevealed >= geometry.horizontalLength - 0.5) {
          var horizontalText = geometry.verticalLength > 0
            ? delta.horizontalLabel : delta.totalLabel
          var horizontalWidth = ctx.measureText(horizontalText).width
            + Style.space(6)
          var horizontalFit = labelFitProgress(geometry.horizontalLength,
            horizontalWidth + Style.space(6), Style.space(12))
          if (horizontalFit > 0) {
            paintBackedLabel(ctx, horizontalText,
              (geometry.startX + geometry.elbowX) / 2, geometry.startY,
              root.foreground, componentOpacity * horizontalFit)
            horizontalOnlyTotalPainted = geometry.verticalLength === 0
          }
        }

        // The life-year label stays horizontally readable but interrupts the
        // vertical line at its own midpoint, matching the horizontal leg's
        // engraved treatment without rotating typography.
        if (geometry.verticalLength > 0
            && verticalRevealed >= geometry.verticalLength - 0.5) {
          var verticalFit = labelFitProgress(geometry.verticalLength,
            Style.space(10), Style.space(8))
          paintBackedLabel(ctx, delta.verticalLabel, geometry.endX,
            (geometry.elbowY + geometry.endY) / 2,
            root.foreground, componentOpacity * verticalFit)
        }

        // The terminal reading belongs to the held endpoint. The route from
        // accented present to this neutral pin already supplies before/after
        // direction, so the ruler needs no sign or prose suffix.
        if (reveal < 0.999 || !delta.totalLabel || horizontalOnlyTotalPainted) return
        var totalWidth = ctx.measureText(delta.totalLabel).width + Style.space(6)
        var totalFit = labelFitProgress(geometry.totalLength,
          totalWidth + Style.space(20), Style.space(14))
        if (totalFit <= 0) return
        var outerSide = geometry.horizontalDirection
        if (outerSide === 0)
          outerSide = geometry.endX < lifeCanvas.width / 2 ? 1 : -1
        var endpointClearance = root.cellWidth() / 2 + Style.space(3)
        var preferredTotalX = geometry.endX
          + outerSide * (endpointClearance + totalWidth / 2)
        var preferredFits = preferredTotalX - totalWidth / 2 >= Style.space(1)
          && preferredTotalX + totalWidth / 2
            <= lifeCanvas.width - Style.space(1)
        if (!preferredFits) outerSide *= -1
        var totalX = geometry.endX
          + outerSide * (endpointClearance + totalWidth / 2)
        var totalFits = totalX - totalWidth / 2 >= Style.space(1)
          && totalX + totalWidth / 2 <= lifeCanvas.width - Style.space(1)
        if (!totalFits) return
        paintBackedLabel(ctx, delta.totalLabel, totalX, geometry.endY,
          root.foreground, totalOpacity * totalFit
            * root.pinTerminalLabelPresence)
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
        var inspectionIndex = root.inspectedIndex()
        var axisInspectionIndex = root.activeInspectionIndex
        if (root.hasPin && axisInspectionIndex === root.pinnedIndex)
          axisInspectionIndex = -1
        var inspectedColor = inspectionIndex !== root.presentCellIndex
          ? root.foreground
          : Color.accent
        ctx.textAlign = "right"
        for (var v = 0; v < vertical.length; v++) {
          ctx.fillStyle = vertical[v].current
            ? Color.accent
            : (vertical[v].inspected
              ? inspectedColor
              : (root.verticalAxisHovered
                ? Color.accent
                : Qt.darker(root.foreground, 1.8)))
          var verticalY = originY + root.rowOffset(vertical[v].row)
            + cellHeight / 2
          var verticalOuterLane = false
          if (vertical[v].inspected && !vertical[v].current) {
            for (var compare = 0; compare < vertical.length; compare++) {
              if (compare === v) continue
              var compareY = originY + root.rowOffset(vertical[compare].row)
                + cellHeight / 2
              if (Math.abs(compareY - verticalY)
                  < Style.font.caption + Style.space(2)) {
                verticalOuterLane = true
                break
              }
            }
          }
          var verticalLabelX = originX
            - Style.space(verticalOuterLane ? 18 : 4)
          if (verticalOuterLane) {
            ctx.fillRect(verticalLabelX + Style.space(2), verticalY,
              Style.space(15), Style.spacing.hairline)
          }
          ctx.fillText(String(vertical[v].age), verticalLabelX, verticalY)
          ctx.fillRect(originX - (vertical[v].fiveYear ? Style.space(3) : Style.space(1)),
            verticalY,
            vertical[v].fiveYear ? Style.space(3) : Style.space(1),
            Style.spacing.hairline)
        }

        // Present owns the base coordinate lane. Ephemeral inspection keeps an
        // exact tick, moving only its text outward when nearby labels collide.
        // The hold is represented separately by dimension brackets.
        var horizontalTicks = []
        var horizontalCandidates = [
          { index: root.presentCellIndex, current: true },
          { index: axisInspectionIndex, current: false }
        ]
        var seenColumns = {}
        for (var candidate = 0; candidate < horizontalCandidates.length; candidate++) {
          var horizontalCandidate = horizontalCandidates[candidate]
          if (horizontalCandidate.index < root.firstVisibleIndex()
              || horizontalCandidate.index >= root.lastVisibleIndex()) continue
          var candidateColumn = (horizontalCandidate.index
            - root.firstVisibleIndex()) % columns
          if (seenColumns[candidateColumn]) continue
          seenColumns[candidateColumn] = true
          horizontalTicks.push(horizontalCandidate)
        }

        for (var h = 0; h < horizontalTicks.length; h++) {
          var tickColumn = (horizontalTicks[h].index - root.firstVisibleIndex()) % columns
          var tickCell = root.cells[horizontalTicks[h].index]
          var tickX = originX + root.columnOffset(tickColumn) + cellWidth / 2
          var tickParts = Model.projectionReadoutParts(tickCell, root.projection, root.today)
          var tickLabel = root.projection === "months"
            ? tickParts.position.replace("MONTH ", "M ")
            : tickParts.position.replace("WEEK ", "W ")
          var tickWidth = ctx.measureText(tickLabel).width + Style.space(6)
          horizontalTicks[h].x = tickX
          horizontalTicks[h].label = tickLabel
          horizontalTicks[h].width = tickWidth
        }

        if (horizontalTicks.length === 2
            && Math.abs(horizontalTicks[0].x - horizontalTicks[1].x)
              < (horizontalTicks[0].width + horizontalTicks[1].width) / 2
                + Style.space(2))
          horizontalTicks[1].outerLane = true

        for (var paintedTick = 0; paintedTick < horizontalTicks.length; paintedTick++) {
          var horizontalTick = horizontalTicks[paintedTick]
          var tickY = originY - Style.space(horizontalTick.outerLane ? 20 : 10)
          ctx.fillStyle = Color.popups.background
          ctx.fillRect(horizontalTick.x - horizontalTick.width / 2,
            tickY - Style.space(6), horizontalTick.width, Style.space(12))
          ctx.fillStyle = horizontalTick.current ? Color.accent : root.foreground
          ctx.textAlign = "center"
          ctx.fillText(horizontalTick.label, horizontalTick.x, tickY)
          if (horizontalTick.outerLane)
            ctx.fillRect(horizontalTick.x, tickY + Style.space(6),
              Style.spacing.hairline,
              Math.max(0, originY - Style.space(6)
                - (tickY + Style.space(6))))
          ctx.fillRect(horizontalTick.x, originY - Style.space(6),
            Style.spacing.hairline, Style.space(6))
        }

        // Present and ephemeral inspection reach the axes. The pin keeps its
        // secondary axis labels and ticks, but the orthogonal ruler is its only
        // full connecting geometry; a second pin-to-axis L would obscure the
        // present-to-pin measurement.
        var guideCandidates = [
          { index: root.presentCellIndex, current: true, pinned: false },
          { index: inspectionIndex, current: false, pinned: false }
        ]
        var guides = []
        var seenGuides = {}
        for (var guideCandidateIndex = 0;
             guideCandidateIndex < guideCandidates.length;
             guideCandidateIndex++) {
          var guideCandidate = guideCandidates[guideCandidateIndex]
          if (guideCandidate.index < root.firstVisibleIndex()
              || guideCandidate.index >= root.lastVisibleIndex()) continue
          if (root.hasPin && guideCandidate.index === root.pinnedIndex) continue
          if (guideCandidate.pinned && !root.hasPin) continue
          if (seenGuides[guideCandidate.index]) continue
          seenGuides[guideCandidate.index] = true
          guides.push(guideCandidate)
        }

        for (var g = 0; g < guides.length; g++) {
          var guideLocal = guides[g].index - root.firstVisibleIndex()
          var guideRow = Math.floor(guideLocal / columns)
          var guideColumn = guideLocal % columns
          var guideX = originX + root.columnOffset(guideColumn) + cellWidth / 2
          var guideY = originY + root.rowOffset(guideRow) + cellHeight / 2
          var guideColor = guides[g].current ? Color.accent : root.foreground
          var guideOpacity = guides[g].current ? 0.32 : (guides[g].pinned ? 0.28 : 0.18)
          var guideProgress = guides[g].current
            ? root.entranceGuideProgress
            : (guides[g].pinned ? root.pinBridgeProgress : 1)
          var horizontalLength = Math.max(0,
            guideX - originX + Style.space(3))
          var verticalLength = Math.max(0,
            guideY - originY + Style.space(6))
          ctx.fillStyle = Qt.rgba(guideColor.r, guideColor.g, guideColor.b,
            guideOpacity)
          ctx.fillRect(originX - Style.space(3), guideY,
            horizontalLength * guideProgress, Style.spacing.hairline)
          ctx.fillRect(guideX, originY - Style.space(6), Style.spacing.hairline,
            verticalLength * guideProgress)
        }

        if (root.projectionMorphing) paintProjectionMorph(ctx)
        else {
          paintProjection(ctx, root.projection, root.cells, 1, root.hoveredIndex)
          paintPinRuler(ctx)
          paintPinRulerLabels(ctx)
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

      MouseArea {
        id: gridMouse
        anchors.fill: parent
        enabled: !root.projectionMorphing
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: root.projectionToggleHovered || root.hoveredIndex >= 0
          ? Qt.PointingHandCursor
          : Qt.ArrowCursor
        onPositionChanged: function(mouse) {
          if (!root.armHoverFromMotion(mouse.x, mouse.y)) return
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
          var overRuler = root.pinRulerContains(mouse.x, mouse.y)
          if (overRuler !== root.pinRulerHovered) {
            root.pinRulerHovered = overRuler
            lifeCanvas.requestPaint()
          }
          if (overRuler) {
            root.keyboardInspecting = false
            root.keyboardDateKey = ""
            if (root.hoveredIndex !== -1) root.hoveredIndex = -1
            lifeCanvas.requestPaint()
            return
          }
          var next = root.hitTest(mouse.x, mouse.y)
          if (next >= 0 && next !== root.hoveredIndex) {
            root.keyboardInspecting = false
            root.keyboardDateKey = ""
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
          root.pinRulerHovered = false
          root.disarmHover()
          lifeCanvas.requestPaint()
        }
        onClicked: function(mouse) {
          root.hoverArmed = true
          root.hoverReferenceValid = true
          root.hoverReferenceX = mouse.x
          root.hoverReferenceY = mouse.y
          if (root.projectionToggleContains(mouse.x, mouse.y)) root.toggleProjection()
          else if (root.hitTest(mouse.x, mouse.y) >= 0) {
            root.keyboardInspecting = false
            root.keyboardDateKey = ""
            root.hoveredIndex = root.hitTest(mouse.x, mouse.y)
            root.togglePinAtIndex(root.hoveredIndex)
          }
          else if (root.gridContains(mouse.x, mouse.y))
            root.registerAnimationTap(mouse.x, mouse.y)
        }
        onWheel: function(wheel) {
          if (wheel.angleDelta.y === 0) return
          root.panRows(wheel.angleDelta.y > 0 ? -1 : 1)
          wheel.accepted = true
        }
      }

      MouseArea {
        id: pinDragMouse
        readonly property bool pinVisible: root.hasPin
          && root.pinnedIndex >= root.firstVisibleIndex()
          && root.pinnedIndex < root.lastVisibleIndex()
          && (root.draggingPin || root.pinnedIndex !== root.presentCellIndex)
        readonly property var pinRect: pinVisible
          ? root.segmentRect(root.projection, root.pinnedIndex, 0, 1)
          : ({ x: 0, y: 0, width: 0, height: 0 })

        visible: pinVisible && !root.projectionMorphing
        x: pinRect.x - Style.space(2)
        y: pinRect.y - Style.space(2)
        width: pinRect.width + Style.space(4)
        height: pinRect.height + Style.space(4)
        z: 2
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        preventStealing: true
        cursorShape: root.draggingPin ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        onEntered: {
          root.pinRulerHovered = true
          root.keyboardInspecting = false
          root.keyboardDateKey = ""
          root.hoveredIndex = -1
          lifeCanvas.requestPaint()
        }
        onExited: {
          if (!root.draggingPin) root.pinRulerHovered = false
          lifeCanvas.requestPaint()
        }
        onPressed: function(mouse) {
          var point = pinDragMouse.mapToItem(lifeCanvas, mouse.x, mouse.y)
          root.beginPinDrag(point.x, point.y)
        }
        onPositionChanged: function(mouse) {
          if (!pressed) return
          var point = pinDragMouse.mapToItem(lifeCanvas, mouse.x, mouse.y)
          root.updatePinDrag(point.x, point.y)
        }
        onReleased: function(mouse) {
          if (root.finishPinDrag()) return
          root.pinPressActive = false
          root.dragOriginalPinnedDateKey = ""
          root.togglePinAtIndex(root.pinnedIndex)
        }
        onCanceled: root.cancelPinDrag()
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
