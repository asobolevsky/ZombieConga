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

    private var playableArea: SKNode!
    private var zombie: SKNode!
    private var playableAreaScaleFactor: CGFloat = 1

    private var lastUpdateTime: TimeInterval = 0
    private var dt: TimeInterval = 0

    private let zombieMoveSpeed: CGFloat = 480
    private var velocity: CGPoint = .zero

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        setupScene()

        let background = setupBackground()
        addChild(background)

        // Happens because the scene size is larger than the view's
        playableAreaScaleFactor = background.size.width / view.bounds.width
        let screenFrameRect = view.frame.scaled(by: playableAreaScaleFactor)
        playableArea = setupPlayableArea(with: screenFrameRect, inside: background.frame)
        addChild(playableArea)

        zombie = createZombie()
        playableArea.addChild(zombie)
    }

    override func update(_ currentTime: TimeInterval) {
        calculateDelta(with: currentTime)

        move(node: zombie, velocity: velocity)
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

        let touchLocation = touch.location(in: playableArea)
        sceneTouched(at: touchLocation)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let touchLocation = touch.location(in: playableArea)
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

    private func setupPlayableArea(with frame: CGRect, inside parentFrame: CGRect) -> SKNode {
        let playableArea = SKShapeNode(rect: frame)
        playableArea.name = .screenFrameNodeName
        playableArea.position = CGPoint(x: parentFrame.midX - frame.midX, y: parentFrame.midY - frame.midY)
        return playableArea
    }

    private func createZombie() -> SKNode {
        let zombie = SKSpriteNode(imageNamed: "zombie1")
        zombie.name = .zombieNodeName
        zombie.position = CGPoint(x: 200, y: 200)
        zombie.zPosition = 1
        return zombie
    }

    // MARK: - Helpers

    private func move(node: SKNode, velocity: CGPoint) {
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
                                   y: velocity.y * CGFloat(dt))
        print("Amount to move: \(amountToMove)")

        node.position = CGPoint(
            x: node.position.x + amountToMove.x,
            y: node.position.y + amountToMove.y
        )
    }

    private func moveZombie(toward location: CGPoint) {
        let offset = CGPoint(x: location.x - zombie.position.x,
                             y: location.y - zombie.position.y)
        let length = CGFloat(sqrt(Double(offset.x * offset.x) + Double(offset.y * offset.y)))

        // Convert vector to a unit vector, normalization
        let direction = CGPoint(x: offset.x / length,
                                y: offset.y / length)
        velocity = CGPoint(x: direction.x * zombieMoveSpeed,
                           y: direction.y * zombieMoveSpeed)
    }

    private func boundsCheckZombie() {
        let bottomLeft = CGPoint.zero
        let topRight = CGPoint(x: playableArea.frame.width,
                               y: playableArea.frame.height)

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

        print("\(dt * 1000) milliseconds since last update")
    }
}

private extension String {
    static let backgroundNodeName = "background"
    static let screenFrameNodeName = "screenFrame"
    static let zombieNodeName = "zombie"
}
