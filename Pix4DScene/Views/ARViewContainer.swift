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
import CoreVideo

enum ARViewError: Error {
    case arViewNotSet
}

protocol ARViewControllerDelegate: AnyObject {
    func overlayIsActive(_ vc: ARViewController, state: Bool)
    func imageCaptured(_ vc: ARViewController, frameCount: Int)
    func coordinatesUpdates(_ vc: ARViewController, angle: Float, distance: Float)
}

class ARViewController: UIViewController {
    let defaultAngle = -15
    let isDebug = true
    var arView: ARSCNView?
    var coachingView: ARCoachingOverlayView?
    var isRecording = false {
        didSet {
            if oldValue != isRecording {
                try? self.recordingHasChanged() // Fix to not have cuts into the session
            }
        }
    }
    var arCamera: ARCamera? {
        didSet {
            DispatchQueue(label: "com.pix4d.arcamera").async { [weak self] in
                guard let self = self else { return }
                self.cameraCoordinates(coordinates: self.arCamera)
                print("--- Current Distance of \(self.useLastNodeArray ? "last node" : "world origin") in cm", self.currentDistanceOfWorldOrigin as Any,
                      "--- Current Angle of world origin in degree:", self.currentAngleOfWorldOrigin as Any)
                print("[DEBUG] The last node name is: \(self.arView?.scene.rootNode.childNodes.last?.name ?? "nil")")

                self.computeAngleAndDistance()
            }
        }
    }
    var overlayIsActive = false {
        didSet {
            debugPrint("Overlay state is \(overlayIsActive)")
            self.delegate?.overlayIsActive(self, state: overlayIsActive)
        }
    }
    var selectedAngle: Int = 0 {
        didSet {
            if oldValue != selectedAngle {
                computeAngleAndDistance()
            }
        }
    }
    var maxAngle: Int = 49
    var maxDistance: Int = 10

    var selectedDistance: Int = 0 {
        didSet {
            if oldValue != selectedDistance {
                computeAngleAndDistance()
            }
        }
    }
    var numberOfFrames: Int = 0 {
        didSet {
            if oldValue != numberOfFrames {
                print("⚠️ TOOK PICTURE")
                self.delegate?.imageCaptured(self, frameCount: numberOfFrames)
            }
        }
    }

    private var useLastNodeArray = false
    private var currentDistanceOfWorldOrigin: Float = 0.0 // !
    private var currentAngleOfWorldOrigin: Float = 0.0 // !
    private var distanceFromLastNode: Float = 0.0

    weak var delegate: ARViewControllerDelegate?

