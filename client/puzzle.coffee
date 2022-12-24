'use strict'

import color from './imports/objectColor.coffee'
import embeddable from './imports/embeddable.coffee'

model = share.model # import
settings = share.settings # import

capType = (puzzle) ->
  if puzzle?.puzzles?
    'Meta'
  else
    'Puzzle'

possibleViews = (puzzle) ->
  x = []
  x.push 'spreadsheet' if puzzle?.spreadsheet?
  x.push 'puzzle' if embeddable puzzle?.link
  x.push 'info'
  x.push 'doc' if puzzle?.doc?
  x
currentViewIs = (puzzle, view) ->
  # only puzzle and round have view.
  page = Session.get 'currentPage'
  return false unless (page is 'puzzle') or (page is 'round')
  possible = possibleViews puzzle
  if Session.equals 'view', view
    return true if possible.includes view
  return false if possible.includes Session.get 'view'
  return view is possible[0]

updatePuzzleTimer = () ->
  start = Session.get 'puzzleTimerStart'
  totalTimeInSec = Math.round ((Date.now() - start) / 1000.0)
  hrsPassed = Math.floor (totalTimeInSec / (60 * 60))
  minPassed = Math.floor ((totalTimeInSec %% (60 * 60)) / 60)
  secPassed = totalTimeInSec %% 60
  hrsPassedString = hrsPassed.toLocaleString('en-US', {minimumIntegerDigits: 2, useGrouping: false})
  minPassedString = minPassed.toLocaleString('en-US', {minimumIntegerDigits: 2, useGrouping: false})
  secPassedString = secPassed.toLocaleString('en-US', {minimumIntegerDigits: 2, useGrouping: false})
  Session.set 'puzzleTimer', (hrsPassedString + ":" + minPassedString + ":" + secPassedString)

pausePuzzleTimer = () ->
  # Don't do anything if the timer is already paused.
  return if Session.get 'puzzleTimerPaused' ? true

  if (Session.get 'puzzleTimerIntervalHandle')?
    Meteor.clearInterval (Session.get 'puzzleTimerIntervalHandle')

  Session.set 'puzzleTimerPaused', true
  Session.set 'puzzleTimerPauseTime', Date.now()

startPuzzleTimer = () ->
  intervalHandle = Meteor.setInterval updatePuzzleTimer, 1000
  Session.set 'puzzleTimerIntervalHandle', intervalHandle
  updatePuzzleTimer()

Template.puzzle_info.helpers
  tag: (name) -> (model.getTag this, name) or ''
  getPuzzle: -> model.Puzzles.findOne this
  caresabout: ->
    cared = model.getTag @puzzle, "Cares About"
    (
      name: tag
      canon: model.canonical tag
    ) for tag in cared?.split(',') or []

  unsetcaredabout: ->
    return unless @puzzle
    r = for meta in (model.Puzzles.findOne m for m in @puzzle.feedsInto)
      continue unless meta?
      for tag in meta.tags.cares_about?.value.split(',') or []
        continue if model.getTag @puzzle, tag
        { name: tag, meta: meta.name }
    [].concat r...
    
  metatags: ->
    return unless @puzzle?
    r = for meta in (model.Puzzles.findOne m for m in @puzzle.feedsInto)
      continue unless meta?
      for canon, tag of meta.tags
        continue unless /^meta /i.test tag.name
        {name: tag.name, value: tag.value, meta: meta.name}
    [].concat r...

  timer: ->
    unless (Session.get 'puzzleTimerInitAlready')?
      Session.set 'puzzleTimerInitAlready', true
      Session.set 'puzzleTimerStart', Date.now()
      startPuzzleTimer()
      Session.set 'puzzleTimerPaused', false
    Session.get 'puzzleTimer'

  timerPaused: ->
    Session.get 'puzzleTimerPaused' ? false

