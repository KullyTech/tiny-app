import SwiftUI

enum CoachMarkAnimationType {
    case doubleTap
    case singleTap
    case hold
    case holdAndDrag
}

struct CoachMarkView: View {
    @State private var iconState = 0  // 0 = idle, 1 = tap1, 2 = tap2, 3 = holding, 4 = dragging
    @State private var dragOffset: CGSize = .zero
    
    // Customization properties
    let animationType: CoachMarkAnimationType
    let showText: Bool
    let customText: String?
    
    // Size customization properties
    let iconSize: CGFloat
    let textSize: Font
    let spacing: CGFloat
    let dragLineWidth: CGFloat
    let dragLineXOffset: CGFloat
    
    // Initializer with default values
    init(
        animationType: CoachMarkAnimationType = .doubleTap,
        showText: Bool = true,
        customText: String? = nil,
        iconSize: CGFloat = 90,
        textSize: Font = .headline,
        spacing: CGFloat = 10,
        dragLineWidth: CGFloat? = nil,
        dragLineXOffset: CGFloat? = nil
    ) {
        self.animationType = animationType
        self.showText = showText
        self.customText = customText
        self.iconSize = iconSize
        self.textSize = textSize
        self.spacing = spacing
        // Set default line properties based on iconSize if not provided
        self.dragLineWidth = dragLineWidth ?? (iconSize / 9)
        self.dragLineXOffset = dragLineXOffset ?? (iconSize * 0.44)
    }

    var body: some View {
        VStack(spacing: spacing) {
            // Icon animation area
            ZStack {
                // Base layer to define the frame and contain static icons
                Image(systemName: "hand.point.up.fill")
                    .opacity(iconState == 0 ? 1 : 0)

                Image(systemName: "hand.tap.fill")
                    .opacity((iconState == 1 || iconState == 2) && (animationType == .doubleTap || animationType == .singleTap) ? 1 : 0)
                
                // NOTE: The 'hold' icon for holdAndDrag is now handled in the overlay
                Image(systemName: "hand.tap.fill")
                    .opacity(iconState == 3 && animationType == .hold ? 1 : 0)
            }
            .font(.system(size: iconSize))
            .frame(width: iconSize * 1.5, height: iconSize * 2) // Define a fixed frame to contain the animation
            .overlay(dragAnimationOverlay) // Apply the drag animation in an overlay
            .foregroundColor(.white.opacity(0.8))
            .animation(.easeInOut(duration: 0.15), value: iconState)
            .animation(.easeInOut(duration: 0.3), value: dragOffset)
            
            // Customizable text
            if showText {
                Text(displayText)
                    .font(textSize)
                    .foregroundColor(.white.opacity(0.7))
                    .transition(.opacity)
            }
        }
        .allowsHitTesting(false) // Make the entire view non-interactive
        .task {
            try? await runAnimationLoop()
        }
    }
    
    // The drag animation is now in an overlay, so it won't affect the layout.
    private var dragAnimationOverlay: some View {
        Group {
            if animationType == .holdAndDrag && (iconState == 3 || iconState == 4) {
                ZStack {
                    // --- Dragging State Components (Visible only when iconState is 4) ---

                    // Drag line
                    Path { path in
                        // Y-offset to place the line under the finger
                        let yOffset = iconSize * 0.45

                        // Apply the horizontal offset to the start and end points
                        let startPoint = CGPoint(x: dragLineXOffset, y: yOffset)
                        let endPoint = CGPoint(x: dragOffset.width + dragLineXOffset, y: dragOffset.height + yOffset)

                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    }
                    // Use the new dynamic properties for line style
                    .stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: dragLineWidth, lineCap: .round, lineJoin: .round))
                    .opacity(iconState == 4 ? 1 : 0) // Only visible during drag

                    // Faded hand at the start position
                    if abs(dragOffset.height) > iconSize * 0.3 {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: iconSize))
                            .opacity(iconState == 4 ? 0.2 : 0) // Only visible during drag
                    }

