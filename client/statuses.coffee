'use strict'

import {statuses, DisplayedStatus} from '../lib/imports/statuses.coffee'

Template.statuses.helpers
  displayedStatus: -> DisplayedStatus(Template.instance().data.statuses).name
  displayedBtnType: -> DisplayedStatus(Template.instance().data.statuses).btnType
  displayedExplanation: -> DisplayedStatus(Template.instance().data.statuses).explanation
  statusesList: -> status for c, status of statuses
  isChecked: -> Template.instance().data.statuses?.includes @canon

Template.statuses.events
  'change input[data-status]': (event, template) ->
    method = if event.currentTarget.checked then 'addStatus' else 'removeStatus'
    Meteor.call method, template.data._id, event.currentTarget.dataset.status
  'click li a': (event, template) ->
    # Stop the dropdown from closing.
    event.stopPropagation()
