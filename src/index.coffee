app = require 'app'
BrowserWindow = require 'browser-window'
Menu = require 'menu'

main_window = null

app.on 'window-all-closed', ->
    # if process.platform != 'darwin'
    app.quit()

app.on 'ready', ->
  main_window = new BrowserWindow(width: 1200, height: 720, frame: false)
  main_window.loadUrl('file://' + __dirname + '/index.html')
  main_window.on 'closed', ->
    main_window = null

  Menu.setApplicationMenu Menu.buildFromTemplate [
    {
      label: "File"
      submenu: [
        { label: "About...", role: "about" }
        { type: "separator" }
        { label: "Quit", accelerator: "CmdOrCtrl+Q", click: -> app.quit() }
      ]
    }
    {
      label: "Edit"
      submenu: [
        { label: "Undo", accelerator: "CmdOrCtrl+Z", role: "undo" }
        { label: "Redo", accelerator: "Shift+CmdOrCtrl+Z", role: "redo" }
        { type: "separator" }
        { label: "Cut", accelerator: "CmdOrCtrl+X", role: "cut" }
        { label: "Copy", accelerator: "CmdOrCtrl+C", role: "copy" }
        { label: "Paste", accelerator: "CmdOrCtrl+V", role: "paste" }
        { label: "Select All", accelerator: "CmdOrCtrl+A", role: "selectall" }
      ]
    }
    {
      label: "View"
      submenu: [
        { label: "Reload", accelerator: "CmdOrCtrl+R", click: (item, focused_window) -> focused_window?.reload() }
        { label: "Developer tools", accelerator: "CmdOrCtrl+D", click: (item, focused_window) -> focused_window.toggleDevTools() }
      ]
    }
  ]
