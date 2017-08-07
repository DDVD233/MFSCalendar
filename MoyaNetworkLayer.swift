//
//  MoyaNetworkLayer.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/6/9.
//  Copyright © 2017年 David. All rights reserved.
//

import Foundation
import Moya

let provider = MoyaProvider<MyService>()

enum MyService {
    case downloadLargeProfilePhoto(link: String)
    case getProfile(userID: String, token: String)
}

fileprivate let assetDir: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!

extension MyService: TargetType {
    
    var baseURL: URL { return URL(string: "https://mfriends.myschoolapp.com")! }
    var path: String {
        switch self {
        case .downloadLargeProfilePhoto(let link):
            return "/\(link)"
        case .getProfile(let userID):
            return "/api/user/\(userID)/"
        }
    }
    
    var assetName: String {
        switch self {
        case .downloadLargeProfilePhoto: return "/ProfilePhoto.png"
        default: return ""
        }
    }
    
    var localLocation: URL {
        return assetDir.appendingPathComponent(assetName)
    }
    
    var method: Moya.Method {
        switch self {
        case .downloadLargeProfilePhoto, .getProfile:
            return .get
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .getProfile(_, let token):
            return ["t": token]
        default: return nil
        }
    }
    
    var parameterEncoding: ParameterEncoding {
        switch self {
        case .downloadLargeProfilePhoto, .getProfile:
            return URLEncoding.default
//        URLEncoding.default: Send parameters in URL for GET, DELETE and HEAD. For other HTTP methods, parameters will be sent in request body
//        URLEncoding.queryString: Always sends parameters in URL, regardless of which HTTP method is used
        }
    }
    
    var sampleData: Data {
        switch self {
        case .downloadLargeProfilePhoto, .getProfile:
            return "".utf8Encoded
        }
    }
    
    var downloadDestination: DownloadDestination {
        return { _, _ in return (self.localLocation, .removePreviousFile) }
    }
    
    var task: Task {
        switch self {
        case .downloadLargeProfilePhoto:
            return .download(.request(downloadDestination))
        case .getProfile:
            return .request
        }
    }
}
