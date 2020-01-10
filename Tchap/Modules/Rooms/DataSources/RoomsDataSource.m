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

#import "RoomsDataSource.h"

#import "RecentCellData.h"

#import "DesignValues.h"

#import "MXRoom+Riot.h"

#import "GeneratedInterface-Swift.h"

#define ROOMSDATASOURCE_SECTION_INVITES       0x02
#define ROOMSDATASOURCE_SECTION_CONVERSATIONS 0x04

#define ROOMSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT     30.0

@interface RoomsDataSource() <KeyBackupBannerCellDelegate>
{
    NSMutableArray* invitesCellDataArray;
    NSMutableArray* conversationCellDataArray;
    
    NSInteger shrinkedSectionsBitMask;
    
    UIView *directorySectionContainer;
    UILabel *networkLabel;
    UILabel *directoryServerLabel;
    
    NSMutableDictionary<NSString*, id> *roomTagsListenerByUserId;
}

@property (nonatomic, assign, readwrite) KeyBackupBanner keyBackupBanner;

@end

@implementation RoomsDataSource
@synthesize invitesSection, conversationSection, keyBackupBannerSection;
@synthesize invitesCellDataArray, conversationCellDataArray;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        invitesCellDataArray = [[NSMutableArray alloc] init];
        conversationCellDataArray = [[NSMutableArray alloc] init];
        
        _keyBackupBanner = KeyBackupBannerNone;
        keyBackupBannerSection = -1;
        invitesSection = -1;
        conversationSection = -1;
        
        _areSectionsShrinkable = NO;
        shrinkedSectionsBitMask = 0;
        
        roomTagsListenerByUserId = [[NSMutableDictionary alloc] init];
        
        // Set default data and view classes
        [self registerCellDataClass:RecentCellData.class forCellIdentifier:kMXKRecentCellIdentifier];
    }
    return self;
}

#pragma mark -

- (UIView *)viewForStickyHeaderInSection:(NSInteger)section withFrame:(CGRect)frame
{
    UIView *stickyHeader;
    
    NSInteger savedShrinkedSectionsBitMask = shrinkedSectionsBitMask;
    
    stickyHeader = [self viewForHeaderInSection:section withFrame:frame];
    
    shrinkedSectionsBitMask = savedShrinkedSectionsBitMask;
    
    return stickyHeader;
}

#pragma mark - Key backup setup banner

- (void)registerKeyBackupStateDidChangeNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBackupStateDidChangeNotification:) name:kMXKeyBackupDidStateChangeNotification object:nil];
    [self keyBackupStateDidChangeNotification:nil];
    
    // Check homeserver update in background
    [self.mxSession.crypto.backup forceRefresh:nil failure:nil];
}

- (void)unregisterKeyBackupStateDidChangeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKeyBackupDidStateChangeNotification object:nil];
}

- (void)keyBackupStateDidChangeNotification:(NSNotification*)notification
{
    if ([self updateKeyBackupBanner])
    {
        [self forceRefresh];
    }
}

- (BOOL)updateKeyBackupBanner
{
    KeyBackupBanner keyBackupBanner = KeyBackupBannerNone;
    
    // Tchap: display the banner even if there is no new key to backup, in order to let the user recover an existing
    // backup (if any)
    //if (self.mxSession.crypto.backup.hasKeysToBackup)
    {
        KeyBackupBannerPreferences *keyBackupBannersPreferences = KeyBackupBannerPreferences.shared;
        
        NSString *keyBackupVersion = self.mxSession.crypto.backup.keyBackupVersion.version;
        
        switch (self.mxSession.crypto.backup.state) {
            case MXKeyBackupStateDisabled:
                // Show key backup setup banner only if user has not hidden it once.
                if (keyBackupBannersPreferences.hideSetupBanner)
                {
                    keyBackupBanner = KeyBackupBannerNone;
                }
                else
                {
                    keyBackupBanner = KeyBackupBannerSetup;
                }
                break;
            case MXKeyBackupStateNotTrusted:
            case MXKeyBackupStateWrongBackUpVersion:
                // Show key backup recover banner only if user has not hidden it for the given version.
                if (keyBackupVersion && [keyBackupBannersPreferences isRecoverBannerHiddenFor:keyBackupVersion])
                {
                    keyBackupBanner = KeyBackupBannerNone;
                }
                else
                {
                    keyBackupBanner = KeyBackupBannerRecover;
                }
                break;
            default:
                keyBackupBanner = KeyBackupBannerNone;
                break;
        }
    }
    
    BOOL updated = (self.keyBackupBanner != keyBackupBanner);
    
    self.keyBackupBanner = keyBackupBanner;
    
    return updated;
}

