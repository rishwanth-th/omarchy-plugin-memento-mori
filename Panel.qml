import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

// The clock's calendar popup: a month grid with ISO week numbers, built to
// sit beside the weather panel — same hero-over-detail composition, same
// spacing scale, same small-caps labels.
//
// The grid is a read-out rather than a picker: today is the only marked
// day, and the only thing that moves is which month is on screen —
// chevrons, the scroll wheel, and the arrow keys all step it.
//
// BarWidget.qml owns the bar label and hands this panel the button to
// anchor against.
Panel {
  id: root
  moduleName: "rishwanth.memento-mori"
  ipcTarget: "rishwanth.memento-mori"
  manageIpc: false

  property var anchorItem: null

  // The bar tracks the widget mounted in its slot — BarWidget.qml — not this
  // nested panel. Everything the bar identifies a panel by has to be that
  // widget: the popout coordinator (and with it the open-panel dot under the
  // pill) compares against `slot.activeItem`, and switchPanelFrom looks the
  // slot up the same way.
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // ---- Today. SystemClock keeps this honest across midnight so the
  //      highlight rolls over without the panel being reopened.
  property date today: new Date()
  readonly property string todayKey: Model.keyForDate(today)

  // The month on screen. Stepping moves this and nothing else: the grid is
  // a read-out, not a picker, so there is no per-day cursor to keep in sync.
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()

  readonly property date viewDate: new Date(viewYear, viewMonth, 1)
  readonly property bool viewingCurrentMonth: viewYear === today.getFullYear() && viewMonth === today.getMonth()

  // Pinned to today, not to the month being browsed — stepping through the
  // calendar does not change how much of the year is gone.
  readonly property real yearDone: Model.yearProgress(today.getFullYear(), today.getMonth(), today.getDate())
  readonly property int yearDonePercent: Model.yearProgressPercent(today.getFullYear(), today.getMonth(), today.getDate())

  // Memento mori stays local to this clock instance. The exact birth date is
  // needed for exact weekly positioning; 4,000 remains the principled default
  // horizon while a local override keeps the model honest for its owner.
  readonly property string birthDateKey: Model.parseBirthDate(setting("birthDate", ""), today)
  readonly property int horizonWeeks: Model.parseHorizonWeeks(setting("horizonWeeks", 4000))
  readonly property var lifeStats: Model.lifeStats(birthDateKey, today, horizonWeeks)
  readonly property real lifeDone: lifeStats.progress
  readonly property real lifeDonePercent: lifeStats.percent
  property bool editingLife: false
  property bool lifeEntrancePlayed: false
  property bool lifeReturnHandled: false
  property string panelPage: "calendar"
  property real calendarFrameImplicitHeight: 0
  readonly property bool showingLife: panelPage === "life"

  // Unset falls through to the locale's own first day, so a fresh install
  // starts out matching the rest of the desktop rather than a hardcoded
  // convention. Clicking the grid's "W" heading writes the choice back to
  // shell.json.
  readonly property int weekStart: Model.normalizedWeekStart(setting("weekStartDay", null), Qt.locale().firstDayOfWeek)
  // The interface is English throughout, so day names are not taken from the
  // system locale. Where the week starts still is: that is a regional
  // convention rather than a translation, and it stays overridable above.
  readonly property var labelLocale: Qt.locale("en_US")
  readonly property string nextWeekStartLabel: labelLocale.dayName(Model.toggledWeekStart(weekStart), Locale.LongFormat)
  readonly property var weekdays: Model.weekdayOrder(weekStart)
  readonly property var weeks: Model.monthGrid(viewYear, viewMonth, weekStart, todayKey)


  // Guarded so the widget renders before the bar is injected (the bar-widget
  // contract instantiates it bare).
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property int cellWidth: Style.space(52)
  readonly property int cellHeight: Style.space(34)
  readonly property int cellSpacing: Style.space(2)
  readonly property int weekColumnWidth: Style.space(32)
  readonly property int gutterWidth: Style.space(14)

  function open() {
    refresh()
    root.panelPage = "calendar"
    root.controller.show()
    // Set after showing, not before: showing hands the popout coordinator
    // over, which closes whichever panel was open, and that close clears the
    // shared flag. Deferring means the panel taking over always wins, while
    // a handoff to a panel that does not manage the flag still leaves it
    // cleared rather than stuck on.
    Qt.callLater(function() {
      root.rememberCalendarFrame()
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
  }

  function rememberCalendarFrame() {
    if (calendarColumn && calendarColumn.implicitHeight > 0)
      root.calendarFrameImplicitHeight = Math.max(root.calendarFrameImplicitHeight,
        calendarColumn.implicitHeight)
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    // Dismissing the panel mid-edit would otherwise leave the inputs up,
    // waiting behind a closed popup for the next time it opens.
    if (root.editingLife) root.cancelEditingLife()
    if (root.showingLife) {
      lifeView.cancelEntrance()
      lifeView.clearTemporalSelection()
    }
    root.panelPage = "calendar"
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  // Summoning by hotkey moves no pointer, so a hover the bar was still
  // holding must not keep the center indicators revealed behind the panel.
  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  function refresh() {
    root.today = new Date()
    root.goToToday()
  }

  function goToToday() {
    root.viewYear = today.getFullYear()
    root.viewMonth = today.getMonth()
  }

  function moveMonth(delta) {
    var next = Model.stepMonth(viewYear, viewMonth, delta)
    root.viewYear = next.year
    root.viewMonth = next.month
  }

  function moveYear(delta) {
    moveMonth(delta * 12)
  }

  // Applied locally first so the panel redraws on the click itself; the
  // shell.json write comes back through the bar as the same value. With no
  // writable entry (the widget is not in the layout) it stays a session-only
  // preference rather than doing nothing. The host widget builds its own
  // entry when the label format is cycled, so it has to be kept in step or
  // it would write this key straight back out from a stale copy.
  function persistSettings(values) {
    var entry = { id: root.moduleName }
    for (var existing in root.settings) if (existing !== "id") entry[existing] = root.settings[existing]
    for (var key in values) entry[key] = values[key]

    root.settings = entry
    if (root.hostWidget && "settings" in root.hostWidget) root.hostWidget.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function setWeekStart(day) {
    var next = Model.normalizedWeekStart(day, root.weekStart)
    if (next === root.weekStart) return
    persistSettings({ weekStartDay: Model.weekStartSettingName(next) })
  }

  function startEditingLife() {
    root.editingLife = true
    Qt.callLater(function() {
      bornField.text = root.birthDateKey
      horizonField.text = String(root.horizonWeeks)
      bornField.selectAll()
      bornField.forceActiveFocus()
    })
  }

  function cancelEditingLife() {
    root.editingLife = false
    Qt.callLater(function() { if (keyCatcher) keyCatcher.forceActiveFocus() })
  }

  // Shared by both fields: Tab hops to the other one, Enter commits the pair,
  // Escape drops the lot.
  function handleLifeKey(event, other) {
    if (event.key === Qt.Key_Escape) {
      root.cancelEditingLife()
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.commitLife()
      event.accepted = true
    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
      other.selectAll()
      other.forceActiveFocus()
      event.accepted = true
    }
  }

  function commitLife() {
    var born = Model.parseBirthDate(bornField.text, today)
    var span = Model.parseHorizonWeeks(horizonField.text)
    if (born !== root.birthDateKey || span !== root.horizonWeeks) {
      root.lifeEntrancePlayed = false
      persistSettings({ birthDate: born, horizonWeeks: span })
    }
    cancelEditingLife()
  }

  function showLife() {
    if (root.birthDateKey === "") {
      root.startEditingLife()
      return
    }
    root.rememberCalendarFrame()
    lifeView.resetToNow()
    lifeView.prepareEntrance(!root.lifeEntrancePlayed)
    root.panelPage = "life"
    // A deferred call can outlive the object it captured: a plugin reload
    // unregisters the component while this closure is still queued, and the
    // callback then lands on an invalidated LifeView. Check the function is
    // still there rather than trusting the reference.
    Qt.callLater(function() {
      if (lifeView && typeof lifeView.startPreparedEntrance === "function")
        lifeView.startPreparedEntrance()
      if (keyCatcher) keyCatcher.forceActiveFocus()
    })
  }

  function showCalendar() {
    lifeView.cancelEntrance()
    lifeView.clearTemporalSelection()
    root.panelPage = "calendar"
    Qt.callLater(function() {
      root.rememberCalendarFrame()
      if (keyCatcher) keyCatcher.forceActiveFocus()
    })
  }

  function toggleWeekStart() {
    setWeekStart(Model.toggledWeekStart(root.weekStart))
  }

  function toggleGapRhythm() {
    lifeView.toggleGapRhythm()
  }

  // Live review entry points. Projection and animation style are otherwise
  // keyboard-only, which makes them unreachable while capturing the very
  // motion they produce.
  function toggleProjection() {
    lifeView.toggleProjection()
  }

  function toggleAnimationStyle() {
    lifeView.toggleAnimationStyle()
  }

  function moveInspection(dx, dy) {
    lifeView.moveInspection(dx, dy)
  }

  function interactionState() {
    var morphPresentRect = lifeView.interpolatedMorphRect(
      Model.keyForDate(root.today))
    var morphInspectionRect = lifeView.interpolatedMorphRect(
      lifeView.morphInspectionDateKey)
    var morphPinRect = lifeView.interpolatedMorphRect(lifeView.pinnedDateKey)
    return JSON.stringify({
      page: root.panelPage,
      projection: lifeView.projection,
      morphFromProjection: lifeView.morphFromProjection,
      morphProgress: lifeView.morphProgress,
      morphGeometryProgress: lifeView.morphGeometryProgress(),
      projectionMorphing: lifeView.projectionMorphing,
      dateOverlapEnabled: lifeView.dateOverlapEnabled,
      morphInspectionDateKey: lifeView.morphInspectionDateKey,
      morphPresentX: morphPresentRect.visible ? morphPresentRect.x : -1,
      morphPresentY: morphPresentRect.visible ? morphPresentRect.y : -1,
      morphInspectionX: morphInspectionRect.visible ? morphInspectionRect.x : -1,
      morphInspectionY: morphInspectionRect.visible ? morphInspectionRect.y : -1,
      morphPinX: morphPinRect.visible ? morphPinRect.x : -1,
      morphPinY: morphPinRect.visible ? morphPinRect.y : -1,
      gapRhythmEnabled: lifeView.gapRhythmEnabled,
      gapRhythmProgress: lifeView.gapRhythmProgress,
      gapRhythmAnimating: lifeView.gapRhythmAnimating,
      presentIndex: lifeView.presentCellIndex,
      inspectedIndex: lifeView.inspectedIndex(),
      keyboardInspecting: lifeView.keyboardInspecting,
      keyboardIndex: lifeView.keyboardIndex,
      hoveredIndex: lifeView.hoveredIndex,
      hoverArmed: lifeView.hoverArmed,
      horizontalRepeatCadence: lifeView.horizontalRepeatCadence,
      horizontalTraversalInterval: lifeView.horizontalTraversalInterval(),
      semanticColumnGap: lifeView.semanticColumnGap(),
      semanticRowGap: lifeView.semanticRowGap(),
      ordinaryColumnGap: lifeView.columnGapFor(lifeView.projection),
      ordinaryRowGap: lifeView.rowGap(),
      cellWidth: lifeView.cellWidth(),
      cellHeight: lifeView.cellHeight(),
      gridWidth: lifeView.gridWidth(),
      gridHeight: lifeView.gridHeight(),
      panelContentWidth: panel.contentWidth,
      panelContentHeight: panel.contentHeight,
      panelOriginY: panel.cardOrigin.y,
      panelScreenHeight: panel.screenH,
      panelAnchorY: panel.anchorScreenPos.y,
      panelAnchorHeight: panel.anchorH,
      temporalFrameLeft: lifeView.temporalFrameLeft,
      temporalFrameRight: lifeView.temporalFrameRight,
      lifeTrackLeft: lifeView.lifeTrackLeft,
      lifeTrackRight: lifeView.lifeTrackRight,
      lifeTrackWidth: lifeView.lifeTrackWidth,
      structurePaintCount: lifeView.structurePaintCount,
      interactionPaintCount: lifeView.interactionPaintCount,
      visibleRowCount: lifeView.visibleRowCount,
      inspectionMoveBlocked: Date.now() < lifeView.inspectionMoveBlockedUntil,
      pinnedDateKey: lifeView.pinnedDateKey,
      pinnedIndex: lifeView.pinnedIndex,
      inspectionDeltaLabel: lifeView.inspectionDelta.label,
      pinDeltaLabel: lifeView.pinDelta.label,
      pinHorizontalDimension: lifeView.pinRulerDelta.horizontalLabel,
      pinVerticalDimension: lifeView.pinRulerDelta.verticalLabel,
      pinCompactTotal: lifeView.pinRulerDelta.totalLabel,
      deltaLabel: lifeView.visibleDelta.label,
      deltaVisible: lifeView.deltaVisible,
      pinBridgeProgress: lifeView.pinBridgeProgress,
      pinRetargeting: lifeView.pinRetargeting,
      pinRetargetProgress: lifeView.pinRetargetProgress,
      pinRulerHovered: lifeView.pinRulerHovered,
      pinInspectionActive: lifeView.pinInspectionActive,
      pinPressActive: lifeView.pinPressActive,
      draggingPin: lifeView.draggingPin,
      pinRulerVisible: lifeView.pinRulerGeometry().visible,
      pinRulerLength: lifeView.pinRulerGeometry().visible
        ? lifeView.pinRulerGeometry().totalLength : 0,
      visibleYearStart: lifeView.visibleYearStart
    })
  }

  // English short day names, matching the rest of the interface.
  function weekdayLabel(weekday) {
    return String(labelLocale.dayName(weekday, Locale.ShortFormat)).toUpperCase()
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: {
      if (Model.keyForDate(clock.date) === String(root.todayKey)) return
      var followToday = root.viewingCurrentMonth
      root.today = clock.date
      if (followToday) root.goToToday()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(620))
    // Calendar is the size contract for both pages. LIFE spends the recovered
    // height on its Canvas rather than resizing the anchored widget.
    contentHeight: panel.fittedContentHeight(Math.max(root.calendarFrameImplicitHeight,
      calendarColumn.implicitHeight) + Style.space(46))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.editingLife
      onMoveRequested: function(dx, dy) {
        if (root.showingLife) {
          lifeView.moveInspection(dx, dy)
          return
        }
        if (dx !== 0) root.moveMonth(dx)
        if (dy !== 0) root.moveYear(dy)
      }
      onActivateRequested: {
        if (root.showingLife) {
          if (root.lifeReturnHandled) root.lifeReturnHandled = false
          else lifeView.resetToNow(true)
        } else root.goToToday()
      }
      onReturnRequested: {
        if (root.showingLife) {
          root.lifeReturnHandled = true
          lifeView.togglePinAtInspection()
        }
      }
      onCloseRequested: {
        if (root.showingLife && lifeView.pinPressActive) lifeView.cancelPinDrag()
        else if (root.showingLife && lifeView.hasPin) lifeView.clearPin()
        else root.close()
      }
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (root.showingLife) {
          if (t === "t" || t === "T") lifeView.resetToNow(true)
          else if (t === "m" || t === "M") root.showCalendar()
          else if (t === "p" || t === "P") lifeView.toggleProjection()
          else if (t === "a" || t === "A") lifeView.toggleAnimationStyle()
          else if (t === "g" || t === "G") lifeView.toggleGapRhythm()
          return
        }
        if (t === "m" || t === "M") root.showLife()
        else if (t === "[") root.moveMonth(-1)
        else if (t === "]") root.moveMonth(1)
        else if (t === "{") root.moveYear(-1)
        else if (t === "}") root.moveYear(1)
        else if (t === "t" || t === "T") root.goToToday()
        else if (t === "w" || t === "W") root.toggleWeekStart()
      }

      Flickable {
        id: calendarScroll
        visible: !root.showingLife
        anchors.fill: parent
        contentWidth: calendarColumn.width
        contentHeight: calendarColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height || contentWidth > width

        Column {
          id: calendarColumn
          // Never narrower than the grid. The popup width is capped to what
          // the screen allows, and a fixed seven-column grid would otherwise
          // lose its last days off the edge instead of scrolling.
          width: Math.max(calendarScroll.width, gridColumn.width)
          spacing: Style.space(8)

          // ---- Hero: today, centered. Once the view has stepped back
          //      it is also the way home — clicking the date you are
          //      looking for beats hunting for a reset button.
          Item {
            width: parent.width
            height: heroRow.height

            Row {
              id: heroRow
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(22)

              Text {
                // Baseline-aligned, not center-aligned: "July 26" carries a
                // descender, so centering the two boxes leaves the icon
                // sitting visibly low against the digits.
                anchors.baseline: heroDate.baseline
                text: "󰃭"
                color: heroMouse.containsMouse
                  ? Style.hoverStateColor(root.contentForeground, Color.accent)
                  : root.contentForeground
                font.family: root.contentFontFamily
                // Decorative, and deliberately outside the Style.font.*
                // scale. Sized so the glyph reads at the cap height of the
                // date beside it rather than towering over it.
                font.pixelSize: 48
              }

              Text {
                id: heroDate
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(root.today, "MMMM d")
                color: heroMouse.containsMouse
                  ? Style.hoverStateColor(root.contentForeground, Color.accent)
                  : root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: 52
                font.bold: true
              }
            }

            MouseArea {
              id: heroMouse
              x: heroRow.x
              y: heroRow.y
              width: heroRow.width
              height: heroRow.height
              enabled: !root.viewingCurrentMonth
              hoverEnabled: enabled
              cursorShape: Qt.PointingHandCursor
              onClicked: root.goToToday()

              PanelToolTip {
                visible: heroMouse.containsMouse
                text: "Back to today"
                fontFamily: root.contentFontFamily
              }
            }
          }

          // ---- Year progress, doubling as the rule under the hero:
          //      a plain hairline said nothing, and whole days done
          //      over days in the year says the same thing louder.
          Item {
            width: parent.width
            height: yearBlock.y + yearBlock.height

            Item {
              id: yearBlock
              y: Style.space(6)
              anchors.horizontalCenter: parent.horizontalCenter
              width: gridColumn.width
              height: Math.max(yearLabel.implicitHeight, Style.space(10))

              TapHandler {
                enabled: !root.editingLife
                onDoubleTapped: root.startEditingLife()
              }

              Row {
                visible: root.editingLife
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(10)

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "BORN"
                  color: Qt.darker(root.contentForeground, 1.5)
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.letterSpacing: 1
                }

                TextField {
                  id: bornField
                  width: Style.space(110)
                  anchors.verticalCenter: parent.verticalCenter
                  placeholderText: "YYYY-MM-DD"
                  foreground: root.contentForeground
                  font.family: root.contentFontFamily
                  inputMethodHints: Qt.ImhPreferNumbers

                  Keys.onPressed: function(event) { root.handleLifeKey(event, horizonField) }
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.verticalCenterOffset: 0
                  leftPadding: Style.space(6)
                  text: "WEEKS"
                  color: Qt.darker(root.contentForeground, 1.5)
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.letterSpacing: 1
                }

                TextField {
                  id: horizonField
                  width: Style.space(72)
                  anchors.verticalCenter: parent.verticalCenter
                  placeholderText: "4000"
                  foreground: root.contentForeground
                  font.family: root.contentFontFamily
                  inputMethodHints: Qt.ImhDigitsOnly

                  Keys.onPressed: function(event) { root.handleLifeKey(event, bornField) }
                }
              }

              Text {
                id: yearLabel
                visible: !root.editingLife
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.today.getFullYear()
                color: Qt.darker(root.contentForeground, 1.5)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.bodySmall
                font.letterSpacing: 1
              }

              Text {
                id: yearPercentMetric
                visible: false
                text: "100.0%"
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.bodySmall
              }

              Text {
                id: yearPercent
                visible: !root.editingLife
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: yearPercentMetric.implicitWidth
                horizontalAlignment: Text.AlignRight
                // Both readings carry one decimal and one reserved width, so
                // neither the precision nor the track length can disagree.
                text: Number(root.yearDone * 100).toFixed(1) + "%"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.bodySmall
              }

              Rectangle {
                id: yearTrack
                visible: !root.editingLife
                anchors.left: yearLabel.right
                anchors.right: yearPercent.left
                anchors.leftMargin: Style.space(12)
                anchors.rightMargin: Style.space(12)
                anchors.verticalCenter: parent.verticalCenter
                height: Style.space(6)
                radius: Style.cornerRadius > 0 ? height / 2 : 0
                color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)

                Rectangle {
                  width: Math.round(parent.width * root.yearDone)
                  height: parent.height
                  radius: parent.radius
                  color: Style.selectedStateColor(root.contentForeground, Color.accent)

                  Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                }
              }
            }
          }

          // ---- Memento mori. The native LIFE rail now leads somewhere:
          //      one click keeps the same popup open and reveals the finite
          //      timeline. Its geometry and progress are shared with that
          //      view through LifeRail rather than reimplemented there.
          Item {
            visible: root.birthDateKey !== ""
            width: parent.width
            height: visible ? lifeRail.height : 0

            LifeRail {
              id: lifeRail
              anchors.horizontalCenter: parent.horizontalCenter
              width: gridColumn.width
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              progress: root.lifeDone
              percent: root.lifeDonePercent
              horizonWeeks: root.horizonWeeks
              interactive: true
              tooltipText: "Memento Mori"
              onActivated: root.showLife()
            }
          }

          // ---- Month grid: week numbers down a gutter on the left, then
          //      the seven day columns. Always six rows, so the popup is
          //      exactly as tall in February as it is in August.
          Item {
            width: parent.width
            height: gridColumn.y + gridColumn.height

            WheelHandler {
              onWheel: function(event) {
                // Horizontal wheels and touchpad side-scrolls report y === 0;
                // without this they would every one read as "next month".
                if (event.angleDelta.y === 0) return
                root.moveMonth(event.angleDelta.y > 0 ? -1 : 1)
              }
            }

            Column {
              id: gridColumn
              // The meter above is a solid rule; the grid needs room to
              // read as its own block rather than hanging off it.
              y: Style.space(18)
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(3)

              Row {
                id: headerRow
                spacing: root.cellSpacing

                // The week-number heading doubles as the week-start toggle.
                // It is the one control in the panel whose meaning is not
                // self-evident, so it carries a tooltip naming the day the
                // click will switch to.
                Rectangle {
                  width: root.weekColumnWidth
                  height: Style.space(16)
                  radius: Style.cornerRadius
                  color: weekStartMouse.containsMouse
                    ? Style.hoverFillFor(root.contentForeground, Color.accent)
                    : "transparent"

                  Text {
                    anchors.centerIn: parent
                    text: "W"
                    color: weekStartMouse.containsMouse
                      ? Style.hoverStateColor(root.contentForeground, Color.accent)
                      : Qt.darker(root.contentForeground, 1.9)
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    font.letterSpacing: 1
                    font.bold: true
                  }

                  MouseArea {
                    id: weekStartMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleWeekStart()
                  }

                  PanelToolTip {
                    visible: weekStartMouse.containsMouse
                    text: "Start weeks on " + root.nextWeekStartLabel
                    fontFamily: root.contentFontFamily
                  }
                }

                Item {
                  width: root.gutterWidth
                  height: Style.space(16)
                }

                Repeater {
                  model: root.weekdays

                  Text {
                    required property var modelData
                    width: root.cellWidth
                    height: Style.space(16)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: root.weekdayLabel(modelData)
                    color: Qt.darker(root.contentForeground, 1.5)
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    font.letterSpacing: 1
                    font.bold: true
                  }
                }
              }

              Repeater {
                model: root.weeks

                Row {
                  required property var modelData
                  spacing: root.cellSpacing

                  Text {
                    width: root.weekColumnWidth
                    height: root.cellHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.week
                    color: Qt.darker(root.contentForeground, 1.9)
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                  }

                  Item {
                    width: root.gutterWidth
                    height: root.cellHeight
                  }

                  Repeater {
                    model: modelData.days

                    Rectangle {
                      required property var modelData

                      width: root.cellWidth
                      height: root.cellHeight
                      radius: Style.cornerRadius
                      // Today is outlined, not filled: a lit-up block shouts
                      // over a grid this quiet.
                      color: "transparent"
                      border.width: modelData.today ? Style.spacing.hairline : 0
                      border.color: Style.normalBorderFor(root.contentForeground, Color.accent)

                      Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: modelData.inMonth
                          ? (modelData.weekend ? Qt.darker(root.contentForeground, 1.45) : root.contentForeground)
                          : Qt.darker(root.contentForeground, 2.2)
                        font.family: root.contentFontFamily
                        font.pixelSize: Style.font.body
                        font.bold: modelData.today
                      }
                    }
                  }
                }
              }
            }

            // Hairline down the week-number gutter, drawn only beside the
            // day rows so it does not cut through the header band.
            Rectangle {
              x: gridColumn.x + root.weekColumnWidth + root.cellSpacing + Math.round((root.gutterWidth - width) / 2)
              y: gridColumn.y + headerRow.height + gridColumn.spacing
              width: Style.spacing.hairline
              height: gridColumn.height - headerRow.height - gridColumn.spacing
              color: root.contentForeground
              opacity: 0.1
            }
          }

          // ---- Month stepping, spanning the grid it drives. The chevrons
          //      sit on the grid's outer bounds, the same edges the year
          //      rail above uses, so the row reads as the panel's other
          //      full-width rail instead of a cluster floating in space.
          //      The label is centered and fixed-width, so it holds still
          //      from "MAY" to "SEPTEMBER".
          Item {
            width: parent.width
            height: monthNav.height

            Item {
              id: monthNav
              anchors.horizontalCenter: parent.horizontalCenter
              width: gridColumn.width
              height: monthLabel.implicitHeight + Style.space(10)

              Text {
                id: monthLabel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                // Fixed width so the chevrons hold still between a
                // "MAY 2026" and a "SEPTEMBER 2026".
                width: Style.space(130)
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(root.viewDate, "MMMM yyyy").toUpperCase()
                color: Qt.darker(root.contentForeground, 1.4)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.letterSpacing: 1
              }

              PanelActionButton {
                // Pulled out by the button's own padding so the glyph, not
                // its hit box, lines up with the "2026" on the year rail.
                anchors.left: parent.left
                anchors.leftMargin: -Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                iconText: "󰅁"
                tooltipText: "Previous month"
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.moveMonth(-1)
              }

              PanelActionButton {
                anchors.right: parent.right
                anchors.rightMargin: -Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                iconText: "󰅂"
                tooltipText: "Next month"
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.moveMonth(1)
              }
            }
          }
        }
      }

      LifeView {
        id: lifeView
        visible: root.showingLife
        anchors.fill: parent
        birthKey: root.birthDateKey
        today: root.today
        horizonWeeks: root.horizonWeeks
        foreground: root.contentForeground
        fontFamily: root.contentFontFamily
        onBackRequested: root.showCalendar()
        onEntranceCompleted: function(fullEntrance) {
          if (fullEntrance) root.lifeEntrancePlayed = true
        }
      }
    }
  }
}
