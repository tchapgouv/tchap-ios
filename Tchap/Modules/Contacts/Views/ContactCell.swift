/*
 Copyright 2018 Vector Creations Ltd
 
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

@objcMembers class ContactCell: UITableViewCell, MXKCellRendering, Stylable {

    @IBOutlet private(set) weak var thumbnailBadgeView: UIImageView!
    @IBOutlet private(set) weak var thumbnailView: MXKImageView!
    @IBOutlet private(set) weak var presenceView: UIImageView!
    @IBOutlet private(set) weak var contactDisplayNameLabel: UILabel!
    @IBOutlet private(set) weak var contactDomainLabel: UILabel!
    @IBOutlet private(set) weak var contactEmailLabel: UILabel!
    
    private(set) var style: Style!
    
    /// The current displayed contact.
    private var contact: MXKContact?
    /// The tchap id
    private var matrixId: String?
    
    weak var delegate: MXKCellRenderingDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.update(style: Variant2Style.shared)
        
        self.thumbnailView.enableInMemoryCache = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    class func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    class func defaultReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.thumbnailView.tc_makeCircle()
        
        // Finalize the badge displayed on online contacts avatar.
        if let presenceView = self.presenceView {
            presenceView.layer.cornerRadius = presenceView.frame.size.height / 2
            presenceView.layer.borderColor = UIColor.white.cgColor
            presenceView.layer.borderWidth = 1.0
        }
    }
    
    func render(_ cellData: MXKCellData!) {
        guard let contact = cellData as? MXKContact else {
            fatalError("ContactCell data is not of the expected class")
        }
        
        // Remove any pending observers
        unregisterContactUpdateNotification()
        unregisterContactPresenceNotification()
        
        self.contact = contact
        
        // Tchap contacts are defined with only one matrix id.
        // Consider here only the first id if any.
        if let matrixId = contact.matrixIdentifiers?.first as? String {
            self.matrixId = matrixId
            registerContactPresenceNotification()
        } else {
            self.matrixId = nil
        }
        
        // Be warned when the thumbnail is updated
        registerContactUpdateNotification()
        
        refreshContactThumbnail()
        refreshContactDisplayName()
        refreshContactPresence()
        refreshContactEmail()
    }
    
    // TODO: this method should be optional in the MXKCellRendering protocol
    class func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        // The ContactCell instances support the self-sizing mode, return a default value
        return 60
    }
    
    func didEndDisplay() {
        unregisterContactUpdateNotification()
        unregisterContactPresenceNotification()
        self.delegate = nil
        self.contact = nil
    }
    
    func update(style: Style) {
        self.style = style
        self.contactDisplayNameLabel.textColor = style.primaryTextColor
        self.contactDomainLabel.textColor = style.primarySubTextColor
        self.contactEmailLabel.textColor = style.secondaryTextColor
        
        // Clear the default background color of a MXKImageView instance
        self.thumbnailView?.defaultBackgroundColor = UIColor.clear
        
        self.presenceView?.backgroundColor = style.presenceIndicatorOnlineColor
    }
    
    private func refreshContactThumbnail() {
        if let image = self.contact?.thumbnail(withPreferedSize: self.thumbnailView.frame.size) {
            self.thumbnailView.image = image
        } else {
            self.thumbnailView.image = AvatarGenerator.generateAvatar(forMatrixItem: self.matrixId, withDisplayName: contact?.displayName)
        }
    }
    
    private func refreshContactDisplayName() {
        if let name = self.contact?.displayName {
            let displayNameComponents = DisplayNameComponents(displayName: name)
            self.contactDisplayNameLabel.text = displayNameComponents.name
            self.contactDomainLabel.text = displayNameComponents.domain
        } else {
            self.contactDisplayNameLabel.text = nil
            self.contactDomainLabel.text = nil
        }
    }
    
    private func refreshContactPresence() {
        self.presenceView.isHidden = true
        guard self.matrixId != nil, let sessions = MXKContactManager.shared().mxSessions as? [MXSession] else {
            // There is no discussion for the moment with this user
            return
        }
        
        // Look for the matrix user
        for session in sessions {
            guard let user = session.user(withUserId: self.matrixId) else { continue }
        
            self.presenceView.isHidden = user.presence != MXPresenceOnline
            break
        }
    }
    
    private func refreshContactEmail() {
        self.contactEmailLabel.isHidden = true
        guard self.matrixId == nil, let email = self.contact?.emailAddresses?.first as? MXKEmail else {
            // The email is displayed only for no-tchap users
            return
        }
        
        self.contactEmailLabel.isHidden = false
        self.contactEmailLabel.text = email.emailAddress
    }
    
    private func registerContactUpdateNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(onThumbnailUpdate(notification:)), name: NSNotification.Name.mxkContactThumbnailUpdate, object: nil)
    }
    
    private func unregisterContactUpdateNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.mxkContactThumbnailUpdate, object: nil)
    }
    
    @objc private func onThumbnailUpdate(notification: Notification) {
        guard let contactId = notification.object as? String, contactId == self.contact?.contactID else {
            return
        }
        
        refreshContactThumbnail()
    }
    
    private func registerContactPresenceNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(onPresenceUpdate(notification:)), name: NSNotification.Name.mxkContactManagerMatrixUserPresenceChange, object: nil)
    }
    
    private func unregisterContactPresenceNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.mxkContactThumbnailUpdate, object: nil)
    }
    
    @objc private func onPresenceUpdate(notification: Notification) {
        guard let matrixId = notification.object as? String, matrixId == self.matrixId else {
            return
        }
        
        refreshContactPresence()
    }
}
