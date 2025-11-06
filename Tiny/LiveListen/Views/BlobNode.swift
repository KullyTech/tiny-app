//
//  SwiftUIView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 06/11/25.
//

import SpriteKit

class BlobNode: SKNode {
    private var shapeNode: SKShapeNode!
    private var baseRadius: CGFloat
    private var currentSkewX: CGFloat = 0
    private var currentSkewY: CGFloat = 0
    private var currentScaleX: CGFloat = 1.0
    private var currentScaleY: CGFloat = 1.0
    private var velocityX: CGFloat = 0
    private var velocityY: CGFloat = 0
    
    private let springStiffness: CGFloat = 0.15
    private let damping: CGFloat = 0.85
    private var idleTime: TimeInterval = 0
    
    init(screenWidth: CGFloat) {
        self.baseRadius = screenWidth * 0.75
        super.init()
        setupBlob()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented!")
    }
    
    private func setupBlob() {
        let path = createBlobPath()
        shapeNode = SKShapeNode(path: path)
        shapeNode.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
        shapeNode.strokeColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
        shapeNode.lineWidth = 3
//        shapeNode.glowWidth = 10
        
        addChild(shapeNode)
    }
    
    private func createBlobPath() -> CGPath {
        let path = UIBezierPath(
            arcCenter: .zero, radius: baseRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true
        
        )
        return path.cgPath
    }
    
    func updateIdleState(deltaTime: TimeInterval) {
        idleTime += deltaTime
        
        // Create a smooth, periodic "breathing" effect using a sine wave
        let breathScale = 1.0 + 0.03 * sin(idleTime * 1.5)
        
        // Gently apply the breathing scale
        currentScaleX += (breathScale - currentScaleX) * 0.05
        currentScaleY += (breathScale - currentScaleY) * 0.05
        
        // Reset skew and rotation towards neutral
        currentSkewX += (0 - currentSkewX) * 0.05
        currentSkewY += (0 - currentSkewY) * 0.05
        shapeNode.zRotation += (0 - shapeNode.zRotation) * 0.05
        
        updateBlobTransform()
    }
    
    func updateWithMotion(deltaTime: TimeInterval, gravityX: Double, gravityY: Double, rotationZ: Double, accelerationX: Double, accelerationY: Double) {
        idleTime += deltaTime
        
        // Create a smooth, periodic "breathing" effect using a sine wave
        let breathScale = 1.0 + 0.03 * sin(idleTime * 1.5)
        
        let targetSkewX = CGFloat(gravityX * 0.5)
        let targetSkewY = CGFloat(-gravityY * 0.3)
        
        let accelerationMagnitude = sqrt(accelerationX * accelerationX + accelerationY * accelerationY)
        let squishFactor = min(accelerationMagnitude * 0.3, 0.3)
        
        let targetScaleX = breathScale + CGFloat(accelerationX * 0.2) - CGFloat(squishFactor)
        let targetScaleY = breathScale - CGFloat(accelerationY * 0.2) + CGFloat(squishFactor)
        
        let skewDiffX = targetSkewX - currentSkewX
        let skewDiffY = targetSkewY - currentSkewY
        
        velocityX += skewDiffX * springStiffness
        velocityY += skewDiffY * springStiffness
        
        velocityX *= damping
        velocityY *= damping
        
        currentSkewX += velocityX
        currentSkewY += velocityY
        
        currentScaleX += (targetScaleX - currentScaleX) * 0.1
        currentScaleY += (targetScaleY - currentScaleY) * 0.1
        
        currentSkewX = max(-0.5, min(0.5, currentSkewX))
        currentSkewY = max(-0.3, min(0.3, currentSkewY))
        currentScaleX = max(0.7, min(1.3, currentScaleX))
        currentScaleY = max(0.7, min(1.3, currentScaleY))
        
        updateBlobTransform()
        
        let rotationDamping = 0.3
        let targetRotation = CGFloat(rotationZ * rotationDamping)
        let currentRotation = shapeNode.zRotation
        shapeNode.zRotation = currentRotation + (targetRotation - currentRotation) * 0.1
    }
    
    private func updateBlobTransform() {
        var transform = CGAffineTransform.identity
        
        transform = transform.scaledBy(x: currentScaleX, y: currentScaleY)
        
        var skewTransform = CGAffineTransform.identity
        skewTransform.c = currentSkewX
        skewTransform.b = currentSkewY
        
        transform = transform.concatenating(skewTransform)
        
        shapeNode.setScale(1.0)
        shapeNode.xScale = transform.a
        shapeNode.yScale = transform.d
        
        let skewOffsetX = currentSkewX * baseRadius * 0.5
        let skewOffsetY = currentSkewY * baseRadius * 0.5
        
        shapeNode.position = CGPoint(x: skewOffsetX, y: skewOffsetY)
        
    }
    
}

// #Preview {
//    BlobNode()
// }
