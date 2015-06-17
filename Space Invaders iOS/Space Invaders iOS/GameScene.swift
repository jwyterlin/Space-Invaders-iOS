//
//  GameScene.swift
//  Space Invaders iOS
//
//  Created by Jhonathan Wyterlin on 11/06/15.
//  Copyright (c) 2015 Jhonathan Wyterlin. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Private GameScene Properties

    var score: Int = 0
    var shipHealth: Float = 1.0
    
    var contactQueue = Array<SKPhysicsContact>()
    
    let kInvaderCategory: UInt32 = 0x1 << 0
    let kShipFiredBulletCategory: UInt32 = 0x1 << 1
    let kShipCategory: UInt32 = 0x1 << 2
    let kSceneEdgeCategory: UInt32 = 0x1 << 3
    let kInvaderFiredBulletCategory: UInt32 = 0x1 << 4
    
    var tapQueue: Array<Int> = []
    
    let motionManager: CMMotionManager = CMMotionManager()
    
    enum BulletType {
        case ShipFired
        case InvaderFired
    }
    
    let kShipFiredBulletName = "shipFiredBullet"
    let kInvaderFiredBulletName = "invaderFiredBullet"
    let kBulletSize = CGSize(width:4, height: 8)
    
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
            motionManager.startAccelerometerUpdates()
            userInteractionEnabled = true
            physicsWorld.contactDelegate = self
        }
    }
    
    func createContent() {
        
        //let invader = SKSpriteNode(imageNamed: "InvaderA_00.png")
        
        //invader.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        
        //self.addChild(invader)
        
        // black space color
        self.backgroundColor = SKColor.blackColor()
        
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        physicsBody!.categoryBitMask = kSceneEdgeCategory
        
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
        
        invader.physicsBody = SKPhysicsBody(rectangleOfSize: invader.frame.size)
        invader.physicsBody!.dynamic = false
        invader.physicsBody!.categoryBitMask = kInvaderCategory
        invader.physicsBody!.contactTestBitMask = 0x0
        invader.physicsBody!.collisionBitMask = 0x0
        
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
        
        // Create a rectangular physics body the same size as the ship.
        ship.physicsBody = SKPhysicsBody(rectangleOfSize: ship.frame.size)
        
        // Make the shape dynamic; this makes it subject to things such as collisions and other outside forces.
        ship.physicsBody!.dynamic = true
        
        // You don't want the ship to drop off the bottom of the screen, so you indicate that it's not affected by gravity.
        ship.physicsBody!.affectedByGravity = false
        
        // Give the ship an arbitrary mass so that its movement feels natural.
        ship.physicsBody!.mass = 0.02
        
        // Set the ship's category.
        ship.physicsBody!.categoryBitMask = kShipCategory
        // Don't detect contact between the ship and other physics bodies.
        ship.physicsBody!.contactTestBitMask = 0x0
        // Do detect collisions between the ship and the scene's outer edges.
        ship.physicsBody!.collisionBitMask = kSceneEdgeCategory
        
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
        healthLabel.text = String(format: "Health: %.1f%%", self.shipHealth * 100.0)
        
        // Position the health below the score label.
        healthLabel.position = CGPoint(x: frame.size.width / 2, y: size.height - (80 + healthLabel.frame.size.height/2))
        addChild(healthLabel)
        
    }
    
    func makeBulletOfType(bulletType: BulletType) -> SKNode! {
        
        var bullet: SKNode!
        
        switch bulletType {
        case .ShipFired:
            
            bullet = SKSpriteNode(color: SKColor.greenColor(), size: kBulletSize)
            bullet.name = kShipFiredBulletName
            
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
            bullet.physicsBody!.dynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = kShipFiredBulletCategory
            bullet.physicsBody!.contactTestBitMask = kInvaderCategory
            bullet.physicsBody!.collisionBitMask = 0x0
            
        case .InvaderFired:
            
            bullet = SKSpriteNode(color: SKColor.magentaColor(), size: kBulletSize)
            bullet.name = kInvaderFiredBulletName
            
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
            bullet.physicsBody!.dynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = kInvaderFiredBulletCategory
            bullet.physicsBody!.contactTestBitMask = kShipCategory
            bullet.physicsBody!.collisionBitMask = 0x0
            
            break;
        default:
            bullet = nil
        }
        
        return bullet
        
    }
    
    // Scene Update
    
    override func update(currentTime: CFTimeInterval) {

        /* Called before each frame is rendered */
        
        processContactsForUpdate(currentTime)
        
        processUserTapsForUpdate(currentTime)
        
        processUserMotionForUpdate(currentTime)
        
        moveInvadersForUpdate(currentTime)
        
        fireInvaderBulletsForUpdate(currentTime)
        
    }
    
    // Scene Update Helpers
    func moveInvadersForUpdate(currentTime: CFTimeInterval) {
        
        // If it’s not yet time to move, then exit the method.
        if (currentTime - timeOfLastMove < timePerMove) {
            return
        }
        
        determineInvaderMovementDirection()
        
        // Recall that your scene holds all of the invaders as child nodes
        enumerateChildNodesWithName(kInvaderName) {
            node, stop in
            
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
        }
    }
    
    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        
        // Get the ship from the scene so you can move it.
        if let ship = self.childNodeWithName(kShipName) as! SKSpriteNode! {
            
            // Get the accelerometer data from the motion manager.
            // It is an Optional, that is a variable that can hold either a value or no value.
            // The if let data statement allows to check if there is a value in accelerometerData,
            // if is the case assign it to the constant data in order to use it safely within the if’s scope.
            if let data = motionManager.accelerometerData {
                
                // If your device is oriented with the screen facing up and the home button at the bottom,
                // then tilting the device to the right produces data.acceleration.x > 0,
                // whereas tilting it to the left produces data.acceleration.x < 0.
                // The check against 0.2 means that the device will be considered perfectly flat/no
                // thrust (technically data.acceleration.x == 0) as long as it's close enough to zero
                // (data.acceleration.x in the range [-0.2, 0.2]).
                // There's nothing special about 0.2, it just seemed to work well for me.
                // Little tricks like this will make your control system more reliable and less frustrating for users.
                if (fabs(data.acceleration.x) > 0.2) {
                    
                    ship.physicsBody!.applyForce(CGVectorMake(40.0 * CGFloat(data.acceleration.x), 0))
                    
                }

            }

        }

    }
    
    func processUserTapsForUpdate(currentTime: CFTimeInterval) {
        
        // Loop over tapQueue.
        for tapCount in self.tapQueue {
            
            if tapCount == 1 {
                // If the queue entry is a single-tap, handle it.
                self.fireShipBullets()
            }
            
            // Remove the tap from the queue.
            self.tapQueue.removeAtIndex(0)
            
        }
        
    }
    
    func fireInvaderBulletsForUpdate(currentTime: CFTimeInterval) {
        
        let existingBullet = self.childNodeWithName(kInvaderFiredBulletName)
        
        // Only fire a bullet if one’s not already on-screen.
        if existingBullet == nil {
            
            var allInvaders = Array<SKNode>()
            
            // Collect all the invaders currently on-screen.
            self.enumerateChildNodesWithName(kInvaderName) {
                node, stop in
                
                allInvaders.append(node)
            }
            
            if allInvaders.count > 0 {
                
                // Select an invader at random.
                let allInvadersIndex = Int( arc4random_uniform( UInt32( allInvaders.count ) ) )
                
                let invader = allInvaders[allInvadersIndex]
                
                // Create a bullet and fire it from just below the selected invader.
                let bullet = self.makeBulletOfType(.InvaderFired)
                bullet.position = CGPoint(x: invader.position.x, y: invader.position.y - invader.frame.size.height / 2 + bullet.frame.size.height / 2)
                
                // The bullet should travel straight down and move just off the bottom of the screen.
                let bulletDestination = CGPoint(x: invader.position.x, y: -(bullet.frame.size.height / 2))
                
                // Fire off the invader’s bullet.
                self.fireBullet(bullet, toDestination: bulletDestination, withDuration: 2.0, andSoundFileName: "InvaderBullet.wav")
        
            }
        
        }
        
    }
    
    func processContactsForUpdate(currentTime: CFTimeInterval) {
        
        for contact in self.contactQueue {
        
            self.handleContact(contact)
            
            if let index = (self.contactQueue as NSArray).indexOfObject(contact) as Int? {
                self.contactQueue.removeAtIndex(index)
            }
            
        }
        
    }
    
    // Invader Movement Helpers
    func determineInvaderMovementDirection() {
        
        // Here you keep a reference to the current invaderMovementDirection so that you can modify just after below.
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        // Loop over all the invaders in the scene and invoke the block with the invader as an argument
        enumerateChildNodesWithName(kInvaderName) { node, stop in
            switch self.invaderMovementDirection {
            case .Right:
                //   If the invader’s right edge is within 1 point of the right edge of the scene,
                // it’s about to move offscreen. 
                //   Set proposedMovementDirection so that the invaders move down then left.
                //   You compare the invader’s frame (the frame that contains its content in the scene’s coordinate system)
                // with the scene width. 
                //   Since the scene has an anchorPoint of (0, 0) by default,
                // and is scaled to fill its parent view, this comparison ensures you’re testing against the view’s edges.
                if (CGRectGetMaxX(node.frame) >= node.scene!.size.width - 1.0) {
                    proposedMovementDirection = .DownThenLeft
                    stop.memory = true
                }
            case .Left:
                // If the invader’s left edge is within 1 point of the left edge of the scene, it’s about to move offscreen. 
                // Set proposedMovementDirection so that invaders move down then right.
                if (CGRectGetMinX(node.frame) <= 1.0) {
                    proposedMovementDirection = .DownThenRight
                    stop.memory = true
                }
            case .DownThenLeft:
                // If invaders are moving down then left, they’ve already moved down at this point, 
                // so they should now move left. 
                // How this works will become more obvious when you integrate determineInvaderMovementDirection with moveInvadersForUpdate().
                proposedMovementDirection = .Left
                stop.memory = true
            case .DownThenRight:
                // If the invaders are moving down then right, they’ve already moved down at this point, so they should now move right.
                proposedMovementDirection = .Right
                stop.memory = true
            default:
                break
            }
        }
        
        // If the proposed invader movement direction is different than the current invader movement direction, 
        // update the current direction to the proposed direction.
        if (proposedMovementDirection != invaderMovementDirection) {
            invaderMovementDirection = proposedMovementDirection
        }
        
    }
    
    // Bullet Helpers
    func fireBullet(bullet: SKNode, toDestination destination:CGPoint, withDuration duration:CFTimeInterval, andSoundFileName soundName: String) {
        
        // Create an SKAction that moves the bullet to the desired destination and then removes it from the scene.
        let bulletAction = SKAction.sequence([SKAction.moveTo(destination, duration: duration), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        
        // Play the desired sound to signal that the bullet was fired.
        let soundAction = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        // Move the bullet and play the sound at the same time by putting them in the same group. A group runs its actions in parallel, not sequentially.
        bullet.runAction(SKAction.group([bulletAction, soundAction]))
        
        // Fire the bullet by adding it to the scene.
        self.addChild(bullet)
    }
    
    func fireShipBullets() {
        
        let existingBullet = self.childNodeWithName(kShipFiredBulletName)
        
        // Only fire a bullet if there isn’t one currently on-screen.
        if existingBullet == nil {
            
            if let ship = self.childNodeWithName(kShipName) {
                
                if let bullet = self.makeBulletOfType(.ShipFired) {
                    
                    // Set the bullet’s position so that it comes out of the top of the ship.
                    bullet.position = CGPoint(x: ship.position.x, y: ship.position.y + ship.frame.size.height - bullet.frame.size.height / 2)
                    
                    // Set the bullet’s destination to be just off the top of the screen.
                    let bulletDestination = CGPoint(x: ship.position.x, y: self.frame.size.height + bullet.frame.size.height / 2)
                    
                    // Fire the bullet!
                    self.fireBullet(bullet, toDestination: bulletDestination, withDuration: 1.0, andSoundFileName: "ShipBullet.wav")
                    
                }
            }
        }
    }
    
    // User Tap Helpers
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        // Intentional no-op
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent)  {
        // Intentional no-op
    }
    
    override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent) {
        // Intentional no-op
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent)  {
        
        if let touch = touches.first as? UITouch {
            
            if (touch.tapCount == 1) {
                
                self.tapQueue.append(1)
            }
        }
    }
    
    // HUD Helpers
    func adjustScoreBy(points: Int) {
        
        self.score += points
        
        let score = self.childNodeWithName(kScoreHudName) as! SKLabelNode
        
        score.text = String(format: "Score: %04u", self.score)
    }
    
    func adjustShipHealthBy(healthAdjustment: Float) {
        
        // ensures that the ship’s health doesn’t go negative.
        self.shipHealth = max(self.shipHealth + healthAdjustment, 0)
        
        let health = self.childNodeWithName(kHealthHudName) as! SKLabelNode
        
        health.text = String(format: "Health: %.1f%%", self.shipHealth * 100)
        
    }
    
    // Physics Contact Helpers
    func didBeginContact(contact: SKPhysicsContact!) {
        if contact as SKPhysicsContact? != nil {
            self.contactQueue.append(contact)
        }
    }
    
    func handleContact(contact: SKPhysicsContact) {
        
        // Don't allow the same contact twice.
        // Ensure you haven't already handled this contact and removed its nodes
        if (contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil) {
            return
        }
        
        var nodeNames = [contact.bodyA.node!.name!, contact.bodyB.node!.name!]
        
        // containsObject is not yet implemented in Swift's Array and 
        // you should cast the Array to NSArray like so (instanceOfSwiftArray as NSArray)
        // in order to get access to NSArray's methods.
        if (nodeNames as NSArray).containsObject(kShipName) && (nodeNames as NSArray).containsObject(kInvaderFiredBulletName) {
            
            // If an invader bullet hits your ship, remove your ship and the bullet from the scene and play a sound.
            // Invader bullet hit a ship
            self.runAction(SKAction.playSoundFileNamed("ShipHit.wav", waitForCompletion: false))
            
            // Adjust the ship’s health when it gets hit by an invader’s bullet.
            self.adjustShipHealthBy(-0.334)
            
            if self.shipHealth <= 0.0 {
                
                // If the ship’s health is zero, remove the ship and the invader’s bullet from the scene.
                contact.bodyA.node!.removeFromParent()
                contact.bodyB.node!.removeFromParent()
                
            } else {
                
                // If the ship’s health is greater than zero, 
                // only remove the invader’s bullet from the scene. 
                // Dim the ship’s sprite slightly to indicate damage.
                let ship = self.childNodeWithName(kShipName)!
                
                ship.alpha = CGFloat(self.shipHealth)
                
                if contact.bodyA.node == ship {
                    
                    contact.bodyB.node!.removeFromParent()
                    
                } else {
                    
                    contact.bodyA.node!.removeFromParent()
                }
                
            }
            
        } else if ((nodeNames as NSArray).containsObject(kInvaderName) && (nodeNames as NSArray).containsObject(kShipFiredBulletName)) {
            
            // If a ship bullet hits an invader, 
            // remove the invader and the bullet from the scene and play a different sound.
            // Ship bullet hit an invader
            self.runAction(SKAction.playSoundFileNamed("InvaderHit.wav", waitForCompletion: false))
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
            
            // When an invader is hit, add 100 points to the score.
            self.adjustScoreBy(100)
            
        }
    }
    
    // Game End Helpers
    
}
