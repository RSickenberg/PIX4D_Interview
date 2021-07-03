//
//  CameraViewController.swift
//  Pix4DScene
//
//  Created by Romain Sickenberg on 2.07.21.
//

import UIKit
import SwiftUI

final class CameraViewController: UIViewController {
    let cameraController = CameraController()
    var previewView: UIView!
    var isRecording = false {
        willSet {
            print("$IsRecording will move to \(isRecording)")
        }
    }

    override func viewDidLoad() {
        previewView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        previewView.contentMode = UIView.ContentMode.scaleToFill

        view.addSubview(previewView)

        cameraController.prepare(completion: { error in
            if let error = error {
                print(error)
            }

            try? self.cameraController.displayPreview(on: self.previewView)
        })
    }

    func shouldRecord(state: Bool) {
        print("Got action")
    }
}

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CameraViewController

    @Binding var isRecording: Bool
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> CameraViewController {
        let controller = CameraViewController()
        controller.isRecording = self.isRecording
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: UIViewControllerRepresentableContext<CameraView>) {
        uiViewController.isRecording = self.isRecording
    }
}
