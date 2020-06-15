//
//  SpotifyBrowseApi.swift
//  SpotifyAuthDemo
//
//  Created by lau on 2020/5/30.
//

import Foundation

protocol ResourceBrowseAPI { }
extension SpotifyAPI where Self: ResourceBrowseAPI {
    var resource: String {
        return "browse"
    }
}

struct SPTGetCategoryApi: SpotifyAPIVersion1, GetAPI, ResourceBrowseAPI {
    typealias Response = SpotifyCategory
    
    var path: String {
        return "/categories/\(category_id)"
    }
    
    var query: [String : String] {
        var dict: [String: String] = [:]
        if let country = country {
            dict["country"] = country
        }
        if let locale = locale {
            dict["locale"] = locale
        }
        return dict
    }
    
    let category_id: String
    let country: String?
    let locale: String?
}

struct SPTGetCategoryPlaylistsApi: SpotifyAPIVersion1, GetAPI, ResourceBrowseAPI {
    typealias Response = SpotifyPaging<SpotifyPlaylistSimple>
    
    var path: String {
        return "\(category_id)/playlists"
    }
    var query: [String : String] {
        var dict = [String: String]()
        if let country = country {
            dict["country"] = country
        }
        if let limit = limit {
            dict["limit"] = "\(limit)"
        }
        if let offset = offset {
            dict["offset"] = "\(offset)"
        }
        return dict
    }
    
    let category_id: String
    let country: String?
    let limit: Int?
    let offset: Int?
}

struct SPTGetCategoriesListApi: SpotifyAPIVersion1, GetAPI, ResourceBrowseAPI {
    typealias Response = SpotifyPaging<SpotifyCategory>
    
    var path: String {
        return "categories"
    }
    
    var query: [String : String] {
        var dict = [String: String]()
        if let country = country {
            dict["country"] = country
        }
        if let locale = locale {
            dict["locale"] = locale
        }
        if let limit = limit {
            dict["limit"] = "\(limit)"
        }
        if let offset = offset {
            dict["offset"] = "\(offset)"
        }
        return dict
    }
    
    let country: String?
    let locale: String?
    let limit: Int?
    let offset: Int?
}

struct SPTGetFeaturedPlaylistsListApi: SpotifyAPIVersion1, GetAPI, ResourceBrowseAPI {
    
    typealias Response = Model
    struct Model: Codable {
        let message: String?
        let playlists: SpotifyPaging<SpotifyPlaylistSimple>
    }
    
    var path: String {
        return ""
    }
    
    var query: [String : String] {
        var dict = [String: String]()
        if let country = country {
            dict["country"] = country
        }
        if let locale = locale {
            dict["locale"] = locale
        }
        if let limit = limit {
            dict["limit"] = "\(limit)"
        }
        if let offset = offset {
            dict["offset"] = "\(offset)"
        }
        if let timestamp = timestamp {
            let formatter = DateFormatter()
            let string = formatter.string(from: timestamp)
            dict["timestamp"] = "\(string)"
        }
        return dict
    }
    
    let locale: String?
    let country: String?
    let timestamp: Date?
    let limit: String?
    let offset: String?
}

struct SPTGetNewReleaseListApi: SpotifyAPIVersion1, GetAPI, ResourceBrowseAPI {
    let country: String?
    let limit: Int?
    let offset: Int?
    
    typealias Response = Model
    struct Model: Codable {
        let albums: SpotifyPaging<SpotifyAlbumSimple>
    }
    
    var path: String {
        return "new-release"
    }
    
    var query: [String : String] {
        var dict = [String: String]()
        if let limit = limit {
            dict["limit"] = "\(limit)"
        }
        if let offset = offset {
            dict["offset"] = "\(offset)"
        }
        if let country = country {
            dict["country"] = country
        }
        return dict
    }
}

struct SPTRecommendationsApi: SpotifyAPIVersion1, GetAPI {
    typealias Response = Model
    struct Model: Codable {
        let seeds: [SpotifyRecommenddationsSeed]?
        let tracks: [SpotifyTrackSimple]?
    }
    
    var resource: String {
        return "recommendations"
    }
    
    var path: String {
        return ""
    }
    
    var query: [String : String] {
        var dict = [String: String]()
        if let limit = limit {
            dict["limit"] = "\(limit)"
        }
        if let market = market {
            dict["market"] = market
        }
        if let att = maxAttibute {
            dict["max_\(att.keyValue.key)"] = att.keyValue.value
        }
        if let att = minAttibute {
            dict["min_\(att.keyValue.key)"] = att.keyValue.value
        }
        let count = [seed_genres, seed_tracks, seed_artists].reduce(0) {
            $0 + ($1?.count ?? 0)
        }
        if count > 5 {
            fatalError("Up to 5 seed values may be provided in any combination of seed_artists, seed_tracks and seed_genres.")
        }
        if let array = seed_artists,
            array.isEmpty == false {
            dict["seed_artists"] = array.joined(separator: ",")
        }
        if let array = seed_genres,
            array.isEmpty == false {
            dict["seed_genres"] = array.joined(separator: ",")
        }
        if let array = seed_tracks,
            array.isEmpty == false {
            dict["seed_tracks"] = array.joined(separator: ",")
        }
        if let att = targetAttibute {
            dict["target_\(att.keyValue.key)"] = att.keyValue.value
        }
        return dict
    }
    
    enum TuneableTrackAttributes {
        case acousticness(Float)
        case danceability(Float)
        case duration_ms(Int)
        case energy(Float)
        case instrumentalness(Float)
        case key(Int)
        case liveness(Float)
        case loudness(Float)
        case mode(Int)
        case popularity(Int)
        case speechiness(Float)
        case tempo(Float)
        case time_signature(Int)
        case valence(Float)
        
        var keyValue: (key: String, value: String) {
            switch self {
            case .acousticness(let v):
                return ("acousticness", "\(v)")
            case .danceability(let v):
                return ("danceability", "\(v)")
            case .duration_ms(let v):
                return ("duration_ms", "\(v)")
            case .energy(let v):
                return ("energy", "\(v)")
            case .instrumentalness(let v):
                return ("instrumentalness", "\(v)")
            case .key(let v):
                return ("key", "\(v)")
            case .liveness(let v):
                return ("liveness", "\(v)")
            case .loudness(let v):
                return ("loudness", "\(v)")
            case .mode(let v):
                return ("mode", "\(v)")
            case .popularity(let v):
                return ("popularity", "\(v)")
            case .speechiness(let v):
                return ("speechiness", "\(v)")
            case .tempo(let v):
                return ("tempo", "\(v)")
            case .time_signature(let v):
                return ("time_signature", "\(v)")
            case .valence(let v):
                return ("valence", "\(v)")
            }
        }
    }
    
    let limit: String?
    let market: String?
    let minAttibute: TuneableTrackAttributes?
    let maxAttibute: TuneableTrackAttributes?
    let seed_artists: [String]?
    let seed_genres: [String]?
    let seed_tracks: [String]?
    let targetAttibute: TuneableTrackAttributes?
}
