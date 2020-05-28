//
//  SpotifyApi.swift
//  Wear_new
//
//  Created by iosdv on 2020/5/20.
//  Copyright © 2020 quan. All rights reserved.
//

import Foundation
import AFNetworking
import SwiftyJSON
import HandyJSON

//MARK: - 网络接口
enum SpotifyHTTPMethod: String {
    case GET, POST, DELETE
}
protocol SpotifyAPI {
    associatedtype Response
    ///"https://api.spotify.com/v1/me" = baseURL / apiVersion / resource / path
    var baseURL: String { get }
    var httpMethod: SpotifyHTTPMethod { get }
    var apiVersion: String { get }
    var resource: String { get }
    var url: String { get }
    var path: String { get }
    
    var bodyData: Data? { get }
    
    /// url 请求参数
    var query: [String: String] { get }
    /// body 请求参数
    var params: [String: Any] { get }
    
    static func response(from data: Data) throws -> Response
}

extension SpotifyAPI {
    var baseURL: String {
        return "https://api.spotify.com"
    }
    var url: String {
        var string = "\(baseURL)/\(apiVersion)/\(resource)/\(path)"
        if query.isEmpty == false {
            let queryString = query.map({ "\($0.key)=\($0.value)" }).joined(separator: "&")
            if let urlQuery = queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                string += "?\(urlQuery)"
            }
        }
        return string
    }
}

extension SpotifyAPI where Response: Codable {
    static func response(from data: Data) throws -> Response {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Response.self, from: data)
    }
}

extension SpotifyAPI where Response == SwiftyJSON.JSON {
    static func response(from data: Data) throws -> Response {
        return try SwiftyJSON.JSON(data: data)
    }
}

extension SpotifyAPI where Response: HandyJSON {
    static func response(from data: Data) throws -> Response {
        let object = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        guard let dict = object as? [String: Any] else {
            throw NSError(domain: "Decode", code: 22, userInfo: nil)
        }
        // TODO: -
        return Response.deserialize(from: dict)!
    }
}

extension SpotifyAPI where Response == Dictionary<String, Any> {
    static func response(from data: Data) throws -> Response {
        let object = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        guard let dict = object as? [String: Any] else {
            throw NSError(domain: "Decode", code: 22, userInfo: nil)
        }
        return dict
    }
}

protocol DeleteAPI { }
protocol PostAPI { }
protocol GetAPI { }
extension SpotifyAPI where Self: DeleteAPI {
    var httpMethod: SpotifyHTTPMethod {
        return .DELETE
    }
    var bodyData: Data? {
        guard let data = try? JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            return nil
        }
        return data
    }
}
extension SpotifyAPI where Self: PostAPI {
    var httpMethod: SpotifyHTTPMethod {
        return .POST
    }
    var bodyData: Data? {
        guard let data = try? JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            return nil
        }
        return data
    }
}
extension SpotifyAPI where Self: GetAPI {
    var httpMethod: SpotifyHTTPMethod {
        return .GET
    }
    var bodyData: Data? {
        return nil
    }
    var params: [String : Any] {
        return [:]
    }
}

protocol SpotifyAPIVersion1: SpotifyAPI { }
extension SpotifyAPIVersion1 {
    var apiVersion: String {
        return "v1"
    }
}

protocol ResourcePlaylistsAPI { }
protocol ResourceMeAPI { }
protocol ResourceSearchAPI { }
protocol ResourceAudioAnalysisAPI { }
extension SpotifyAPI where Self: ResourcePlaylistsAPI {
    var resource: String {
        return "playlists"
    }
}
extension SpotifyAPI where Self: ResourceMeAPI {
    var resource: String {
        return "me"
    }
}
extension SpotifyAPI where Self: ResourceSearchAPI {
    var resource: String {
        return "search"
    }
}
extension SpotifyAPI where Self: ResourceAudioAnalysisAPI {
    var resource: String {
        return "audio-analysis"
    }
}

//https://developer.spotify.com/documentation/web-api/reference/playlists/remove-tracks-playlist/
struct SPTRemoveItemsFromPlaylistApi: SpotifyAPI, SpotifyAPIVersion1, ResourcePlaylistsAPI, DeleteAPI {
    
    typealias Response = JSON
    
    var query: [String : String] {
        return [:]
    }
    
    var path: String {
        return playlistID + "/tracks"
    }
    
    var params: [String : Any] {
        let array = uri.map({ ["uri": $0] })
        let params  = ["tracks" : array]
        return params
    }
    
    let playlistID: String
    let uri: [String]
}

//https://developer.spotify.com/documentation/web-api/reference/users-profile/get-current-users-profile/
struct SPTUserProfileApi: SpotifyAPIVersion1, ResourceMeAPI, GetAPI {
    
    typealias Response = SpotifyUserProfile
    var query: [String : String] {
        return [:]
    }
    var params: [String : Any] {
        return [:]
    }
    var path: String {
        return ""
    }
}

//https://developer.spotify.com/documentation/web-api/reference/playlists/get-a-list-of-current-users-playlists/
struct SPTUserPlaylistsApi: SpotifyAPIVersion1, ResourceMeAPI, GetAPI {
    typealias Response = JSON
    var query: [String : String] {
        return [:]
    }
    var path: String {
        return "playlist"
    }
    var params: [String : Any] {
        return [:]
    }
}

//https://developer.spotify.com/documentation/web-api/reference/tracks/get-audio-analysis/
struct SPTAudioAnalysisApi: SpotifyAPIVersion1, ResourceAudioAnalysisAPI, GetAPI {
    typealias Response = JSON
    var query: [String : String] {
        return [:]
    }
    var path: String {
        return id
    }
    
    let id: String
}

//https://developer.spotify.com/documentation/web-api/reference/search/search/
struct SPTSearchApi: SpotifyAPIVersion1, ResourceSearchAPI, GetAPI {
    enum SearchType: String {
        case album, artist, playlist, track, show, episode
    }
    typealias Response = SpotifySearchRM
    var query: [String : String] {
        let type = self.type.map({ $0.rawValue }).joined(separator: ",")
        var dict = ["q": self.q, "type": type]
        if let value = self.market {
            dict["market"] = value
        }
        if let value = self.limit {
            dict["limit"] = value
        }
        if let value = self.offset {
            dict["offset"] = value
        }
        if let value = self.include_external {
            dict["include_external"] = value
        }
        return dict
    }
    var path: String {
        return ""
    }
    
    let q: String
    let type: [SearchType]
    
    let market: String?
    //default: 20, range [1...50]
    let limit: String?
    //default: 0, max: 2000
    let offset: String?
    let include_external: String?
}
