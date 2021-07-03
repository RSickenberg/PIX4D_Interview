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

class ARViewController: UIViewController {
    var arView: ARView?
    let isDebug = true
    var isRecording = false {
        didSet {
            try? self.recordingHasChanged()
        }
    }

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

        configureARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        self.arView!.session.pause()
    }

    private func configureARSession() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.vertical, .horizontal]
        config.sceneReconstruction = .mesh // Classification of structural scene isn't needed for this exercise

        if isRecording {
            self.arView!.session.run(config, options: .resetTracking)
        }
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
    }

    private func recordingHasChanged() throws {
        guard let view = self.arView else {
            throw ARViewError.arViewNotSet
        }
        try configureARScene()

        if isRecording {
            configureARSession()
        } else {
            self.arView!.session.pause()
        }

        print(view.session)
    }
}

extension ARViewController: ARSessionDelegate {
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        session.getCurrentWorldMap(completionHandler: { map, error in
            print(map)
        })
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

struct ARViewContainer: UIViewControllerRepresentable {
    typealias UIViewControllerType = ARViewController

    @Binding var isRecording: Bool

    func makeUIViewController(context: UIViewControllerRepresentableContext<ARViewContainer>) -> ARViewController {
        let controller = ARViewController()
        controller.isRecording = isRecording
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: UIViewControllerRepresentableContext<ARViewContainer>) {
        uiViewController.isRecording = isRecording
    }
}
