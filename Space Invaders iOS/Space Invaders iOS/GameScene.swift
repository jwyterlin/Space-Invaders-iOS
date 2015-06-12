//
//  GameScene.swift
//  Space Invaders iOS
//
//  Created by Jhonathan Wyterlin on 11/06/15.
//  Copyright (c) 2015 Jhonathan Wyterlin. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene {
    
    // Private GameScene Properties
    
    var contentCreated = false
    
    // Object Lifecycle Management
    
    // Scene Setup and Content Creation
    override func didMoveToView(view: SKView) {
        
        if (!self.contentCreated) {
            self.createContent()
            self.contentCreated = true
        }
    }
    
    func createContent() {
        
        let invader = SKSpriteNode(imageNamed: "InvaderA_00.png")
        
        invader.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        
        self.addChild(invader)
        
        // black space color
        self.backgroundColor = SKColor.blackColor()
    }
    
    // Scene Update
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    
    // Scene Update Helpers
    
    // Invader Movement Helpers
    
    // Bullet Helpers
    
    // User Tap Helpers
    
    // HUD Helpers
    
    // Physics Contact Helpers
    
    // Game End Helpers
    
}
