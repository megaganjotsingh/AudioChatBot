//
//  ContentView.swift
//  Voice
//
//  Created by Gaganjot Singh on 01/05/24.
//

import SwiftUI
import Combine

struct VoiceChatView: View {
    
    @State var isFirstSession = true
    @State var isRecording = false
    @State var isPlaying = false
    @State var cancellable = Set<AnyCancellable>()
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.yellow
            Group {
                speakerButton
                micButton
            }
            .padding(.bottom)
        }
        .onAppear {
            GSAudioRecorder.shared.objectWillChange.sink { recorder in
                isRecording = recorder.isRecording
                isPlaying = recorder.isPlaying
                if !recorder.isRecording && recorder.recordedUrl != nil {
                    sendVoice(with: recorder.recordedUrl!)
                    recorder.recordedUrl = nil
                }
            }
            .store(in: &cancellable)
        }
    }
}

extension VoiceChatView {
    var speakerButton: some View {
        HStack {
            Spacer()
                Image(isPlaying ? .speakerRed : .volume)
                    .padding()
                    .background()
                    .clipShape(Ellipse())
                    
            Spacer()
        }
    }
    
    var micButton: some View {
        Button {
            if isRecording {
                GSAudioRecorder.shared.stop()
            } else {
                GSAudioRecorder.shared.delete(name: "navaiRecordedVoice")
                GSAudioRecorder.shared.record()
            }
        } label: {
            Image(isRecording ? .microphoneRed : .mic)
                .background()
                .padding()
        }
    }
}

extension VoiceChatView {
    
    func sendVoice(with url: URL?) {
        guard let url else { return }
        
        ChatController().sendVoiceMessage(with: url, isFirstSession: isFirstSession)
    }
}