- (void)hideKeyBackupBanner:(KeyBackupBanner)keyBackupBanner
{
    KeyBackupBannerPreferences *keyBackupBannersPreferences = KeyBackupBannerPreferences.shared;
    
    switch (keyBackupBanner) {
        case KeyBackupBannerSetup:
            keyBackupBannersPreferences.hideSetupBanner = YES;
            break;
        case KeyBackupBannerRecover:
        {
            NSString *keyBackupVersion = self.mxSession.crypto.backup.keyBackupVersion.version;
            if (keyBackupVersion)
            {
                [keyBackupBannersPreferences hideRecoverBannerFor:keyBackupVersion];
            }
        }
            break;
        default:
            break;
    }
    
    [self updateKeyBackupBanner];
    [self forceRefresh];
}


#pragma mark -

- (MXKSessionRecentsDataSource *)addMatrixSession:(MXSession *)mxSession
{
    MXKSessionRecentsDataSource *recentsDataSource = [super addMatrixSession:mxSession];
    
    return recentsDataSource;
}

- (void)removeMatrixSession:(MXSession*)matrixSession
{
    [super removeMatrixSession:matrixSession];
    
    // sanity check
    if (matrixSession.myUser && matrixSession.myUser.userId)
    {
        id roomTagListener = [roomTagsListenerByUserId objectForKey:matrixSession.myUser.userId];
        
        if (roomTagListener)
        {
            [matrixSession removeListener:roomTagListener];
            [roomTagsListenerByUserId removeObjectForKey:matrixSession.myUser.userId];
        }
    }
}

- (void)dataSource:(MXKDataSource*)dataSource didStateChange:(MXKDataSourceState)aState
{
    [super dataSource:dataSource didStateChange:aState];
    
    if ((aState == MXKDataSourceStateReady) && dataSource.mxSession.myUser.userId)
    {
        // Register the room tags updates to refresh the favorites order
        id roomTagsListener = [dataSource.mxSession listenToEventsOfTypes:@[kMXEventTypeStringRoomTag]
                                                                  onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {
                                                                      
                                                                      // Consider only live event
                                                                      if (direction == MXTimelineDirectionForwards)
                                                                      {
                                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                                              
                                                                              [self forceRefresh];
                                                                              
                                                                          });
                                                                      }
                                                                      
                                                                  }];
        
        [roomTagsListenerByUserId setObject:roomTagsListener forKey:dataSource.mxSession.myUser.userId];
    }
}

- (void)forceRefresh
{
    [self refreshRoomsSections];
    
    // And inform the delegate about the update
    [self.delegate dataSource:self didCellChange:nil];
}

