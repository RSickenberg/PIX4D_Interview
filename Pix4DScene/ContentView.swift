//
//  ContentView.swift
//  Pix4DScene
//
//  Created by Romain Sickenberg on 2.07.21.
//

import SwiftUI

struct ContentView: View {
    @State var isRecording = false

    var body: some View {
        ZStack {
            VStack {
                CameraViewController()
                    .background(Color.white)
                    .ignoresSafeArea()

                ControlPannel(isRecording: $isRecording)
            }
        }
    }
}

struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct ControlPannel: View {
    @State private var angle = 0.0
    @State private var distance = 0.0

    @Binding var isRecording: Bool

    private func toggleButton() -> Void {
        self.isRecording = !self.isRecording
    }

    var body: some View {
        ZStack {
            VStack {
                HStack() {
                    VStack {
                        Text("Angle: \(Int(angle))°")
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
                        Slider(value: $distance, in: 0...100)
                    }
                    .padding(.trailing, 10)
                }
                .padding(.vertical, 20.0)
                .background(Blur(style: .systemThinMaterial))
                .cornerRadius(30)
            }
            .padding(.horizontal, 10.0)
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
