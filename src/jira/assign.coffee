Config = require "../config"
User = require "./user"
Utils = require "../utils"

class Assign

  @forTicketToPerson: (ticket, person, msg, includeAttachment=no) ->
    person = if person is "me" then msg.message.user.name else person
    slackUser = Utils.lookupSlackUser person

    if slackUser
      User.withEmail(slackUser.email_address)
      .then (user) ->
        Utils.fetch "#{Config.jira.url}/rest/api/2/issue/#{ticket.key}",
          method: "PUT"
          body: JSON.stringify
            fields:
              assignee:
                name: user.name
      .then ->
        Create = require "./create"
        Create.fromKey ticket.key
      .then (ticket) ->
        msg.robot.emit "JiraTicketAssigned", ticket, slackUser, msg.message.room, includeAttachment
      .catch (error) ->
        msg.robot.emit "JiraTicketAssignmentFailed", error, msg.message.room
        Promise.reject error
    else
      error = "Cannot find slack user `#{person}`"
      msg.robot.emit "JiraTicketAssignmentFailed", error, msg.message.room
      Promise.reject error

  @forTicketKeyToPerson: (key, person, msg, includeAttachment=no) ->
    Create = require "./create"
    Create.fromKey(key)
    .then (ticket) ->
      Assign.forTicketToPerson ticket, person, msg, includeAttachment

  @forTicketKeyToUnassigned: (key, msg, includeAttachment=no) ->
    Utils.fetch "#{Config.jira.url}/rest/api/2/issue/#{key}",
      method: "PUT"
      body: JSON.stringify
        fields:
          assignee:
            name: null
    .then ->
      Create = require "./create"
      Create.fromKey(key)
      .then (ticket) ->
        msg.robot.emit "JiraTicketUnassigned", ticket, msg.message.room, no

module.exports = Assign
