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
    
    // Define the possible types of invader enemies
    enum InvaderType {
        case A
        case B
        case C
    }
    
    enum InvaderMovementDirection {
        case Right
        case Left
        case DownThenRight
        case DownThenLeft
        case None
    }
    
    // Define the size of the invaders and that they’ll be laid out in a grid of rows and columns on the screen
    let kInvaderSize = CGSize(width:24, height:16)
    let kInvaderGridSpacing = CGSize(width:12, height:12)
    let kInvaderRowCount = 6
    let kInvaderColCount = 6
    
    // Define a name to identify invaders when searching for them in the scene.
    let kInvaderName = "invader"
    
    let kShipSize = CGSize(width:30, height:16)
    let kShipName = "ship"
    
    let kScoreHudName = "scoreHud"
    let kHealthHudName = "healthHud"
    
    var contentCreated = false
    
    // Invaders begin by moving to the right.
    var invaderMovementDirection: InvaderMovementDirection = .Right

    // Invaders haven’t moved yet, so set the time to zero.
    var timeOfLastMove: CFTimeInterval = 0.0
    
    // Invaders take 1 second for each move. Each step left, right or down takes 1 second.
    let timePerMove: CFTimeInterval = 1.0
    
    // Object Lifecycle Management
    
    // Scene Setup and Content Creation
    override func didMoveToView(view: SKView) {
        
        if (!self.contentCreated) {
            self.createContent()
            self.contentCreated = true
        }
    }
    
    func createContent() {
        
        //let invader = SKSpriteNode(imageNamed: "InvaderA_00.png")
        
        //invader.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        
        //self.addChild(invader)
        
        // black space color
        self.backgroundColor = SKColor.blackColor()
        
        setupInvaders()
        
        setupShip()
        
        setupHud()
        
    }
    
    func makeInvaderOfType(invaderType: InvaderType) -> (SKNode) {
        
        // Use the invaderType parameter to determine the color of the invader
        var invaderColor: SKColor
        
        switch(invaderType) {
        case .A:
            invaderColor = SKColor.redColor()
        case .B:
            invaderColor = SKColor.greenColor()
        case .C:
            invaderColor = SKColor.blueColor()
        default:
            invaderColor = SKColor.blueColor()
        }
        
        // Call the handy convenience initializer SKSpriteNode(color:size:) to allocate and initialize a sprite that renders as a rectangle of the given color invaderColor with size kInvaderSize.
        let invader = SKSpriteNode(color: invaderColor, size: kInvaderSize)
        invader.name = kInvaderName
        
        return invader
    }
    
    func setupInvaders() {
        
        // Declare and set the baseOrigin constant and loop over the rows.
        let baseOrigin = CGPoint(x:size.width / 3, y:180)
        for var row = 1; row <= kInvaderRowCount; row++ {
            
            // Choose a single InvaderType for all invaders in this row based on the row number.
            var invaderType: InvaderType
            if row % 3 == 0 {
                invaderType = .A
            } else if row % 3 == 1 {
                invaderType = .B
            } else {
                invaderType = .C
            }
            
            // Do some math to figure out where the first invader in this row should be positioned.
            let invaderPositionY = CGFloat(row) * (kInvaderSize.height * 2) + baseOrigin.y
            var invaderPosition = CGPoint(x:baseOrigin.x, y:invaderPositionY)
            
            // Loop over the columns.
            for var col = 1; col <= kInvaderColCount; col++ {
                
                // Create an invader for the current row and column and add it to the scene.
                var invader = makeInvaderOfType(invaderType)
                invader.position = invaderPosition
                addChild(invader)
                
                // Update the invaderPosition so that it’s correct for the next invader.
                invaderPosition = CGPoint(x: invaderPosition.x + kInvaderSize.width + kInvaderGridSpacing.width, y: invaderPositionY)
            }
        }
    }
    
    func setupShip() {
        // Create a ship
        let ship = makeShip()
        
        // Place the ship on the screen
        ship.position = CGPoint(x:size.width / 2.0, y:kShipSize.height / 2.0)
        addChild(ship)
    }
    
    func makeShip() -> SKNode {
        let ship = SKSpriteNode(color: SKColor.greenColor(), size: kShipSize)
        ship.name = kShipName
        return ship
    }
    
    func setupHud() {
        
        // Give the score label a name so you can find it later when you need to update the displayed score.
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = kScoreHudName
        scoreLabel.fontSize = 25
        
        // Color the score label green.
        scoreLabel.fontColor = SKColor.greenColor()
        scoreLabel.text = String(format: "Score: %04u", 0)
        
        // Position the score label.
        println(size.height)
        scoreLabel.position = CGPoint(x: frame.size.width / 2, y: size.height - (40 + scoreLabel.frame.size.height/2))
        addChild(scoreLabel)
        
        // Give the health label a name so you can reference it later when you need to update the displayed health.
        let healthLabel = SKLabelNode(fontNamed: "Courier")
        healthLabel.name = kHealthHudName
        healthLabel.fontSize = 25
        
        // Color the health label red; 
        // the red and green indicators are common colors for these indicators in games, 
        // and they’re easy to differentiate in the middle of furious gameplay.
        healthLabel.fontColor = SKColor.redColor()
        healthLabel.text = String(format: "Health: %.1f%%", 100.0)
        
        // Position the health below the score label.
        healthLabel.position = CGPoint(x: frame.size.width / 2, y: size.height - (80 + healthLabel.frame.size.height/2))
        addChild(healthLabel)
        
    }
    
    // Scene Update
    
    override func update(currentTime: CFTimeInterval) {

        /* Called before each frame is rendered */
        
        moveInvadersForUpdate(currentTime)
        
    }
    
    // Scene Update Helpers
    func moveInvadersForUpdate(currentTime: CFTimeInterval) {
        
        // If it’s not yet time to move, then exit the method.
        if (currentTime - timeOfLastMove < timePerMove) {
            return
        }
        
        // Recall that your scene holds all of the invaders as child nodes
        enumerateChildNodesWithName(kInvaderName, usingBlock: {
            (node: SKNode!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            switch self.invaderMovementDirection {
            case .Right:
                node.position = CGPoint(x: node.position.x + 10, y: node.position.y)
            case .Left:
                node.position = CGPoint(x: node.position.x - 10, y: node.position.y)
            case .DownThenLeft, .DownThenRight:
                node.position = CGPoint(x: node.position.x, y: node.position.y - 10)
            case .None:
                break
            default:
                break
            }
            
            // Record that you just moved the invaders
            self.timeOfLastMove = currentTime
        })
    }
    
    // Invader Movement Helpers
    
    // Bullet Helpers
    
    // User Tap Helpers
    
    // HUD Helpers
    
    // Physics Contact Helpers
    
    // Game End Helpers
    
}
