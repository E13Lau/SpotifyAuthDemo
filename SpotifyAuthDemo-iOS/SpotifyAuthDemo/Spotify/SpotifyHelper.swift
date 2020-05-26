//
//  SpotifyHelper.swift
//  Wear_new
//
//  Created by iosdv on 2020/5/20.
//  Copyright © 2020 quan. All rights reserved.
//

import Foundation
import WebKit

//MARK: SpotifyPersistenceToken protocol
protocol SpotifyPersistenceToken {
    func save(spotifyToken: SpotifyToken?)
    func removeSpotifyToken()
    func getSpotifyToken() -> SpotifyToken?
}

protocol SpotifyAuthControl {
    func initiateSession(_ viewController: UIViewController?)
    func renewSession(refreshToken: String?) -> Bool
    func unlink()
    func application(app: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool
}

struct SpotifySaveTokenUserDefaults: SpotifyPersistenceToken {
    private let SpotifyTokenUserDefaultKey = "SpotifyTokenUserDefaultKey"
    func save(spotifyToken: SpotifyToken?) {
        guard let token = spotifyToken else {
            return
        }
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(token) else {
            return
        }
        let ud = UserDefaults.standard
        ud.set(encoded, forKey: SpotifyTokenUserDefaultKey)
    }
    
    func removeSpotifyToken() {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: SpotifyTokenUserDefaultKey)
    }
    
    func getSpotifyToken() -> SpotifyToken? {
        let ud = UserDefaults.standard
        let object = ud.object(forKey: SpotifyTokenUserDefaultKey)
        guard let data = object as? Data else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let token = try? decoder.decode(SpotifyToken.self, from: data) else {
            return nil
        }
        return token
    }
}

struct SpotifyAuthWithSDK: SpotifyAuthControl {
    init(config: SpotifyConfigurate, delegate: SPTSessionManagerDelegate) {
        let spotifyConfiguration = SPTConfiguration(clientID: config.clientID, redirectURL: URL(string: config.redirectURI)!)
        let tokenSwapURL: URL? = URL(string: config.swapURLTest)
        let tokenRefreshURL: URL? = URL(string: config.refreshURLTest)
        if let tokenSwapURL = tokenSwapURL,
            let tokenRefreshURL = tokenRefreshURL {
            spotifyConfiguration.tokenSwapURL = tokenSwapURL
            spotifyConfiguration.tokenRefreshURL = tokenRefreshURL
            spotifyConfiguration.playURI = ""
        }
        self.spotifySessionManager = SPTSessionManager(configuration: spotifyConfiguration, delegate: delegate)
        self.sptScope = config.requestedScopes
    }
    
    let spotifySessionManager: SPTSessionManager
    private let sptScope: SPTScope

    func initiateSession(_ viewController: UIViewController? = nil) {
        if #available(iOS 11.0, *) {
            self.getSession()
        } else {
            self.getSessionBeforeiOS11(viewController)
        }
    }
    
    @available(iOS 11.0, *)
    private func getSession() {
        self.spotifySessionManager.initiateSession(with: self.sptScope, options: .default)
    }
    private func getSessionBeforeiOS11(_ viewController: UIViewController?) {
        guard let viewController = viewController else {
            return
        }
        self.spotifySessionManager.initiateSession(with: self.sptScope, options: .default, presenting: viewController)
    }
    
    func renewSession(refreshToken: String?) -> Bool {
        if self.spotifySessionManager.session == nil {
            return false
        }
        self.spotifySessionManager.renewSession()
        return true
    }
    
    func application(app: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return self.spotifySessionManager.application(app, open: url, options: options)
    }
    
    func unlink() {
        self.spotifySessionManager.session = nil
    }
}

protocol SpotifyAuthWithWebDelegate: class {
    func spotifyDidAuth(token: SpotifyToken?)
}

class SpotifyAuthWithWeb: SpotifyAuthControl {
    init(config: SpotifyConfigurate, delegate: SpotifyAuthWithWebDelegate) {
        self.spotifyConfig = config
        self.delegate = delegate
    }
    
    let spotifyConfig: SpotifyConfigurate
    weak var delegate: SpotifyAuthWithWebDelegate?
    