                    // --- Holding and Dragging Hand (Always visible in this overlay) ---
                    // This hand is visible during the hold (3) and moves during the drag (4)
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: iconSize))
                        .offset(dragOffset) // This is (0,0) during hold, and changes during drag
                }
            } else {
                EmptyView()
            }
        }
    }
    
    // Computed property for display text
    private var displayText: String {
        if let customText = customText {
            return customText
        }
        
        switch animationType {
        case .doubleTap:
            return "Tap Twice to Start"
        case .singleTap:
            return "Tap to Play"
        case .hold:
            return "Hold to Stop"
        case .holdAndDrag:
            return "Hold then drag the sphere"
        }
    }
    
    // MARK: - Animation Loop
    func runAnimationLoop() async throws {
        while true {
            switch animationType {
            case .doubleTap:
                try await runDoubleTapAnimation()
            case .singleTap:
                try await runSingleTapAnimation()
            case .hold:
                try await runHoldAnimation()
            case .holdAndDrag:
                try await runHoldAndDragAnimation()
            }
        }
    }
    
    // MARK: - Single Tap Animation
    private func runSingleTapAnimation() async throws {
        iconState = 1
        try await Task.sleep(for: .milliseconds(250))
        iconState = 0
        try await Task.sleep(for: .milliseconds(1000))
    }
    
    // MARK: - Double Tap Animation
    private func runDoubleTapAnimation() async throws {
        iconState = 1
        try await Task.sleep(for: .milliseconds(200))
        iconState = 0
        try await Task.sleep(for: .milliseconds(150))
        iconState = 2
        try await Task.sleep(for: .milliseconds(200))
        iconState = 0
        try await Task.sleep(for: .milliseconds(800))
    }
    
    // MARK: - Hold Animation
    private func runHoldAnimation() async throws {
        iconState = 3
        try await Task.sleep(for: .milliseconds(3000))
        iconState = 0
        try await Task.sleep(for: .milliseconds(1000))
    }
    
    // MARK: - Hold and Drag Animation
    private func runHoldAndDragAnimation() async throws {
        iconState = 3
        dragOffset = .zero
        try await Task.sleep(for: .milliseconds(1000))
        
        iconState = 4
        let dragSteps = 15
        // Make drag distance proportional to the icon size for correct scaling
        let totalDragDistance = iconSize * 0.67
        
        for step in 1...dragSteps {
            let progress = Double(step) / Double(dragSteps)
            let easedProgress = easeInOutQuad(progress)
            // Revert to vertical-only drag
            dragOffset = CGSize(width: 0, height: totalDragDistance * easedProgress)
            try await Task.sleep(for: .milliseconds(40))
        }
        
        try await Task.sleep(for: .milliseconds(300))
        
        iconState = 0
        dragOffset = .zero
        try await Task.sleep(for: .milliseconds(1200))
    }
    
    // Easing function for smooth animation
    private func easeInOutQuad(_ time: Double) -> Double {
        return time < 0.5 ? 2 * time * time : -1 + (4 - 2 * time) * time
    }
}

// MARK: - Convenience Initializers
extension CoachMarkView {
    // Small size preset
    static func small(
        animationType: CoachMarkAnimationType = .doubleTap,
        showText: Bool = true,
        customText: String? = nil
    ) -> CoachMarkView {
        CoachMarkView(
            animationType: animationType,
            showText: showText,
            customText: customText,
            iconSize: 60,
            textSize: .caption,
            spacing: 8
        )
    }
    
    // Medium size preset (default)
    static func medium(
        animationType: CoachMarkAnimationType = .doubleTap,
        showText: Bool = true,
        customText: String? = nil
    ) -> CoachMarkView {
        CoachMarkView(
            animationType: animationType,
            showText: showText,
            customText: customText,
            iconSize: 90,
            textSize: .headline,
            spacing: 10
        )
    }
    
    // Large size preset
    static func large(
        animationType: CoachMarkAnimationType = .doubleTap,
        showText: Bool = true,
        customText: String? = nil
    ) -> CoachMarkView {
        CoachMarkView(
            animationType: animationType,
            showText: showText,
            customText: customText,
            iconSize: 120,
            textSize: .title2,
            spacing: 15
        )
    }
}

#Preview("Single Tap") {
    CoachMarkView.medium(animationType: .singleTap, showText: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}

#Preview("Double Tap") {
    CoachMarkView.medium(animationType: .doubleTap, showText: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}

#Preview("Hold") {
    CoachMarkView.medium(animationType: .hold, showText: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}

#Preview("Hold and Drag") {
    CoachMarkView.medium(animationType: .holdAndDrag, showText: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}

#Preview("Large Hold and Drag") {
    CoachMarkView.large(animationType: .holdAndDrag, showText: true, customText: "Save or Delete")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
