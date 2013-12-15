nameTemplate = require '../templates/name.jade'
scoreboardTemplate = require '../templates/scoreboard.jade'
countdownTemplate = require '../templates/countdown.jade'

class Main
  initialize: =>
    socket = io.connect('/')

    socket.on 'nameTaken', =>
      $('#name > h1').text 'Bummer! That name\'s taken. Try again!'

    socket.on 'joined', =>
      $('#name').remove()

    socket.on 'countdown', (data) =>
      $('body').append Mustache.render(countdownTemplate, data)

      endTime = Math.floor((new Date).getTime()/1000) + parseInt(data.time)

      @countdownTimer = setInterval( =>
        timeLeft = endTime - Math.floor((new Date).getTime()/1000)

        if timeLeft < 0
          timeLeft = 0

        $('#countdown-number').text(timeLeft)
      , 300)

    socket.on 'startGame', (data) =>
      if @countdownTimer
        clearInterval @countdownTimer

      $('#scoreboard').remove()
      $('#countdown').remove()
      $('body').css('overflow', 'visible')
      Math.seedrandom(data.seed)
      @currentSeed = Math.random
      @gameTimer = @game.time.now + (data.length * 1000)
      @reset()
      @playing = true

    socket.on 'endGame', (data) =>
      @playing = false

      @blackBlocks.forEachAlive (block) =>
        block.kill()
      , @

      @whiteBlocks.forEachAlive (block) =>
        block.kill()
      , @

      socket.emit('distance', @totalDistance);

    socket.on 'scoreboard', (data) =>
      $('body').css('overflow', 'hidden')
      $('body').append Mustache.render(scoreboardTemplate, data)

    @gameTimer = 0;
    @noNameTries = 0
    @playing = false

    @reset()

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

    $('body').append Mustache.render(nameTemplate, {placeholder:placeholderNames[Math.floor(Math.random() * placeholderNames.length)]})

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

    @game.load.image('black_block', 'assets/images/black_block.png')
    @game.load.image('white_block', 'assets/images/white_block.png')
    @game.load.atlasJSONHash('player', 'assets/images/player.png', 'assets/images/player.json');

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

    @player = @game.add.sprite(@game.world.centerX, @game.world.height / 4, 'player')
    @player.animations.add('center_black', [0...7])
    @player.animations.add('center_white', [7...14])
    @player.anchor.setTo(0.5, 1)
    @player.body.customSeparateX = true
    @player.body.customSeparateY = true
    @player.animations.play('center_black', 15, true)

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

      if @game.time.now <= @gameTimer
        @totalDistance += @currentBlocksVelocity * -1

      @blocksFrequency = 1500 - -@currentBlocksVelocity

      @game.physics.collide(@player, @blackBlocks, @blackBlockCollide, null, @)
      @game.physics.collide(@player, @whiteBlocks, @whiteBlockCollide, null, @)

  switchColors: =>
    if !@collided
      if @currentColor is 'white'
        @currentColor = 'black'
        @player.animations.play('center_black', 15, true)
      else
        @currentColor = 'white'
        @player.animations.play('center_white', 15, true)

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

  reset: =>
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
  main = new Main()
  main.initialize()
