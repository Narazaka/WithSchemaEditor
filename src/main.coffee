fs = require 'fs'
path = require 'path'
jsyaml = require 'js-yaml'
remote = require 'remote'
app = remote.require 'app'
BrowserWindow = remote.require 'browser-window'
dialog = remote.require 'dialog'

cwd = process.cwd()

# read config
config_path = path.join cwd, 'WithSchemaEditor.config.yaml'
try
  config = jsyaml.safeLoad fs.readFileSync config_path
catch
  config = {}

# read schema plugins
schema_plugins_path = path.join cwd, 'node_modules'
try
  schema_plugin_ids = fs.readdirSync schema_plugins_path
  schema_plugins = schema_plugin_ids.filter (schema_plugin_id) ->
    /^with-schema-editor-schema-/.test schema_plugin_id
  .reduce (schema_plugins, schema_plugin_id) ->
    console.log path.join cwd, 'node_modules', schema_plugin_id
    schema_plugins[schema_plugin_id] = require path.join cwd, 'node_modules', schema_plugin_id
    schema_plugins
  , {}
catch error
  dialog.showErrorBox 'Cannot load schema plugins', 'check node_modules directory: ' + error
  app.quit()
unless Object.keys(schema_plugins).length
  dialog.showErrorBox 'No schema plugins found', 'try `npm install with-schema-editor-schema-foo` or some'
  app.quit()

editor = null
schema_plugin = null

config_updated = ->
  if config.target? and config.target.length
    $('#target_view').val config.target
  else
    $('#target_view').val ''
  if config.schema? and config.schema.length
    $('#schema').val config.schema
  fs.writeFileSync config_path, jsyaml.safeDump config

set_schema_plugin = (schema_plugin_id, clear_target=true) ->
  config.schema = schema_plugin_id
  schema_plugin = schema_plugins[config.schema]
  unless schema_plugin
    schema_plugin = schema_plugins[Object.keys(schema_plugins)[0]]

  editor?.destroy()
  if schema_plugin.read_type == 'file'
    $('#target_file').show()
    $('#target_directory').hide()
  else if schema_plugin.read_type == 'directory'
    $('#target_file').hide()
    $('#target_directory').show()
  else
    $('#target_file').show()
    $('#target_directory').show()
  editor = get_editor(schema_plugin.schema())
  schema_plugin.oneditor(editor)
  if clear_target
    set_target(null)
  read()
  config_updated()

set_target = (target) ->
  config.target = target
  read()
  config_updated()

read = ->
  if config.target?
    editor.setValue schema_plugin.read(config.target, editor)

window.onload = ->
  # apply schema plugins settings
  for schema_plugin_id, schema_plugin of schema_plugins
    $('#schema').append $('<option></option>').text(schema_plugin.name).val(schema_plugin_id)
  if config.schema?
    $('#schema').val config.schema

  # schema plugin init
  set_schema_plugin($('#schema').val(), false)

  last_path = if config.target? then config.target else __dirname
  # dom init
  $('#close').click -> app.quit()
  $('#maximize').click ->
    win = BrowserWindow.getFocusedWindow()
    if win.isMaximized()
      win.unmaximize()
    else
      win.maximize()
  $('#minimize').click ->
    win = BrowserWindow.getFocusedWindow()
    win.minimize()
  $('#target_file').click ->
    file = dialog.showOpenDialog null,
      title: 'Open File'
      defaultPath: last_path
      filters: schema_plugin.filters()
      properties: ['openFile']
    if file?
      last_path = file
      set_target(file[0])
  $('#target_directory').click ->
    dir = dialog.showOpenDialog null,
      title: 'Open Directory'
      defaultPath: last_path
      properties: ['openDirectory']
    if dir?
      last_path = dir
      set_target(dir[0])
  $('#schema').change ->
    set_schema_plugin($('#schema').val())

get_editor = (schema) ->
  _editor = new JSONEditor document.getElementById('editor'),
    ajax: true
    theme: 'bootstrap3'
    iconlib: 'fontawesome4'
    disable_edit_json: true
    disable_properties: true
    disable_collapse: true
    schema: schema

  $('html').css(height: "100%")
  $('body').css(height: "100%")
  $('.tabs.list-group').parent().parent().parent().css('height': 'calc(100% - 52px - 20px)')
  $('.tabs.list-group').parent().parent().css('height': '100%')
  $('.tabs.list-group').parent().css('height': 'calc(100% - 34px - 10px)')
  $('.tabs.list-group').css('overflow': 'auto', 'height': '100%', 'margin-bottom': '0px')

  _editor
