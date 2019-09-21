//
//  GameScene.swift
//  ZombieConga
//
//  Created by Alexey Sobolevsky on 16/09/2019.
//  Copyright © 2019 Alexey Sobolevsky. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    private let playableRect: CGRect
    private var zombie: SKNode!

    private var lastUpdateTime: TimeInterval = 0
    private var dt: TimeInterval = 0

    private let zombieMoveSpeed: CGFloat = 480
    private let zombieRotationSpeed: CGFloat = 4.0 * π
    private var velocity: CGPoint = .zero
    private var lastTouchedLocation: CGPoint = .zero

    private let enableLogging = false

    override init(size: CGSize) {
        let actualAspectRation = UIScreen.main.bounds.width / UIScreen.main.bounds.height
        let maxAspectRation: CGFloat = 16.0 / 9.0
        let playableHeight = size.width / max(actualAspectRation, maxAspectRation)
        let playableMargin = (size.height - playableHeight) / 2.0
        playableRect = CGRect(origin: CGPoint(x: 0, y: playableMargin),
                              size: CGSize(width: size.width, height: playableHeight))

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
    }

    override func update(_ currentTime: TimeInterval) {
        calculateDelta(with: currentTime)

        updateZombiePosition()
        boundsCheckZombie()
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
    }

    private func setupBackground() -> SKSpriteNode {
        let background = SKSpriteNode(imageNamed: "background1")
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

    private func createZombie() -> SKNode {
        let zombie = SKSpriteNode(imageNamed: "zombie1")
        zombie.name = .zombieNodeName
        zombie.position = CGPoint(x: 200, y: playableRect.minY + 200)
        zombie.zPosition = 1
        return zombie
    }

    // MARK: - Helpers

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
        let offset = location - zombie.position
        velocity = offset.normalized * zombieMoveSpeed
        lastTouchedLocation = location
    }

    private func updateZombiePosition() {
        let distance = (lastTouchedLocation - zombie.position).length
        let moveValue = zombieMoveSpeed * CGFloat(dt)

        if distance <= moveValue {
            zombie.position = lastTouchedLocation
            velocity = .zero
        } else {
            move(node: zombie, velocity: velocity)
            rotate(node: zombie, direction: velocity, speed: zombieRotationSpeed)
        }
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

    private func calculateDelta(with currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime

        log("\(dt * 1000) milliseconds since last update")
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
}
