//
//  ChatViewModel.swift
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
    let medic: Medic?
    
    init(userText: String) {
        self.text = userText
        self.isUser = true
        self.medic = nil
    }
    
    init(description: String, medic: Medic) {
        self.text = description
        self.medic = medic
        self.isUser = false
    }
}

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isRecording: Bool = false
    @Published var isConverting: Bool = false
    @Published var recordedAudioURL: URL? = nil
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    
    private let endpoint = Endpoint()
    
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        let newMessage = Message(userText: inputText)
        messages.append(newMessage)
        inputText = ""
        self.processMessage(newMessage.text)
    }
    
    func startRecording() {
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
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        transcribeAudio()
    }
    
    func deleteRecording() {
        recordedAudioURL = nil
    }
    
    private func transcribeAudio() {
        guard let recordedAudioURL = recordedAudioURL else { return }
        
        isConverting = true
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                let recognizer = SFSpeechRecognizer()
                let request = SFSpeechURLRecognitionRequest(url: recordedAudioURL)
                
                recognizer?.recognitionTask(with: request) { result, error in
                    DispatchQueue.main.async {
                        self.isConverting = false
                    }
                    
                    if let result = result, result.isFinal {
                        let messageText = result.bestTranscription.formattedString
                        DispatchQueue.main.async {
                            let newMessage = Message(userText: messageText)
                            self.messages.append(newMessage)
                            self.processMessage(newMessage.text)
                        }
                    } else if let error = error {
                        print("Transcription error: \(error)")
                    }
                }
            default:
                DispatchQueue.main.async {
                    self.isConverting = false
                }
                print("Speech recognition authorization denied")
            }
        }
    }
    
    private func processMessage(_ message: String) {
        self.isConverting = true
        let symptoms = message
        let prompt = """
        The user will provide a description of their symptoms. Please respond by recommending the type of medical specialist they should consult, using the json format:
        "{message: Based on your symptoms, it would be best to consult a [specialist type],
           speciality: speciality
         }".
        
        Consider common medical specialties, such as cardiology, dermatology, gastroenterology, neurology, orthopedics, and psychiatry, and choose the one that best fits the user's symptoms.
        
        User's Symptoms: \(symptoms)
        """
        
        endpoint.makeOpenAIRequest(prompt: prompt) { [weak self] response in
            DispatchQueue.main.async {
                guard let medic = MedicsRepo.getMedics(response?.speciality ?? "") else {
                    self?.isConverting = false
                    return
                }
                
                let responseMessage = Message(description: response?.message ?? "-",
                                              medic: medic)
                
                self?.messages.append(responseMessage)
                self?.isConverting = false
            }
        }
    }
}
