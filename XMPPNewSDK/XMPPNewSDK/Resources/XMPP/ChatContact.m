//
//  ChatContact.m
//  GoIDD
//
//  Created by apple on 20/06/17.
//  Copyright © 2017 GoIDD. All rights reserved.
//

#import "ChatContact.h"

@implementation ChatContact

- (id) init:(NSString*)bareJid bareJidStr:(NSString*)bareJidStr mostRecentMessageTimestamp:(NSDate*)mostRecentMessageTimestamp mostRecentMessageBody:(NSString*)mostRecentMessageBody mostRecentMessageOutgoing:(NSNumber*)mostRecentMessageOutgoing streamBareJidStr:(NSString*)streamBareJidStr groupName:(NSString*)groupName unreadCount:(NSString*)unreadCount groupImage:(NSString*)groupImage displayName:(NSString*)displayName
{
    if (self=[super init])
    {
        self.bareJid =[bareJid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        self.bareJidStr =[bareJidStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        self.mostRecentMessageTimestamp = mostRecentMessageTimestamp ;
        
        self.mostRecentMessageBody =[mostRecentMessageBody stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        self.mostRecentMessageOutgoing = mostRecentMessageOutgoing;
        
        self.streamBareJidStr =[streamBareJidStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
         self.groupName =[groupName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
         self.unreadCount =[unreadCount stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
         self.groupImage =[groupImage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.displayName = displayName;
    }
    return self;
}

@end