Template.puzzle_info.events
  'click .bb-reset-timer-button': (event, template) ->
    Session.set 'puzzleTimerStart', Date.now()
    Session.set 'puzzleTimerPauseTime', Date.now()
    pausePuzzleTimer()
    updatePuzzleTimer()
  'click .bb-pause-start-timer-button': (event, template) ->
    isPaused = Session.get 'puzzleTimerPaused' ? false
    if isPaused
      # Update timer start with the elapsed time since pausing.
      Session.set 'puzzleTimerStart', ((Session.get 'puzzleTimerStart') + Date.now() - (Session.get 'puzzleTimerPauseTime'))
      startPuzzleTimer()
    else
      pausePuzzleTimer()
    Session.set 'puzzleTimerPaused', not isPaused



Template.puzzle.helpers
  data: ->
    r = {}
    puzzle = r.puzzle = model.Puzzles.findOne Session.get 'id'
    round = r.round = model.Rounds.findOne puzzles: puzzle?._id
    r.isMeta = puzzle?.puzzles?
    r.stuck = model.isStuck puzzle
    r.capType = capType puzzle
    return r
  vsize: -> share.Splitter.vsize.get()
  vsizePlusHandle: -> +share.Splitter.vsize.get() + 6
  hsize: -> share.Splitter.hsize.get()
  currentViewIs: (view) -> currentViewIs @puzzle, view
  color: -> color @puzzle if @puzzle

Template.header_breadcrumb_extra_links.helpers
  currentViewIs: (view) -> currentViewIs this, view

Template.puzzle.onCreated ->
  this.autorun =>
    # set page title
    id = Session.get 'id'
    puzzle = model.Puzzles.findOne id
    name = puzzle?.name or id
    $("title").text("#{capType puzzle}: #{name}")
  # presumably we also want to subscribe to the puzzle's chat room
  # and presence information at some point.
  this.autorun =>
    return if settings.BB_SUB_ALL
    id = Session.get 'id'
    return unless id
    @subscribe 'puzzle-by-id', id
    @subscribe 'round-for-puzzle', id
    @subscribe 'puzzles-by-meta', id

# Make sure that the answer / status boxes automatically get focus when we click
Template.puzzle.onRendered ->
  this.autorun => 
    editing = Session.get 'editing'
    return unless editing?
    Meteor.defer () ->
      $("##{editing.split('/').join '-'}").focus()


Template.puzzle_summon_button.helpers
  stuck: -> model.isStuck this

Template.puzzle_add_tag.events
  "click .bb-add-tag": (event, template) ->
    alertify.prompt "Name of new tag:", (e,str) =>
      return unless e # bail if cancelled
      Meteor.call 'setTag',
        type: "puzzles"
        object: Session.get 'id'
        name: str
        value: ''

Template.puzzle_summon_button.events
  "click .bb-summon-btn.unstuck": (event, template) ->
    how = "Stuck"
    Meteor.call 'summon',
      type: Session.get 'type'
      object: Session.get 'id'
      how: how
  "click .bb-summon-btn.stuck": (event, template) ->
    Meteor.call 'unsummon',
      type: Session.get 'type'
      object: Session.get 'id'
      
Template.puzzle_summon_modal.events
  "click .bb-summon-submit, submit form": (event, template) ->
    event.preventDefault() # don't reload page
    at = template.$('.stuck-at').val()
    need = template.$('.stuck-need').val()
    other = template.$('.stuck-other').val()
    how = "Stuck #{at}"
    if need isnt 'other'
        how += ", need #{need}"
    if other isnt ''
        how += ": #{other}"
    Meteor.call 'summon',
      type: Session.get 'type'
      object: Session.get 'id'
      how: how
    template.$('.modal').modal 'hide'

Template.puzzle.events
  'click .gCanEdit.bb-editable': (event, template) ->
    # note that we rely on 'blur' on old field (which triggers ok or cancel)
    # happening before 'click' on new field
    Session.set 'editing', share.find_bbedit(event).join('/')
  'click input[type=color]': (event, template) ->
    event.stopPropagation()
  'input input[type=color]': (event, template) ->
    edit = $(event.currentTarget).closest('*[data-bbedit]').attr('data-bbedit')
    [type, id, rest...] = edit.split('/')
    # strip leading/trailing whitespace from text (cancel if text is empty)
    text = hexToCssColor event.currentTarget.value.replace /^\s+|\s+$/, ''
    processBlackboardEdit[type]?(text, id, rest...) if text
  'click .bb-delete-icon': (event, template) ->
    event.stopPropagation() # keep .bb-editable from being processed!
    [type, id, rest...] = share.find_bbedit(event)
    message = "Are you sure you want to delete "
    if (type is'tags') or (rest[0] is 'title')
      message += "this #{model.pretty_collection(type)}?"
    else
      message += "the #{rest[0]} of this #{model.pretty_collection(type)}?"
    share.confirmationDialog
      ok_button: 'Yes, delete it'
      no_button: 'No, cancel'
      message: message
      ok: ->
        processBlackboardEdit[type]?(null, id, rest...) # process delete


