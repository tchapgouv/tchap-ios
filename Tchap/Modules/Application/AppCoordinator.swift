/*
 Copyright 2018 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import Intents

final class AppCoordinator: AppCoordinatorType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let expiredAccountError: String = "ORG_MATRIX_EXPIRED_ACCOUNT"
    }
    
    // MARK: - Properties
  
    // MARK: Private
    
    private let rootRouter: RootRouterType
    
    private let universalLinkService: UniversalLinkService
    private var registrationService: RegistrationServiceType?
    
//    private weak var splitViewCoordinator: SplitViewCoordinatorType?
    private weak var homeCoordinator: HomeCoordinatorType?
    
    private weak var expiredAccountAlertController: UIAlertController?
    private var accountValidityService: AccountValidityServiceType?
    
    /// Main user Matrix session
    private var mainSession: MXSession? {
        return MXKAccountManager.shared().activeAccounts.first?.mxSession
    }
  
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: RootRouterType) {
        self.rootRouter = router
        self.universalLinkService = UniversalLinkService()
    }
    
    // MARK: - Public methods
    
    func start() {
        // If main user exist, user is logged in
        if let mainSession = self.mainSession {
//            self.showSplitView(session: mainSession)
            self.showHome(session: mainSession)
        } else {
            self.showWelcome()
        }
    }
    
    func handleUserActivity(_ userActivity: NSUserActivity, application: UIApplication) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            return self.universalLinkService.handleUserActivity(userActivity, completion: { (response) in
                switch response {
                case .success(let parsingResult):
                    switch parsingResult {
                    case .registrationLink(let registerParams):
                        self.handleRegisterAfterEmailValidation(registerParams)
                    case .roomLink(let roomIdOrAlias, let eventID):
                        _ = self.showRoom(with: roomIdOrAlias, onEventID: eventID)
                    }
                case .failure(let error):
                    self.showError(error)
                }
            })
        } else if userActivity.activityType == INStartAudioCallIntentIdentifier ||
        userActivity.activityType == INStartVideoCallIntentIdentifier {
            // Check whether a session is available (Ignore multi-accounts FTM)
            guard let account = MXKAccountManager.shared()?.activeAccounts.first else {
                return false
            }
            guard let session = account.mxSession else {
                return false
            }
            let interaction = userActivity.interaction
            
            let finalRoomID: String?
            // Check roomID provided by Siri intent
            if let roomID = userActivity.userInfo?["roomID"] as? String {
                finalRoomID = roomID
            } else {
                // We've launched from calls history list
                let person: INPerson?
                
                if let audioCallIntent = interaction?.intent as? INStartAudioCallIntent {
                    person = audioCallIntent.contacts?.first
                } else if let videoCallIntent = interaction?.intent as? INStartVideoCallIntent {
                    person = videoCallIntent.contacts?.first
                } else {
                    person = nil
                }
                
                finalRoomID = person?.personHandle?.value
            }
            
            if let roomID = finalRoomID {
                let isVideoCall = userActivity.activityType == INStartVideoCallIntentIdentifier
                var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
                
                // Start background task since we need time for MXSession preparation because our app can be launched in the background
                if application.applicationState == .background {
                    backgroundTaskIdentifier = application.beginBackgroundTask(expirationHandler: nil)
                }
                
                session.callManager.placeCall(inRoom: roomID, withVideo: isVideoCall, success: { (call) in
                    if application.applicationState == .background {
                        let center = NotificationCenter.default
                        var token: NSObjectProtocol?
                        token = center.addObserver(forName: Notification.Name(kMXCallStateDidChange), object: call, queue: nil, using: { [weak center] (note) in
                            if call.state == .ended {
                                if let bgTaskIdentifier = backgroundTaskIdentifier {
                                    application.endBackgroundTask(bgTaskIdentifier)
                                }
                                if let obsToken = token {
                                    center?.removeObserver(obsToken)
                                }
                            }
                        })
                    }
                }, failure: { (error) in
                    if let bgTaskIdentifier = backgroundTaskIdentifier {
                        application.endBackgroundTask(bgTaskIdentifier)
                    }
                })
            } else {
                let error = NSError(domain: MXKAuthErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: Bundle.mxk_localizedString(forKey: "error_common_message")])
                self.showError(error)
            }
            
            return true
        }
        return false
    }
    
    func showRoom(with roomIdOrAlias: String, onEventID eventID: String? = nil) -> Bool {
        guard let account = MXKAccountManager.shared().accountKnowingRoom(withRoomIdOrAlias: roomIdOrAlias),
            let homeCoordinator = self.homeCoordinator else {
                return false
        }
        
        let roomID: String?
        
        if roomIdOrAlias.hasPrefix("#") {
            // Translate the alias into the room id
            if let room = account.mxSession.room(withAlias: roomIdOrAlias) {
                roomID = room.roomId
            } else {
                roomID = nil
            }
        } else {
            roomID = roomIdOrAlias
        }
        
        if let finalRoomID = roomID {
            homeCoordinator.showRoom(with: finalRoomID, onEventID: eventID)
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Private methods
    
    private func showWelcome() {
        let welcomeCoordinator = WelcomeCoordinator(router: self.rootRouter)
        welcomeCoordinator.delegate = self
        welcomeCoordinator.start()
        self.add(childCoordinator: welcomeCoordinator)
    }
    
    // Disable usage of UISplitViewController for the moment
//    private func showSplitView(session: MXSession) {
//        let splitViewCoordinator = SplitViewCoordinator(router: self.rootRouter, session: session)
//        splitViewCoordinator.start()
//        self.add(childCoordinator: splitViewCoordinator)
//
//        self.registerLogoutNotification()
//    }
    
    func showHome(session: MXSession) {
        // Remove the potential existing home coordinator.
        self.removeHome()
        
        let homeCoordinator = HomeCoordinator(session: session)
        homeCoordinator.start()
        homeCoordinator.delegate = self
        self.add(childCoordinator: homeCoordinator)
        
        homeCoordinator.overrideContactManagerUsersDiscovery(true)
        
        self.rootRouter.setRootModule(homeCoordinator)
        
        self.homeCoordinator = homeCoordinator
        
        self.registerLogoutNotification()
        self.registerIgnoredUsersDidChangeNotification()
        self.registerDidCorruptDataNotification()
        
        // Track ourself the server error related to an expired account.
        AppDelegate.theDelegate().ignoredServerErrorCodes = [Constants.expiredAccountError]
        self.registerTrackedServerErrorNotification()
    }
    
    private func removeHome() {
        if let homeCoordinator = self.homeCoordinator {
            homeCoordinator.overrideContactManagerUsersDiscovery(false)
            self.remove(childCoordinator: homeCoordinator)
        }
    }
    
    private func reloadSession(clearCache: Bool) {
        self.unregisterLogoutNotification()
        self.unregisterIgnoredUsersDidChangeNotification()
        self.unregisterDidCorruptDataNotification()
        self.unregisterTrackedServerErrorNotification()
        
        if let accounts = MXKAccountManager.shared().activeAccounts, !accounts.isEmpty {
            for account in accounts {
                account.reload(clearCache)
                
                // Replace default room summary updater
                if let eventFormatter = EventFormatter(matrixSession: account.mxSession) {
                    eventFormatter.isForSubtitle = true
                    account.mxSession.roomSummaryUpdateDelegate = eventFormatter
                }
            }
            
            if clearCache {
                // clear the media cache
                MXMediaManager.clearCache()
            }
        }
        
        if let mainSession = self.mainSession {
            self.showHome(session: mainSession)
        }
    }
    
    private func registerLogoutNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogout), name: NSNotification.Name.legacyAppDelegateDidLogout, object: nil)
    }
    
    private func unregisterLogoutNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.legacyAppDelegateDidLogout, object: nil)
    }
    
    private func registerIgnoredUsersDidChangeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSessionAndClearCache), name: NSNotification.Name.mxSessionIgnoredUsersDidChange, object: nil)
    }
    
    private func unregisterIgnoredUsersDidChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.mxSessionIgnoredUsersDidChange, object: nil)
    }
    
    private func registerDidCorruptDataNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSessionAndClearCache), name: NSNotification.Name.mxSessionDidCorruptData, object: nil)
    }
    
    private func unregisterDidCorruptDataNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.mxSessionDidCorruptData, object: nil)
    }
    
    private func registerTrackedServerErrorNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleTrackedServerError(notification:)), name: NSNotification.Name.mxhttpClientMatrixError, object: nil)
    }
    
    private func unregisterTrackedServerErrorNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.mxhttpClientMatrixError, object: nil)
    }
    
    private func handleRegisterAfterEmailValidation(_ registerParams: [String: String]) {
        // Check required parameters
        guard let homeserver = registerParams["hs_url"],
            let sessionId = registerParams["session_id"],
            let clientSecret = registerParams["client_secret"],
            let sid = registerParams["sid"] else {
                NSLog("[AppCoordinator] handleRegisterAfterEmailValidation: failed, missing parameters")
                return
        }
        
        // Check whether there is already an active account
        if self.mainSession != nil {
            NSLog("[AppCoordinator] handleRegisterAfterEmailValidation: Prompt to logout current sessions to complete the registration")
            AppDelegate.theDelegate().logout(withConfirmation: true) { (isLoggedOut) in
                if isLoggedOut {
                    self.handleRegisterAfterEmailValidation(registerParams)
                }
            }
            return
        }
        
        // Create a rest client
        let restClientBuilder = RestClientBuilder()
        restClientBuilder.build(fromHomeServer: homeserver) { (restClientBuilderResult) in
            switch restClientBuilderResult {
            case .success(let restClient):
                // Apply the potential id server url if any
                if let identityServerURL = registerParams["is_url"] {
                    restClient.identityServer = identityServerURL
                }
                
                guard let identityServer = restClient.identityServer,
                    let identityServerURL = URL(string: identityServer),
                    let identityServerHost = identityServerURL.host else {
                        let error = NSError(domain: MXKAuthErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: Bundle.mxk_localizedString(forKey: "error_common_message")])
                        self.showError(error)
                        return
                }
                
                let registrationService = RegistrationService(accountManager: MXKAccountManager.shared(), restClient: restClient)
                let deviceDisplayName = UIDevice.current.name
                let threePIDCredentials = ThreePIDCredentials(clientSecret: clientSecret, sid: sid, identityServerHost: identityServerHost)
                
                registrationService.register(withEmailCredentials: threePIDCredentials, sessionId: sessionId, password: nil, deviceDisplayName: deviceDisplayName) { (registrationResult) in
                    self.registrationService = nil
                    switch registrationResult {
                    case .success:
                        print("[AppCoordinator] handleRegisterAfterEmailValidation: success")
                        _ = self.userDidLogin()
                    case .failure(let error):
                        self.showError(error)
                    }
                }
                self.registrationService = registrationService
            case .failure(let error):
                self.showError(error)
            }
        }
    }
    
    private func showError(_ error: Error) {
        // FIXME: Present an error on coordinator.toPresentable()
        AppDelegate.theDelegate().showError(asAlert: error)
    }
    
    private func userDidLogin() -> Bool {
        let success: Bool
        
        if let mainSession = self.mainSession {
            // self.showSplitView(session: mainSession)
            self.showHome(session: mainSession)
            success = true
        } else {
            NSLog("[AppCoordinator] Did not find session for current user")
            success = false
            // TODO: Present an error on
            // coordinator.toPresentable()
        }
        
        return success
    }
    
    @objc private func userDidLogout() {
        self.unregisterLogoutNotification()
        self.unregisterIgnoredUsersDidChangeNotification()
        self.unregisterDidCorruptDataNotification()
        self.unregisterTrackedServerErrorNotification()
        
        self.showWelcome()
        
//        if let splitViewCoordinator = self.splitViewCoordinator {
//            self.remove(childCoordinator: splitViewCoordinator)
//        }
        
        self.removeHome()
    }
    
    @objc private func reloadSessionAndClearCache() {
        // Reload entirely the app
        self.reloadSession(clearCache: true)
    }
    
    @objc private func handleTrackedServerError(notification: Notification) {
        guard let error = notification.userInfo?[kMXHTTPClientMatrixErrorNotificationErrorKey] as? MXError else {
            return
        }
        if error.errcode == Constants.expiredAccountError {
            self.handleExpiredAccount()
        }
    }
    
    private func handleExpiredAccount() {
        NSLog("[AppCoordinator] expired account")
        // Suspend the app by closing all the sessions (presently only one session is supported)
        if let accounts = MXKAccountManager.shared().activeAccounts, !accounts.isEmpty {
            for account in accounts {
                account.closeSession(true)
            }
        }
        // clear the media cache
        MXMediaManager.clearCache()
        
        // Remove the block provided to the contactManager to discover users
        if let homeCoordinator = self.homeCoordinator {
            homeCoordinator.overrideContactManagerUsersDiscovery(false)
        }
        
        if self.expiredAccountAlertController == nil {
            self.displayExpiredAccountAlert()
        }
    }
    
    private func displayExpiredAccountAlert() {
        guard let presenter = self.homeCoordinator?.toPresentable() else {
            return
        }
        
        self.expiredAccountAlertController?.dismiss(animated: false)
        
        let alert = UIAlertController(title: TchapL10n.warningTitle, message: TchapL10n.expiredAccountAlertMessage, preferredStyle: .alert)
        
        let resumeTitle = TchapL10n.expiredAccountResumeButton
        let resumeAction = UIAlertAction(title: resumeTitle, style: .default, handler: { action in
            // Relaunch the session
            self.reloadSession(clearCache: false)
        })
        alert.addAction(resumeAction)
        let sendEmailTitle = TchapL10n.expiredAccountRequestRenewalEmailButton
        let sendEmailAction = UIAlertAction(title: sendEmailTitle, style: .default, handler: { action in
            // Request a new email for the main account
            if let credentials = MXKAccountManager.shared().activeAccounts.first?.mxCredentials {
                let accountValidityService = AccountValidityService(credentials: credentials)
                _ = accountValidityService.requestRenewalEmail(completion: { (response) in
                    switch response {
                    case .success:
                        // Keep display the alert
                        self.displayExpiredAccountAlert()
                    case .failure(let error):
                        self.showError(error)
                    }
                    self.accountValidityService = nil
                    
                })
                self.accountValidityService = accountValidityService
            }
        })
        alert.addAction(sendEmailAction)
        self.expiredAccountAlertController = alert
        
        presenter.present(alert, animated: true, completion: nil)
    }
}

// MARK: - WelcomeCoordinatorDelegate
extension AppCoordinator: WelcomeCoordinatorDelegate {
    
    func welcomeCoordinatorUserDidAuthenticate(_ coordinator: WelcomeCoordinatorType) {
        // Check that the new account actually exists before removing the current coordinator
        if userDidLogin() {
            self.remove(childCoordinator: coordinator)
        }
    }
}

// MARK: - HomeCoordinatorDelegate
extension AppCoordinator: HomeCoordinatorDelegate {
    func homeCoordinator(_ coordinator: HomeCoordinatorType, reloadMatrixSessionsByClearingCache clearCache: Bool) {
        self.reloadSession(clearCache: clearCache)
    }
}
