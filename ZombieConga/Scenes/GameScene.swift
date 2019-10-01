//
//  GameScene.swift
//  ZombieConga
//
//  Created by Alexey Sobolevsky on 16/09/2019.
//  Copyright © 2019 Alexey Sobolevsky. All rights reserved.
//

import SpriteKit
import GameplayKit

enum GameState {
    case running
    case gameOver(Bool)
}

final class GameScene: SKScene {

    private let playableRect: CGRect

    private var zombie: SKNode!
    private let zombieAnimation: SKAction
    private var train = [SKNode]()

    private let moveSpeed: CGFloat = 480
    private let rotationSpeed: CGFloat = 4.0 * π
    private var lastUpdateTime: TimeInterval = 0
    private var dt: TimeInterval = 0
    private var velocity: CGPoint = .zero
    private var lastTouchedLocation: CGPoint = .zero
    private var isInvincible = false

    private let maxTrainCount = 15
    private var lives = 5
    private var gameState: GameState = .running

    private let catCollisionSound = SKAction.playSoundFileNamed(Resources.Audio.hitCat, waitForCompletion: false)
    private let ladyCollisionSound = SKAction.playSoundFileNamed(Resources.Audio.hitLady, waitForCompletion: false)

    private let enableLogging = false

    override init(size: CGSize) {
        let actualAspectRation = UIScreen.main.bounds.width / UIScreen.main.bounds.height
        let maxAspectRation: CGFloat = 16.0 / 9.0
        let playableHeight = size.width / max(actualAspectRation, maxAspectRation)
        let playableMargin = (size.height - playableHeight) / 2.0
        playableRect = CGRect(origin: CGPoint(x: 0, y: playableMargin),
                              size: CGSize(width: size.width, height: playableHeight))
        zombieAnimation = Self.setupZombieAnimation()

        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        setupScene()

        let background = setupBackground()
        addChild(background)

        zombie = createZombie()
        addChild(zombie)
        debugDrawPlayableArea()

        runRepeatedBlock(with: 2.0) { [weak self] in
            self?.spawnLady()
        }

        runRepeatedBlock(with: 1.0) { [weak self] in
            self?.spawnCat()
        }

        let customAction = SKAction.customAction(withDuration: 1) { (_, elapsedTime) in
            print("elapsedTime: \(elapsedTime)")
        }
        let log = SKAction.run {
            print("Now reversed")
        }
        let reversedCustomAction = customAction.reversed()
        run(SKAction.sequence([ customAction, log, reversedCustomAction ]))
    }

    override func update(_ currentTime: TimeInterval) {
        calculateDelta(with: currentTime)

        if case let .gameOver(isWin) = gameState {
            presentGameOverScene(isWin)
        }

        guard case .running = gameState else {
            return
        }

        updateZombiePosition()
        boundsCheckZombie()
        moveTrain()
    }

    override func didEvaluateActions() {
        checkCollisions()
    }

    // MARK: - Touches

    private func sceneTouched(at location: CGPoint) {
        moveZombie(toward: location)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let touchLocation = touch.location(in: self)
        sceneTouched(at: touchLocation)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let touchLocation = touch.location(in: self)
        sceneTouched(at: touchLocation)
    }

    // MARK: - Setup

    private func setupScene() {
        backgroundColor = SKColor.black
        playBackgroundMusic(Resources.Audio.backgroundMusic)
    }

    private func setupBackground() -> SKSpriteNode {
        let background = SKSpriteNode(imageNamed: Resources.Images.background1)
        background.name = .backgroundNodeName
        background.anchorPoint = .zero
        background.position = .zero
        background.zPosition = -1
        return background
    }

