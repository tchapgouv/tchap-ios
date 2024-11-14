/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>
#import <MatrixSDK/MatrixSDK.h>

@interface Tools : NSObject

/**
 Compute the text to display user's presence
 
 @param user the user. Can be nil.
 @return the string to display.
 */
+ (NSString*)presenceText:(MXUser*)user;

#pragma mark - Universal link

/**
 @return YES if the URL is a Tchap permalink.
 */
+ (BOOL)isPermaLink:(NSURL*)url;

/**
 Detect if a URL is a universal link for the application.

 @return YES if the URL can be handled by the app.
 */
+ (BOOL)isUniversalLink:(NSURL*)url;

/**
 Fix a http path url.

 This method fixes the issue with iOS which handles URL badly when there are several hash
 keys ('%23') in the link.
 Vector.im links have often several hash keys...

 @param url a NSURL with possibly several hash keys and thus badly parsed.
 @return a NSURL correctly parsed.
 */
+ (NSURL*)fixURLWithSeveralHashKeys:(NSURL*)url;

#pragma mark - Time utilities

/**
 * Convert a number of days to a duration in ms.
 */
+ (uint64_t)durationInMsFromDays:(uint)days;

#pragma mark - Tchap permalink

/*
 Return a permalink to a room.
 
 @param roomIdOrAlias the id or the alias of the room to link to.
 @return the Tchap permalink.
 */
+ (NSString*)permalinkToRoom:(NSString*)roomIdOrAlias;


/*
 Return a permalink to a room which has no alias.
 
 @param roomState the RoomState of the room, containing the roomId and the room members necessary to build the permalink.
 @return the Tchap permalink.
 */
+ (NSString *)permalinkToRoomWithoutAliasFromRoomState:(MXRoomState *)roomState;


/*
 Return a permalink to an event.
 
 @param eventId the id of the event to link to.
 @param roomIdOrAlias the room the event belongs to.
 @return the Tchap permalink.
 */
+ (NSString*)permalinkToEvent:(NSString*)eventId inRoom:(NSString*)roomIdOrAlias;



@end
