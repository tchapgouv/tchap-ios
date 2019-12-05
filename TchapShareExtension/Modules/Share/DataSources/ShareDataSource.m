/*
 Copyright 2017 Vector Creations Ltd
 Copyright 2019 New Vector Ltd
 
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

#import "ShareDataSource.h"
#import "ShareExtensionManager.h"

@interface ShareDataSource ()

@property (nonatomic, readwrite) ShareDataSourceMode dataSourceMode;

@property NSArray <MXKRecentCellData *> *recentCellDatas;
@property NSMutableArray <MXKRecentCellData *> *visibleRoomCellDatas;

@end

@implementation ShareDataSource

- (instancetype)initWithMode:(ShareDataSourceMode)dataSourceMode
{
    self = [super init];
    if (self)
    {
        self.dataSourceMode = dataSourceMode;
        
        [self loadCellData];
    }
    return self;
}

- (void)destroy
{
    [super destroy];
    
    _recentCellDatas = nil;
    _visibleRoomCellDatas = nil;
}

#pragma mark - Private
     
- (void)loadCellData
{
    [[ShareExtensionManager sharedManager].fileStore asyncRoomsSummaries:^(NSArray<MXRoomSummary *> * _Nonnull roomsSummaries) {
        
        NSMutableArray *cellData = [NSMutableArray array];
        
        // Add a fake matrix session to each room summary to provide it a REST client (used to handle correctly the room avatar).
        MXSession *session = [[MXSession alloc] initWithMatrixRestClient:[[MXRestClient alloc] initWithCredentials:[ShareExtensionManager sharedManager].userAccount.mxCredentials andOnUnrecognizedCertificateBlock:nil]];
        
        for (MXRoomSummary *roomSummary in roomsSummaries)
        {
            if (!roomSummary.hiddenFromUser
                && ((self.dataSourceMode == DataSourceModeRooms) ^ roomSummary.isDirect)
                && roomSummary.membership != MXMembershipInvite)
            {
                // Hide the rooms created to invite some non-tchap contact by email.
                if (roomSummary.isDirect && [MXTools isEmailAddress:roomSummary.directUserId])
                {
                    continue;
                }
                
                [roomSummary setMatrixSession:session];
                MXKRecentCellData *recentCellData = [[MXKRecentCellData alloc] initWithRoomSummary:roomSummary andRecentListDataSource:nil];
                [cellData addObject:recentCellData];
            }
        }
        
        // Sort rooms in alphabetic order
        NSComparator comparator = ^NSComparisonResult(MXKRecentCellData *recentCellData1, MXKRecentCellData *recentCellData2) {
            
            // Then order by name
            if (recentCellData1.roomDisplayname.length && recentCellData2.roomDisplayname.length)
            {
                return [recentCellData1.roomDisplayname compare:recentCellData2.roomDisplayname options:NSCaseInsensitiveSearch];
            }
            else if (recentCellData1.roomDisplayname.length)
            {
                return NSOrderedAscending;
            }
            else if (recentCellData2.roomDisplayname.length)
            {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        };
        [cellData sortUsingComparator:comparator];
        
        self.recentCellDatas = cellData;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.delegate dataSource:self didCellChange:nil];
            
        });
        
    } failure:^(NSError * _Nonnull error) {
        
        NSLog(@"[ShareDataSource failed to get room summaries]");
        
    }];
}

#pragma mark - MXKRecentsDataSource

- (MXKRecentCellData *)cellDataAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.visibleRoomCellDatas)
    {
        return self.visibleRoomCellDatas[indexPath.row];
    }
    return self.recentCellDatas[indexPath.row];
}

- (void)searchWithPatterns:(NSArray *)patternsList
{
    if (self.visibleRoomCellDatas)
    {
        [self.visibleRoomCellDatas removeAllObjects];
    }
    else
    {
        self.visibleRoomCellDatas = [NSMutableArray arrayWithCapacity:self.recentCellDatas.count];
    }
    if (patternsList.count)
    {
        for (MXKRecentCellData *cellData in self.recentCellDatas)
        {
            for (NSString* pattern in patternsList)
            {
                if (cellData.roomSummary.displayname && [cellData.roomSummary.displayname rangeOfString:pattern options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    [self.visibleRoomCellDatas addObject:cellData];
                    break;
                }
            }
        }
    }
    else
    {
        self.visibleRoomCellDatas = nil;
    }
    [self.delegate dataSource:self didCellChange:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.visibleRoomCellDatas)
    {
        return self.visibleRoomCellDatas.count;
    }
    return self.recentCellDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKRecentCellDataStoring> roomData = [self cellDataAtIndexPath:indexPath];
    if (roomData && self.delegate)
    {
        NSString *cellIdentifier = [self.delegate cellReuseIdentifierForCellData:roomData];
        if (cellIdentifier)
        {
            UITableViewCell<MXKCellRendering> *cell  = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
            
            // Make the bubble display the data
            [cell render:roomData];
            
            return cell;
        }
    }
    
    // Return a fake cell to prevent app from crashing.
    return [[UITableViewCell alloc] init];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


@end
