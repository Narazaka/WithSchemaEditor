gulp = require 'gulp'
merge = require 'merge-stream'
$ = (require 'gulp-load-plugins')()
packager = require 'electron-packager'
mainBowerFiles = require 'main-bower-files'
pkg = require './package.json'
app_name = pkg.name
include_plugin = ['node_modules/with-schema-editor-schema-with-schema-editor-config/**/*', 'node_modules/js-yaml/**/*']

files =
  html: 'src/**/*.html'
  jade: 'src/**/*.jade'
  js: 'src/**/*.js'
  coffee: 'src/**/*.coffee'
  css: 'src/**/*.css'
  stylus: 'src/**/*.styl'
  json: 'src/**/*.json'
  yaml: 'src/**/*.yaml'

gulp.task 'html', ->
  merge [
    gulp.src files.html
      .pipe gulp.dest 'dst'
    gulp.src files.jade
      .pipe $.jade()
      .pipe gulp.dest 'dst'
  ]

gulp.task 'js', ->
  merge [
    gulp.src files.js
      .pipe gulp.dest 'dst'
    gulp.src files.coffee
      .pipe $.coffee()
      .pipe gulp.dest 'dst'
  ]

gulp.task 'css', ->
  merge [
    gulp.src files.css
      .pipe gulp.dest 'dst'
    gulp.src files.stylus
      .pipe $.stylus()
      .pipe gulp.dest 'dst'
  ]

gulp.task 'json', ->
  merge [
    gulp.src files.json
      .pipe gulp.dest 'dst'
    gulp.src files.yaml
      .pipe $.yaml()
      .pipe gulp.dest 'dst'
  ]

gulp.task 'package', ->
  gulp.src 'package.json'
    .pipe gulp.dest 'dst'

gulp.task 'node_modules', ->
  gulp.src $.npmFiles(), base: '.'
    .pipe gulp.dest 'dst'

gulp.task 'bower_components', ->
  gulp.src mainBowerFiles(), base: "./bower_components"
    .pipe gulp.dest 'dst/lib'

gulp.task 'b', ['html', 'js', 'css', 'json', 'package', 'node_modules', 'bower_components']

gulp.task 'w', ->
  gulp.start ['b']
  $.watch [files.html, files.jade], -> gulp.start ['html']
  $.watch [files.js, files.coffee], -> gulp.start ['js']
  $.watch [files.css, files.stylus], -> gulp.start ['css']
  $.watch [files.json, files.yaml], -> gulp.start ['json']

pack = (platform) ->
  new Promise (resolve, reject) ->
    packager
      dir: 'dst'
      out: "release"
      name: app_name
      arch: 'x64'
      platform: platform
      version: '0.34.2'
      overwrite: true
    , (error, path) ->
      if error?
        reject error
      else
        resolve gulp.src(include_plugin, base: '.').pipe(gulp.dest path[0])

gulp.task 'pw', ['b'], ->
  pack 'win32'

gulp.task 'pm', ['b'], ->
  pack 'darwin'

gulp.task 'pl', ['b'], ->
  pack 'linux'
