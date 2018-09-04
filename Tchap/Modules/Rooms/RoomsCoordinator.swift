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

import UIKit

final class RoomsCoordinator: NSObject, RoomsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let session: MXSession
    
    private let roomsViewController: RoomsViewController
    private let roomsDataSource: RoomsDataSource
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: NavigationRouterType, session: MXSession) {
        self.router = router
        self.session = session
        self.roomsViewController = RoomsViewController.instantiate()
        self.roomsDataSource = RoomsDataSource(matrixSession: self.session)
        self.roomsDataSource.finalizeInitialization()
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
    }
    
    // MARK: - Public methods
    
    func start() {
        self.roomsViewController.displayList(self.roomsDataSource)
        self.roomsViewController.roomsViewControllerDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.roomsViewController
    }
    
    // MARK: - Private methods
    
    func showRoom(with roomID: String) {
        let roomViewController: RoomViewController = RoomViewController.instantiate()
        
        self.router.push(roomViewController, animated: true, popCompletion: nil)
        
        self.activityIndicatorPresenter.presentActivityIndicator(on: roomViewController.view, animated: false)
        
        // Present activity indicator when retrieving roomDataSource for given room ID
        let roomDataSourceManager: MXKRoomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.session)
        roomDataSourceManager.roomDataSource(forRoom: roomID, create: true, onComplete: { (roomDataSource) in
            
            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            
            if let roomDataSource = roomDataSource {
                roomViewController.displayRoom(roomDataSource)
            }
        })
    }
}

// MARK: - RoomsViewControllerDelegate
extension RoomsCoordinator: RoomsViewControllerDelegate {
    
    func roomsViewController(_ roomsViewController: RoomsViewController!, didSelectRoomWithID roomID: String!) {
        self.showRoom(with: roomID)
    }
    
    func roomsViewController(_ roomsViewController: RoomsViewController!, didAcceptRoomInviteWithRoomID roomID: String!) {

    }
    
    func roomsViewController(_ roomsViewController: RoomsViewController!, didSelect publicRoom: MXPublicRoom!) {
        
    }
    
    func roomsViewControllerDidSelectDirectoryServerPicker(_ roomsViewController: RoomsViewController!) {
        
    }
}