    func initiateSession(_ viewController: UIViewController? = nil) {
        guard let redirect_uri = spotifyConfig.redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        guard let scope = spotifyConfig.requestedScopesString.joined(separator: " ").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        guard let presentedVC = viewController ?? UIApplication.AppDelegate.window?.topMostController else {
            logger.error("initiateSession presentedVC notfound")
            return
        }
        guard let url = URL(string: "https://accounts.spotify.com/authorize?client_id=\(spotifyConfig.clientID)&response_type=code&redirect_uri=\(redirect_uri)&scope=\(scope)") else {
            return
        }
        // TOOD: presenting Auth Web
        let web = authViewControllerWithURL(url: url)
        presentedVC.present(web, animated: true, completion: nil)
    }
    
    // MARK:  - Spotify 网页授权
    func authViewControllerWithURL(url:URL) -> UIViewController {
        let safari = SFSafariViewController(url: url)
//        safari.delegate = self
        safari.modalPresentationStyle = .pageSheet
        return safari
    }
    
    func renewSession(refreshToken: String?) -> Bool {
        guard let token = refreshToken else {
            return false
        }
        self.requestRenewToken(refreshToken: token)
        return true
    }
    
    func application(app: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        // TODO: - 获取 code 去 swap accessToken
        // TODO: - 判断
        //⚠️ 还不可用
//        if url.host == spotifyConfig.redirectURI {
//            return true
//        }
        return false
    }
    
    func unlink() {
        
    }
    
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
    
    
    ///使用 Code 获取新的 AccessToken、RefreshToken
    @discardableResult
    func requestSwapToken(code: String, complete: () -> Void) -> URLSessionDataTask {
        guard let url = URL(string: spotifyConfig.swapURLTest) else {
            fatalError(SpotifyError.SessionNotFound.localizedDescription)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "code=\(code)"
        request.httpBody = postString.data(using: .utf8)
        
        return self.postFormData(response: SpotifyAuthResponse.self, request: request) {
            [weak self]
            (auth) in
            guard let accessToken = auth?.access_token,
                let refreshToken = auth?.refresh_token,
                let expiresIn = auth?.expires_in else {
                    let model = SpotifyToken(error: auth?.error)
                    self?.delegate?.spotifyDidAuth(token: model)
                    return
            }
            let model = SpotifyToken(accessToken: accessToken, refreshToken: refreshToken, expiresIn: TimeInterval(expiresIn), expirationDate: nil)
            self?.delegate?.spotifyDidAuth(token: model)
        }
    }
    
    ///使用 RefreshToken 刷新 AccessToken
    @discardableResult
    func requestRenewToken(refreshToken: String) -> URLSessionDataTask {
        guard let url = URL(string: spotifyConfig.refreshURLTest) else {
            fatalError(SpotifyError.SessionNotFound.localizedDescription)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "refresh_token=\(refreshToken)"
        request.httpBody = postString.data(using: .utf8)

        return self.postFormData(response: SpotifyAuthResponse.self, request: request) {
            [weak self]
            (auth) in
            let refreshToken = auth?.refresh_token ?? refreshToken
            guard let at = auth?.access_token,
                let ex = auth?.expires_in else {
                    let model = SpotifyToken(error: auth?.error)
                    self?.delegate?.spotifyDidAuth(token: model)
                    return
            }
            let newModel = SpotifyToken(accessToken: at, refreshToken: refreshToken, expiresIn: TimeInterval(ex), expirationDate: nil)
            self?.delegate?.spotifyDidAuth(token: newModel)
        }
    }
    
    private func postFormData<T>(response: T.Type, request: URLRequest, complete: @escaping (T?) -> Void) -> URLSessionDataTask where T: Decodable {
        let task = URLSession.shared.dataTask(with: request) { (data, res, error) in
            if let error = error {
                logger.error(error.localizedDescription)
                complete(nil)
                return
            }
            guard let data = data else {
                logger.error(SpotifyError.DataReadFail)
                complete(nil)
                return
            }
            let decoder = JSONDecoder()
            // TODO: - https://medium.com/%E5%BD%BC%E5%BE%97%E6%BD%98%E7%9A%84-swift-ios-app-%E9%96%8B%E7%99%BC%E5%95%8F%E9%A1%8C%E8%A7%A3%E7%AD%94%E9%9B%86/jsondecoder-%E8%A7%A3%E6%9E%90%E6%99%82%E9%96%93%E7%9A%84-datedecodingstrategy-a4095481f193
            decoder.dateDecodingStrategy = .iso8601
            
            guard let object = try? decoder.decode(T.self, from: data) else {
                logger.error(SpotifyError.DataDecodeFail)
                complete(nil)
                return
            }
            complete(object)
        }
        task.resume()
        return task
    }

}
