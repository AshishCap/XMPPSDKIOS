//
//  ChatMessages.h
//  GoIDD
//
//  Created by apple on 20/06/17.
//  Copyright © 2017 GoIDD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPFramework/XMPPFramework.h>
#import "ChatMessageHistory.h"

@interface ChatMessages : NSObject

@property (nonatomic, strong) XMPPJID * bareJid;      // Transient (proper type, not on disk)
@property (nonatomic, strong) NSString * bareJidStr;  // Shadow (binary data, written to disk)

@property (nonatomic, strong) NSString * body;
@property (nonatomic, strong) NSString * thread;

@property (nonatomic, strong) NSNumber * outgoing;    // Use isOutgoing
@property (nonatomic, assign) BOOL isOutgoing;        // Convenience property

@property (nonatomic, strong) NSNumber * composing;   // Use isComposing
@property (nonatomic, assign) BOOL isComposing;       // Convenience property

@property (nonatomic, strong) NSDate * timestamp;

@property (nonatomic, strong) NSString * streamBareJidStr;
@property (nonatomic, strong) ChatMessageHistory * chatBody;

- (id) init:(XMPPJID*)bareJid bareJidStr:(NSString*)bareJidStr body:(NSString*)body thread:(NSString*)thread isOutgoing:(BOOL)isOutgoing timestamp: (NSDate*)timestamp streamBareJidStr:(NSString*)streamBareJidStr chatBody:(ChatMessageHistory*)chatBody;
@end
