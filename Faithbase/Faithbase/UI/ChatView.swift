//
//  ChatView.swift
//  Faithbase
//
//  Created by Paniti Marta on 2024. 10. 26..
//

import SwiftUI
import AVFoundation
import Speech

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    
    init(text: String,  isUser: Bool) {
        self.text = text
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
    @State private var isConverting: Bool = false
    
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
                                if !message.text.isEmpty {
                                    Text(message.text)
                                        .padding()
                                        .background(message.isUser ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                                        .foregroundColor(message.isUser ? .white : .primary)
                                        .cornerRadius(10)
                                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7,
                                               alignment: message.isUser ? .trailing : .leading)
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
                } else if (recordedAudioURL != nil && isRecording) {
                    HStack {
                        WaveformView() // Waveform preview for recorded audio
                            .frame(height: 40)
                            .cornerRadius(8)
                            .padding(.horizontal)
                        
                        Button(action: stopRecording) {
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
                } else if isConverting {
                    HStack  {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                        Text("Converting audio to text…")
                            .font(.headline)
                            .padding(.leading, 8)
                            .foregroundColor(.primary)
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
    
    private func getReply() {
        // Simulate response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let responseMessage = Message(text: "I'm here to help with your health. How can I assist?",
                                          isUser: false)
            messages.append(responseMessage)
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let newMessage = Message(text: inputText,
                                 isUser: true)
        messages.append(newMessage)
        inputText = ""
        getReply()
    }
    
    private func deleteRecording() {
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
        transcribeAudio()
    }
    
    private func transcribeAudio() {
        guard let recordedAudioURL = recordedAudioURL else { return }
        
        isConverting = true // Show loading view

        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                let recognizer = SFSpeechRecognizer()
                let request = SFSpeechURLRecognitionRequest(url: recordedAudioURL)
                
                recognizer?.recognitionTask(with: request) { result, error in
                    DispatchQueue.main.async {
                        self.isConverting = false // Hide loading view
                    }
                    
                    if let result = result {
                        // Only add the message once when the transcription is final
                        if result.isFinal {
                            let messageText = result.bestTranscription.formattedString
                            DispatchQueue.main.async {
                                let newMessage = Message(text: messageText, isUser: true)
                                self.messages.append(newMessage)
                            }
                        }
                    } else if let error = error {
                        print("Transcription error: \(error)")
                    }
                }
            default:
                DispatchQueue.main.async {
                    self.isConverting = false // Hide loading view if authorization fails
                }
                print("Speech recognition authorization denied")
            }
        }
    }
}

#Preview {
    ChatView()
        .preferredColorScheme(.dark) // Preview in dark mode
}