    private func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }


    // MARK: - Node creators

    private func createZombie() -> SKNode {
        let zombie = SKSpriteNode(imageNamed: Resources.Images.zombieIdle)
        zombie.name = .zombieNodeName
        zombie.position = CGPoint(x: 200, y: playableRect.minY + 200)
        zombie.zPosition = 100
        return zombie
    }

    private static func setupZombieAnimation() -> SKAction {
        var textures = [SKTexture]()

        var frames = Array(1...4)
        frames.append(contentsOf: (2...3).reversed())
        for i in frames {
            textures.append(SKTexture(imageNamed: "\(Resources.Images.zombieAnim)\(i)"))
        }

        return SKAction.animate(with: textures, timePerFrame: 0.1)
    }

    private func makeBlinkingAnimation() -> SKAction {
        let blinkTimes = 10.0
        let duration = 3.0
        let slice = duration / blinkTimes
        let blinkAction = SKAction.customAction(withDuration: duration) { (node, elapsedTime) in
            let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
            node.isHidden = remainder > (slice / 2)
        }
        return blinkAction
    }

    private func spawnLady() {
        let lady = SKSpriteNode(imageNamed: Resources.Images.lady)
        lady.name = .ladyNodeName
        lady.position = CGPoint(
            x: size.width + lady.size.width / 2,
            y: CGFloat.random(
                min: playableRect.minY + lady.size.height / 2,
                max: playableRect.maxY - lady.size.height / 2)
        )
        addChild(lady)

        // NOTE: [action]by actions are preferable as they're reversible
//        let actionMove = SKAction.move(to: CGPoint(x: -lady.size.width/2, y: lady.position.y), duration: 2.0)
        let actionMove = SKAction.moveBy(x: -(size.width + lady.size.width), y: 0, duration: 2.0)
        lady.run(SKAction.sequence([ actionMove, SKAction.removeFromParent() ]))
    }

    private func spawnCat() {
        let cat = SKSpriteNode(imageNamed: Resources.Images.cat)
        cat.name = .catNodeName
        cat.position = CGPoint.randomPoint(in: playableRect)
        cat.setScale(0)
        cat.zRotation = -π / 16.0
        addChild(cat)

        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        // START Wait animation
        let leftWiggle = SKAction.rotate(byAngle: π / 8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([ leftWiggle, rightWiggle ])
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([ fullScale, fullWiggle ])
        let groupWait = SKAction.repeat(group, count: 10)
        // End Wait animation
        let disappear = SKAction.scale(to: 0.0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let sequence = SKAction.sequence([ appear, groupWait, disappear, removeFromParent ])
        cat.run(sequence)
    }

    private func loseCats() {
        var loseCount = 0
        enumerateChildNodes(withName: .trainNodeName) { (node, stop) in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)

            node.name = ""
            node.run(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotate(byAngle: π * 4, duration: 1.0),
                        SKAction.move(to: randomSpot, duration: 1.0),
                        SKAction.scale(to: 0, duration: 1.0)
                    ]),
                    SKAction.removeFromParent()
                ])
            )

            loseCount += 1
            if loseCount >= 2 {
                stop.pointee = true
            }
        }
    }

    private func presentGameOverScene(_ won: Bool) {
        let gameOverScene = GameOverScene(size: size, won: won)
        gameOverScene.scaleMode = scaleMode

        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        backgroundMusicPlayer?.stop()
        view?.presentScene(gameOverScene, transition: reveal)
    }


    // MARK: - Movement helpers

    private func move(node: SKNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        log("Amount to move: \(amountToMove)")
        node.position += amountToMove
    }

    // speed - Radians per second
    private func rotate(node: SKNode, direction: CGPoint, speed: CGFloat) {
        let angleDiff = shortestAngleBetween(node.zRotation, direction.angle)
        let amountToRotate = min(speed * CGFloat(dt), abs(angleDiff))
        node.zRotation += amountToRotate * angleDiff.sign
    }

    private func moveZombie(toward location: CGPoint) {
        startZombieAnimation()
        let offset = location - zombie.position
        velocity = offset.normalized * moveSpeed
        lastTouchedLocation = location
    }

    private func moveTrain() {
        var targetPosition = zombie.position

        train.forEach { node in
            defer {
                targetPosition = node.position
            }

            guard node.hasActions() == false else {
                return
            }

            let actionDuration = 0.3
            let offset = targetPosition - node.position
            let direction = offset.normalized
            let amountToMovePerSec = direction * moveSpeed
            let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
            let amountToRotate = direction * rotationSpeed

            if offset.length > amountToMove.length {
                let moveAction = SKAction.move(by: amountToMove.vector, duration: actionDuration)
                let rotateAction = SKAction.rotate(toAngle: amountToRotate.angle, duration: actionDuration)
                let groupAction = SKAction.group([ moveAction, rotateAction ])
                node.run(groupAction)
            }
        }
    }

    private func updateZombiePosition() {
        let distance = (lastTouchedLocation - zombie.position).length
        let moveValue = moveSpeed * CGFloat(dt)

        if distance <= moveValue {
            zombie.position = lastTouchedLocation
            velocity = .zero
            stopZombieAnimation()
        } else {
            move(node: zombie, velocity: velocity)
            rotate(node: zombie, direction: velocity, speed: rotationSpeed)
        }
    }

    private func startZombieAnimation() {
        if zombie.action(forKey: .zombieAnimationName) == nil {
            zombie.run(SKAction.repeatForever(zombieAnimation), withKey: .zombieAnimationName)
        }
    }

    private func stopZombieAnimation() {
        zombie.removeAction(forKey: .zombieAnimationName)
    }

    private func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
        let topRight = CGPoint(x: size.width, y: playableRect.maxY)

        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x *= -1
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x *= -1
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y *= -1
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y *= -1
        }
    }

    private func zombieHit(cat: SKNode) {
        run(catCollisionSound)

        cat.name = .trainNodeName
        cat.removeAllActions()
        cat.setScale(1)
        cat.zRotation = 0
        train.append(cat)

        let becomeGreen = SKAction.colorize(with: SKColor.green, colorBlendFactor: 1.0, duration: 0.2)
        cat.run(becomeGreen)

        if train.count >= maxTrainCount {
            gameState = .gameOver(true)
        }
    }

    private func zombieHit(lady: SKNode) {
        run(ladyCollisionSound)

        lady.removeFromParent()
        loseCats()
        lives -= 1
        startZombieInvincibleAction()

        if lives <= 0 {
            gameState = .gameOver(false)
        }
    }

    private func startZombieInvincibleAction() {
        guard isInvincible == false else {
            return
        }

        isInvincible = true
        let blinkAction = makeBlinkingAnimation()
        let invincibleEndAction = SKAction.run { [weak self] in
            self?.isInvincible = false
        }
        zombie.run(SKAction.sequence([ blinkAction, invincibleEndAction ]))
    }

    private func checkCollisions() {
        var hitCats = [SKNode]()
        enumerateChildNodes(withName: .catNodeName) { (node, _) in
            guard let cat = node as? SKSpriteNode else {
                return
            }
            if cat.frame.intersects(self.zombie.frame) {
                hitCats.append(cat)
            }
        }
        hitCats.forEach(zombieHit(cat:))

        if isInvincible == false {
            var hitLadies = [SKNode]()
            enumerateChildNodes(withName: .ladyNodeName) { (node, _) in
                guard let lady = node as? SKSpriteNode else {
                    return
                }
                if lady.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) {
                    hitLadies.append(lady)
                }
            }
            hitLadies.forEach(zombieHit(lady:))
        }
    }

    private func calculateDelta(with currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime

        log("\(dt * 1000) milliseconds since last update")
    }

    private func runRepeatedBlock(with duration: TimeInterval, block: @escaping () -> ()) {
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(block),
                SKAction.wait(forDuration: duration)
            ])
        ))
    }

    private func log(_ text: String) {
        if enableLogging {
            print(text)
        }
    }

}

private extension String {
    static let backgroundNodeName = "background"
    static let screenFrameNodeName = "screenFrame"
    static let zombieNodeName = "zombie"
    static let zombieAnimationName = "zombieAnimation"
    static let ladyNodeName = "lady"
    static let catNodeName = "cat"
    static let trainNodeName = "train"
}
