'use strict'

import canonical from './canonical.coffee'

export statuses = {}

# Statuses are:
#   name: short name.
#   btnType: associated button type.
#   category: category, used for color coding (should be similar to btnType).
#   priority: lower priorities will be shown first if there are multiple statuses set.
#   explanation: a short explanation.
export class Status
  constructor: (@name, @btnType, @category, @priority, @explanation, fake=false) ->
    @canon = canonical @name
    unless fake
      statuses[@canon] = @
    Object.freeze @

# Statuses should be some state that is unlikely to change unless a human takes direct action, 
# e.g. NOT statuses that don't change over time like "new" or "has not been looked at in a while".
# Names should also be relatively short to avoid changing table width. Current longest is 10.

# Variations on 'solved':
new Status 'Solved!', 'btn-success', 'solved', 1, 'Solved!' # Remember to change solvedStatus below if changing the name here.
new Status 'Backsolved', 'btn-success', 'solved', 0, 'Backsolved from a meta.' # Remember to change backsolvedStatus below if changing the name here.
new Status 'Obsolete', 'btn-success', 'solved', 2, 'This answer doesn\'t impact anything else.'

# Variations on 'attention':
new Status 'Needs eyes', 'btn-warning', 'attention', 10, 'We need a breakthrough! Please take a quick glance.'
new Status 'Extraction', 'btn-warning', 'attention', 11, 'Information is in place but needs answer extraction.'

# Variations on 'stuck':
new Status 'Stuck', 'btn-danger', 'stuck', 21, 'We have spent lots of time and asked for in-team help without progress.'
new Status 'Pending', 'btn-danger', 'stuck', 19, 'We\'re waiting for a response, e.g. from HQ or an on-campus teammate.'
new Status 'Very stuck', 'btn-danger', 'stuck', 20, 'Stuck x2: We\'ve completely given up on this unless we get a hint from HQ.'

Object.freeze statuses

noStatus = new Status 'none', '', 'unsolved', Number.MAX_SAFE_INTEGER, 'No status set.', true
export solvedStatus = statuses['solved!']
export backsolvedStatus = statuses['backsolved']

export IsStatus = Match.Where (x) -> statuses[x]?

export DisplayedStatus = (inputStatuses) ->
  return noStatus unless inputStatuses?

  lowestPrioStatus = noStatus
  for statusCanon in inputStatuses
    status = statuses[statusCanon]
    unless status?
      console.log 'Wrong status found: ', statusCanon
      continue
    if status.priority < lowestPrioStatus.priority
      lowestPrioStatus = status
  lowestPrioStatus
