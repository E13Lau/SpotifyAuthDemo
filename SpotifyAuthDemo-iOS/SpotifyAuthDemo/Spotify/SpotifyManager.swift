//
//  SpotifyManager.swift
//  Wear_new
//
//  Created by iosdv on 2020/5/20.
//  Copyright © 2020 quan. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

typealias SPTAuth = SpotifyManager
// MARK: - SpotifyManager
class SpotifyManager: NSObject {
    static let shared = SpotifyManager()
    
    var accessToken: String? {
        guard let token = self.spotifyTokenRelay.value?.accessToken else {
            return nil
        }
        return token
    }
    private var refreshToken: String? {
        guard let token = self.spotifyTokenRelay.value?.refreshToken else {
            return nil
        }
        return token
    }
    var tokenObservable: Observable<SpotifyToken?> {
        return spotifyTokenRelay.share()
    }
    
    private var spotifyTokenRelay: BehaviorRelay<SpotifyToken?> = BehaviorRelay(value: nil)
    
    private var cacheUserProfile: SpotifyUserProfile?
    private var saveHelper: SpotifyPersistenceToken?
    private let spotifyConfig = SpotifyConfigurate()
    private var renewBag = DisposeBag()
    private var authHelpers: [SpotifyAuthControl] = []

    private override init() {
        super.init()
    }
        
    public func setup() {
        #if DEBUG
        registerTestNotify()
        #endif
        registerObserver()
        saveHelper = SpotifySaveTokenUserDefaults()
        let web = SpotifyAuthWithWeb(config: spotifyConfig, delegate: self)
        let sdk = SpotifyAuthWithSDK(config: spotifyConfig, delegate: self)
        self.authHelpers = [sdk, web]

        // TODO: - 放在登录后？
        self.initSession()
    }
    
    private func initSession() {
        guard let token = self.saveHelper?.getSpotifyToken(),
            let refreshToken = token.refreshToken else {
            return
        }
        guard token.isExpiry, token.deadline > 300 else {
            self.renewSession(refreshToken: refreshToken)
            return
        }
        // 有效且没有接近期限
        self.on(next: token)
        self.setRenewTimer(time: token.deadline - 300)
    }
    
    @discardableResult
    public func initiateSession(_ viewController: UIViewController? = nil) -> Observable<SpotifyToken?> {
        let single = singleSpotifyToken()
        for helper in authHelpers {
            if helper.initiateSession(viewController) {
                break
            }
        }
        return single
    }

    //解除绑定
    func unlink() {
        self.saveHelper?.removeSpotifyToken()
        for helper in authHelpers {
            helper.unlink()
        }
        self.cacheUserProfile = nil
        self.spotifyTokenRelay.accept(nil)
    }
    
    ///取 spotifyTokenRelay.value 刷新
    @discardableResult
    func renewTokenIfNeed() -> Observable<SpotifyToken?>? {
        // 额外的判断
        guard let refreshToken = self.spotifyTokenRelay.value?.refreshToken else {
            return nil
        }
        return self.renewSession(refreshToken: refreshToken)
    }

    @discardableResult
    func renewSession(refreshToken: String) -> Observable<SpotifyToken?> {
        logger.debug("尝试去刷新 Spotify 的 accessToken")

        let single = singleSpotifyToken()
        for helper in authHelpers {
            if helper.renewSession(refreshToken: refreshToken) {
                break
            }
        }
        return single
    }
    
