class Main
  initialize: =>
    @game = new Phaser.Game($(window).width(), $(window).height(), Phaser.AUTO, 'game', {preload: @preload, create: @create, update: @update})

  preload: =>


  create: =>


  update: =>


$(document).ready ->
  @main = new Main()
  @main.initialize()
