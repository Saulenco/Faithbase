//
//  AudioView.swift
//  Faithbase
//
//  Created by Paniti Marta on 2024. 10. 26..
//

import SwiftUI

struct WaveformView: View {
    @State private var phase: CGFloat = 0
    @State private var amplitude: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            WaveShape(phase: self.phase, amplitude: self.amplitude, frequency: 2.5)
                .stroke(lineWidth: 2)
                .foregroundColor(Color.accentColor)
                .onAppear {
                    // Animate phase for continuous wave movement
                    withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        self.phase = -geometry.size.width
                    }
                    
                    // Randomly adjust amplitude every 0.2 seconds for wave variation
                    Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.amplitude = CGFloat.random(in: 0.5...1.5)
                        }
                    }
                }
        }
        .frame(height: 40)
    }
}

struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midHeight = rect.height / 2
        let width = rect.width

        for x in stride(from: 0, to: width, by: 2) {
            let relativeX = x / width
            let sine = sin(2 * .pi * frequency * relativeX + phase)
            let y = midHeight + amplitude * sine
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

#Preview {
    WaveformView()
}
