import CoreHaptics
import os

class HapticManager {
    private var engine: CHHapticEngine?
    private var beatPattern: CHHapticPattern?
    private var beatPlayer: CHHapticPatternPlayer?
    
    private let logger = Logger(subsystem: "com.example.tiny", category: "HapticManager")

    // Haptic properties
    private var lastHapticTime: Date?
    private let hapticDebounceInterval: TimeInterval = 0.4
    private let amplitudeThresholdLower: Float = 0.08 // Triggers for sounds above this
    private let amplitudeThresholdUpper: Float = 0.2 // Does not trigger for sounds above this (too loud noise)

    var isHapticsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isHapticsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isHapticsEnabled") }
    }

    init() {
        // Initialize default value if not set
        if UserDefaults.standard.object(forKey: "isHapticsEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "isHapticsEnabled")
        }
        prepareHaptics()
    }

    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            logger.info("Haptics not supported on this device.")
            return
        }

        do {
            if engine == nil {
                engine = try CHHapticEngine()
                logger.info("Haptic engine created.")
                
                engine?.stoppedHandler = { [weak self] reason in
                    self?.logger.info("Haptic engine stopped for reason: \(reason.rawValue)")
                    self?.beatPlayer = nil
                }
                
                engine?.resetHandler = { [weak self] in
                    self?.logger.info("Haptic engine reset.")
                    self?.beatPlayer = nil
                    self?.prepareHaptics()
                }
            }
            try engine?.start()
            logger.info("Haptic engine started successfully.")
            
            // Create the reusable pattern
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            beatPattern = try CHHapticPattern(events: [event], parameters: [])

        } catch {
            logger.error("Error setting up haptic engine or pattern: \(error.localizedDescription)")
        }
    }

    func playHapticFromAmplitude(_ amplitude: Float) {
        guard isHapticsEnabled else { return }
        
        let now = Date()
        var shouldTriggerHaptic = false

        if let lastTime = self.lastHapticTime {
            if now.timeIntervalSince(lastTime) >= self.hapticDebounceInterval {
                shouldTriggerHaptic = true
            }
        } else {
            shouldTriggerHaptic = true
        }

        if shouldTriggerHaptic && amplitude > self.amplitudeThresholdLower && amplitude < self.amplitudeThresholdUpper {
            self.playBeatHaptic()
            self.lastHapticTime = now
        }
    }

    private func playBeatHaptic() {
        guard let engine = engine, let pattern = beatPattern else {
            logger.warning("Haptic engine or pattern not available.")
            return
        }

        do {
            if beatPlayer == nil {
                beatPlayer = try engine.makePlayer(with: pattern)
                logger.info("Haptic player created.")
            }
            try beatPlayer?.start(atTime: 0)
        } catch {
            logger.error("Failed to play haptic beat: \(error.localizedDescription)")
        }
    }
    
    func stopHaptics() {
        engine?.stop()
        beatPlayer = nil
        logger.info("Haptic engine stopped.")
    }

    func reset() {
        lastHapticTime = nil
    }
}
