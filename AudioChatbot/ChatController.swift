//
//  ChatController.swift
//  AfterLifeAI
//
//  Created by Gaganjot Singh on 26/04/24.
//

import SwiftUI
import Alamofire

struct TextChatRequestBodyParams: Encodable {
    var queryId: Int = 0
    let avatarId: Int
    let timeSpan: Int = 0
    let query: String
    let isFirstSession: Bool
}

struct VoiceChatRequestBodyParams: Encodable {
    let request: Data
}

struct ChatBotResponse: Decodable {
    let data: ChatData?
    let friendyMessageList: [String]?
    let httpStatusCode: Int?
    
    enum CodingKeys: CodingKey {
        case data
        case friendyMessageList
        case httpStatusCode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try? container.decodeIfPresent(ChatData.self, forKey: .data)
        self.friendyMessageList = try? container.decodeIfPresent([String].self, forKey: .friendyMessageList)
        self.httpStatusCode = try? container.decodeIfPresent(Int.self, forKey: .httpStatusCode)
    }
}
    
struct ChatData: Decodable {
    let response: String?
    let queryId: Int?
    let avatarId: Int?
    let error: String?
    let isError: Bool?
    let isMyMessage: Bool = false
    
    enum CodingKeys: CodingKey {
        case response
        case queryId
        case avatarId
        case error
        case isError
        case isMyMessage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.response = try? container.decodeIfPresent(String.self, forKey: .response)
        self.queryId = try? container.decodeIfPresent(Int.self, forKey: .queryId)
        self.avatarId = try? container.decodeIfPresent(Int.self, forKey: .avatarId)
        self.error = try? container.decodeIfPresent(String.self, forKey: .error)
        self.isError = try? container.decode(Bool.self, forKey: .isError)
    }
}

class ChatController {
    
    func sendVoiceMessage(with url: URL, avatar: Int = 9, isFirstSession: Bool) {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjQ4NCIsIlVzZXJUeXBlTWFwSWQiOiI3MjMiLCJyb2xlIjoiQnV5ZXIiLCJlbWFpbCI6InRlc3RuYXY0QG1haWxpbmF0b3IuY29tIiwibmJmIjoxNzE0NDQ3MjE1LCJleHAiOjE3MTUwNTIwMTUsImlhdCI6MTcxNDQ0NzIxNX0.BYRqRufwLDF-41Aa0AL5lYRKgzk7OGNUz9hRumR3J7Q"
        
        var header = ["Authorization": "Bearer \(token)"]
        
        if isFirstSession {
            header["isFirstSession"] = "\(isFirstSession)"
        }
        
        var request = URLRequest(url: URL(string: "https://afterlifeapi.azurewebsites.net/api/UserBotChat/GetWithVoice/\(188)")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = header

        let upload = AF.upload(multipartFormData: { formdata in
            formdata.append(url, withName: "request")
        }, with: request)
        
        upload.response { res in
            DispatchQueue.main.async {
                GSAudioRecorder.shared.writeDataAndPlay(data: res.data!)
            }
        }
    }
}