- (void)didMXSessionInviteRoomUpdate:(NSNotification *)notif
{
    MXSession *mxSession = notif.object;
    if ([self.mxSessions indexOfObject:mxSession] != NSNotFound)
    {
        [self forceRefresh];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionsCount = 0;
    
    // Check whether all data sources are ready before rendering recents
    if (self.state == MXKDataSourceStateReady)
    {
        keyBackupBannerSection = conversationSection = invitesSection = -1;
        
        if (self.keyBackupBanner != KeyBackupBannerNone)
        {
            self.keyBackupBannerSection = sectionsCount++;
        }
        
        if (invitesCellDataArray.count > 0)
        {
            invitesSection = sectionsCount++;
        }
        
        // Keep visible the main rooms section even if it is empty
        conversationSection = sectionsCount++;                
    }
    
    return sectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = 0;
    
    if (section == self.keyBackupBannerSection && self.keyBackupBanner != KeyBackupBannerNone)
    {
        count = 1;
    }
    else if (section == conversationSection && !(shrinkedSectionsBitMask & ROOMSDATASOURCE_SECTION_CONVERSATIONS))
    {
        count = conversationCellDataArray.count ? conversationCellDataArray.count : 1;
    }
    else if (section == invitesSection && !(shrinkedSectionsBitMask & ROOMSDATASOURCE_SECTION_INVITES))
    {
        count = invitesCellDataArray.count;
    }
    
    return count;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section
{
    if (section == self.keyBackupBannerSection)
    {
        return 0.0;
    }
    
    return ROOMSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT;
}

- (NSAttributedString *)attributedStringForHeaderTitleInSection:(NSInteger)section
{
    NSAttributedString *sectionTitle;
    NSString *title;
    NSUInteger count = 0;
    
    if (section == conversationSection)
    {
        count = conversationCellDataArray.count;
        
        title = NSLocalizedStringFromTable(@"conversations_main_section", @"Tchap", nil);
    }
    else if (section == invitesSection)
    {
        count = invitesCellDataArray.count;
        
        title = NSLocalizedStringFromTable(@"conversations_invites_section", @"Tchap", nil);
    }
    
    if (count)
    {
        NSString *roomCount = [NSString stringWithFormat:@"   %tu", count];
        
        NSMutableAttributedString *mutableSectionTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                                attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.headerTextPrimaryColor,
                                                                                                             NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0]}];
        [mutableSectionTitle appendAttributedString:[[NSMutableAttributedString alloc] initWithString:roomCount
                                                                                           attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.headerTextSecondaryColor,
                                                                                                        NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0]}]];
        
        sectionTitle = mutableSectionTitle;
    }
    else if (title)
    {
        sectionTitle = [[NSAttributedString alloc] initWithString:title
                                                       attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.headerTextPrimaryColor,
                                                                    NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0]}];
    }
    
    return sectionTitle;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame
{
    // No header view in key backup banner section
    if (section == self.keyBackupBannerSection)
    {
        return nil;
    }
    
    UIView *sectionHeader = [[UIView alloc] initWithFrame:frame];
    sectionHeader.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    NSInteger sectionBitwise = 0;
    UIImageView *chevronView;
    UIView *accessoryView;
    
    if (_areSectionsShrinkable)
    {
        if (section == conversationSection)
        {
            sectionBitwise = ROOMSDATASOURCE_SECTION_CONVERSATIONS;
        }
        else if (section == invitesSection)
        {
            sectionBitwise = ROOMSDATASOURCE_SECTION_INVITES;
        }
    }
    
    if (sectionBitwise)
    {
        // Add shrink button
        UIButton *shrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        frame.origin.x = frame.origin.y = 0;
        shrinkButton.frame = frame;
        shrinkButton.backgroundColor = [UIColor clearColor];
        [shrinkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        shrinkButton.tag = sectionBitwise;
        [sectionHeader addSubview:shrinkButton];
        sectionHeader.userInteractionEnabled = YES;
        
        // Add shrink icon
        UIImage *chevron;
        if (shrinkedSectionsBitMask & sectionBitwise)
        {
            chevron = [UIImage imageNamed:@"disclosure_icon"];
        }
        else
        {
            chevron = [UIImage imageNamed:@"shrink_icon"];
        }
        chevronView = [[UIImageView alloc] initWithImage:chevron];
        chevronView.contentMode = UIViewContentModeCenter;
        frame = chevronView.frame;
        frame.origin.x = sectionHeader.frame.size.width - frame.size.width - 16;
        frame.origin.y = (sectionHeader.frame.size.height - frame.size.height) / 2;
        chevronView.frame = frame;
        [sectionHeader addSubview:chevronView];
        chevronView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
        
        accessoryView = chevronView;
    }
    
    // Add label
    frame = sectionHeader.frame;
    frame.origin.x = 20;
    frame.origin.y = 5;
    frame.size.width = accessoryView ? accessoryView.frame.origin.x - 10 : sectionHeader.frame.size.width - 10;
    frame.size.height = ROOMSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT - 10;
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.attributedText = [self attributedStringForHeaderTitleInSection:section];
    [sectionHeader addSubview:headerLabel];
    
    return sectionHeader;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == self.keyBackupBannerSection)
    {
        KeyBackupBannerCell* keyBackupBannerCell = [tableView dequeueReusableCellWithIdentifier:KeyBackupBannerCell.defaultReuseIdentifier forIndexPath:indexPath];
        [keyBackupBannerCell configureFor:self.keyBackupBanner];
        keyBackupBannerCell.delegate = self;
        return keyBackupBannerCell;
    }
    else if (indexPath.section == conversationSection && !conversationCellDataArray.count)
    {
        MXKTableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
        if (!tableViewCell)
        {
            tableViewCell = [[MXKTableViewCell alloc] init];
            tableViewCell.textLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
            tableViewCell.textLabel.font = [UIFont systemFontOfSize:15.0];
            tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        // Check whether a search session is in progress
        if (self.searchPatternsList)
        {
            tableViewCell.textLabel.text = NSLocalizedStringFromTable(@"search_no_result", @"Tchap", nil);
        }
        else
        {
            tableViewCell.textLabel.text = NSLocalizedStringFromTable(@"conversations_no_conversation", @"Tchap", nil);
        }
        
        return tableViewCell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (id<MXKRecentCellDataStoring>)cellDataAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKRecentCellDataStoring> cellData = nil;
    NSUInteger cellDataIndex = indexPath.row;
    NSInteger tableSection = indexPath.section;
    
    if (tableSection== conversationSection)
    {
        if (cellDataIndex < conversationCellDataArray.count)
        {
            cellData = [conversationCellDataArray objectAtIndex:cellDataIndex];
        }
    }
    else if (tableSection == invitesSection)
    {
        if (cellDataIndex < invitesCellDataArray.count)
        {
            cellData = [invitesCellDataArray objectAtIndex:cellDataIndex];
        }
    }
    
    return cellData;
}

- (CGFloat)cellHeightAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == conversationSection && !conversationCellDataArray.count)
    {
        return 50.0;
    }
    
    // Override this method here to use our own cellDataAtIndexPath
    id<MXKRecentCellDataStoring> cellData = [self cellDataAtIndexPath:indexPath];
    
    if (cellData && self.delegate)
    {
        Class<MXKCellRendering> class = [self.delegate cellViewClassForCellData:cellData];
        
        return [class heightForCellData:cellData withMaximumWidth:0];
    }
    
    return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Invited rooms are not editable.
    return (indexPath.section != invitesSection);
}

