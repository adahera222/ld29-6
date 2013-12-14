class Main
  initialize: =>
    @boxTimer = 0
    @currentBoxesVelocity = 0
    @maxBoxesVelocity = 1200
    @boxesAcceleration = 10
    @currentColor = 'white'

    @game = new Phaser.Game($(window).width(), $(window).height(), Phaser.AUTO, 'game', {preload: @preload, create: @create, update: @update})

  preload: =>
    @game.load.image('black_player', 'assets/images/black_player.png')
    @game.load.image('white_player', 'assets/images/white_player.png')
    @game.load.image('black_box', 'assets/images/black_box.png')
    @game.load.image('white_box', 'assets/images/white_box.png')

  create: =>
    @game.stage.backgroundColor = '#999999'

    $(window).resize =>
      @resize()

    @resize()

    @leftKey = @game.input.keyboard.addKey(Phaser.Keyboard.LEFT)
    @rightKey = @game.input.keyboard.addKey(Phaser.Keyboard.RIGHT)
    @spaceKey = @game.input.keyboard.addKey(Phaser.Keyboard.SPACEBAR)

    @player = @game.add.sprite(@game.world.centerX, @game.world.height / 4, 'white_player')
    @player.anchor.setTo(0.5, 0.5)
    @player.body.immovable = true
    @player.body.collideWorldBounds = true

    @spaceKey.onDown.add(@switchColors, @)

    @blackBoxes = @game.add.group()
    @blackBoxes.createMultiple(30, 'black_box')
    @blackBoxes.setAll('anchor.x', 0.5)
    @blackBoxes.setAll('anchor.y', 0.5)

    @whiteBoxes = @game.add.group()
    @whiteBoxes.createMultiple(30, 'white_box')
    @whiteBoxes.setAll('anchor.x', 0.5)
    @whiteBoxes.setAll('anchor.y', 0.5)

  switchColors: =>
    if @currentColor is 'white'
      @currentColor = 'black'
      @player.loadTexture('black_player', 0)
    else
      @currentColor = 'white'
      @player.loadTexture('white_player', 0)

  update: =>
    horPor = @game.world.width / 50

    if (@leftKey.isDown)
      @player.x -= horPor
    else if (@rightKey.isDown)
      @player.x += horPor

    if (@game.time.now > @boxTimer)
      @addBox()

    @blackBoxes.forEachAlive( (box) =>
      box.body.velocity.y = @currentBoxesVelocity
    , @)

    @whiteBoxes.forEachAlive( (box) =>
      box.body.velocity.y = @currentBoxesVelocity
    , @)

    @currentBoxesVelocity -= @boxesAcceleration if @currentBoxesVelocity > -@maxBoxesVelocity

    @game.physics.collide(@player, @blackBoxes, @blackBoxCollide, null, @)
    @game.physics.collide(@player, @whiteBoxes, @whiteBoxCollide, null, @)

  blackBoxCollide: (collider, collidee) =>
    collidee.kill()

  whiteBoxCollide: (collider, collidee) =>
    collidee.kill()

  addBox: =>
    rand = Math.floor(Math.random() * 2)

    if rand is 0
      box = @blackBoxes.getFirstExists(false)
    else
      box = @whiteBoxes.getFirstExists(false)

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
