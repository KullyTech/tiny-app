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
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        backgroundColor = .black // Set a base color
        setupGradientBackground()
        
        blobNode = BlobNode(screenWidth: size.width)
        blobNode.position = CGPoint(x: size.width / 2, y: -size.width * 0.15)
        addChild(blobNode)
        startMotionUpdates()
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        
        let topColor = UIColor.black.cgColor
        let bottomColor = UIColor(red: 0.1, green: 0.0, blue: 0.25, alpha: 1.0).cgColor
        
        gradientLayer.colors = [bottomColor, topColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
    
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
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, let self = self else { return }
            let gravity = motion.gravity
            let rotation = motion.rotationRate
            let acceleration = motion.userAcceleration
            
            self.blobNode.updateWithMotion(
                gravityX: gravity.x,
                gravityY: gravity.y,
                rotationZ: rotation.z,
                accelerationX: acceleration.x,
                accelerationY: acceleration.y
            )
        }
    }
    deinit {
            motionManager.stopDeviceMotionUpdates()
        }
}

//#Preview {
//    LiveListenView()
//}
