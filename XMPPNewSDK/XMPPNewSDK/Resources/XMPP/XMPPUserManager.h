//
//  XMPPUserManager.h
//  GoIDD
//
//  Created by CapanicusMacMini on 14/12/17.
//  Copyright © 2017 Lifeline Connect Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPFramework/XMPPFramework.h>
#import "XMPPConnectionManager.h"

@interface XMPPUserManager : NSObject <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage   *xmppMessageArchivingCoreDataStorage;

+ (XMPPUserManager*) sharedManager;
- (NSManagedObjectContext*)xmppMessageNSManagedObjectContext;
- (void)sendUnsendMessages;
- (void)customArchiveMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing xmppStream:(XMPPStream *)xmppStream;
- (NSString*)encryptedString:(NSString*)message;
- (NSString*)decryptedString:(NSString*)message;
- (void) clearAllMessage : (NSString*)bareJidStr;

- (NSMutableArray*) getAllMediaArray:(NSString *)contactBareJidStr;
-(BOOL)IsDuplicateMessage:(NSString *)messageId;

@end