    func registerObserver() {
        self.spotifyTokenRelay
            .debug()
            .subscribe(onNext: { [weak self]
                (token) in
                guard let token = token else {
                    NotificationCenter.default.post(name: Notification.Name.spotifyUpdateSessionName, object: nil)
                    return
                }
                NotificationCenter.default.post(name: Notification.Name.spotifyUpdateSessionName, object: token.accessToken)
                guard token.error == nil else {
                    return
                }
                self?.saveHelper?.save(spotifyToken: token)
                if token.deadline > 300 {
                    self?.setRenewTimer(time: token.deadline - 300)
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    func on(next token: SpotifyToken?) {
        guard let token = token else {
            self.unlink()
            return
        }
        self.cacheUserProfile = nil
        guard token.error == nil else {
            self.spotifyTokenRelay.accept(token)
            self.spotifyTokenRelay.accept(nil)
            return
        }
        self.spotifyTokenRelay.accept(token)
    }
    
    private func setRenewTimer(time: TimeInterval) {
        self.renewBag = DisposeBag()
        logger.debug("\(time)秒后执行 renewTokenIfNeed()")
        guard time >= 0 else {
            //立即触发
            self.renewTokenIfNeed()
            return
        }
        Observable<Int>
            .timer(.seconds(Int(time)), scheduler: MainScheduler.asyncInstance)
            .debug()
            .subscribe(onNext: { [weak self]
                (_) in
                self?.renewTokenIfNeed()
            })
            .disposed(by: self.renewBag)
    }
    
    func singleSpotifyToken() -> Observable<SpotifyToken?> {
        return spotifyTokenRelay
                .skip(1)
                .take(1)
    }
    
    func application(app: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        logger.debug("application(app: UIApplication, url: \(url), options: \(options)")
        
        var bool = false
        for helper in authHelpers {
            if helper.application(app: app, url: url, options: options) {
                bool = true
                break
            }
        }
        return bool
    }
    
}

// MARK: - 账号相关
extension SpotifyManager {
    var isHasSession: Bool {
        guard let value = self.spotifyTokenRelay.value else {
            return false
        }
        guard value.error == nil else {
            return false
        }
        return true
    }
    var isSessionValid: Bool {
        guard let token = self.spotifyTokenRelay.value else {
            return false
        }
        // 期限计算
        guard token.isExpiry else {
            return false
        }
        return true
    }
    
    var isPremium: Bool? {
        guard let profile = self.cacheUserProfile else {
            return nil
        }
        let product = profile.product ?? ""
        let state = SPTAccountState(rawValue: product)
        logger.info("会员状态: product: \(state?.rawValue ?? "nil")")
        
        switch state {
        case .premium, .unlimited:
            return true
        default:
            return false
        }
    }
    
    func getSpotifyAccessToken(_ complete: ((String?) -> Void)?) {
        // 获取 AccessToken、RefreshToken,判断 token 是否有效，
        guard let token = self.spotifyTokenRelay.value,
            let accessToken = token.accessToken,
            token.isExpiry else {
            // 不存在 Token，需要重新授权
            _ = self.initiateSession()
                    .subscribe(onNext: { (token) in
                        complete?(token?.accessToken)
                    })
            return
        }
        // 判断 Token 是否临近无效
        guard token.isNearInvalid else {
            // 有效期长直接返回 Token
            complete?(accessToken)
            return
        }
        guard let refreshToken = token.refreshToken else {
            // 有效期长直接返回 Token
            complete?(accessToken)
            return
        }
        _ = self.renewSession(refreshToken: refreshToken)
            .subscribe(onNext: { (t) in
                guard let t = t?.accessToken else {
                    // 刷新失败 返回旧 Token
                    complete?(accessToken)
                    return
                }
                // 刷新成功 返回新 Token
                complete?(t)
            })
    }
    
    func getUserIsPremium(_ complete: ((Bool?) -> Void)?) {
        guard self.spotifyTokenRelay.value != nil else {
            self.cacheUserProfile = nil
            complete?(nil)
            return
        }
        guard let isPremium = self.isPremium else {
            self.getUserProfile { [weak self]
                (_) in
                guard let isPremium = self?.isPremium else {
                    complete?(false)
                    return
                }
                complete?(isPremium)
            }
            return
        }
        complete?(isPremium)
    }

    func getUserProfile(_ complete: ((SpotifyUserProfile?) -> Void)?) {
        guard self.spotifyTokenRelay.value != nil else {
            self.cacheUserProfile = nil
            complete?(nil)
            return
        }
        guard let cache = self.cacheUserProfile else {
            self.requestUserProfile { [weak self] (result) in
                switch result {
                case .success(let profile):
                    if let err = profile.error {
                        if err.status == 401 {
                            
                        }
                        logger.error(err.message ?? "")
                        complete?(nil)
                        return
                    }
                    self?.cacheUserProfile = profile
                    complete?(profile)
                case .failure(let error):
                    complete?(nil)
                    logger.error(error.localizedDescription)
                }
            }
            return
        }
        complete?(cache)
    }
}


// MARK: - SPTSessionManagerDelegate
extension SpotifyManager: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        let token = SpotifyToken(accessToken: session.accessToken, refreshToken: session.refreshToken, expiresIn: nil, expirationDate: session.expirationDate.timeIntervalSinceReferenceDate)
        self.on(next: token)
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        let error = error as NSError
        logger.error(error)
        if error.code == 1 {
            self.on(next: nil)
            return
        }
        let token = SpotifyToken(error: "Spotify login error")
        self.on(next: token)
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        let token = SpotifyToken(accessToken: session.accessToken, refreshToken: session.refreshToken, expiresIn: nil, expirationDate: session.expirationDate.timeIntervalSinceReferenceDate)
        self.on(next: token)
    }
    
    func sessionManager(manager: SPTSessionManager, shouldRequestAccessTokenWith code: String) -> Bool {
        logger.debug("sessionManager(manager: , shouldRequestAccessTokenWith code:\(code)")
        return true
    }
}

extension SpotifyManager: SpotifyAuthWithWebDelegate {
    func spotifyDidAuth(token: SpotifyToken?) {
        self.on(next: token)
    }
}

//MARK: - 测试方法
extension Notification.Name {
    static let testSpotifyRenewToken = Notification.Name("spotifyRenewToken")
    static let testSpotifyRenewTokenWithWeb = Notification.Name("testSpotifyRenewTokenWithWeb")
    static let testSpotifyTokenInvaild = Notification.Name("spotifyTokenInvaild")
    static let testSpotifyTokenWillInvaild = Notification.Name("spotifyTokenWillInvaild")
    static let testSpotifyTokenError = Notification.Name("testSpotifyTokenError")
    static let testSpotifyTokenAuthToggle = Notification.Name("testSpotifyTokenAuthToggle")
    static let testSpotifyTokenSaveInvaild = Notification.Name("testSpotifyTokenSaveInvaild")
}

private extension SpotifyManager {
    
    func registerTestNotify() {
        
        NotificationCenter.default.rx
            .notification(.testSpotifyTokenSaveInvaild)
            .subscribe(onNext: { [weak self]
                (notification) in
                self?.t_saveInvaildToken()
            })
            .disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx
            .notification(.testSpotifyTokenAuthToggle)
            .subscribe(onNext: { [weak self]
                (notification) in
                self?.t_toggleAuth()
            })
            .disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx
            .notification(.testSpotifyRenewToken)
            .subscribe(onNext: { [weak self]
                (notification) in
                self?.t_renewToken()
            })
            .disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx
            .notification(.testSpotifyTokenInvaild)
            .subscribe(onNext: { [weak self]
                (notification) in
                let stamp = (notification.object as? TimeInterval) ?? 5
                self?.t_setTokenInvaild(expiresIn: stamp)
            })
        .disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx
            .notification(.testSpotifyTokenWillInvaild)
            .subscribe(onNext: { [weak self]
                (notification) in
                self?.t_setTokenInvaild(expiresIn: 30)
            })
            .disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx
            .notification(.testSpotifyTokenError)
            .subscribe(onNext: { [weak self]
                (notification) in
                self?.t_madeError()
            })
            .disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx
            .notification(.testSpotifyRenewTokenWithWeb)
            .subscribe(onNext: { [weak self]
                (notification) in
                self?.t_renewTokenWithWeb()
            })
            .disposed(by: rx.disposeBag)
    }
    
    func t_setTokenInvaild(expiresIn: TimeInterval = 1) {
        guard let oldToken = self.spotifyTokenRelay.value else {
            return
        }
        if expiresIn == 0 {
            self.on(next: nil)
            return
        }
        let newToken = SpotifyToken(accessToken: oldToken.accessToken, refreshToken: oldToken.refreshToken, expiresIn: expiresIn, expirationDate: nil)
        self.on(next: newToken)
    }
    
    func t_renewToken() {
        self.renewTokenIfNeed()
    }
    
    func t_madeError() {
        let newToken = SpotifyToken(error: "Spotify Token Error")
        self.on(next: newToken)
    }
    
    func t_renewTokenWithWeb() {
        if let token = self.spotifyTokenRelay.value,
            let refreshToken = token.refreshToken {
            _ = self.authHelpers
                .first(where: { $0.tag == "Web" })?
                .renewSession(refreshToken: refreshToken)
        }
    }
    
    func t_toggleAuth() {
        self.authHelpers = self.authHelpers.reversed()
        let type = self.authHelpers.first?.tag ?? ""
        DispatchQueue.main.async {
            HUD().showError(at: "现在的授权方式为\(type)")
        }
    }
    
    func t_saveInvaildToken() {
        guard let oldToken = self.spotifyTokenRelay.value else {
            return
        }
        let date = Date().addingTimeInterval(-(60 * 60 * 24))
        let token = SpotifyToken(accessToken: oldToken.accessToken, refreshToken: oldToken.refreshToken, expiresIn: oldToken.expiresIn, expirationDate: oldToken.expirationDate, createAt: date)
        self.saveHelper?.save(spotifyToken: token)
        DispatchQueue.main.async {
            HUD().showError(at: "保存成功")
        }
    }
    
}
