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
        .background(Color.blue)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
