Cached.Views.Articles ||= {}

class Cached.Views.Articles.EditView extends Backbone.View
  template: JST['backbone/templates/articles/edit']

  events:
    'submit #edit-article': 'update'
    'click #delete-btn': 'delete'

  update: (e) ->
    e.preventDefault()
    e.stopPropagation()

    @beforeSave()
    @model.save(null,
      success: =>
        window.location.hash = "/#{@model.id}"
      error: (article, jqXHR) =>
        alert jqXHR.responseText
    )

  delete: ->
    if (confirm 'Are you sure you want to delete?')
      @model.destroy
        success: ->
          window.location.hash = '/index'
        error: ->
          alert 'Delete was not successful'

  beforeSave: ->
    @$('#body').val $("[contenteditable='true']").html()
    @$('#body').change() # trigger backbone link

  render: ->
    $(@el).html(@template(@model.toJSON()))
    @$('form').backboneLink(@model)
    @