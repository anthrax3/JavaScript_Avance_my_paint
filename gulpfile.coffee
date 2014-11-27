#!/usr/local/bin/node
gulp = require 'gulp'
sourcemaps = require 'gulp-sourcemaps';

coffeelint = require 'gulp-coffeelint'
coffee = require 'gulp-coffee'
stylus = require 'gulp-stylus'
livereload = require 'gulp-livereload'

sources =
	stylus: 'css/*.styl'
	coffee: 'js/*.coffee'
	html:   '*.html'

destinations =
	css: 'css'
	js: 'js'

gulp.task 'style', ->
	gulp.src sources.stylus
		.pipe stylus(
			compress: false
			sourcemap:
				inline: true
		)
		.pipe gulp.dest(destinations.css)
		.pipe livereload()

gulp.task 'lint',->
	gulp.src sources.coffee
		.pipe coffeelint(
			indentation:
				value: 1
			no_tabs:
				level: "ignore"
		)
		.pipe coffeelint.reporter()

gulp.task 'coffee', ->
	gulp.src sources.coffee
		.pipe sourcemaps.init()
		.pipe coffee(
			bare: true
		)
		.pipe sourcemaps.write()
		.pipe gulp.dest(destinations.js)
		.pipe livereload()

gulp.task 'html', ->
	gulp.src sources.html
		.pipe livereload()


gulp.task 'watch', ->
	livereload.listen()
	gulp.watch(sources.coffee, ['lint', 'coffee'])
	gulp.watch(sources.stylus, ['style'])
	gulp.watch(sources.html, ['html'])

gulp.task 'default', ->
