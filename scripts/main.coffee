nameTemplate = require '../templates/name.jade'

class Main
  initialize: =>
    Math.seedrandom('12345')

    @currentSeed = Math.random

    socket = io.connect('/')

    socket.on 'nameTaken', =>
      $('#name > h1').text 'Bummer! That name\'s taken. Try again!'

    socket.on 'start', =>
      $('#name').remove()
      @playing = true

    @noNameTries = 0
    @playing = false
    @blocksTimer = 0
    @currentBlocksVelocity = 0
    @blocksFrequency = @currentBlocksVelocity
    @maxBlocksVelocity = 1000
    @blocksAccelerationIncrement = 10
    @currentBlocksAcceleration = @blocksAccelerationIncrement
    @currentColor = 'white'
    @collided = false
    @collideTimer = 0
    @totalDistance = 0

    @game = new Phaser.Game($(window).width(), $(window).height(), Phaser.AUTO, 'game', {preload: @preload, create: @create, update: @update})

    placeholderNames = [
      "Sparaticus Fisticuffs"
      "Barry Jackalope"
      "Warsh Higgins"
      "Two-Sky McFry Guy"
      "Wonder \"Kid\" Pushlimiter"
      "Guy"
      "Smalls Twolover"
    ]

    Math.seedrandom()

    $('body').append Mustache.render(nameTemplate, {placeholder:placeholderNames[Math.floor(Math.random() * placeholderNames.length)]})

    Math.random = @currentSeed

    $('#name-form').submit (event) =>
      event.preventDefault()
      playerName = $('#player-name').val()
      if playerName isnt ''
        @noNameTries = 0
        socket.emit('newPlayer', playerName)
      else
        @noNameTries++

        switch @noNameTries
          when 1 then $('#name > h1').text 'Perhaps I wasn\'t clear. I need a name.'
          when 2 then $('#name > h1').text 'Oh, come on. Just write a name.'
          when 3 then $('#name > h1').text 'Yeeaaaa...gettin\' old. Name time.'
          when 4 then $('#name > h1').text 'Seriously. Name.'
          else $('#name > h1').text 'Sigh.'

  preload: =>
    @game.stage.disableVisibilityChange = true
    @game.stage.backgroundColor = '#999999'

    @game.load.image('black_player', 'assets/images/black_player.png')
    @game.load.image('white_player', 'assets/images/white_player.png')
    @game.load.image('black_block', 'assets/images/black_block.png')
    @game.load.image('white_block', 'assets/images/white_block.png')

  create: =>
    $(window).resize =>
      @resize()

    @resize()

    @leftKey = @game.input.keyboard.addKey(Phaser.Keyboard.LEFT)
    @rightKey = @game.input.keyboard.addKey(Phaser.Keyboard.RIGHT)

    @game.input.keyboard.addKey(Phaser.Keyboard.SPACEBAR).onDown.add(@switchColors, @)

    @blackBlocks = @game.add.group()
    @blackBlocks.createMultiple(30, 'black_block')
    @blackBlocks.setAll('anchor.x', 0.5)
    @blackBlocks.setAll('anchor.y', 0)
    @blackBlocks.setAll('body.immovable', true)

    @whiteBlocks = @game.add.group()
    @whiteBlocks.createMultiple(30, 'white_block')
    @whiteBlocks.setAll('anchor.x', 0.5)
    @whiteBlocks.setAll('anchor.y', 0)
    @whiteBlocks.setAll('body.immovable', true)

    @player = @game.add.sprite(@game.world.centerX, @game.world.height / 4, 'white_player')
    @player.anchor.setTo(0.5, 1)
    @player.body.customSeparateX = true
    @player.body.customSeparateY = true

  update: =>
    if @playing
      horPor = @game.world.width / 50

      if @collided
        if @game.time.now > @collideTimer
          @collided = false
      else
        if (@leftKey.isDown)
          @player.x -= horPor
        else if (@rightKey.isDown)
          @player.x += horPor

        if @blocksFrequency > 0
          if @game.time.now > @blocksTimer
            @addBlock()

        @currentBlocksVelocity -= @currentBlocksAcceleration if @currentBlocksVelocity > -@maxBlocksVelocity

      @blackBlocks.forEachAlive( (block) =>
        block.body.velocity.y = @currentBlocksVelocity
      , @)

      @whiteBlocks.forEachAlive( (block) =>
        block.body.velocity.y = @currentBlocksVelocity
      , @)

      @totalDistance += @currentBlocksVelocity * -1

      @blocksFrequency = 1500 - -@currentBlocksVelocity

      @game.physics.collide(@player, @blackBlocks, @blackBlockCollide, null, @)
      @game.physics.collide(@player, @whiteBlocks, @whiteBlockCollide, null, @)

  switchColors: =>
    if !@collided
      if @currentColor is 'white'
        @currentColor = 'black'
        @player.loadTexture('black_player', 0)
      else
        @currentColor = 'white'
        @player.loadTexture('white_player', 0)

  blackBlockCollide: (collider, collidee) =>
    if @currentColor is 'black'
      @explodeBlock collidee
    else
      @playerCollide collidee

  whiteBlockCollide: (collider, collidee) =>
    if @currentColor is 'white'
      @explodeBlock collidee
    else
      @playerCollide collidee

  explodeBlock: (block) =>
    block.kill()
    @currentBlocksAcceleration += @blocksAccelerationIncrement
    @currentBlocksVelocity -= @currentBlocksAcceleration

  playerCollide: (block) =>
    @collided = true
    @collideTimer = @game.time.now + 2000
    @currentBlocksVelocity = 0
    @blocksFrequency = 0
    @currentBlocksAcceleration = @blocksAccelerationIncrement

  addBlock: =>
    rand = Math.floor(Math.random() * 2)

    if rand is 0
      block = @blackBlocks.getFirstExists(false)
    else
      block = @whiteBlocks.getFirstExists(false)

    if (block)
      block.reset(Math.random() * @game.world.width, @game.world.height + 50)
      block.width = Math.random() * (@game.world.width / 2)
      block.body.velocity.y = @currentBlocksVelocity
      block.revive()
      block.events.onOutOfBounds.add( =>
        if block.y < 0
          block.kill()
      , @)

    @blocksTimer = @game.time.now + @blocksFrequency

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
