import CRaylib
import Glibc
import Raylib

struct WindowSize {
  let width: Float = 600.0
  let height: Float = 1000.0
}

let wsize = WindowSize()

struct GameConfig {
  let ballRadius: Float = 10.0
  let playerRadius: Float = 20.0
  let vertical: Float = 180.0
  let horizontal: Float = 360.0
  let ballColor: Color = RED
  let playerColor: Color = BLUE
  let spawnPointBall = Vector2(x: wsize.width / 2.0, y: wsize.height / 2.0)
  let spawnPointPlayer = Vector2(x: wsize.width / 2.0, y: 2 * wsize.height / 3.0)
  let playerVelMax: Float = 2.0
  let addBallEvery = 5
}

let config = GameConfig()

// -- BALL ------------------------------------------------
struct Ball {
  var pos: Vector2 = config.spawnPointBall
  var direction: Direction = Direction(
    angle: Float.random(in: 0 ..< 360), speed: Float.random(in: 2 ... 6)
  )
  var radius: Float = config.ballRadius
  var color: Color = config.ballColor

  mutating func reflect(plane: Float) {
    var angle = direction.angle
    angle = plane - angle
    if angle < 0.0 {
      angle = 360.0 + angle
    } else if angle > 360.0 {
      angle = angle - 360.0
    }
    direction.angle = angle
  }

  mutating func updatePos() {
    pos.x += sin(direction.angle.radians) * direction.speed
    pos.y += cos(direction.angle.radians) * direction.speed
  }
}

typealias Balls = [Ball]

extension Balls {
  mutating func updatePos() {
    for idx in indices {
      self[idx].updatePos()
      // Bounds check
      if (self[idx].pos.x - self[idx].radius) <= 0
        || (self[idx].pos.x + self[idx].radius) >= wsize.width {
        self[idx].reflect(plane: config.horizontal)
      }
      if (self[idx].pos.y - self[idx].radius) <= 0
        || (self[idx].pos.y + self[idx].radius) >= wsize.height {
        self[idx].reflect(plane: config.vertical)
      }
    }
  }

  func draw() {
    for ball in self {
      DrawCircleV(ball.pos, ball.radius, ball.color)
    }
  }
}

// -- PLAYER ----------------------------------------------
struct Player {
  var pos: Vector2 = config.spawnPointPlayer
  var direction: Direction = Direction(angle: 0.0, speed: 0.0)
  var radius: Float = config.playerRadius
  var color: Color = config.playerColor

  func getMouseAngleDist() -> (Float, Float) {
    let mouseX = Float(GetMouseX())
    let mouseY = Float(GetMouseY())
    let dX = (mouseX - pos.x)
    let dY = (mouseY - pos.y)
    var angle: Float
    var dist: Float
    if dX >= 0.0 {
      if dY >= 0.0 {
        angle = atan(abs(dX / dY)).degrees
      } else {
        angle = 90.0 + atan(abs(dY / dX)).degrees
      }
    } else {
      if dY < 0.0 {
        angle = 180.0 + atan(abs(dX / dY)).degrees
      } else {
        angle = 270.0 + atan(abs(dY / dX)).degrees
      }
    }
    dist = ((dX * dX) + (dY * dY)).squareRoot()
    return (angle, dist)
  }

  func hasCollided(with balls: Balls) -> Bool {
    for ball in balls {
      if CheckCollisionCircles(pos, config.playerRadius, ball.pos, config.ballRadius) {
        return true
      }
    }
    return false
  }

  mutating func updatePos() {
    let playerRadius = config.playerRadius
    let (angle, dist) = getMouseAngleDist()
    direction.angle = angle
    var speed: Float

    if dist < config.playerRadius {
      speed = 0.0
    } else {
      speed = min((dist - config.playerRadius) * 0.05, config.playerVelMax)
    }
    direction.speed = speed

    pos.x += sin(direction.angle.radians) * direction.speed
    pos.y += cos(direction.angle.radians) * direction.speed
    if (pos.x - playerRadius) <= 0 {
      pos.x = playerRadius
    } else if (pos.x + playerRadius) >= wsize.width {
      pos.x = wsize.width - playerRadius
    }
    if (pos.y - playerRadius) <= 0 {
      pos.y = playerRadius
    } else if (pos.y + playerRadius) >= wsize.height {
      pos.y = wsize.height - playerRadius
    }
  }

  func draw() {
    DrawCircleV(pos, radius, color)
  }
}

enum GameState {
  case running, paused, gameover
}

// -- MAIN PROGRAM ----------------------------------------
var state = GameState.paused
var balls: Balls = [Ball(), Ball(), Ball(), Ball(), Ball(), Ball()]
var player = Player()
var msg = "Dodge the Virus. Press SPACE to start"
var seconds: Int
var score: Int = 0
var startTime: Int = 0
var addedInSecond = 0
var extraPoints = 0

// -- Update Positions ------------------------------------

print("Dodge")

InitWindow(Int32(wsize.width), Int32(wsize.height), "Dodge the Virus. Press SPACE to start.")
SetTargetFPS(60)

while !WindowShouldClose() {
  switch state {
  case .paused:
    if IsKeyPressed(Int32(KEY_SPACE.rawValue)) {
      state = .running
      msg = ""
      startTime = getCurrentTime()
    }
  case .gameover:
    msg = "GAME OVER. Press SPACE to play again."
    if IsKeyPressed(Int32(KEY_SPACE.rawValue)) {
      state = .running
      balls = [Ball(), Ball(), Ball(), Ball(), Ball(), Ball()]
      player = Player()
      msg = ""
      startTime = getCurrentTime()
      addedInSecond = 0
      extraPoints = 0
    }
  case .running:
    // -- GAME LOOP: Update objects -----------------------
    if player.hasCollided(with: balls) {
      state = .gameover
    } else {
      seconds = getCurrentTime() - startTime
      score = seconds + extraPoints
      if seconds % config.addBallEvery == 0, seconds != addedInSecond {
        addedInSecond = seconds
        balls.append(Ball())
      }

      if IsMouseButtonPressed(Int32(MOUSE_LEFT_BUTTON.rawValue)) {
        balls.append(Ball())
      }

      balls.updatePos()

      player.updatePos()
    }
  }

  BeginDrawing()
  ClearBackground(BLACK)

  // Mark the spawn area
  DrawCircleV(config.spawnPointBall, config.ballRadius + 10.0, DARKGRAY)

  // Draw the balls (viruses)
  balls.draw()

  // Draw the Player
  player.draw()

  DrawText(msg, 10, 10, 20, LIGHTGRAY)
  DrawText("Score: \(score)", Int32(wsize.width) - 130, 10, 20, LIGHTGRAY)

  EndDrawing()
}

CloseWindow()
