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
        let request = SPTRemoveItemsFromPlaylistApi(playlistID: playlistID, uri: uriArray)
        return SpotifyManager.call(api: request, complete: complete)
    }
    
    ///Get Current User's Profile
    @discardableResult
    func requestUserProfile(complete: @escaping ((Result<SPTUserProfileApi.Response, Error>) -> Void)) -> URLSessionTask? {
        let request = SPTUserProfileApi()
        return SpotifyManager.call(api: request, complete: complete)
    }
    
    ///Get a List of Current User's Playlists
    @discardableResult
    func requestUserPlaylists(complete: @escaping ((Result<SPTUserPlaylistsApi.Response, Error>) -> Void)) -> URLSessionTask? {
        let request = SPTUserPlaylistsApi()
        return SpotifyManager.call(api: request, complete: complete)
    }
    
    ///Search for an Item
    @discardableResult
    func requestSearch(q: String, type: [SPTSearchApi.SearchType], limit: String?, offset: String?, complete: @escaping ((Result<SPTSearchApi.Response, Error>) -> Void)) -> URLSessionTask? {
        let request = SPTSearchApi(q: q, type: type, market: nil, limit: limit, offset: offset, include_external: nil)
        return SpotifyManager.call(api: request, complete: complete)
    }
    
    private static func call<Request: SpotifyAPI>(api: Request, complete: @escaping ((Result<Request.Response, Error>) -> Void)) -> URLSessionTask? {
        guard let accessToken = SpotifyManager.shared.accessToken else {
            complete(.failure(SpotifyError.SessionNotFound))
            return nil
        }
        return SpotifyManager._call(accessToken: accessToken, api: api) { (result) in
            switch result {
            case .success(let res):
                guard let r = res as? SpotifyErrorModel else {
                    complete(result)
                    return
                }
                let status = r.error?.status ?? 1
                switch status {
                case 401:
                    _ = SpotifyManager
                        .shared
                        .renewTokenIfNeed()?.subscribe(onNext: { (newToken) in
                        _ = SpotifyManager._call(accessToken: accessToken, api: api, complete: complete)
                    })
                default:
                    complete(result)
                }
            case .failure(_):
                complete(result)
            }
        }
    }
    
    private static func _call<Request: SpotifyAPI>(accessToken: String, api: Request, complete: @escaping ((Result<Request.Response, Error>) -> Void)) -> URLSessionTask? {
        guard let url = URL(string: api.url) else {
            complete(.failure(SpotifyError.URLFail))
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = api.httpMethod.rawValue
        request.setValue(" Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
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
