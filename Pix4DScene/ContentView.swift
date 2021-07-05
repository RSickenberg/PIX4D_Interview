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

    @State var angle: Double = -15.0
    @State var distance: Double = 0.0

    @State var angleThresold = 10
    @State var distanceThresold = 10

    // Computed values by ARKit and RealityKit
    @State var currentAngle: Float = 0.0
    @State var currentDistance: Float = 0.0

    @State var frameCounter : Int = 0

    var body: some View {
        ZStack {
            ARViewContainer(overlayIsActive: $haveOverlayVisible, isRecording: $isRecording, angle: $angle, distance: $distance, angleThresold: $angleThresold, distanceThresold: $distanceThresold, currentAngle: $currentAngle, currentDistance: $currentDistance, frameCounter: $frameCounter)
                .ignoresSafeArea()
                .foregroundColor(.none)
            VStack {
                HStack {
                    Text("Current Angle: \(Int(currentAngle))°")
                        .foregroundColor(.primary)
                    Text("Current Distance: \(Int(currentDistance))cm")
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .background(Blur(style: .systemUltraThinMaterial))
                .cornerRadius(10)
                .opacity(haveOverlayVisible ? 0.0 : 1.0)

                Spacer()
                    .frame(height: UIScreen.main.bounds.size.height / 1.4)

                HStack {
                    Text("N° of frames: \(frameCounter)")
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .background(Blur(style: .systemUltraThinMaterial))
                .cornerRadius(10)
                .opacity(haveOverlayVisible ? 0.0 : 1.0)

                ControlPannel(angle: $angle, distance: $distance, angleThresold: $angleThresold, distanceThresold: $distanceThresold, isRecording: $isRecording, shouldBeVisible: $haveOverlayVisible)
            }
        }
    }
}

struct ControlPannel: View {
    @Binding var angle: Double
    @Binding var distance: Double

    @Binding var angleThresold: Int
    @Binding var distanceThresold: Int

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
                            .foregroundColor(Int(angle) >= angleThresold || Int(angle) <= -angleThresold ? .red : .black)
                        Slider(value: $angle, in: -30...30)
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
                        Text("Distance: \(Int(distance)) cm")
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
