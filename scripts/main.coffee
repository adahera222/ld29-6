class Main
  initialize: =>
    @game = new Phaser.Game($(window).width(), $(window).height(), Phaser.AUTO, 'game', {preload: @preload, create: @create, update: @update})

  preload: =>


  create: =>
    @game.stage.scaleMode = Phaser.StageScaleMode.EXACT_FIT;
    @game.stage.scale.setShowAll();
    @game.stage.scale.refresh();

  update: =>


$(document).ready ->
  @main = new Main()
  @main.initialize()
