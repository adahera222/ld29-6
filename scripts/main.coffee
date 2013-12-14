class Main
  initialize: =>
    @boxTimer = 0
    @currentBoxesVelocity = 0
    @maxBoxesVelocity = 1200
    @boxesAcceleration = 10

    @game = new Phaser.Game($(window).width(), $(window).height(), Phaser.AUTO, 'game', {preload: @preload, create: @create, update: @update})

  preload: =>
    @game.load.image('player', 'assets/images/player.png')
    @game.load.image('box', 'assets/images/box.png')

  create: =>
    @game.stage.backgroundColor = '#999999'

    $(window).resize =>
      @resize()

    @resize()

    @leftKey = @game.input.keyboard.addKey(Phaser.Keyboard.LEFT)
    @rightKey = @game.input.keyboard.addKey(Phaser.Keyboard.RIGHT)

    @player = @game.add.sprite(@game.world.centerX, @game.world.height / 4, 'player')
    @player.anchor.setTo(0.5, 0.5)
    @player.body.collideWorldBounds = true

    @boxes = @game.add.group()
    @boxes.createMultiple(30, 'box')

    for i in [0...30]
      @boxes.create(@game.world.centerX, @game.world.height + 50, 'box')
    @boxes.setAll('anchor.x', 0.5)
    @boxes.setAll('anchor.y', 0.5)

  update: =>
    horPor = @game.world.width / 50

    if (@leftKey.isDown)
      @player.x -= horPor
    else if (@rightKey.isDown)
      @player.x += horPor

    if (@game.time.now > @boxTimer)
      @addBox()

    @boxes.forEachAlive( (box) =>
      box.body.velocity.y = @currentBoxesVelocity
    , @)

    @currentBoxesVelocity -= @boxesAcceleration if @currentBoxesVelocity > -@maxBoxesVelocity

  addBox: =>
    box = @boxes.getFirstExists(false);

    if (box)
      box.reset(Math.random() * @game.world.width, @game.world.height + 50)
      box.body.velocity.y = @currentBoxesVelocity
      box.revive()
      box.events.onOutOfBounds.add( =>
        if box.y < 0
          box.kill()
      , @)

    @boxTimer = @game.time.now + 500

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
