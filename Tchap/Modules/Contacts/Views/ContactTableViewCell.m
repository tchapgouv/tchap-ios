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

#import "ContactTableViewCell.h"

#import <MatrixKit/MatrixKit.h>

#import "RiotDesignValues.h"

#import "AvatarGenerator.h"
#import "Tools.h"

//#import "NBPhoneNumberUtil.h"

@interface ContactTableViewCell()
{
    /**
     The observer of the presence for matrix user.
     */
    id mxPresenceObserver;
}
@end

@implementation ContactTableViewCell
@synthesize mxRoom, delegate;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Prepare the badge displayed on online contacts avatar.
    self.thumbnailBadgeView.backgroundColor = UIColorFromRGB(0x60ad0d);
    self.thumbnailBadgeView.layer.cornerRadius = self.thumbnailBadgeView.frame.size.width / 2;
    self.thumbnailBadgeView.layer.borderColor= [UIColor whiteColor].CGColor;
    self.thumbnailBadgeView.layer.borderWidth = 1.0;
    
    // Disable by default interactions defined in the cell
    // because we want [tableView didSelectRowAtIndexPath:] to be called
    self.thumbnailView.userInteractionEnabled = NO;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    // apply the vector colours
    self.contactDisplayNameLabel.textColor = kRiotPrimaryTextColor;
    self.contactInformationLabel.textColor = kRiotSecondaryTextColor;
    
    // Clear the default background color of a MXKImageView instance
    self.thumbnailView.defaultBackgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    self.thumbnailView.layer.cornerRadius = self.thumbnailView.frame.size.width / 2;
    self.thumbnailView.clipsToBounds = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    // Restore default values
    self.contentView.alpha = 1;
    self.userInteractionEnabled = YES;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessoryView = nil;
}

- (void)setShowCustomAccessoryView:(BOOL)show
{
    _showCustomAccessoryView = show;
    
    if (show)
    {
        self.customAccessViewWidthConstraint.constant = 25;
        self.customAccessoryViewLeadingConstraint.constant = 13;
    }
    else
    {
        self.customAccessViewWidthConstraint.constant = 0;
        self.customAccessoryViewLeadingConstraint.constant = 0;
    }
}

#pragma mark - MXKCellRendering

// returns the first matrix id of the contact
// nil if there is none
- (NSString*)firstMatrixId
{
    NSString* matrixId = nil;
    
    if (contact.matrixIdentifiers.count > 0)
    {
        matrixId = contact.matrixIdentifiers.firstObject;
    }
    
    return matrixId;
}

- (void)render:(MXKCellData *)cellData
{
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (mxPresenceObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxPresenceObserver];
        mxPresenceObserver = nil;
    }
    
    self.thumbnailBadgeView.hidden = YES;
    
    // Sanity check: accept only object of MXKContact classes or sub-classes
    NSParameterAssert([cellData isKindOfClass:[MXKContact class]]);
    contact = (MXKContact*)cellData;
    
    // sanity check
    // should never happen
    if (!contact)
    {
        self.thumbnailView.image = nil;
        self.contactDisplayNameLabel.text = nil;
        self.contactInformationLabel.text = nil;
        
        return;
    }
    
    // Be warned when the thumbnail is updated
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onThumbnailUpdate:) name:kMXKContactThumbnailUpdateNotification object:nil];
    
    [self refreshContactThumbnail];
    
    [self refreshContactDisplayName];
    
    if (contact.matrixIdentifiers.count)
    {
        // The sub label is not used for Tchap users
        self.contactInformationLabel.hidden = YES;
        
        // Observe contact presence change
        mxPresenceObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKContactManagerMatrixUserPresenceChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            NSString* matrixId = self.firstMatrixId;
            
            if (matrixId && [matrixId isEqualToString:notif.object])
            {
                [self refreshContactPresence];
            }
        }];
        
        [self refreshContactPresence];
    }
    else
    {
        [self refreshLocalContactInformation];
    }
}

