//
//  LoadingAnimationView.swift
//  Faithbase
//
//  Created by Paniti Marta on 2024. 10. 27..
//

import SwiftUI

struct LoadingAnimationView: View {
    @State private var animateFirstDot = false
    @State private var animateSecondDot = false
    @State private var animateThirdDot = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .frame(width: 10, height: 10)
                .scaleEffect(animateFirstDot ? 1.0 : 0.5)
                .animation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(0.1),
                    value: animateFirstDot
                )
            Circle()
                .frame(width: 10, height: 10)
                .scaleEffect(animateSecondDot ? 1.0 : 0.5)
                .animation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(0.2),
                    value: animateSecondDot
                )
            Circle()
                .frame(width: 10, height: 10)
                .scaleEffect(animateThirdDot ? 1.0 : 0.5)
                .animation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(0.3),
                    value: animateThirdDot
                )
        }
        .foregroundColor(Color.accentColor)
        .onAppear {
            animateFirstDot.toggle()
            animateSecondDot.toggle()
            animateThirdDot.toggle()
        }
    }
}

#Preview {
    LoadingAnimationView()
}
