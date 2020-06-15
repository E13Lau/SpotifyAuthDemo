//
//  SpotifyPlayerApi.swift
//  SpotifyAuthDemo
//
//  Created by lau on 2020/5/30.
//

import Foundation

struct SPTAddItemtoPlaybackQueueApi: SpotifyAPIVersion1, PostAPI, ResourceMeAPI {
    var params: [String : Any] {
        return [:]
    }
    
    var path: String {
        return "player/queue"
    }
    
    let uri: String
    let device_id: String?
    
    var query: [String : String] {
        var dict = [String: String]()
        dict["uri"] = uri
        if let device_id = device_id {
            dict["device_id"] = device_id
        }
        return dict
    }

    typealias Response = String
}

struct SPTGetCurrentPlaybackStateApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    var path: String {
        return "player"
    }
    
    enum Additional: String {
        case track, episode
    }
    let market: String?
    let additional_types: Additional?
    
    var query: [String : String] {
        var dict = [String: String]()
        if let market = market {
            dict["market"] = market
        }
        if let additional_types = additional_types {
            dict["additional_types"] = additional_types.rawValue
        }
        return dict
    }
    
    typealias Response = SpotifyCurrentlyPlayingContext
    struct SpotifyCurrentlyPlayingContext: Codable {
        
        struct Device: Codable {
            let id: String?
            let is_active: Bool?
            let is_private_session: Bool?
            let is_restricted: Bool?
            let name: String?
            enum DeviceType: String, Codable {
                case Computer
                case Tablet
                case Smartphone
                case Speaker
                case TV
                case AVR
                case STB
                case AudioDongle
                case GameConsole
                case CastVideo
                case CastAudio
                case Automobile
                case Unknown
            }
            let type: DeviceType?
            let volume_percent: Int?
        }
        
        let device: Device?
        let repeat_state: String?
        let shuffle_state: Bool?
        struct Context: Codable {
            let uri: String?
            let href: String?
            let external_urls: ExternalObject?
            enum `Type`: String, Codable {
                case album, artist, playlist
            }
            let type: Type?
        }
        let context: Context?
        ///Unix Millisecond Timestamp
        let timestamp: Int?
        let progress_ms: Int?
        let is_playing: Bool?
        enum `Item`: Codable {
            enum Key: CodingKey {
                case type
            }
            enum CodingError: Error {
                case unknownValue
            }
            init(from decoder: Decoder) throws {
                let contanier = try decoder.container(keyedBy: Key.self)
                let type = try contanier.decode(String.self, forKey: .type)
                switch type {
                case "track":
                    let track = try SpotifyTracks(from: decoder)
                    self = .Track(track)
                case "episode":
                    let episode = try SpotifyEpisode(from: decoder)
                    self = .Episode(episode)
                default:
                    throw CodingError.unknownValue
                }
            }
            func encode(to encoder: Encoder) throws {
                switch self {
                case .Track(let track):
                    try track.encode(to: encoder)
                case .Episode(let episode):
                    try episode.encode(to: encoder)
                }
            }
            case Track(SpotifyTracks)
            case Episode(SpotifyEpisode)
        }
        let item: Item?
        enum currently_playing_type: String, Codable {
            case track, episode,ad, unknown
        }
        let current_playing_type: currently_playing_type?
        struct Actions: Codable {
            enum SpotifyDisallows: String, Codable {
                case interrupting_playback
                case pausing
                case resuming
                case seeking
                case skipping_next
                case skipping_prev
                case toggling_repeat_context
                case toggling_shuffle
                case toggling_repeat_track
                case transferring_playback
            }
            let disallows: [SpotifyDisallows: Bool]?
        }
        let actions: Actions?
    }
}


struct SPTGetCurrentUserRecentlyPlayedTracksApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    
    var path: String {
        return "player/recently-played"
    }
    
    let limit: Int?
    let after: String?
    let before: String?
    
    typealias Response = NoContentable<SpotifyCursorbasedPaging<SpotifyPlayHistory>>
    
    var query: [String : String] {
        var dict = [String: String]()
        if let limit = limit {
            dict["limit"] = "\(limit)"
        }
        if let after = after {
            dict["after"] = after
        }
        if let before = before {
            dict["before"] = before
        }
        return dict
    }
}
