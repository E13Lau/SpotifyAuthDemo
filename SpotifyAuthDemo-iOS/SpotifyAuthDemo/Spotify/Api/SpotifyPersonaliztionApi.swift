//
//  SpotifyPersonaliztionApi.swift
//  SpotifyAuthDemo
//
//  Created by lau on 2020/5/30.
//

import Foundation

struct SPTGetUserTopArtistsApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    var query: [String : String] {
        var dict = [String: String]()
        dict["time_range"] = "\(time_range?.rawValue ?? TimeRange.medium_term.rawValue)"
        dict["limit"] = "\(limit ?? 20)"
        dict["offset"] = "\(offset ?? 0)"
        return dict
    }
    
    enum TimeRange: String {
        case long_term, medium_term, short_term
    }
    
    var limit: Int?
    var offset: Int?
    let time_range: TimeRange?
    
    var path: String {
        return "top/artists"
    }
    
    typealias Response = SpotifyPaging<SpotifyTracks>
}

struct SPTGetUserTopTracksApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    enum TimeRange: String {
        case long_term, medium_term, short_term
    }
    
    var limit: Int?
    var offset: Int?
    let time_range: TimeRange?
    
    var path: String {
        return "top/tracks"
    }
    
    var query: [String : String] {
        var dict = [String: String]()
        dict["time_range"] = "\(time_range?.rawValue ?? TimeRange.medium_term.rawValue)"
        dict["limit"] = "\(limit ?? 20)"
        dict["offset"] = "\(offset ?? 0)"
        return dict
    }
    
    typealias Response = SpotifyPaging<SpotifyArtist>
}
