//
//  AudioMessageView.swift
//  Faithbase
//
//  Created by Paniti Marta on 2024. 10. 26..
//

import SwiftUI
import AVFAudio

struct AudioMessageView: View {
    var audioURL: URL
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        HStack {
            Button(action: playAudio) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 25))
                    .foregroundColor(Color.accentColor)
            }
            Text("Voice message")
                .foregroundColor(.primary)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor, lineWidth: 1)
        )
        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
    }
    
    private func playAudio() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.play()
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
}

#Preview {
    AudioMessageView(audioURL: URL(string: "https://file-examples.com/wp-content/storage/2017/11/file_example_WAV_1MG.wav")!)
}
