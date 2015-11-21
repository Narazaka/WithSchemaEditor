fs = require 'fs'
path = require 'path'
jsyaml = require 'js-yaml'
remote = require 'remote'
app = remote.require 'app'
BrowserWindow = remote.require 'browser-window'
dialog = remote.require 'dialog'

class WithSchemaEditorApp
  cwd: ->
    if @_cwd then return @_cwd
    @_cwd = process.cwd()
    if process.platform == 'darwin' and @_cwd == '/'
      @_cwd = path.join app.getAppPath(), '../../../..'
    @_cwd

  config_path: (@_config_path=@default_config_path()) -> @_config_path

  default_config_path: -> @_default_config_path ?= path.join @cwd(), 'WithSchemaEditor.config.yaml'

  config: (config=null) ->
    if config?
      @_config = config
    unless @_config
      @load_config()
    @_config

  load_config: (config_path=null) ->
    config_path = @config_path(config_path)
    try
      @config(jsyaml.safeLoad fs.readFileSync config_path)
    catch
      @config({})
    @

  write_config: (config_path=null) ->
    config_path = @config_path(config_path)
    fs.writeFileSync config_path, jsyaml.safeDump @config()
    @

  schema_plugins_path: (@_schema_plugins_path=@default_schema_plugins_path()) -> @_schema_plugins_path

  default_schema_plugins_path: -> @_default_schema_plugins_path ?= path.join @cwd(), 'node_modules'

  schema_plugins: (schema_plugins=null) ->
    if schema_plugins?
      @_schema_plugins = schema_plugins
    unless @_schema_plugins?
      @load_schema_plugins()
    @_schema_plugins

  load_schema_plugins: (schema_plugins_path=null) ->
    schema_plugins_path = @schema_plugins_path(schema_plugins_path)
    try
      schema_plugin_ids = fs.readdirSync schema_plugins_path
      @schema_plugins(schema_plugin_ids.filter (schema_plugin_id) =>
        /^with-schema-editor-schema-/.test schema_plugin_id
      .reduce (schema_plugins, schema_plugin_id) =>
        schema_plugin_path = path.join @cwd(), 'node_modules', schema_plugin_id
        console.info "load plugin #{schema_plugin_path}"
        schema_plugins[schema_plugin_id] = require schema_plugin_path
        schema_plugins
      , {})
    catch error
      dialog.showErrorBox 'Cannot load schema plugins', 'check node_modules directory: ' + error
      app.quit()
    unless Object.keys(@schema_plugins()).length
      dialog.showErrorBox 'No schema plugins found', 'try `npm install with-schema-editor-schema-foo` or some'
      app.quit()
    @

  schema_plugin_id: (@_schema_plugin_id=@default_schema_plugin_id()) -> @config().schema = @_schema_plugin_id

  default_schema_plugin_id: ->
    @config().schema || Object.keys(@schema_plugins())[0]

  load_schema_plugin: (schema_plugin_id=null) ->
    schema_plugin_id = @schema_plugin_id(schema_plugin_id)
    schema_plugin = @schema_plugins()[schema_plugin_id]
    if schema_plugin?
      @schema_plugin(schema_plugin)
      @
    else
      throw new Error("schema_plugin id=#{schema_plugin_id} not found")

  schema_plugin: (schema_plugin=null) ->
    if schema_plugin?
      @_schema_plugin = schema_plugin
    unless @_schema_plugin?
      @load_schema_plugin()
    @_schema_plugin

  editor: (editor=null) ->
    if editor?
      @_editor = editor
    unless @_editor?
      @load_editor()
    @_editor

  load_editor: (schema_plugin=null) ->
    schema_plugin = @schema_plugin(schema_plugin)
    @set_controll_view()
    @_editor?.destroy()
    @editor(
      new JSONEditor(document.getElementById('editor'),
        ajax: true
        theme: 'bootstrap3'
        iconlib: 'fontawesome4'
        disable_edit_json: false
        disable_properties: false
        disable_collapse: false
        template: 'underscore'
        schema: schema_plugin.schema(@)
      )
    )
    $('.tabs.list-group').parent().parent().parent().css('height': 'calc(100% - 52px - 20px)')
    $('.tabs.list-group').parent().parent().css('height': '100%')
    $('.tabs.list-group').parent().css('height': 'calc(100% - 34px - 10px)')
    $('.tabs.list-group').css('overflow': 'auto', 'height': '100%', 'margin-bottom': '0px')
    $('.tabs.list-group + *').css('overflow': 'auto', 'height': '100%', 'margin-bottom': '0px')
    @

  set_controll_view: (schema_plugin=@schema_plugin()) ->
    if schema_plugin.read_type == 'file'
      $('#target_file').show()
      $('#target_directory').hide()
    else if schema_plugin.read_type == 'directory'
      $('#target_file').hide()
      $('#target_directory').show()
    else
      $('#target_file').show()
      $('#target_directory').show()
    if schema_plugin.save
      $('#save').show()
    else
      $('#save').hide()

  target: (@_target=@default_target()) -> @config().target = @_target

  default_target: -> @config().target

  prepare_dom: ->
    for schema_plugin_id, schema_plugin of @schema_plugins()
      $('#schema').append $('<option></option>').text(schema_plugin.name).val(schema_plugin_id)
    $('#schema').change =>
      @set_schema($('#schema').val())

    $('#save').click =>
      @schema_plugin().save?(@)
    $('#close').click =>
      @schema_plugin().close?(@)
      app.quit()

    $('#maximize').click =>
      win = BrowserWindow.getFocusedWindow()
      if win.isMaximized()
        win.unmaximize()
      else
        win.maximize()
    $('#minimize').click =>
      win = BrowserWindow.getFocusedWindow()
      win.minimize()

    $('#target_file').click =>
      file = dialog.showOpenDialog null,
        title: 'Open File'
        defaultPath: @_last_target || @target() || @cwd()
        filters: @schema_plugin().filters(@)
        properties: ['openFile']
      if file?
        @_last_target = @target()
        @set_target(file[0])
    $('#target_directory').click =>
      dir = dialog.showOpenDialog null,
        title: 'Open Directory'
        defaultPath: @_last_target || @target() || @cwd()
        properties: ['openDirectory']
      if dir?
        @_last_target = @target()
        @set_target(dir[0])

  set_schema: (schema_plugin_id=null) ->
    $('#schema').val @schema_plugin_id(schema_plugin_id)
    @load_schema_plugin($('#schema').val())
    @load_editor()
    @clear_target()
    # 全てエラーなく終わって初めて設定ファイルを更新
    @write_config()

  set_target: (target) ->
    $('#target_view').val @target(target)
    @load_editor()
    @schema_plugin().load(@)
    # 全てエラーなく終わって初めて設定ファイルを更新
    @write_config()

  clear_target: ->
    @target('')
    $('#target_view').val @target()

# patch
JSONEditor.defaults.templates.underscore = ->
  if !window._ then return false
  compile: (template) -> window._.template(template)

# boot
$ ->
  App = new WithSchemaEditorApp()
  window.App = App # for debug

  App.prepare_dom()

  if App.target()
    App.set_target()
  else
    App.set_schema()
