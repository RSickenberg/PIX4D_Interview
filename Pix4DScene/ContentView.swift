//
//  ContentView.swift
//  Pix4DScene
//
//  Created by Romain Sickenberg on 2.07.21.
//

import SwiftUI

struct ContentView: View {
    @State var isRecording = false
    @State var haveOverlayVisible = false

    var body: some View {
        ZStack {
            ARViewContainer(overlayIsActive: $haveOverlayVisible, isRecording: $isRecording)
                .ignoresSafeArea()
                .foregroundColor(.none)
            VStack {
                Spacer()
                    .frame(height: UIScreen.main.bounds.size.height / 1.3)
                ControlPannel(isRecording: $isRecording, shouldBeVisible: $haveOverlayVisible)
            }
        }
    }
}

struct ControlPannel: View {
    @State private var angle = 0.0
    @State private var distance = 0.0

    @State private var angleThresold = 49
    @State private var distanceThresold = 10

    @Binding var isRecording: Bool
    @Binding var shouldBeVisible: Bool

    private func toggleButton() -> Void {
        self.isRecording = !self.isRecording
    }

    var body: some View {
        ZStack {
            VStack {
                HStack() {
                    VStack {
                        Text("Angle: \(Int(angle))°")
                            .foregroundColor(Int(angle) >= angleThresold ? .red : .black)
                        Slider(value: $angle, in: 0...360)
                    }
                    .padding(.leading, 10)

                    Button(action: toggleButton, label: {
                        Label(isRecording ? "Stop" : "Play", systemImage: isRecording ? "stop" : "play")
                    })
                    .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.size.width / 2, alignment: .center)
                    .padding(.vertical, 40)
                    .background(Blur())
                    .clipShape(Circle())

                    VStack(alignment: .center, spacing: 12) {
                        Text("Distance: \(Int(distance)) m")
                            .foregroundColor(Int(distance) >= distanceThresold ? .red : .black)
                        Slider(value: $distance, in: 0...100)
                    }
                    .padding(.trailing, 10)
                }
                .padding(.vertical, 20.0)
                .background(Blur(style: .systemThinMaterial))
                .cornerRadius(30)
            }
            .padding(.horizontal, 10.0)
            .opacity(shouldBeVisible ? 0.0 : 1.0)
        }
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
