nameTemplate = require '../templates/name.jade'
scoreboardTemplate = require '../templates/scoreboard.jade'
countdownTemplate = require '../templates/countdown.jade'

class Main
  initialize: =>
    @socket = io.connect('/')

    @socket.on 'nameTaken', =>
      $('#name > h1').text 'Bummer! That name\'s taken. Try again!'

    @socket.on 'joined', =>
      $('#title').remove()
      $('#name').remove()

    @socket.on 'countdown', (data) =>
      data.message = "NEXT GAME IN"

      $('body').append Mustache.render(countdownTemplate, data)

      endTime = Math.floor((new Date).getTime()/1000) + parseInt(data.time)

      lastTime = parseInt(data.time)

      @countdownTimer = setInterval( =>
        timeLeft = endTime - Math.floor((new Date).getTime()/1000)

        if timeLeft < 0
          timeLeft = 0

        if (timeLeft isnt lastTime) and timeLeft < 5
          @beepboopSound.play()

        lastTime = timeLeft

        $('#countdown-number').text(timeLeft)
      , 500)

    @socket.on 'startGame', (data) =>
      if @scoreboardMusic.isPlaying
        @scoreboardMusic.stop()

      if !@fallingMusic.isPlaying
        @fallingMusic.play('', 0, 1, true)

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

      $('body').append Mustache.render(countdownTemplate, {time: data.length, message: "TIME LEFT"})

      endTime = Math.floor((new Date).getTime()/1000) + parseInt(data.length)

      lastTime = parseInt(data.length)

      @countdownTimer = setInterval( =>
        timeLeft = endTime - Math.floor((new Date).getTime()/1000)

        if timeLeft < 0
          timeLeft = 0

        if (timeLeft isnt lastTime) and timeLeft < 10
          @beepboopSound.play()

        lastTime = timeLeft

        $('#countdown-number').text(timeLeft)
      , 500)

    @socket.on 'endGame', (data) =>
      $('#countdown').remove()

      if @countdownTimer
        clearInterval @countdownTimer

      @playing = false

      @blackBlocks.forEachAlive (block) =>
        block.kill()
      , @

      @whiteBlocks.forEachAlive (block) =>
        block.kill()
      , @

      @socket.emit('distance', @totalDistance);

    @socket.on 'scoreboard', (data) =>
      if @fallingMusic.isPlaying
        @fallingMusic.stop()

      if !@scoreboardMusic.isPlaying
        @scoreboardMusic.play('', 0, 1, true)

      $('body').css('overflow', 'hidden')
      $('body').append Mustache.render(scoreboardTemplate, data)

    @gameTimer = 0;
    @noNameTries = 0
    @currentColor = 'white'
    @playing = false

    @reset()

    @game = new Phaser.Game($(window).width(), $(window).height(), Phaser.AUTO, 'game', {preload: @preload, create: @create, update: @update})

  preload: =>
    @game.stage.disableVisibilityChange = true
    @game.stage.backgroundColor = '#999999'

    @game.load.image('background', 'assets/images/background.jpg')
    @game.load.image('black_block', 'assets/images/black_block.png')
    @game.load.image('white_block', 'assets/images/white_block.png')
    @game.load.image('black_particle', 'assets/images/black_particle.jpg')
    @game.load.image('white_particle', 'assets/images/white_particle.jpg')
    @game.load.image('black_block_particle', 'assets/images/black_block_particle.jpg')
    @game.load.image('white_block_particle', 'assets/images/white_block_particle.jpg')
    @game.load.atlasJSONHash('player', 'assets/images/player.png', 'assets/images/player.json')
    @game.load.audio('falling', ['assets/audio/falling.wav'])
    @game.load.audio('scoreboard', ['assets/audio/scoreboard.wav'])
    @game.load.audio('change', ['assets/audio/change.wav'])
    @game.load.audio('collide', ['assets/audio/collide.wav'])
    @game.load.audio('explode', ['assets/audio/explode.wav'])
    @game.load.audio('beepboop', ['assets/audio/beepboop.wav'])

  create: =>
    $(window).resize =>
      @resize()

    @resize()

    @leftKey = @game.input.keyboard.addKey(Phaser.Keyboard.LEFT)
    @rightKey = @game.input.keyboard.addKey(Phaser.Keyboard.RIGHT)

    @game.input.keyboard.addKey(Phaser.Keyboard.SPACEBAR).onDown.add(@switchColors, @)

    @background = @game.add.tileSprite(0, 0, 2560, 1600, 'background')

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

    @blackEmitter = @game.add.emitter(0, 0, 200)
    @blackEmitter.makeParticles('black_particle')
    @blackEmitter.gravity = -10

    @whiteEmitter = @game.add.emitter(0, 0, 200)
    @whiteEmitter.makeParticles('white_particle')
    @whiteEmitter.gravity = -10

    @blackBlockEmitter = @game.add.emitter(0, 0, 200)
    @blackBlockEmitter.makeParticles('black_block_particle')
    @blackBlockEmitter.minParticleSpeed.setTo(-1000, -300)
    @blackBlockEmitter.maxParticleSpeed.setTo(1000, -400)
    @blackBlockEmitter.gravity = -10

    @whiteBlockEmitter = @game.add.emitter(0, 0, 200)
    @whiteBlockEmitter.makeParticles('white_block_particle')
    @whiteBlockEmitter.minParticleSpeed.setTo(-1000, -300)
    @whiteBlockEmitter.maxParticleSpeed.setTo(1000, -400)
    @whiteBlockEmitter.gravity = -10

    @player = @game.add.sprite(@game.world.centerX, @game.world.height / 4, 'player')
    @player.animations.add('center_black', [0...7])
    @player.animations.add('center_white', [7...14])
    @player.animations.add('switch_to_white', [14...28])
    @player.animations.add('switch_to_black', [28...42])
    @player.animations.add('collide_black', [42...44])
    @player.animations.add('collide_white', [44...46])
    @player.anchor.setTo(0.5, .5)
    @player.body.collideWorldBounds = true
    @player.body.customSeparateX = true
    @player.body.customSeparateY = true
    @player.animations.play('center_white', 15, true)

    @player.events.onAnimationComplete.add =>
      if @currentColor is 'black'
        @player.animations.play('center_black', 15, true)
      else
        @player.animations.play('center_white', 15, true)

    @fallingMusic = @game.add.audio('falling')
    @scoreboardMusic = @game.add.audio('scoreboard')
    @changeSound = @game.add.audio('change')
    @collideSound = @game.add.audio('collide')
    @explodeSound = @game.add.audio('explode')
    @beepboopSound = @game.add.audio('beepboop')

    @fallingMusic.play('', 0, 1, true)

    @goLeft = false
    @goRight = false

    @game.input.onDown.add =>
      if @game.input.x < @game.world.width / 2
        @goRight = false
        @goLeft = true
      else
        @goRight = true
        @goLeft = false

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
        @socket.emit('newPlayer', playerName)
      else
        @noNameTries++

        switch @noNameTries
          when 1 then $('#name > h1').text 'Perhaps I wasn\'t clear. I need a name.'
          when 2 then $('#name > h1').text 'Oh, come on. Just write a name.'
          when 3 then $('#name > h1').text 'Yeeaaaa...gettin\' old. Name time.'
          when 4 then $('#name > h1').text 'Seriously. Name.'
          else $('#name > h1').text 'Sigh.'

  update: =>
    if @playing
      horPor = @game.world.width / 50

      if @collided
        if @game.time.now > @collideTimer
          @collided = false
      else
        if (@leftKey.isDown or @goLeft)
          @goLeft = false
          @goRight = false
          @player.x -= horPor
        else if (@rightKey.isDown or @goRight)
          @goLeft = false
          @goRight = false
          @player.x += horPor
        else if @goLeft
          @player.x -= horPor / 2
        else if @goRight
          @player.x += horPor / 2

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
      @blocksFrequency = 1 if @blocksFrequency < 1

      @game.physics.collide(@player, @blackBlocks, @blackBlockCollide, null, @)
      @game.physics.collide(@player, @whiteBlocks, @whiteBlockCollide, null, @)

    @background.tilePosition.y += @currentBlocksVelocity / 1000

  switchColors: =>
    if !@collided
      @changeSound.play()

      if @currentColor is 'white'
        @currentColor = 'black'
        @player.animations.play('switch_to_black', 35, false)
        setTimeout( =>
          @blackEmitter.x = @player.x
          @blackEmitter.y = @player.y
          @blackEmitter.start(true, 2000, null, 35)
        , 225)

      else
        @currentColor = 'white'
        @player.animations.play('switch_to_white', 35, false)
        setTimeout( =>
          @whiteEmitter.x = @player.x
          @whiteEmitter.y = @player.y
          @whiteEmitter.start(true, 2000, null, 35)
        , 225)

  blackBlockCollide: (collider, collidee) =>
    if @currentColor is 'black'
      @blackBlockEmitter.x = collidee.x
      @blackBlockEmitter.y = collidee.y
      @blackBlockEmitter.start(true, 2000, null, 35)
      @explodeBlock collidee
    else
      @playerCollide collidee

  whiteBlockCollide: (collider, collidee) =>
    if @currentColor is 'white'
      @whiteBlockEmitter.x = collidee.x
      @whiteBlockEmitter.y = collidee.y
      @whiteBlockEmitter.start(true, 2000, null, 35)
      @explodeBlock collidee
    else
      @playerCollide collidee

  explodeBlock: (block) =>
    @explodeSound.play()
    block.kill()
    @currentBlocksAcceleration += @blocksAccelerationIncrement
    @currentBlocksVelocity -= @currentBlocksAcceleration

  playerCollide: (block) =>
    @collideSound.play()
    @collided = true
    @collideTimer = @game.time.now + 2000
    @currentBlocksVelocity = 0
    @blocksFrequency = 0
    @currentBlocksAcceleration = @blocksAccelerationIncrement

    if @currentColor is 'black'
      @player.animations.play('collide_black', 1, false)
    else
      @player.animations.play('collide_white', 1, false)

  addBlock: =>
    rand = Math.floor(Math.random() * 2)

    if rand is 0
      block = @blackBlocks.getFirstExists(false)
    else
      block = @whiteBlocks.getFirstExists(false)

    if (block)
      block.reset(Math.random() * @game.world.width, @game.world.height + 50)
      block.width = Math.random() * (@game.world.width / 2)
      block.width = Math.floor(block.width / 8) * 8;
      block.width = 96 if block.width < 96
      block.body.velocity.y = @currentBlocksVelocity
      block.revive()
      block.events.onOutOfBounds.add( =>
        if block.y < 0
          block.kill()
      , @)

    @blocksTimer = @game.time.now + @blocksFrequency

  reset: =>
    @blocksTimer = 0
    @blocksFrequency = @currentBlocksVelocity
    @maxBlocksVelocity = 1000
    @currentBlocksVelocity = -@maxBlocksVelocity
    @blocksAccelerationIncrement = 10
    @currentBlocksAcceleration = @blocksAccelerationIncrement
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

    if @player
      @player.x = @game.world.centerX
      @player.y = @game.world.height / 4

$(document).ready ->
  main = new Main()
  main.initialize()
