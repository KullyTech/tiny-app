//
//  LiveListenView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 06/11/25.
//

import SwiftUI
import SpriteKit
import CoreMotion

class LiveListenView: SKScene {
    private var blobNode: BlobNode!
    private let motionManager = CMMotionManager()
    private var lastUpdateTime: TimeInterval = 0
    private var isIdle = true
    
    private var gravity = (x: 0.0, y: 0.0)
    private var rotation = 0.0
    private var acceleration = (x: 0.0, y: 0.0)
    
    private var lastBeatTime: TimeInterval = 0
    private let beatCooldown: TimeInterval = 0.2
    private let heartbeatThreshold: Float = 0.15
    var currentAmplitude: Float = 0.0
    
    private var smoothedAmplitude: Float = 0.0
    private let amplitudeSmoothingFactor: Float = 0.3
    
    private var isHeartbeatEnabled = true
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        backgroundColor = .black
        setupGradientBackground()
        
        blobNode = BlobNode(screenWidth: size.width * 1.4)
        blobNode.position = CGPoint(x: size.width / 2, y: -size.height * 0.15)
        addChild(blobNode)
        startMotionUpdates()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        if isHeartbeatEnabled {
            smoothedAmplitude += (currentAmplitude - smoothedAmplitude) * amplitudeSmoothingFactor
            
            if smoothedAmplitude > heartbeatThreshold && 
               (currentTime - lastBeatTime) > beatCooldown {
                triggerHeartbeat()
                lastBeatTime = currentTime
            }
        } else {
            smoothedAmplitude *= 0.9
        }
        
        if isIdle {
            blobNode.updateIdleState(deltaTime: deltaTime)
        } else {
            blobNode.updateWithMotion(
                deltaTime: deltaTime,
                gravityX: gravity.x,
                gravityY: gravity.y,
                rotationZ: rotation,
                accelerationX: acceleration.x,
                accelerationY: acceleration.y
            )
        }
    }
    
    func resetHeartbeat() {
        isHeartbeatEnabled = false
        currentAmplitude = 0.0
        smoothedAmplitude = 0.0
        
        blobNode.removeAction(forKey: "heartbeat")
        
        blobNode.resetToIdleState()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isHeartbeatEnabled = true
        }
    }
    
    private func triggerHeartbeat() {
        blobNode.removeAction(forKey: "heartbeat")
        
        let scaleUp = SKAction.scale(to: 1.12, duration: 0.08)
        scaleUp.timingMode = .easeOut
        
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.12)
        scaleDown.timingMode = .easeIn
        
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        blobNode.run(sequence, withKey: "heartbeat")
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        
        let topColor = UIColor.black.cgColor
        let bottomColor = UIColor(Color(hex: "8647B9")).cgColor
        
        gradientLayer.colors = [bottomColor, topColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.85)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.2)
    
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let gradientImage = image else { return }
        
        let texture = SKTexture(image: gradientImage)
        let backgroundNode = SKSpriteNode(texture: texture)
        
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = -1
        addChild(backgroundNode)
    }
    
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available!")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 120.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, let self = self else { return }
            
            self.gravity = (motion.gravity.x, motion.gravity.y)
            self.rotation = motion.rotationRate.z
            self.acceleration = (motion.userAcceleration.x, motion.userAcceleration.y)
            
            let motionThreshold = 0.02
            let isMoving = abs(self.gravity.x) > motionThreshold ||
                           abs(self.gravity.y) > motionThreshold ||
                           abs(self.acceleration.x) > motionThreshold ||
                           abs(self.acceleration.y) > motionThreshold ||
                           abs(self.rotation) > motionThreshold
            
            self.isIdle = !isMoving
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}
