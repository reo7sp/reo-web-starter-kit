gulp = require 'gulp'
$ = require('gulp-load-plugins')()

fs = require 'fs'
_ = require 'lodash'
del = require 'del'
runSequence = require 'run-sequence'
browserSync = require 'browser-sync'
browserify = require 'browserify'
browserifyInc = require 'browserify-incremental'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'


# --- Utils --- #
file_exists = (file) ->
  try
    fs.statSync(file).isFile()
  catch
    false


plumberOptions =
  errorHandler: (err) ->
    $.util.beep()
    $.util.log(
      $.util.colors.cyan('Plumber') + $.util.colors.red(' found unhandled error:\n'),
      err.toString()
    )
    @emit("end")


# --- Styles --- #
possibleStylesMain = ['app/styles/main.sass', 'app/styles/main.scss', 'app/styles/main.css']
stylesMain = _.find(possibleStylesMain, file_exists)
stylesMain ?= possibleStylesMain[0]
styles = 'app/styles/**/*.{sass,scss,css}'

stylesPipe = ->
  gulp.src stylesMain
    .pipe $.plumber(plumberOptions)
    .pipe $.sourcemaps.init()
    .pipe $.sass.sync()
    .pipe $.rename('app.css')
    .pipe $.autoprefixer()

gulp.task 'styles:debug', ->
  stylesPipe()
    .pipe $.sourcemaps.write('.')
    .pipe gulp.dest '.tmp/styles'

gulp.task 'styles:dist', ->
  cssnanoOptions =
    discardComments:
      removeAll: true

  stylesPipe()
    .pipe $.cssnano(cssnanoOptions)
    .pipe $.rev()
    .pipe gulp.dest 'dist/styles'
    .pipe $.rev.manifest(merge: true)
    .pipe gulp.dest '.'


# --- Scripts --- #
possibleScriptsMain = ['app/scripts/main.coffee', 'app/scripts/main.js']
scriptsMain = _.find(possibleScriptsMain, file_exists)
scriptsMain ?= possibleScriptsMain[0]
scripts = 'app/scripts/**/*.{coffee,js}'

scriptsPipe = ->
  b = browserify(scriptsMain, _.extend(browserifyInc.args, debug: true))
  browserifyInc(b, cacheFile: './browserify-cache.json')
  b
    .transform('coffeeify')
    .bundle()
    .on('error', plumberOptions.errorHandler)
    .pipe source('app.js')
    .pipe buffer()

gulp.task 'scripts:debug', ->
  scriptsPipe()
    .pipe $.sourcemaps.init(loadMaps: true)
    .pipe $.sourcemaps.write('.')
    .pipe gulp.dest '.tmp/scripts'

gulp.task 'scripts:dist', ->
  scriptsPipe()
    .pipe $.uglify()
    .pipe $.rev()
    .pipe gulp.dest 'dist/scripts'
    .pipe $.rev.manifest(merge: true)
    .pipe gulp.dest '.'


# --- HTMLs --- #
htmls = ['app/**/*.html', '!app/**/_*.html']

htmlsPipe = ->
  gulp.src htmls
    .pipe $.plumber(plumberOptions)
    .pipe $.nunjucksRender(path: 'app')

gulp.task 'htmls:debug', ->
  htmlsPipe()
    .pipe $.cached('htmls')
    .pipe gulp.dest '.tmp'

gulp.task 'htmls:dist', ->
  htmlminOptions =
    removeComments: true
    collapseWhitespace: true
    collapseBooleanAttributes: true
    removeAttributeQuotes: true
    removeRedundantAttributes: true
    removeEmptyAttributes: true
    removeScriptTypeAttributes: true
    removeStyleLinkTypeAttributes: true
    removeOptionalTags: true

  htmlsPipe()
    .pipe $.cached('htmls:dist')
    .pipe $.revReplace(manifest: gulp.src('./rev-manifest.json'))
    .pipe $.htmlmin(htmlminOptions)
    .pipe gulp.dest 'dist'


# --- Images --- #
images = 'app/images/**/*'

imagesPipe = ->
  gulp.src images
    .pipe $.plumber(plumberOptions)

gulp.task 'images:debug', ->
  imagesPipe()
    .pipe $.cached('images')
    .pipe gulp.dest '.tmp/images'

gulp.task 'images:dist', ->
  imagesPipe()
    .pipe $.cached('images:dist')
    .pipe $.imagemin(progressive: true, interlaced: true)
    .pipe gulp.dest 'dist/images'


#
sourcesTasks = ['styles', 'scripts', 'htmls', 'images']
sourcesFileGroups = [styles, scripts, htmls, images]
sources = _.flattenDeep(sourcesFileGroups)
everything = 'app/**/*'


# --- Other --- #
other = _.concat(everything, _.map(sources, (match) -> "#{if match[0] != '!' then '!' else ''}#{match}"))

otherPipe = ->
  gulp.src other
    .pipe $.plumber(plumberOptions)
    .pipe $.cached('other')
    .pipe gulp.dest 'dist'

gulp.task 'other:debug', ->
  otherPipe()

gulp.task 'other:dist', ->
  otherPipe()


#
allSourcesTasks = _.concat(sourcesTasks, 'other')
allSourcesDebugTasks = _.map(allSourcesTasks, (task) -> "#{task}:debug")
allSourcesDistTasks = _.map(allSourcesTasks, (task) -> "#{task}:dist")
allSourcesFileGroups = _.concat(sourcesFileGroups, [other])


# --- Main --- #
gulp.task 'clean', ->
  del(['.tmp', 'dist/*', 'rev-manifest.json'], dot: true)

gulp.task 'compile:debug', allSourcesDebugTasks

gulp.task 'compile:dist', (callback) ->
  runSequence _.without(allSourcesDistTasks, 'htmls:dist'), 'htmls:dist', callback

gulp.task 'serve', ['compile:debug'], ->
  browserSync(notify: false, server: ['.tmp', 'dist'])
  for [name, group] in _.zip allSourcesDebugTasks, allSourcesFileGroups
    gulp.watch group, [name, browserSync.reload]
  return

gulp.task 'serve:dist', ['compile:dist'], ->
  browserSync(notify: false, server: ['dist'])
  for [name, group] in _.zip(allSourcesDistTasks, allSourcesFileGroups)
    gulp.watch group, [name, browserSync.reload]
  return

gulp.task 'build:debug', (callback) ->
  runSequence 'clean', 'compile:debug', callback

gulp.task 'build:dist', (callback) ->
  runSequence 'clean', 'compile:dist', callback

gulp.task 'deploy', ['build:dist'], ->
  surgeOptions =
    project: './dist'
    # domain: 'example.surge.sh' # Your domain or Surge subdomain

  $.surge(surgeOptions)

gulp.task 'default', ['build:dist']
