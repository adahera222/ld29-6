class Main
  initialize: =>
    @game = new Phaser.Game($(window).width(), $(window).height(), Phaser.AUTO, 'game', {preload: @preload, create: @create, update: @update})

  preload: =>
    @game.load.image('player', 'assets/images/player.png');

  create: =>
    $(window).resize =>
      @resize()

    @resize()

    @leftKey = @game.input.keyboard.addKey(Phaser.Keyboard.LEFT)
    @rightKey = @game.input.keyboard.addKey(Phaser.Keyboard.RIGHT)

    @player = @game.add.sprite(@game.world.centerX, @game.world.height / 4, 'player')
    @player.body.collideWorldBounds = true

  update: =>
    horPor = @game.world.width / 50

    if (@leftKey.isDown)
      @player.x -= horPor
    else if (@rightKey.isDown)
      @player.x += horPor

  resize: =>
    width = $(window).width()
    height = $(window).height()

    @game.width = width
    @game.height = height
    @game.world.width = width
    @game.world.height = height
    @game.stage.bounds.width = width
    @game.stage.bounds.height = height

    if @game.renderType is Phaser.WEBGL
      @game.renderer.resize(width, height)

$(document).ready ->
  @main = new Main()
  @main.initialize()
