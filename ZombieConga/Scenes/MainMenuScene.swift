//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Alexey Sobolevsky on 01/10/2019.
//  Copyright © 2019 Alexey Sobolevsky. All rights reserved.
//

import Foundation
import SpriteKit

final class MainMenuScene: SKScene {

    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: Resources.Images.mainMenu)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(background)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode

        let reveal = SKTransition.doorway(withDuration: 1.5)
        view?.presentScene(gameScene, transition: reveal)
    }

}