    override func viewDidLoad() {
        self.arView = ARSCNView(frame: .zero)
        self.arView!.contentMode = .scaleToFill
        self.arView!.frame = view.bounds

        self.arView!.session.delegate = self

        view.insertSubview(arView!, at: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let coachingView = ARCoachingOverlayView(frame: .zero)
        coachingView.frame = arView!.bounds
        coachingView.delegate = self
        coachingView.goal = .tracking
        coachingView.session = arView!.session
        coachingView.setActive(true, animated: true)

        self.arView!.addSubview(coachingView)
        self.coachingView = coachingView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        configureARSession()
    }

    private func configureARSession() {
        let config = ARWorldTrackingConfiguration() // Maybe use ARPositionalTrackingConfiguration?
        config.planeDetection = .vertical
        config.sceneReconstruction = .mesh // Classification of structural scene isn't needed for this exercise
        // config.initialWorldMap = self.precedentWorldMap
        self.numberOfFrames = 0

        self.arView!.session.run(config, options: [.resetTracking, .resetSceneReconstruction, .removeExistingAnchors])

        guard let documentRoot = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        guard let arViewSessionIdentifier = self.arView?.session.identifier else { return }
        let directoryName = "session_\(arViewSessionIdentifier)"
        let dataPath = documentRoot.appendingPathComponent(directoryName)
        if !FileManager.default.fileExists(atPath: dataPath.path) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("[ERROR] Cannot create default directory")
            }
        }
    }

    private func configureARScene() throws {
        guard let view = self.arView else {
            throw ARViewError.arViewNotSet
        }

        if isDebug {
            view.debugOptions.insert(.showFeaturePoints)
            view.debugOptions.insert(.showWorldOrigin)
            view.debugOptions.insert(.showCameras)
        } else {
            view.debugOptions.remove(.showFeaturePoints)
            view.debugOptions.remove(.showWorldOrigin)
            view.debugOptions.remove(.showCameras)
        }
    }

    private func recordingHasChanged() throws {
        guard let view = self.arView else {
            throw ARViewError.arViewNotSet
        }
        try configureARScene()

        if isRecording {
            print("--- Starting angle and distance calculation based on selection of [\(selectedAngle)°] and distance of [\(selectedDistance)cm] with a thresold of respective [\(maxAngle)°] and [\(maxDistance)cm]")
            configureARSession()
            computeAngleAndDistance()
        } else {
            view.session.pause()
        }
    }

    private func cameraCoordinates(coordinates: ARCamera?) {
        guard let camera = coordinates else { return }
//        guard let pointOfView = self.arView?.pointOfView?.transform else { return }
        guard let origin = self.arView?.scene.rootNode.simdTransform.columns.3 else { return }
        guard let secondOrign = self.arView?.scene.rootNode.childNodes.last?.simdTransform.columns.3 else { return }
        guard let rotation = coordinates?.eulerAngles.z else { return } // Roll values
        var distance: Float

//        let orientation = SCNVector3(-pointOfView.m31, -pointOfView.m32, pointOfView.m33)
//        let location = SCNVector3(pointOfView.m41, pointOfView.m42, pointOfView.m43)
//        let currentPositionOfCamera = orientation + location

        self.currentAngleOfWorldOrigin = rotation * 10

        if self.useLastNodeArray {
            print("--- Using second origin now, aka last node")
            distance = simd_distance(camera.transform.columns.3, secondOrign) * 10
            self.distanceFromLastNode = distance
        } else {
            distance = simd_distance(camera.transform.columns.3, origin) * 10
            print("[DEBUG] Used world distance instead")
        }

        self.currentDistanceOfWorldOrigin = distance
        self.delegate?.coordinatesUpdates(self, angle: self.currentAngleOfWorldOrigin, distance: distance)
    }

    private func computeAngleAndDistance() {
        guard isRecording else { return }
        switch self.arCamera?.trackingState {
        case .normal:
            break
        default:
            print("Non-normalized tracking state, skipping this frame")
            return
        }

        if self.arView?.session.currentFrame?.worldMappingStatus == .limited || self.arView?.session.currentFrame?.worldMappingStatus == .notAvailable {
            return
        }

        // Si -15 est plus grand ou égal à l'angle selectionné ou si -15 est plus petit ou égal à l'angle sélectioné (neg)
        if (Int(currentDistanceOfWorldOrigin) >= 5) {
            if ((Int(currentAngleOfWorldOrigin) >= selectedAngle || (Int(currentAngleOfWorldOrigin) >= -selectedAngle)) && (Int(currentDistanceOfWorldOrigin) >= selectedDistance)) {
                takeScreenCapture()
            }
        }
    }

    private func takeScreenCapture() {
        guard let buffer = self.arView?.session.currentFrame?.capturedImage else {
            print("Cannot buffer current frame image")
            return
        }
        guard let framePosition = self.arView?.session.currentFrame?.camera.transform else {
            print("Cannot get current frame position")
            return
        }
        let frameTime = self.arView?.session.currentFrame?.timestamp
        var imageIsProcessed = false

        if !imageIsProcessed {
            self.useLastNodeArray = true
            placeCube()
            if let wOrigin = self.arView?.scene.rootNode.simdTransform.columns.3 {
                print("--- Cube Placed at the distance from origin of [\(simd_distance(framePosition.columns.3, wOrigin) * 10)]")
            }
            print("--- Distance from previous cube is [\(distanceFromLastNode)]")

            self.numberOfFrames += 1
        }

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            imageIsProcessed = true
            let ciImage = CIImage(cvImageBuffer: buffer)
            ciImage.settingProperties(["coordinates": framePosition, "time": frameTime as Any])
            let UIkitImage = UIImage(ciImage: ciImage)


            let jpgData = UIkitImage.jpegData(compressionQuality: 0.2)
            imageIsProcessed = false
            self?.saveImage(image: jpgData, fileName: "img_\(frameTime?.description ?? "n/a")")
            return
        }
    }

    private func saveImage(image: Data?, fileName: String) {
        guard let imageData = image else { return }
        guard let documentRoot = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        guard let arViewSessionIdentifier = self.arView?.session.identifier else { return }
        let directoryName = "session_\(arViewSessionIdentifier)"
        let dataPath = documentRoot.appendingPathComponent(directoryName)

        do {
            try imageData.write(to: dataPath.appendingPathExtension("\(fileName).jpg"))
        } catch {
            print("[ERROR] Cannot write image")
        }
    }

    private func placeCube() {
        let box: SCNBox = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
        let node: SCNNode = SCNNode(geometry: box)
        node.name = "cube"
        guard let cameraPosition = self.arView?.session.currentFrame?.camera.transform.columns.3 else { return }

        node.position = SCNVector3(cameraPosition.x, cameraPosition.y, cameraPosition.z - 0.05) // Place the cube slightly in front of us
        arView?.scene.rootNode.addChildNode(node)
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

    @Binding var angle: Double
    @Binding var distance: Double

    @Binding var angleThresold: Int
    @Binding var distanceThresold: Int

    @Binding var currentAngle: Float
    @Binding var currentDistance: Float

    @Binding var frameCounter: Int

    class Coordinator: ARViewControllerDelegate {
        var overlayState: Binding<Bool>

        var currentAngle: Binding<Float>
        var currentDistance: Binding<Float>

        var frameCounter: Binding<Int>

        init(overlayState: Binding<Bool>, currentAngle: Binding<Float>, currentDistance: Binding<Float>, frameCounter: Binding<Int>) {
            self.overlayState = overlayState
            self.currentDistance = currentDistance
            self.currentAngle = currentAngle
            self.frameCounter = frameCounter
        }

        func overlayIsActive(_ vc: ARViewController, state: Bool) {
            overlayState.wrappedValue = state
        }

        func imageCaptured(_ vc: ARViewController, frameCount: Int) {
            frameCounter.wrappedValue = frameCount
        }

        func coordinatesUpdates(_ vc: ARViewController, angle: Float, distance: Float) {
            currentAngle.wrappedValue = angle
            currentDistance.wrappedValue = distance
        }
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ARViewContainer>) -> ARViewController {
        let controller = ARViewController()
        controller.delegate = context.coordinator
        controller.isRecording = isRecording
        controller.maxAngle = angleThresold
        controller.maxDistance = distanceThresold
        controller.selectedAngle = Int(angle)
        controller.selectedDistance = Int(distance)

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: UIViewControllerRepresentableContext<ARViewContainer>) {
        uiViewController.isRecording = isRecording
        uiViewController.maxAngle = angleThresold
        uiViewController.maxDistance = distanceThresold
        uiViewController.selectedAngle = Int(angle)
        uiViewController.selectedDistance = Int(distance)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(overlayState: $overlayIsActive, currentAngle: $currentAngle, currentDistance: $currentDistance, frameCounter: $frameCounter)
    }
}
