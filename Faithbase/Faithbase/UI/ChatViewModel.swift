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
        let allMessages = messages.map{$0.text}.joined(separator: ", ")
        guard hasMoreThanTwoWords(allMessages) else {
            askForMoreDetails()
            return
        }
        
        self.isLoading = true
        
        // Construct the conversation history for the prompt
        var conversationHistory = "This is an ongoing conversation between a user seeking medical advice and an AI medical assistant. The assistant's goal is to understand the user's symptoms fully, analyze their relevance, and provide guidance on the appropriate specialist if enough information is available.\n\nConversation:\n"
        for msg in messages {
            let role = msg.isUser ? "User" : "AI"
            conversationHistory += "\(role): \(msg.text)\n"
        }
        
        let prompt = """
               \(conversationHistory)
               
               Instructions for the AI:
               - Carefully analyze the conversation history to determine if the user has provided sufficient medically relevant information, such as symptoms, duration, intensity, location, and any other necessary context.
               - Only if the provided information is incomplete or unclear should the assistant ask for additional specific details. Avoid asking unnecessary questions if the input already includes enough detail for an accurate recommendation.
               - If there is enough information, recommend an appropriate specialist in the following JSON format:

               {
                 "message": "Based on your symptoms, it would be best to consult a [specialist type].",
                 "speciality": "[specialist type]"
               }

               - If additional information is truly necessary, identify the missing information and ask a specific follow-up question in the following JSON format. Ensure the question is clear, concise, and directly relevant to making an accurate recommendation:

               {
                 "message": "Could you provide more information on [missing information]? For example, [example question based on context].",
                 "missing_information": "[missing category]"
               }

               Guidelines for determining when additional information is needed:
               - For pain: If location, severity, or duration is unclear, request these specifics. Otherwise, proceed with the available information.
               - For fatigue: If the duration, severity, or impact on daily activities is missing, ask about these aspects. Do not ask if these are already covered.
               - For respiratory issues: If relevant details like shortness of breath, cough type, or duration are missing, request them. Avoid redundancy if covered.
               - For digestive issues: Ask about nausea, vomiting, or specific triggers only if not mentioned by the user.

               The goal is to minimize repetitive or redundant questions while ensuring the assistant gathers enough information to make an informed recommendation.
               """
        
        // Call the OpenAI endpoint with the complete prompt
        endpoint.makeOpenAIRequest(prompt: prompt) { [weak self] response in
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
