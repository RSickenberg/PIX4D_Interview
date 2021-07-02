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
}

extension CameraViewController: UIViewControllerRepresentable {
    typealias UIViewControllerType = CameraViewController

    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
