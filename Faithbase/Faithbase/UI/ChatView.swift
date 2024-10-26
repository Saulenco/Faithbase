//
//  ChatView.swift
//  Faithbase
//
//  Created by Paniti Marta on 2024. 10. 26..
//

import SwiftUI
import AVFoundation
import SwiftUI
import AVFoundation

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String?
    let audioURL: URL?
    let isUser: Bool
    
    init(text: String?, audioURL: URL?, isUser: Bool) {
        self.text = text
        self.audioURL = audioURL
        self.isUser = isUser
    }
}

struct ChatView: View {
    @Environment(\.colorScheme) var colorScheme // Detect light or dark mode
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isRecording: Bool = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordedAudioURL: URL?
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack {
                HStack {
                    Image("icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health Assistant")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Chat with me to identify health concerns.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding()
                
                Divider()
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                }
                                if let text = message.text {
                                    Text(text)
                                        .padding()
                                        .background(message.isUser ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                                        .foregroundColor(message.isUser ? .white : .primary)
                                        .cornerRadius(10)
                                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7,
                                               alignment: message.isUser ? .trailing : .leading)
                                } else if let audioURL = message.audioURL {
                                    AudioMessageView(audioURL: audioURL)
                                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                                }
                                if !message.isUser {
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: messages) { _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Area
            HStack(spacing: 10) {
                if isRecording {
                    WaveformView() // Custom Waveform View
                        .frame(height: 40)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                } else if recordedAudioURL != nil {
                    HStack {
                        WaveformView() // Waveform preview for recorded audio
                            .frame(height: 40)
                            .cornerRadius(8)
                            .padding(.horizontal)
                        
                        Button(action: sendAudioMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.accentColor)
                        }
                        
                        Button(action: deleteRecording) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    TextField("Tell me about your problem...", text: $inputText)
                        .padding(10)
                        .frame(height: 40)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.leading, 8)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.accentColor)
                    }
                }
                
                Button(action: isRecording ? stopRecording : startRecording) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 25))
                        .foregroundColor(isRecording ? .red : .accentColor)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let newMessage = Message(text: inputText, audioURL: nil, isUser: true)
        messages.append(newMessage)
        inputText = ""
        
        // Simulate response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let responseMessage = Message(text: "I'm here to help with your health. How can I assist?", audioURL: nil, isUser: false)
            messages.append(responseMessage)
        }
    }
    
    private func deleteRecording() {
        recordedAudioURL = nil
    }
    
    private func sendAudioMessage() {
        guard let audioURL = recordedAudioURL else { return }
        let newMessage = Message(text: nil, audioURL: audioURL, isUser: true)
        messages.append(newMessage)
        recordedAudioURL = nil
    }
    
    private func startRecording() {
        isRecording = true
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            recordedAudioURL = documentDirectory.appendingPathComponent("recording.m4a")
            
            audioRecorder = try AVAudioRecorder(url: recordedAudioURL!, settings: settings)
            audioRecorder?.record()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    private func playRecording() {
        guard let audioURL = recordedAudioURL else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.play()
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
}

#Preview {
    ChatView()
        .preferredColorScheme(.dark) // Preview in dark mode
}
