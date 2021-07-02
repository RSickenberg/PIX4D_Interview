//
//  ContentView.swift
//  Pix4DScene
//
//  Created by Romain Sickenberg on 2.07.21.
//

import SwiftUI
import UIKit
import RealityKit
import AVFoundation

struct ContentView : View {
    var body: some View {
        CameraViewController()
            .edgesIgnoringSafeArea(.top)
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
