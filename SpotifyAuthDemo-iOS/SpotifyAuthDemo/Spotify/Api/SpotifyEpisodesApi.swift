//
//  SpotifyEpisodesApi.swift
//  SpotifyAuthDemo
//
//  Created by lau on 2020/5/30.
//

import Foundation

protocol ResourceEpisodesAPI { }
extension SpotifyAPI where Self: ResourceEpisodesAPI {
    var resource: String {
        return "episodes"
    }
}

struct SPTGetEpisodeApi: SpotifyAPIVersion1, GetAPI, ResourceEpisodesAPI {
    let id: String
    let market: String?
    
    typealias Response = SpotifyEpisode
    
    var path: String {
        return "\(id)"
    }
    
    var query: [String : String] {
        if let market = market {
            return ["market": market]
        }
        return [:]
    }
}

struct SPTGetServeralEpisodesApi: SpotifyAPIVersion1, GetAPI, ResourceEpisodesAPI {
    let ids: [String]
    //An ISO 3166-1 alpha-2 country code.
    let market: String?
    
    var path: String {
        return ""
    }
    
    var query: [String : String] {
        if let market = market {
            return ["market": market]
        }
        return [:]
    }
    
    typealias Response = Model
    struct Model: Codable {
        let episodes: [SpotifyEpisode]?
    }
}
