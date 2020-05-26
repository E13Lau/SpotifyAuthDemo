//
//  SpotifyManager+Request.swift
//  Wear_new
//
//  Created by iosdv on 2020/5/20.
//  Copyright © 2020 quan. All rights reserved.
//

import Foundation

// MARK: - Action
extension SpotifyManager {
    
    enum SpotifyError: Error {
        case SessionNotFound
        case URLFail
        case DataReadFail
        case DataDecodeFail
    }
    
    struct SpotifyAuthResponse: Codable {
        let access_token: String?
        let token_type: String?
        let scope: String?
        let expires_in: Int?
        let refresh_token: String?
        let error: String?
    }
    
    ///删除用户播放列表中的一个或多个
    @discardableResult
    func requestPlaylistDelete(playlistID: String, uriArray: [String], complete: @escaping ((Result<SPTRemoveItemsFromPlaylistApi.Response, Error>) -> Void)) -> URLSessionTask? {
        let apiRequest = SPTRemoveItemsFromPlaylistApi(playlistID: playlistID, uri: uriArray)
        return call(api: apiRequest, complete: complete)
    }
    
    ///Get Current User's Profile
    @discardableResult
    func requestUserProfile(complete: @escaping ((Result<SPTUserProfileApi.Response, Error>) -> Void)) -> URLSessionTask? {
        let request = SPTUserProfileApi()
        return call(api: request, complete: complete)
    }
    
    ///Get a List of Current User's Playlists
    @discardableResult
    func requestUserPlaylists(complete: @escaping ((Result<SPTUserPlaylistsApi.Response, Error>) -> Void)) -> URLSessionTask? {
        let request = SPTUserPlaylistsApi()
        return call(api: request, complete: complete)
    }
    
    ///Search for an Item
    @discardableResult
    func requestSearch(q: String, type: [SPTSearchApi.SearchType], limit: String?, offset: String?, complete: @escaping ((Result<SPTSearchApi.Response, Error>) -> Void)) -> URLSessionTask? {
        let request = SPTSearchApi(q: q, type: type, market: nil, limit: limit, offset: offset, include_external: nil)
        return call(api: request, complete: complete)
    }
    
    private func call<Request: SpotifyAPI>(api: Request, complete: @escaping ((Result<Request.Response, Error>) -> Void)) -> URLSessionTask? {
        guard let accessToekn = self.accessToken else {
            complete(.failure(SpotifyError.SessionNotFound))
            return nil
        }
        guard let url = URL(string: api.url) else {
            complete(.failure(SpotifyError.URLFail))
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = api.httpMethod.rawValue
        request.setValue(" Bearer \(accessToekn)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = api.bodyData
        request.timeoutInterval = 20
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, res, error) in
            if let error = error {
                complete(.failure(error))
                return
            }
            guard let data = data else {
                complete(.failure(SpotifyError.DataReadFail))
                return
            }
            guard let object = try? Request.response(from: data) else {
                complete(.failure(SpotifyError.DataDecodeFail))
                return
            }
            complete(.success(object))
        }
        task.resume()
        return task
    }
}
