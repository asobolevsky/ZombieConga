//
//  GameOverScene.swift
//  ZombieConga
//
//  Created by Alexey Sobolevsky on 01/10/2019.
//  Copyright © 2019 Alexey Sobolevsky. All rights reserved.
//

import Foundation
import SpriteKit

final class GameOverScene: SKScene {

    let won: Bool

    init(size: CGSize, won: Bool) {
        self.won = won
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        var (image, sound): (String, String)

        if won {
            (image, sound) = (Resources.Images.winBackground, Resources.Audio.winSound)
        } else {
            (image, sound) = (Resources.Images.loseBackground, Resources.Audio.loseSound)
        }

        let backgroundView = SKSpriteNode(imageNamed: image)
        run(SKAction.playSoundFileNamed(sound, waitForCompletion: false))
        backgroundView.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(backgroundView)

        let wait = SKAction.wait(forDuration: 3.0)
        let showGameScene = SKAction.run { [unowned self] in
            let gameScene = MainMenuScene(size: self.size)
            gameScene.scaleMode = self.scaleMode

            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            self.view?.presentScene(gameScene, transition: reveal)
        }
        run(SKAction.sequence([ wait, showGameScene ]))
    }

}
