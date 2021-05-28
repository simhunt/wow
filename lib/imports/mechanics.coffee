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
new Mechanic 'crossword/wordplay'
new Mechanic 'cryptic'
new Mechanic 'duck konundrum'
new Mechanic 'extraction'
new Mechanic 'grunt work'
new Mechanic 'ID task'
new Mechanic 'location-based/runaround'
new Mechanic 'logic'
new Mechanic 'math'
new Mechanic 'MIT knowledge'
new Mechanic 'music'
new Mechanic 'physical'
new Mechanic 'sports'
new Mechanic 'text adventure'
new Mechanic 'TV and movie'
new Mechanic 'video game'

Object.freeze mechanics

export IsMechanic = Match.Where (x) -> mechanics[x]?
