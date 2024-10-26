//
//  ChatViewModel.swift
//  Faithbase
//
//  Created by Paniti Marta on 2024. 10. 26..
//

import SwiftUI
import AVFoundation
import Speech
import PDFKit
import NaturalLanguage

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let medic: Medic?
    let document: String?
    
    init(userDocument: String) {
        self.text = ""
        self.isUser = true
        self.medic = nil
        self.document = userDocument
    }
    
    init(userText: String) {
        self.text = userText
        self.isUser = true
        self.medic = nil
        self.document = nil
    }
    
    init(responseText: String) {
        self.text = responseText
        self.isUser = false
        self.medic = nil
        self.document = nil
    }
    
    init(description: String, medic: Medic?) {
        self.text = description
        self.medic = medic
        self.isUser = false
        self.document = nil
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
    
    func initChat() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4)) {
                self.messages.append(Message(responseText: "Hi! Please tell me about your problem."))
            }
        }
    }
    
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        let newMessage = Message(userText: inputText)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4)) {
            messages.append(newMessage)
        }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4)) {
                    self.messages.append(response)
                }
            }
                
            return
        }
        
        self.isLoading = true
        let symptoms = message
        let prompt = """
           The user will input a text containing medical examination data or symptom descriptions. First, analyze the input to determine if it contains medically relevant information about health-related symptoms. If it does, recommend the type of medical specialist they should consult, using the JSON format:
           
           {
             "message": "Based on your symptoms, it would be best to consult a [specialist type]",
             "speciality": "[specialist type]"
           }
           
           Consider common medical specialties, such as cardiology, dermatology, gastroenterology, neurology, orthopedics, and psychiatry, and choose the one that best fits the user's symptoms.
           
           If the input does not contain relevant medical information, respond with a JSON format:
           
           {
             "message": "Your input doesn't seem to contain medical symptoms. Could you please describe your symptoms in more detail?",
             "speciality": "none"
           }
           
           User's Symptoms: \(symptoms)
           """
        
        endpoint.makeOpenAIRequest(prompt: prompt) { [weak self] response in
            var medic: Medic?
            if let speciality = response?.speciality {
                medic = MedicsRepo.getMedics(speciality)
            }
            
            let responseMessage = Message(description: response?.message ?? "-",
                                          medic: medic)
            DispatchQueue.main.async {
                self?.messages.append(responseMessage)
                self?.isLoading = false
            }
        }
    }
    
    func extractTextFromPDF(url: URL) -> String? {
        guard let pdfDocument = PDFDocument(url: url) else { return nil }
        var text = ""
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                text += page.string ?? ""
            }
        }
        return text
    }
    
    func extractTextFromTXT(url: URL) -> String? {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Error reading TXT file: \(error)")
            return nil
        }
    }
    
    func extractEntities(text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var formattedText: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag {
                let formatted = "\(text[range]): \(tag.rawValue)"
                formattedText.append(formatted)
            }
            return true
        }
        return formattedText.isEmpty ? text : formattedText.joined(separator: ", ")
    }
    
    func getDocument(fileurl: URL) {
        guard fileurl.startAccessingSecurityScopedResource() else {
            return
        }
        
        defer { fileurl.stopAccessingSecurityScopedResource() }
        
        var text = ""
        if fileurl.pathExtension.lowercased() == "pdf" {
            text = extractTextFromPDF(url: fileurl) ?? ""
        } else if fileurl.pathExtension.lowercased() == "txt" {
            text = extractTextFromTXT(url: fileurl) ?? ""
        }
        if !text.isEmpty {
            let newMessage = Message(userDocument: fileurl.lastPathComponent)
            messages.append(newMessage)
            processMessage(text)
        }
    }
}
