import { reactiveLocalStorage } from './imports/storage.coffee'

# console.log('compactMode? ', reactiveLocalStorage.getItem compactMode)
# console.log('darkMode? ', reactiveLocalStorage.getItem darkMode)

doBoolean = (name, newVal) ->
  reactiveLocalStorage.setItem name, newVal

Template.options.events
  "change .bb-hide-solved input": (event, template) ->
    doBoolean 'hideSolved', event.target.checked
  "change .bb-hide-solved-meta input": (event, template) ->
    doBoolean 'hideSolvedMeta', event.target.checked
  "change .bb-compact-mode input": (event, template) ->
    doBoolean 'compactMode', event.target.checked
  "change .bb-boring-mode input": (event, template) ->
    doBoolean 'boringMode', event.target.checked
  "change .bb-dark-mode input": (event, template) ->
    doBoolean 'darkMode', event.target.checked
    document.body.classList.toggle('dark-theme')

  'click li a': (event, template) -> event.stopPropagation()
