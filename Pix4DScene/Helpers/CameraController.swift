//
//  CameraController.swift
//  Pix4DScene
//
//  Created by Romain Sickenberg on 2.07.21.
//

import SwiftUI
import Combine
import AVFoundation

enum CameraControllerError: Swift.Error {
    case captureSessionAlreadyRunning
    case captureSessionIsMissing
    case inputsAreInvalid
    case invalidOperation
    case noCamerasAvailable
    case unknown
}

class CameraController: NSObject, AVCaptureMetadataOutputObjectsDelegate, ObservableObject {
    @Published var captureSession: AVCaptureSession?
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    var backCamera: AVCaptureDevice?
    var backCameraInput: AVCaptureDeviceInput?

    func prepare(completion: @escaping(Error?) -> Void) {
        func createCaptureSession() {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { flag in
                if !flag {
                    abort()
                }
            })

            self.captureSession = AVCaptureSession()
        }

        func configureCaptureDevice() throws {
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

            self.backCamera = camera
            try camera?.lockForConfiguration()
            camera?.unlockForConfiguration()
        }

        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }

            if let backCamera = self.backCamera {
                self.backCameraInput = try AVCaptureDeviceInput(device: backCamera)

                if captureSession.canAddInput(self.backCameraInput!) {
                    captureSession.addInput(self.backCameraInput!)
                } else {
                    throw CameraControllerError.inputsAreInvalid
                }

                let metadataOutput = AVCaptureMetadataOutput()

                if (captureSession.canAddOutput(metadataOutput)) {
                    captureSession.addOutput(metadataOutput)

                    metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    metadataOutput.metadataObjectTypes = [.qr]
                }
            } else {
                throw CameraControllerError.noCamerasAvailable
            }

            captureSession.startRunning()
        }

        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevice()
                try configureDeviceInputs()
            } catch let error {
                DispatchQueue.main.async {
                    completion(error)
                }

                return
            }

            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }

    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }

        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = .resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait

        self.previewLayer!.frame = view.layer.bounds
        self.previewLayer!.position = CGPoint(x: view.layer.bounds.midX, y: view.layer.bounds.midY)
        view.layer.insertSublayer(self.previewLayer!, at: 0)
    }
}
