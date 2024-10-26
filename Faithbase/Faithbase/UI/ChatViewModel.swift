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
    
    init(responseText: String) {
        self.text = responseText
        self.isUser = false
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
    @Published var isLoading: Bool = false
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
        
        isLoading = true
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                let recognizer = SFSpeechRecognizer()
                let request = SFSpeechURLRecognitionRequest(url: recordedAudioURL)
                
                recognizer?.recognitionTask(with: request) { result, error in
                    DispatchQueue.main.async {
                        self.isLoading = false
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
                    self.isLoading = false
                }
                print("Speech recognition authorization denied")
            }
        }
    }
    
    func hasMoreThanTwoWords(_ input: String) -> Bool {
        let words = input.split(separator: " ")
        return words.count > 2
    }
    
    
    private func processMessage(_ message: String) {
        let responseMessages: [String] = ["Could you provide additional information about your issue?",
                                          "Please share more specifics regarding your problem.",
                                          "We’d love more details to better understand your situation.",
                                          "Could you elaborate on the issue you’re experiencing?",
                                          "Additional context would be helpful in addressing your problem.",
                                          "Could you describe your problem in more detail?",
                                          "Please include more information so we can assist you more effectively."]
        guard hasMoreThanTwoWords(message) else {
            let response = Message(responseText: responseMessages.randomElement() ?? "")
            self.messages.append(response)
            return
        }
        
        self.isLoading = true
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
<<<<<<< HEAD
            guard let medic = MedicsRepo.getMedics(response?.speciality ?? "") else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                return
            }
            
            let responseMessage = Message(description: response?.message ?? "-",
                                          medic: medic)
=======
>>>>>>> 2bd1452b0aa8d5df3bc37ebfd3ccfbd8b42f828b
            DispatchQueue.main.async {
                guard let medic = MedicsRepo.getMedics(response?.speciality ?? "") else {
                    self?.isConverting = false
                    return
                }
                
                let responseMessage = Message(description: response?.message ?? "-",
                                              medic: medic)
                
                self?.messages.append(responseMessage)
                self?.isLoading = false
            }
        }
    }
}
