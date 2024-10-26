//
//  ChatView.swift
//  Faithbase
//
//  Created by Paniti Marta on 2024. 10. 26..
//

import SwiftUI
import AVFoundation
import Speech

struct ChatView: View {
    @Environment(\.colorScheme) var colorScheme // Detect light or dark mode
    @StateObject var viewModel: ChatViewModel = .init()
    
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
                        ForEach(viewModel.messages) { message in
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
                .onChange(of: viewModel.messages) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Area
            HStack(spacing: 10) {
                if viewModel.isRecording {
                    WaveformView() // Custom Waveform View
                        .frame(height: 40)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                } else if (viewModel.recordedAudioURL != nil && viewModel.isRecording) {
                    HStack {
                        WaveformView() // Waveform preview for recorded audio
                            .frame(height: 40)
                            .cornerRadius(8)
                            .padding(.horizontal)
                        
                        Button(action: viewModel.stopRecording) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.accentColor)
                        }
                        
                        Button(action: viewModel.deleteRecording) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.red)
                        }
                    }
                } else if viewModel.isConverting {
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
                    TextField("Tell me about your problem...", text: $viewModel.inputText)
                        .padding(10)
                        .frame(height: 40)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.leading, 8)
                    
                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.accentColor)
                    }
                }
                
                Button(action: viewModel.isRecording ? viewModel.stopRecording : viewModel.startRecording) {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 25))
                        .foregroundColor(viewModel.isRecording ? .red : .accentColor)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

#Preview {
    ChatView()
        .preferredColorScheme(.dark) // Preview in dark mode
}
