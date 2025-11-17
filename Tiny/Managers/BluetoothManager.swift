//
//  BluetoothManager.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 12/11/25.
//

import SwiftUI
import AVFoundation
internal import Combine

class BluetoothManager: NSObject, ObservableObject {
    @Published var isConnected: Bool = false
    @Published var connectedDeviceName: String?
    @Published var isLiveListenActive: Bool = false
    @Published var connectionType: ConnectionType = .none

    enum ConnectionType {
        case none
        case wired
        case bluetooth
        case airPods
        case tws

        var displayName: String {
            switch self {
            case .none:
                return "No Device"
            case .wired:
                return "Wired"
            case .bluetooth:
                return "Bluetooth"
            case .airPods:
                return "AirPods"
            case .tws:
                return "TWS"
            }
        }
    }

    private var audioSessionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?

    override init() {
        super.init()
        setupAudioSessionObservers()
        checkCurrentAudioRoute()
    }

    deinit {
        removeObservers()
    }

    private func setupAudioSessionObservers() {
        let notificationCenter = NotificationCenter.default

        // Observe audio session route changes
        routeChangeObserver = notificationCenter.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }

        // Observe audio session interruptions
        audioSessionObserver = notificationCenter.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    private func removeObservers() {
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = audioSessionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        DispatchQueue.main.async {
            switch reason {
            case .newDeviceAvailable:
                self.checkCurrentAudioRoute()
            case .oldDeviceUnavailable:
                self.checkCurrentAudioRoute()
            case .categoryChange, .override, .wakeFromSleep, .noSuitableRouteForCategory, .routeConfigurationChange:
                self.checkCurrentAudioRoute()
            case .unknown:
                self.checkCurrentAudioRoute()
            @unknown default:
                break
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        DispatchQueue.main.async {
            self.checkCurrentAudioRoute()
        }
    }

    private func checkCurrentAudioRoute() {
        let session = AVAudioSession.sharedInstance()
        let currentRoute = session.currentRoute

        // Check for output routes
        let outputPorts = currentRoute.outputs
        let inputPorts = currentRoute.inputs

        // Determine connection type and device name
        determineConnectionType(outputPorts: outputPorts, inputPorts: inputPorts)

        // Check if Live Listen is active
        checkLiveListenStatus(session: session)
    }

    private func determineConnectionType(outputPorts: [AVAudioSessionPortDescription], inputPorts: [AVAudioSessionPortDescription]) {
        // Check for AirPods first (most specific)
        for port in outputPorts where isAirPods(port: port) {
            connectionType = .airPods
            connectedDeviceName = port.portName
            isConnected = true
            return
        }

        // Check for TWS devices
        for port in outputPorts where isTWSDevice(port: port) {
            connectionType = .tws
            connectedDeviceName = port.portName
            isConnected = true
            return
        }

        // Check for other Bluetooth devices
        for port in outputPorts {
            if port.portType == .bluetoothA2DP || port.portType == .bluetoothHFP {
                connectionType = .bluetooth
                connectedDeviceName = port.portName
                isConnected = true
                return
            }
        }

        // Check for wired devices
        for port in outputPorts {
            if port.portType == .headphones || port.portType == .headsetMic {
                connectionType = .wired
                connectedDeviceName = port.portName
                isConnected = true
                return
            }
        }

        // No device connected
        connectionType = .none
        connectedDeviceName = nil
        isConnected = false
    }

    private func isAirPods(port: AVAudioSessionPortDescription) -> Bool {
        let portName = port.portName.lowercased()
        return portName.contains("airpods") ||
        portName.contains("airpods pro") ||
        portName.contains("airpods max") ||
        port.portType == .bluetoothHFP && portName.contains("airpods")
    }

    private func isTWSDevice(port: AVAudioSessionPortDescription) -> Bool {
        let portName = port.portName.lowercased()

        // Common TWS indicators
        let twsIndicators = [
            "left", "right", "l", "r", "tws", "earbuds", "buds",
            "galaxy buds", "pixel buds", "echo buds", "wf-1000",
            "freebuds", "jabra", "soundcore", "anker"
        ]

        return twsIndicators.contains { portName.contains($0) } &&
        (port.portType == .bluetoothA2DP || port.portType == .bluetoothHFP)
    }

    private func checkLiveListenStatus(session: AVAudioSession) {
        let category = session.category
        let mode = session.mode

        let isPlayAndRecord = category == .playAndRecord
        let isMeasurementMode = mode == .measurement
        let hasBluetoothInput = session.currentRoute.inputs.contains { input in
            input.portType == .bluetoothHFP || input.portType == .bluetoothLE
        }

        isLiveListenActive = isPlayAndRecord && (isMeasurementMode || hasBluetoothInput)
    }

    // MARK: - Computed Properties for UI

    var connectionStatus: String {
        if isLiveListenActive {
            return "Live Listen Active"
        } else if isConnected {
            return connectionType.displayName
        } else {
            return "No Device Connected"
        }
    }

    var connectionIcon: String {
        if isLiveListenActive {
            return "wave.3.left.circle.fill"
        } else if isConnected {
            switch connectionType {
            case .airPods:
                return "airpods"
            case .tws, .bluetooth:
                return "airpods.right"
            case .wired:
                return "headphones"
            case .none:
                return "airpods"
            }
        } else {
            return "airpods.slash"
        }
    }

    var connectionColor: Color {
        if isLiveListenActive {
            return .green
        } else if isConnected {
            return .blue
        } else {
            return .gray
        }
    }

    // MARK: - Public Methods

    func refreshConnectionStatus() {
        checkCurrentAudioRoute()
    }

    func requestBluetoothPermission() {
        // iOS doesn't require explicit Bluetooth permission for audio devices
        // But we can ensure audio session is properly configured
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.allowBluetoothHFP, .allowBluetoothA2DP, .allowAirPlay]
            )
            try session.setActive(true)
            checkCurrentAudioRoute()
        } catch {
            print("Error configuring audio session for Bluetooth: \(error.localizedDescription)")
        }
    }
}

// MARK: - Color Extension

extension Color {
    static let connectionGreen = Color.green
    static let connectionBlue = Color.blue
    static let connectionGray = Color.gray
}
