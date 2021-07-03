//
//  ARViewContainer.swift
//  Pix4DScene
//
//  Created by Romain Sickenberg on 3.07.21.
//

import SwiftUI
import UIKit
import RealityKit
import SceneKit
import CoreGraphics
import ARKit

enum ARViewError: Error {
    case arViewNotSet
}

protocol ARViewControllerDelegate: AnyObject {
    func overlayIsActive(_ vc: ARViewController, state: Bool)
}

class ARViewController: UIViewController {
    var arView: ARView?
    var coachingView: ARCoachingOverlayView?
    let isDebug = true
    var isRecording = false {
        didSet {
            try? self.recordingHasChanged()
        }
    }
    var arCamera: ARCamera? {
        didSet {
            DispatchQueue(label: "com.pix4d.arcamera").async { [weak self] in
                self?.cameraCoordinates(coordinates: self?.arCamera?.transform)
            }
        }
    }
    var overlayIsActive = false {
        didSet {
            debugPrint("Overlay state is \(overlayIsActive)")
            self.delegate?.overlayIsActive(self, state: overlayIsActive)
        }
    }
    weak var delegate: ARViewControllerDelegate?

    override func viewDidLoad() {
        self.arView = ARView(frame: .zero)
        self.arView!.contentMode = .scaleToFill
        self.arView!.frame = view.bounds

        self.arView!.session.delegate = self
        self.arView?.automaticallyConfigureSession = false

        view.insertSubview(arView!, at: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let coachingView = ARCoachingOverlayView(frame: .zero)
        coachingView.frame = arView!.bounds
        coachingView.delegate = self
        coachingView.goal = .tracking
        coachingView.session = arView!.session

        self.arView!.addSubview(coachingView)
        self.coachingView = coachingView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        configureARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        self.arView!.session.pause()
    }

    private func configureARSession() {
        let config = ARWorldTrackingConfiguration() // Maybe use ARPositionalTrackingConfiguration?
        config.planeDetection = [.vertical, .horizontal]
        config.sceneReconstruction = .mesh // Classification of structural scene isn't needed for this exercise
        // config.initialWorldMap = self.precedentWorldMap

        self.arView!.session.run(config, options: .resetTracking)
        self.coachingView?.setActive(true, animated: true)
    }

    private func configureARScene() throws {
        guard let view = self.arView else {
            throw ARViewError.arViewNotSet
        }

        if isDebug {
            view.debugOptions.insert(.showFeaturePoints)
            view.debugOptions.insert(.showPhysics)
            view.debugOptions.insert(.showWorldOrigin)
            view.debugOptions.insert(.showSceneUnderstanding)
        } else {
            view.debugOptions.remove(.showFeaturePoints)
            view.debugOptions.remove(.showPhysics)
            view.debugOptions.remove(.showWorldOrigin)
            view.debugOptions.remove(.showSceneUnderstanding)
        }

        view.environment.background = .cameraFeed()
        view.environment.reverb = .automatic
        view.environment.sceneUnderstanding.options.insert(.receivesLighting)
        view.environment.sceneUnderstanding.options.insert(.occlusion)
    }

    private func recordingHasChanged() throws {
        guard let view = self.arView else {
            throw ARViewError.arViewNotSet
        }
        try configureARScene()

        if isRecording {
            configureARSession()
        } else {
            view.session.pause()
        }
    }

    private func cameraCoordinates(coordinates: simd_float4x4?) {

    }
}

extension ARViewController: ARSessionDelegate {
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue(label: "com.pix4d.scene.worldmap").async { [weak self] in
            self?.arCamera = frame.camera
        }
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            debugPrint("not available")
        case .limited:
            debugPrint("limited")
        case .normal:
            debugPrint("normal")

        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }
}

extension ARViewController: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        self.configureARSession()
    }

    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        self.overlayIsActive = true
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        self.overlayIsActive = false
    }
}

struct ARViewContainer: UIViewControllerRepresentable {
    typealias UIViewControllerType = ARViewController
    @Binding var overlayIsActive: Bool
    @Binding var isRecording: Bool

    class Coordinator: ARViewControllerDelegate {
        var overlayState: Binding<Bool>

        init(overlayState: Binding<Bool>) {
            self.overlayState = overlayState
        }

        func overlayIsActive(_ vc: ARViewController, state: Bool) {
            overlayState.wrappedValue = state
        }
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ARViewContainer>) -> ARViewController {
        let controller = ARViewController()
        controller.isRecording = isRecording
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: UIViewControllerRepresentableContext<ARViewContainer>) {
        uiViewController.isRecording = isRecording
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(overlayState: $overlayIsActive)
    }
}
