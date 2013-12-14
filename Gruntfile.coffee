module.exports = (grunt) ->
  config =
    root: 'public'

  grunt.initConfig
    config: config
    concat:
      dist:
        src: [
          './scripts/vendor/seedrandom/seedrandom.min.js'
          './scripts/vendor/jquery/jquery.min.js'
          './scripts/vendor/phaser/phaser.min.js'
        ]
        dest: './<%= config.root %>/scripts/vendor.min.js'
    watch:
      scripts:
        files: [
          './scripts/**/*'
          './templates/**/*'
        ]
        tasks: ['browserify']
        options:
          livereload: true
      styles:
        files: [
          './styles/**/*'
        ]
        tasks: ['stylus']
        options:
          livereload: true
    browserify:
      basic:
        src: ['./scripts/main.coffee']
        dest: './public/scripts/main.js'
        options:
          transform: ['coffeeify']
    stylus:
      compile:
        files:
          './<%= config.root %>/styles/styles.css': './styles/styles.styl'
    copy:
      assets:
        src: 'assets/**/*'
        dest: '<%= config.root %>/'
        filter: 'isFile'

  grunt.task.registerTask('default', ['build'])
  grunt.task.registerTask('server', ['concat', 'browserify', 'stylus', 'copy', 'watch'])
  grunt.task.registerTask('build', ['concat', 'browserify', 'stylus', 'copy'])

  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-concat')
  grunt.loadNpmTasks('grunt-browserify')
  grunt.loadNpmTasks('grunt-contrib-stylus')
  grunt.loadNpmTasks('grunt-contrib-copy')