// @TODO: Remove this method required by `MXKCellRendering` protocol.
// The height must not be fixed to support dynamic fonts
+ (CGFloat)heightForCellData:(MXKCellData*)cellData withMaximumWidth:(CGFloat)maxWidth
{
    return 74;
}

- (void)didEndDisplay
{
    // remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (mxPresenceObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:mxPresenceObserver];
        mxPresenceObserver = nil;
    }
    
    // Remove all gesture recognizer
    while (self.thumbnailView.gestureRecognizers.count)
    {
        [self.thumbnailView removeGestureRecognizer:self.thumbnailView.gestureRecognizers[0]];
    }
    
    self.delegate = nil;
    contact = nil;
}

#pragma mark Refresh cell part

- (void)refreshContactThumbnail
{
    UIImage* image = [contact thumbnailWithPreferedSize:self.thumbnailView.frame.size];
    
    if (!image)
    {
        NSArray *identifiers = contact.matrixIdentifiers;
        
        if (identifiers.count)
        {
            image = [AvatarGenerator generateAvatarForMatrixItem:identifiers.firstObject withDisplayName:contact.displayName];
        }
        else if (contact.isThirdPartyInvite)
        {
            image = [AvatarGenerator generateAvatarForText:contact.displayName];
        }
        else if ((!contact.isMatrixContact && contact.phoneNumbers.count && !contact.emailAddresses.count))
        {
            image = [AvatarGenerator imageFromText:@"#" withBackgroundColor:kRiotColorGreen];
        }
        else
        {
            image = [AvatarGenerator imageFromText:@"@" withBackgroundColor:kRiotColorGreen];
        }
    }
    
    self.thumbnailView.image = image;
}

- (void)refreshContactDisplayName
{
    // @TODO extract the user "domain" from his display name, and display it on the right side
    self.contactDisplayNameLabel.text = contact.displayName;
}

- (void)refreshLocalContactInformation
{
    // We consider here the contact is not a Tchap user
    
    // Display the first contact method in sub label.
    NSString *subLabelText = nil;
    if (contact.emailAddresses.count)
    {
        MXKEmail* email = contact.emailAddresses.firstObject;
        subLabelText = email.emailAddress;
    }
    // We don't consider phone number FTM
//    else if (contact.phoneNumbers.count)
//    {
//        MXKPhoneNumber *phoneNumber = contact.phoneNumbers.firstObject;
//
//        if (phoneNumber.nbPhoneNumber)
//        {
//            subLabelText = [[NBPhoneNumberUtil sharedInstance] format:phoneNumber.nbPhoneNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:nil];
//        }
//        else
//        {
//            subLabelText = phoneNumber.textNumber;
//        }
//    }
    
    if (subLabelText.length)
    {
        self.contactInformationLabel.hidden = NO;
    }
    else
    {
        // Hide and fill the label with a fake string to harmonize the height of all the cells.
        // This is a drawback of the self-sizing cell.
        self.contactInformationLabel.hidden = YES;
        subLabelText = @"No method";
    }
    
    self.contactInformationLabel.text = subLabelText;
}

- (void)refreshContactPresence
{
    NSString* matrixId = self.firstMatrixId;
    if (matrixId)
    {
        MXUser *user = nil;
        
        // Consider here all sessions reported into contact manager
        NSArray* mxSessions = [MXKContactManager sharedManager].mxSessions;
        for (MXSession *mxSession in mxSessions)
        {
            user = [mxSession userWithUserId:matrixId];
            if (user)
            {
                break;
            }
        }

        if (user && user.presence == MXPresenceOnline)
        {
            self.thumbnailBadgeView.hidden = NO;
        }
        else
        {
            self.thumbnailBadgeView.hidden = YES;
        }
    }
}

#pragma mark - events

- (void)onThumbnailUpdate:(NSNotification *)notif
{
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]])
    {
        NSString* contactID = notif.object;
        
        if ([contactID isEqualToString:contact.contactID])
        {
            [self refreshContactThumbnail];
        }
    }
}

@end
