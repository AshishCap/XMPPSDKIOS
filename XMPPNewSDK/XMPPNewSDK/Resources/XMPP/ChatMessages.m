//
//  ChatMessages.m
//  GoIDD
//
//  Created by apple on 20/06/17.
//  Copyright © 2017 GoIDD. All rights reserved.
//

#import "ChatMessages.h"


@implementation ChatMessages

- (id) init:(XMPPJID*)bareJid bareJidStr:(NSString*)bareJidStr body:(NSString*)body thread:(NSString*)thread isOutgoing:(BOOL)isOutgoing timestamp: (NSDate*)timestamp streamBareJidStr:(NSString*)streamBareJidStr
    chatBody:(ChatMessageHistory*)chatBody
{
    if (self=[super init])
    {
        self.bareJid = bareJid ;
        
        self.bareJidStr =[bareJidStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        self.body   = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        self.thread = [thread stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        self.isOutgoing         = isOutgoing;
        self.timestamp          = timestamp;
        self.streamBareJidStr   = streamBareJidStr;
        self.chatBody           = chatBody;
    }
    return self;
}

@end
