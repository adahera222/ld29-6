path = require 'path'
rimraf = require 'rimraf'
{spawn, exec} = require 'child_process'

task 'clean', 'Clean up working directory', ->
  rimraf path.resolve('./public'), ->
    console.log 'Working directory cleaned!\n'
