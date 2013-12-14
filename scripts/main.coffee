class Main
  initialize: =>
    Math.seedrandom('12345')

    @blockTimer = 0
    @currentBlocksVelocity = 0
    @maxBlocksVelocity = 1000
    @blocksAccelerationIncrement = 10
    @currentBlocksAcceleration = @blocksAccelerationIncrement
    @currentColor = 'white'
    @collided = false

    @game = new Phaser.Game($(window).width(), $(window).height(), Phaser.AUTO, 'game', {preload: @preload, create: @create, update: @update})

  preload: =>
    @game.load.image('black_player', 'assets/images/black_player.png')
    @game.load.image('white_player', 'assets/images/white_player.png')
    @game.load.image('black_block', 'assets/images/black_block.png')
    @game.load.image('white_block', 'assets/images/white_block.png')

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

    @blackBlocks = @game.add.group()
    @blackBlocks.createMultiple(30, 'black_block')
    @blackBlocks.setAll('anchor.x', 0.5)
    @blackBlocks.setAll('anchor.y', 0.5)

    @whiteBlocks = @game.add.group()
    @whiteBlocks.createMultiple(30, 'white_block')
    @whiteBlocks.setAll('anchor.x', 0.5)
    @whiteBlocks.setAll('anchor.y', 0.5)

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

    if (@game.time.now > @blockTimer)
      @addBlock()

    @blackBlocks.forEachAlive( (block) =>
      block.body.velocity.y = @currentBlocksVelocity
    , @)

    @whiteBlocks.forEachAlive( (block) =>
      block.body.velocity.y = @currentBlocksVelocity
    , @)

    if !@collided
      @currentBlocksVelocity -= @currentBlocksAcceleration if @currentBlocksVelocity > -@maxBlocksVelocity

    if !@player.touching
      @collided = false

    @game.physics.collide(@player, @blackBlocks, @blackBlockCollide, null, @)
    @game.physics.collide(@player, @whiteBlocks, @whiteBlockCollide, null, @)

  blackBlockCollide: (collider, collidee) =>
    if @currentColor is 'black'
      @explodeBlock collidee
    else
      @playerCollide()

  whiteBlockCollide: (collider, collidee) =>
    if @currentColor is 'white'
      @explodeBlock collidee
    else
      @playerCollide()

  explodeBlock: (block) =>
    block.kill()
    @currentBlocksAcceleration += @blocksAccelerationIncrement
    @currentBlocksVelocity -= @currentBlocksAcceleration

  playerCollide: =>
    @collided = true
    @currentBlocksVelocity = 0
    @currentBlocksAcceleration = @blocksAccelerationIncrement

  addBlock: =>
    rand = Math.floor(Math.random() * 2)

    if rand is 0
      block = @blackBlocks.getFirstExists(false)
    else
      block = @whiteBlocks.getFirstExists(false)

    if (block)
      block.reset(Math.random() * @game.world.width, @game.world.height + 50)
      block.body.velocity.y = @currentBlocksVelocity
      block.revive()
      block.events.onOutOfBounds.add( =>
        if block.y < 0
          block.kill()
      , @)

    @blockTimer = @game.time.now + 500

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