#pragma mark -

- (NSInteger)cellIndexPosWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)matrixSession within:(NSMutableArray*)cellDataArray
{
    if (roomId && matrixSession && cellDataArray.count)
    {
        for (int index = 0; index < cellDataArray.count; index++)
        {
            id<MXKRecentCellDataStoring> cellDataStoring = [cellDataArray objectAtIndex:index];
            
            if ([roomId isEqualToString:cellDataStoring.roomSummary.roomId] && (matrixSession == cellDataStoring.roomSummary.room.mxSession))
            {
                return index;
            }
        }
    }
    
    return NSNotFound;
}

- (NSIndexPath*)cellIndexPathWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)matrixSession
{
    NSIndexPath *indexPath = nil;
    NSInteger index;
    
    if (invitesSection >= 0)
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:invitesCellDataArray];
        
        if (index != NSNotFound)
        {
            // Check whether the invitations are shrinked
            if (shrinkedSectionsBitMask & ROOMSDATASOURCE_SECTION_INVITES)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:invitesSection];
        }
    }
    
    if (!indexPath && (conversationSection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:conversationCellDataArray];
        
        if (index != NSNotFound)
        {
            // Check whether the conversations are shrinked
            if (shrinkedSectionsBitMask & ROOMSDATASOURCE_SECTION_CONVERSATIONS)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:conversationSection];
        }
    }
    
    return indexPath;
}


