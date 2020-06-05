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

#import "RoomAttachmentAntivirusScanStatusBubbleCell.h"

#import "RoomBubbleCellData.h"
#import "GeneratedInterface-Swift.h"

@interface RoomAttachmentAntivirusScanStatusBubbleCell()

@property (weak, nonatomic) IBOutlet RoomAttachmentAntivirusScanStatusCellContentView *roomAttachmentAntivirusScanStatusCellContentView;

@property (nonatomic, strong) RoomAttachmentAntivirusScanStatusViewModelBuilder *roomAttachmentAntivirusScanStatusViewModelBuilder;

@end

@implementation RoomAttachmentAntivirusScanStatusBubbleCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (!self.roomAttachmentAntivirusScanStatusViewModelBuilder)
    {
        self.roomAttachmentAntivirusScanStatusViewModelBuilder = [RoomAttachmentAntivirusScanStatusViewModelBuilder new];
    }
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (bubbleData)
    {
        RoomAttachmentAntivirusScanStatusViewModel *roomAttachmentAntivirusScanStatusViewModel = [self.roomAttachmentAntivirusScanStatusViewModelBuilder viewModelFrom: bubbleData];
        
        if (roomAttachmentAntivirusScanStatusViewModel)
        {
            [self.roomAttachmentAntivirusScanStatusCellContentView fillWith:roomAttachmentAntivirusScanStatusViewModel];
        }
    }
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    static RoomAttachmentAntivirusScanStatusBubbleCell *cell;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cell = [RoomAttachmentAntivirusScanStatusBubbleCell new];
    });
    
    [cell render:cellData];
    [cell layoutIfNeeded];
    
    CGSize fittingSize = UILayoutFittingCompressedSize;
    fittingSize.width = maxWidth;
    
    return [cell systemLayoutSizeFittingSize:fittingSize].height;
}

@end
