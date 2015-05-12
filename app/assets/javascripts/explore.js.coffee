Explore =
  init: () ->
    return if $('#explore_projects_page').length == 0

    $('#explore_search_form .icon-search').click (e) ->
      e.preventDefault()
      $(this).closest('form').trigger('submit')
      return false

    $("#explore_search_form input[name='q']").keydown (e) ->
      if e.which == 13
        e.preventDefault()
        $(this).siblings('.icon-search').trigger('click')
        return false

    $('.similar_projects #project').autocomplete
      source: '/autocompletes/project'
      select: (e, ui) ->
        $('#project').val(ui.item.value)
        $('#proj_id').val(ui.item.id)
        $(this).parents('form:first').submit()

    $('.similar_projects .icon-search').click (e) ->
      $(this).parents('form:first').trigger('submit')

    $('form[rel=similar_project_jump]').submit (e) ->
      projectId = $("#proj_id").val()
      if $('#project').val() != '' and projectId != ''
        e.preventDefault()
        $('#proj_id').val('')
        window.location.href = "/p/#{projectId}/similar"
      else
        $('span.error').removeClass('hidden')
        return false

    $('form[rel=sort_filter] select').change () ->
      if $('#explore_projects_page') && $(this).val() == ''
        $(this).attr('disabled', 'disabled')
      $(this).parents('form').attr('action', document.location).submit()