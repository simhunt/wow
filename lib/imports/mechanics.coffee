'use strict'

import canonical from './canonical.coffee'

export mechanics = {}

export class Mechanic
  constructor: (@name) ->
    @canon = canonical @name
    mechanics[@canon] = @
    Object.freeze @

new Mechanic 'meta squad'
new Mechanic 'backsolvers'
new Mechanic 'extraction'
new Mechanic 'grunt work'
new Mechanic 'ID task'
new Mechanic 'code'
new Mechanic 'crossword'
new Mechanic 'cryptic'
new Mechanic 'duck conundrum'
new Mechanic 'grid logic'
new Mechanic 'location-based'
new Mechanic 'physical'
new Mechanic 'runaround'
new Mechanic 'audio manipulation'
new Mechanic 'biology'
new Mechanic 'board games'
new Mechanic 'chemistry'
new Mechanic 'chinese'
new Mechanic 'ciphers'
new Mechanic 'classics'
new Mechanic 'food/cooking'
new Mechanic 'geography'
new Mechanic 'history/law/politics'
new Mechanic 'IPA (phonetics)'
new Mechanic 'knitting'
new Mechanic 'lgbt'
new Mechanic 'literature'
new Mechanic 'math'
new Mechanic 'medicine'
new Mechanic 'memes'
new Mechanic 'nikoli'
new Mechanic 'MIT knowledge'
new Mechanic 'musicals/theater'
new Mechanic 'music ID'
new Mechanic 'music theory'
new Mechanic 'niche topic'
new Mechanic 'NPL flat'
new Mechanic 'origami'
new Mechanic 'poetry'
new Mechanic 'pop culture'
new Mechanic 'potent potable'
new Mechanic 'puns'
new Mechanic 'spanish'
new Mechanic 'sport'
new Mechanic 'text adventure'
new Mechanic 'TV and movie'
new Mechanic 'video game'
new Mechanic 'weeb'

Object.freeze mechanics

export IsMechanic = Match.Where (x) -> mechanics[x]?
