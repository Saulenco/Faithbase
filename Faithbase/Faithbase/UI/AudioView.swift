//
//  AudioView.swift
//  Faithbase
//
//  Created by Paniti Marta on 2024. 10. 26..
//

import SwiftUI

struct WaveformView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    WaveShape(phase: self.phase, amplitude: CGFloat(10 + i * 5), frequency: 2.5)
                        .stroke(lineWidth: 2)
                        .foregroundColor(Color.blue.opacity(Double(5 - i) * 0.2))
                }
            }
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    self.phase -= geometry.size.width / 2
                }
            }
        }
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
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}

#Preview {
    WaveformView()
}
