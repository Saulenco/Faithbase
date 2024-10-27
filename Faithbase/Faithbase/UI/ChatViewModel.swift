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
    
    init(userDocument: String, documentText: String) {
        self.text = documentText
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
        messages.removeAll()
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
        self.processMessages()
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
                            self.processMessages()
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
    
    // Follow-up question categories based on common medical symptom information needs
       private let followUpQuestions: [String] = [
               "Could you tell me more about your symptoms?",
               "How long have you been experiencing these symptoms?",
               "Is there anything that makes your symptoms better or worse?",
               "Have you tried any treatments or medications?",
               "How severe would you rate your symptoms on a scale of 1-10?"]
       
    private func processMessages() {
        var messagesToProcess = messages
        messagesToProcess.removeFirst()
        let allMessages = messagesToProcess.map{$0.text}.joined(separator: ", ")
        guard hasMoreThanTwoWords(allMessages) else {
            askForMoreDetails()
            return
        }
        
        self.isLoading = true

        // Call the OpenAI endpoint with the complete prompt
        endpoint.makeOpenAIRequest(for: messages) { [weak self] response in
            if let missingInfo = response?.missing_information {
                self?.askForSpecificDetails(missingInfo: response?.message ?? "Could you be more specific about your symptoms?")
            } else if let speciality = response?.speciality {
                let medic = MedicsRepo.getMedics(speciality)
                let responseMessage = Message(description: response?.message ?? "-", medic: medic)
                DispatchQueue.main.async {
                    self?.messages.append(responseMessage)
                    self?.isLoading = false
                }
            } else {
                let responseMessage = Message(responseText: response?.message ?? "-")
                DispatchQueue.main.async {
                    self?.messages.append(responseMessage)
                    self?.isLoading = false
                }
            }
        }
    }
       
    private func askForMoreDetails() {
        // Get the list of general questions and filter out those that have already been asked
        let askedQuestions = messages.map { $0.text }
        let availableQuestions = followUpQuestions.filter { !askedQuestions.contains($0) }
        
        // If there are no new questions left, use a default question or skip asking
        let genericQuestion = availableQuestions.randomElement() ?? "Could you provide additional information about your issue?"
        
        let responseMessage = Message(responseText: genericQuestion)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4)) {
                self.messages.append(responseMessage)
            }
        }
    }

    private func askForSpecificDetails(missingInfo: String) {
        let responseMessage = Message(responseText: missingInfo)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4)) {
                self.messages.append(responseMessage)
                self.isLoading = false
            }
        }
    }
       
    func hasMoreThanTwoWords(_ input: String) -> Bool {
        let words = input.split(separator: " ")
        return words.count > 2
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
            let newMessage = Message(userDocument: fileurl.lastPathComponent,
                                     documentText: "This is a document uploaded by user: \(text)")
            messages.append(newMessage)
            processMessages()
        }
    }
}