okCancelEvents = share.okCancelEvents = (selector, callbacks) ->
  ok = callbacks.ok or (->)
  cancel = callbacks.cancel or (->)
  evspec = ("#{ev} #{selector}" for ev in ['keyup','keydown','focusout'])
  events = {}
  events[evspec.join(', ')] = (evt) ->
    if evt.type is "keydown" and evt.which is 27
      # escape = cancel
      cancel.call this, evt
    else if evt.type is "keyup" and evt.which is 13 or evt.type is "focusout"
      # blur/return/enter = ok/submit if non-empty
      value = String(evt.target.value or "")
      if value
        ok.call this, value, evt
      else
        cancel.call this, evt
  events

processBlackboardEdit =
  tags: (text, id, canon, field) ->
    field = 'name' if text is null # special case for delete of status tag
    processBlackboardEdit["tags_#{field}"]?(text, id, canon)
  puzzles: (text, id, field) ->
    processBlackboardEdit["puzzles_#{field}"]?(text, id)
  rounds: (text, id, field) ->
    processBlackboardEdit["rounds_#{field}"]?(text, id)
  puzzles_title: (text, id) ->
    if text is null # delete puzzle
      Meteor.call 'deletePuzzle', id
    else
      Meteor.call 'renamePuzzle', {id:id, name:text}
  rounds_title: (text, id) ->
    if text is null # delete round
      Meteor.call 'deleteRound', id
    else
      Meteor.call 'renameRound', {id:id, name:text}
  tags_name: (text, id, canon) ->
    n = model.Names.findOne(id)
    if text is null # delete tag
      return Meteor.call 'deleteTag', {type:n.type, object:id, name:canon}
    t = model.collection(n.type).findOne(id).tags[canon]
    Meteor.call 'setTag', {type:n.type, object:id, name:text, value:t.value}, (error,result) ->
      if (canon isnt model.canonical(text)) and (not error)
        Meteor.call 'deleteTag', {type:n.type, object:id, name:t.name}
  tags_value: (text, id, canon) ->
    n = model.Names.findOne(id)
    t = model.collection(n.type).findOne(id).tags[canon]
    # special case for 'status' tag, which might not previously exist
    for special in ['Status', 'Answer']
      if (not t) and canon is model.canonical(special)
        t =
          name: special
          canon: model.canonical(special)
          value: ''
    # set tag (overwriting previous value)
    Meteor.call 'setTag', {type:n.type, object:id, name:t.name, value:text}
  link: (text, id) ->
    n = model.Names.findOne(id)
    Meteor.call 'setField',
      type: n.type
      object: id
      fields: link: text

moveWithinMeta = (pos) -> (event, template) -> 
  meta = template.data
  Meteor.call 'moveWithinMeta', @puzzle._id, meta.puzzle._id, pos: pos

Template.puzzle.events okCancelEvents('.bb-editable input[type=text]',
  ok: (text, evt) ->
    # find the data-bbedit specification for this field
    console.log('hellooooo')
    edit = $(evt.currentTarget).closest('*[data-bbedit]').attr('data-bbedit')
    console.log(edit)
    [type, id, rest...] = edit.split('/')
    console.log(type)
    console.log(id)
    console.log(rest)
    # strip leading/trailing whitespace from text (cancel if text is empty)
    text = text.replace /^\s+|\s+$/, ''
    processBlackboardEdit[type]?(text, id, rest...) if text
    Session.set 'editing', undefined # done editing this
  cancel: (evt) ->
    Session.set 'editing', undefined # not editing anything anymore
)
