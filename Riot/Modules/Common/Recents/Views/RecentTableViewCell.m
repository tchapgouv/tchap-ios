/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "RecentTableViewCell.h"

#import "AvatarGenerator.h"

#import "RiotDesignValues.h"

#import "MXRoomSummary+Riot.h"

#import "GeneratedInterface-Swift.h"

#pragma mark - Defines & Constants

static const CGFloat kDirectRoomBorderColorAlpha = 0.75;
static const CGFloat kDirectRoomBorderWidth = 3.0;

@interface RecentTableViewCell() <Stylable>
@property (nonatomic, strong) id<Style> currentStyle;
@end

@implementation RecentTableViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.currentStyle = Variant2Style.shared;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    [self updateWithStyle:self.currentStyle];
}

- (void)updateWithStyle:(id<Style>)style
{
    self.currentStyle = style;
    
    self.roomTitle.textColor = style.primaryTextColor;
    self.lastEventDescription.textColor = style.primarySubTextColor;
    self.lastEventDate.textColor = style.primarySubTextColor;
    self.missedNotifAndUnreadBadgeLabel.textColor = style.backgroundColor;
    
    self.roomAvatar.defaultBackgroundColor = [UIColor clearColor];
    
    self.pinView.backgroundColor = [UIColor clearColor];
    
    // TODO: remove this direct room border
    // Prepare direct room border
    CGColorRef directRoomBorderColor = CGColorCreateCopyWithAlpha(kRiotColorGreen.CGColor, kDirectRoomBorderColorAlpha);
    [self.directRoomBorderView.layer setCornerRadius:self.directRoomBorderView.frame.size.width / 2];
    self.directRoomBorderView.clipsToBounds = YES;
    self.directRoomBorderView.layer.borderColor = directRoomBorderColor;
    self.directRoomBorderView.layer.borderWidth = kDirectRoomBorderWidth;
    CFRelease(directRoomBorderColor);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    [_roomAvatar.layer setCornerRadius:_roomAvatar.frame.size.width / 2];
    _roomAvatar.clipsToBounds = YES;
    
    // Round unread badge corners
    [_missedNotifAndUnreadBadgeBgView.layer setCornerRadius:10];
    
    // Design the pinned room marker
    CAShapeLayer *pinViewMaskLayer = [[CAShapeLayer alloc] init];
    pinViewMaskLayer.frame = _pinView.bounds;
    
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, _pinView.frame.size.height)];
    [path addLineToPoint:CGPointMake(_pinView.frame.size.width, 0)];
    [path closePath];
    
    pinViewMaskLayer.path = path.CGPath;
    _pinView.layer.mask = pinViewMaskLayer;
}

- (void)render:(MXKCellData *)cellData
{
    // Hide by default missed notifications and unread widgets
    self.missedNotifAndUnreadIndicator.hidden = YES;
    self.missedNotifAndUnreadBadgeBgView.hidden = YES;
    self.missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = 0;
    
    roomCellData = (id<MXKRecentCellDataStoring>)cellData;
    if (roomCellData)
    {
        // Report computed values as is
        self.roomTitle.text = roomCellData.roomDisplayname;
        self.lastEventDate.text = roomCellData.lastEventDate;
        
        // Manage lastEventAttributedTextMessage optional property
        if ([roomCellData respondsToSelector:@selector(lastEventAttributedTextMessage)])
        {
            // Force the default text color for the last message (cancel highlighted message color)
            NSMutableAttributedString *lastEventDescription = [[NSMutableAttributedString alloc] initWithAttributedString:roomCellData.lastEventAttributedTextMessage];
            [lastEventDescription addAttribute:NSForegroundColorAttributeName value:kRiotSecondaryTextColor range:NSMakeRange(0, lastEventDescription.length)];
            self.lastEventDescription.attributedText = lastEventDescription;
        }
        else
        {
            self.lastEventDescription.text = roomCellData.lastEventTextMessage;
        }
        
        // Notify unreads and bing
        if (roomCellData.hasUnread)
        {
            self.missedNotifAndUnreadIndicator.hidden = NO;
            
            if (0 < roomCellData.notificationCount)
            {
                self.missedNotifAndUnreadIndicator.backgroundColor = roomCellData.highlightCount ? kRiotColorPinkRed : kRiotColorGreen;
                
                self.missedNotifAndUnreadBadgeBgView.hidden = NO;
                self.missedNotifAndUnreadBadgeBgView.backgroundColor = self.missedNotifAndUnreadIndicator.backgroundColor;
                
                self.missedNotifAndUnreadBadgeLabel.text = roomCellData.notificationCountStringValue;
                [self.missedNotifAndUnreadBadgeLabel sizeToFit];
                
                self.missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = self.missedNotifAndUnreadBadgeLabel.frame.size.width + 18;
            }
            else
            {
                self.missedNotifAndUnreadIndicator.backgroundColor = kRiotAuxiliaryColor;
            }
            
            // Use bold font for the room title
            if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
            {
                self.roomTitle.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
            }
            else
            {
                self.roomTitle.font = [UIFont boldSystemFontOfSize:17];
            }
        }
        else
        {
            self.lastEventDate.textColor = kRiotSecondaryTextColor;
            
            // The room title is not bold anymore
            if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
            {
                self.roomTitle.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
            }
            else
            {
                self.roomTitle.font = [UIFont systemFontOfSize:17];
            }
        }
        
        self.directRoomBorderView.hidden = !roomCellData.roomSummary.room.isDirect;

        self.encryptedRoomIcon.hidden = !roomCellData.roomSummary.isEncrypted;

        [roomCellData.roomSummary setRoomAvatarImageIn:self.roomAvatar];
    }
    else
    {
        self.lastEventDescription.text = @"";
    }
    
    // Check whether the room is pinned
    if (roomCellData.roomSummary.room.accountData.tags[kMXRoomTagFavourite])
    {
        _pinView.backgroundColor = self.currentStyle.buttonBorderedBackgroundColor;
    }
    else
    {
        _pinView.backgroundColor = [UIColor clearColor];
    }
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 74;
}

@end
