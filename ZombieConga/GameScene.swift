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

    private var screenFrame: SKNode!
    private var screenScaleFactor: CGFloat = 1

    override func didMove(to view: SKView) {
        setupScene()

        let background = setupBackground()
        addChild(background)

        // Happens because the scene size is larger than the view's
        screenScaleFactor = background.size.width / view.bounds.width
        let screenFrameRect = view.frame.scaled(by: screenScaleFactor)
        screenFrame = setupScreenFrame(with: screenFrameRect, inside: background.frame)
        addChild(screenFrame)

        let zombie = createZombie()
        screenFrame.addChild(zombie)
    }

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

    private func setupScreenFrame(with frame: CGRect, inside parentFrame: CGRect) -> SKNode {
        let screenFrame = SKShapeNode(rect: frame)
        screenFrame.name = .screenFrameNodeName
        screenFrame.position = CGPoint(x: parentFrame.midX - frame.midX, y: parentFrame.midY - frame.midY)
        return screenFrame
    }

    private func createZombie() -> SKNode {
        let zombie = SKSpriteNode(imageNamed: "zombie1")
        zombie.name = .zombieNodeName
        zombie.position = CGPoint(x: 10, y: 10)
        zombie.anchorPoint = .zero
        zombie.zPosition = 1
        return zombie
    }
}

private extension String {
    static let backgroundNodeName = "background"
    static let screenFrameNodeName = "screenFrame"
    static let zombieNodeName = "zombie"
}