#pragma mark - MXKDataSourceDelegate

- (void)refreshRoomsSections
{
    [invitesCellDataArray removeAllObjects];
    [conversationCellDataArray removeAllObjects];
    
    _missedConversationsCount = _missedHighlightConversationsCount = 0;
    
    keyBackupBannerSection = conversationSection = invitesSection = -1;
    
    if (displayedRecentsDataSourceArray.count > 0)
    {
        // FIXME manage multi accounts
        MXKSessionRecentsDataSource *recentsDataSource = [displayedRecentsDataSourceArray objectAtIndex:0];
        
        NSInteger count = recentsDataSource.numberOfCells;
        NSInteger pinnedRoomIndex = 0;
        
        for (int index = 0; index < count; index++)
        {
            id<MXKRecentCellDataStoring> recentCellDataStoring = [recentsDataSource cellDataAtIndex:index];
            MXRoom* room = recentCellDataStoring.roomSummary.room;
            
            // Hide the rooms created to invite some non-tchap contact by email.
            if (room.isDirect && [MXTools isEmailAddress:room.directUserId])
            {
                continue;
            }
            
            // Keep only the invites, the favourites and the rooms without tag
            if (room.summary.membership == MXMembershipInvite)
            {
                [invitesCellDataArray addObject:recentCellDataStoring];
            }
            else if (room.accountData.tags[kMXRoomTagFavourite])
            {
                // Display in first possition the pinned (favorites) rooms
                [conversationCellDataArray insertObject:recentCellDataStoring atIndex:pinnedRoomIndex++];
            }
            else
            {
                [conversationCellDataArray addObject:recentCellDataStoring];
            }
            
            // Update missed conversations counts
            NSUInteger notificationCount = recentCellDataStoring.roomSummary.notificationCount;
            
            // Ignore the regular notification count if the room is in 'mentions only" mode at the Riot level.
            if (room.isMentionsOnly)
            {
                // Only the highlighted missed messages must be considered here.
                notificationCount = recentCellDataStoring.roomSummary.highlightCount;
            }
            
            if (notificationCount)
            {
                _missedConversationsCount ++;
                
                if (recentCellDataStoring.roomSummary.highlightCount)
                {
                    _missedHighlightConversationsCount ++;
                }
            }
            else if (room.summary.membership == MXMembershipInvite)
            {
                _missedConversationsCount ++;
            }
        }
    }
}

- (void)dataSource:(MXKDataSource*)dataSource didCellChange:(id)changes
{
    // FIXME : manage multi accounts
    // to manage multi accounts
    // this method in MXKInterleavedRecentsDataSource must be split in two parts
    // 1 - the intervealing cells method
    // 2 - [super dataSource:dataSource didCellChange:changes] call.
    // the [self refreshRoomsSections] call should be done at the end of the 1- method
    // so a dedicated method must be implemented in MXKInterleavedRecentsDataSource
    // this class will inherit of this new method
    // 1 - call [super thisNewMethod]
    // 2 - call [self refreshRoomsSections]
    
    // refresh the sections
    [self refreshRoomsSections];
    
    // Call super to keep update readyRecentsDataSourceArray.
    [super dataSource:dataSource didCellChange:changes];
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *shrinkButton = (UIButton*)sender;
        NSInteger selectedSectionBit = shrinkButton.tag;
        
        if (shrinkedSectionsBitMask & selectedSectionBit)
        {
            // Disclose the section
            shrinkedSectionsBitMask &= ~selectedSectionBit;
        }
        else
        {
            // Shrink this section
            shrinkedSectionsBitMask |= selectedSectionBit;
        }
        
        // Inform the delegate about the update
        [self.delegate dataSource:self didCellChange:nil];
    }
}

#pragma mark - KeyBackupSetupBannerCellDelegate

- (void)keyBackupBannerCellDidTapCloseAction:(KeyBackupBannerCell * _Nonnull)cell
{
    [self hideKeyBackupBanner:self.keyBackupBanner];
}

@end
