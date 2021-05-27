'use strict'

import canonical from './canonical.coffee'

export mechanics = {}

export class Mechanic
  constructor: (@name) ->
    @canon = canonical @name
    mechanics[@canon] = @
    Object.freeze @

new Mechanic 'audio manipulation'
new Mechanic 'coding'
new Mechanic 'crossword'
new Mechanic 'cryptic'
new Mechanic 'extraction'
new Mechanic 'grunt work'
new Mechanic 'ID task'
new Mechanic 'linguistics'
new Mechanic 'location-based/runaround'
new Mechanic 'logic'
new Mechanic 'math'
new Mechanic 'MIT knowledge'
new Mechanic 'music'
new Mechanic 'physical'
new Mechanic 'sports'
new Mechanic 'TV and movie'
new Mechanic 'video game'
new Mechanic 'word stuff'

Object.freeze mechanics

export IsMechanic = Match.Where (x) -> mechanics[x]?
