# Format Coffeekup's html-output to human-readable form with indents and line breaks.
@.format = true

# NOTE! If you update templates, update the 'templatesversion' in layout.coffee
# TODO some automatic system for template version detection?

# Map page -template
div id: 'map-page', ->
  header 'data-role': 'header', ->
    h1 'Map'


# Navigation bar -template
div id: 'navigation-bar'


# User settings page -template
div id: 'user-settings-page', ->
  header 'data-role': 'header'


