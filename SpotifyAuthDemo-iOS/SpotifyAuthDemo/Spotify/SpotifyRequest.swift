import Foundation

// MARK: - Action
extension SpotifyManager {
    
    struct AuthenticationError: Codable {
        let error: String?
        let error_description: String?
    }
    struct RegularError: Codable {
        struct ErrorObject: Codable {
            let status: ResponseStatusCodes?
            let message: String?
        }
        let error: ErrorObject?
    }
    enum SpotifyError: Error {
        case SessionNotFound
        case URLFail
        case DataReadFail
        case DataDecodeFail
        case notSupportStatus(Int)
        case authenticationError(AuthenticationError)
        case regularError(RegularError)
        case other(Error)
    }
    
    struct SpotifyAuthResponse: Codable {
        let access_token: String?
        let token_type: String?
        let scope: String?
        let expires_in: Int?
        let refresh_token: String?
        let error: String?
    }
    
    typealias ResultError = SpotifyError
        
    private static func call<Request: SpotifyAPI>(api: Request, complete: @escaping ((Result<Request.Response, ResultError>) -> Void)) -> URLSessionTask? {
        guard let accessToken = SpotifyManager.shared.accessToken else {
            complete(.failure(SpotifyError.SessionNotFound))
            return nil
        }
        return SpotifyManager._call(accessToken: accessToken, api: api) { (result) in
            switch result {
            case .success(let res):
                complete(.success(res))
            case .failure(let error):
                switch error {
                case .authenticationError(let authErr):
                    complete(.failure(error))
                case .regularError(let err):
                    switch err.error?.status {
                    case .unauthorized:
                        _ = SpotifyManager
                            .shared
                            .renewTokenIfNeed()?.subscribe(onNext: { (newToken) in
                                guard let accessToken = newToken?.accessToken else {
                                    return
                                }
                                _ = SpotifyManager._call(accessToken: accessToken, api: api, complete: complete)
                            })
                    default: break
                    }
                default:
                    complete(.failure(error))
                }
            }
        }
    }
    
    private static func _call<Request: SpotifyAPI>(accessToken: String, api: Request, complete: @escaping ((Result<Request.Response, ResultError>) -> Void)) -> URLSessionTask? {
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
        
        let task = URLSession.shared.dataTask(with: request) { (data, res, error) in
            if let error = error {
                complete(.failure(.other(error)))
                return
            }
            guard let response = res as? HTTPURLResponse else {
                complete(.failure(SpotifyError.DataReadFail))
                return
            }
            guard let status = ResponseStatusCodes(rawValue: response.statusCode) else {
                complete(.failure(.notSupportStatus(response.statusCode)))
                return
            }
            switch status {
            case .ok, .accepted:
                guard let data = data else {
                    complete(.failure(SpotifyError.DataReadFail))
                    return
                }
                guard let object = try? Request.response(from: data) else {
                    complete(.success("" as! Request.Response))
                    return
                }
                complete(.success(object))
            case .noContent, .created:
                complete(.success(<#T##Request.Response#>))
                complete(.success("" as! Request.Response))
            default:
                complete(.failure(SpotifyError.DataReadFail))
            }
        }
        task.resume()
        return task
    }
}

extension SpotifyManager {
    ///删除用户播放列表中的一个或多个
    @discardableResult
    func requestPlaylistDelete(playlistID: String, uriArray: [String], complete: @escaping ((Result<SPTRemoveItemsFromPlaylistApi.Response, ResultError>) -> Void)) -> URLSessionTask? {
        let request = SPTRemoveItemsFromPlaylistApi(playlistID: playlistID, uri: uriArray)
        return SpotifyManager.call(api: request, complete: complete)
    }
    
    ///Get Current User's Profile
    @discardableResult
    func requestUserProfile(complete: @escaping ((Result<SPTUserProfileApi.Response, ResultError>) -> Void)) -> URLSessionTask? {
        let request = SPTUserProfileApi()
        return SpotifyManager.call(api: request, complete: complete)
    }
    
    ///Get a List of Current User's Playlists
    @discardableResult
    func requestUserPlaylists(complete: @escaping ((Result<SPTUserPlaylistsApi.Response, ResultError>) -> Void)) -> URLSessionTask? {
        let request = SPTUserPlaylistsApi()
        return SpotifyManager.call(api: request, complete: complete)
    }
    
    ///Search for an Item
    @discardableResult
    func requestSearch(q: String, type: [SPTSearchApi.SearchType], limit: String?, offset: String?, complete: @escaping ((Result<SPTSearchApi.Response, ResultError>) -> Void)) -> URLSessionTask? {
        let request = SPTSearchApi(q: q, type: type, market: nil, limit: limit, offset: offset, include_external: nil)
        return SpotifyManager.call(api: request, complete: complete)
    }
}
