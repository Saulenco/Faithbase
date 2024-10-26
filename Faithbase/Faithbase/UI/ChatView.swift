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
    @State var showDocumentPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            titleView
            
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.messages) { message in
                           messageView(message)
                        }
                        if viewModel.isLoading {
                            HStack {
                                LoadingAnimationView()
                            }
                            .padding()
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
            
            Divider()
            
            inputView()
            
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .onAppear {
            viewModel.initChat()
        }
    }
    
    private var titleView: some View {
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
    }
    
    private func messageView(_ message: Message) -> some View {
        Group {
            if message.isUser {
                if let document = message.document {
                    DocumentView(documentName: document)
                } else {
                    userMessageView(message: message.text)
                }
            } else if let medic = message.medic {
                AppointmentView(description: message.text,
                                medic: medic)
            } else {
                responseMessageView(message: message.text)
            }
        }
        .transition(.move(edge: message.isUser ? .trailing : .leading).combined(with: .opacity))
    }
    
    private func userMessageView(message: String) -> some View{
        HStack {
            Spacer()
            if !message.isEmpty {
                Text(message)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7,
                           alignment: .trailing)
            }
        }
    }
    
    private func responseMessageView(message: String) -> some View{
        HStack {
            if !message.isEmpty {
                Text(message)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7,
                           alignment: .leading)
            }
            Spacer()
        }
    }
    
    private func inputView() -> some View {
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
            } else if !viewModel.isLoading  {
                Button(action: {
                    showDocumentPicker = true
                }) {
                    Image(systemName: "paperclip.circle.fill")
                        .font(.system(size: 25))
                        .foregroundColor(.accentColor)
                }
                .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.pdf, .text, .plainText], allowsMultipleSelection: false, onCompletion: { results in
                    switch results {
                    case .success(let fileurls):
                        print(fileurls.count)
                        viewModel.getDocument(fileurl: fileurls.first!)
                    case .failure(let error):
                        print("Error importing file: \(error)")
                    }
                })
            
                TextField("Tell me about your problem...", text: $viewModel.inputText)
                    .padding(10)
                    .frame(height: 40)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                    )
                    .padding(.horizontal, 8)
                
                if !viewModel.inputText .isEmpty {
                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            if !viewModel.isLoading && viewModel.inputText.isEmpty {
                Button(action: viewModel.isRecording ? viewModel.stopRecording : viewModel.startRecording) {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 25))
                        .foregroundColor(viewModel.isRecording ? .red : .accentColor)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    ChatView()
        .preferredColorScheme(.dark) // Preview in dark mode
}
