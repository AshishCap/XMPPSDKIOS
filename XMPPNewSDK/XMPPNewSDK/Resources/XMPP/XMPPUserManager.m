//
//  XMPPUserManager.m
//  GoIDD
//
//  Created by CapanicusMacMini on 13/12/17.
//  Copyright © 2017 Lifeline Connect Pty Ltd. All rights reserved.
//

#import "XMPPUserManager.h"
#import <CoreData/CoreData.h>
//#import "XMPPNewSDK-Swift.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"

@implementation XMPPUserManager

+ (XMPPUserManager *)sharedManager
{
    static XMPPUserManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[XMPPUserManager alloc] init];
    });
    return sharedInstance;
}

- (NSManagedObjectContext*)xmppMessageNSManagedObjectContext {
    if (self.xmppMessageArchivingCoreDataStorage == nil) {
        self.xmppMessageArchivingCoreDataStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
        return self.xmppMessageArchivingCoreDataStorage.mainThreadManagedObjectContext;
    }
    return self.xmppMessageArchivingCoreDataStorage.mainThreadManagedObjectContext;
}

/*------- Send Unsend message ------*/
- (void)sendUnsendMessages
{
    NSManagedObjectContext *moc = [self xmppMessageNSManagedObjectContext];
    NSEntityDescription *entity = [self.xmppMessageArchivingCoreDataStorage messageEntity:moc];
    NSString *messageStatus  =  @"0";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageStatus == %@",messageStatus];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray * arr  = [moc executeFetchRequest:fetchRequest error:&error];
    if (arr.count > 0)
    {
        double delayInSeconds = 0.0;
        for (int i = 0; i < arr.count ; i++)
        {
            XMPPMessageArchiving_Message_CoreDataObject * message = [arr objectAtIndex:i];
//            NSArray *arrMedia = [[MediaManager sharedInstance] getMediaWithMessageIdWithMessageId:message.message.elementID];
//            if (arrMedia.count > 0) {
//
//            } else {
//                delayInSeconds += 1.0;
//                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//                dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
//                               {
//                                   [[XMPPConnectionManager sharedManager] sendXmppMessage:message.message];
//                               });
//            }
        }
    }
}

- (void)customArchiveMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing xmppStream:(XMPPStream *)xmppStream
{
    // Message should either have a body, or be a composing notification
    
    NSString *messageBody = [[message elementForName:@"body"] stringValue];
    messageBody = [[XMPPUserManager sharedManager] decryptedString:messageBody];
    BOOL isComposing = NO;
    BOOL shouldDeleteComposingMessage = NO;
    
    if ([messageBody length] == 0)
    {
        // Message doesn't have a body.
        // Check to see if it has a chat state (composing, paused, etc).
        
        isComposing = [message hasComposingChatState];
        if (!isComposing)
        {
            if ([message hasChatState])
            {
                // Message has non-composing chat state.
                // So if there is a current composing message in the database,
                // then we need to delete it.
                shouldDeleteComposingMessage = YES;
            }
            else
            {
                // Message has no body and no chat state.
                // Nothing to do with it.
                return;
            }
        }
    }
    
    [self.xmppMessageArchivingCoreDataStorage scheduleBlock:^{
        
        NSManagedObjectContext *moc = [self.xmppMessageArchivingCoreDataStorage managedObjectContext];
        XMPPJID *myJid = [self.xmppMessageArchivingCoreDataStorage myJIDForXMPPStream:xmppStream];
        
        //XMPPJID *messageJid = isOutgoing ? [message to] : [message from];
        
        XMPPJID *messageJid;
        if (isOutgoing){
            if ([message isKindOfClass:[XMPPMessage class]])
            {
                messageJid = [message to];
            }
            else
            {
                XMPPJID * jid = [XMPPJID jidWithString:[[message attributeForName:@"to"] stringValue]];
                messageJid = jid;
            }
        }
        else
        {
            if ([message isKindOfClass:[XMPPMessage class]])
            {
                messageJid = [message from];
            }
            else
            {
                XMPPJID * jid = [XMPPJID jidWithString:[[message attributeForName:@"from"] stringValue]];
                messageJid = jid;
            }
        }
        
        // Fetch-n-Update OR Insert new message
        
        XMPPMessageArchiving_Message_CoreDataObject *archivedMessage =
        [self.xmppMessageArchivingCoreDataStorage composingMessageWithJid:messageJid
                            streamJid:myJid
                             outgoing:isOutgoing
                 managedObjectContext:moc];
        
        if (shouldDeleteComposingMessage)
        {
            if (archivedMessage)
            {
                [self.xmppMessageArchivingCoreDataStorage willDeleteMessage:archivedMessage]; // Override hook
                [moc deleteObject:archivedMessage];
            }
            else
            {
                // Composing message has already been deleted (or never existed)
            }
        }
        else
        {
            //XMPPLogVerbose(@"Previous archivedMessage: %@", archivedMessage);
            
            BOOL didCreateNewArchivedMessage = NO;
            if (archivedMessage == nil)
            {
                archivedMessage = (XMPPMessageArchiving_Message_CoreDataObject *)
                [[NSManagedObject alloc] initWithEntity:[self.xmppMessageArchivingCoreDataStorage messageEntity:moc]
                         insertIntoManagedObjectContext:nil];
                
                didCreateNewArchivedMessage = YES;
            }
            
            archivedMessage.message = message;
            archivedMessage.body = messageBody;
            //NSString *typeStr = [[message attributeForName:@"type"] stringValue];
            
            archivedMessage.bareJid = [messageJid bareJID];
            archivedMessage.streamBareJidStr = [myJid bare];
            
            NSDate *timestamp = [message delayedDeliveryDate];
            if (timestamp)
                archivedMessage.timestamp = timestamp;
            else
                archivedMessage.timestamp = [[NSDate alloc] init];
            
            archivedMessage.thread = [[message elementForName:@"thread"] stringValue];
            archivedMessage.isOutgoing = isOutgoing;
            archivedMessage.isComposing = isComposing;
            
            archivedMessage.messageId = [[message attributeForName:@"id"] stringValue];
//            NSLog(@"%@",[[message attributeForName:@"translation"] stringValue]);
//            NSLog(@"%@",[message elementsForName:@"translation"]);

            if (isOutgoing) {
                archivedMessage.messageStatus = @"0";
            } else {
                if ([[message fromStr] containsString:@"muclight.chat.goidd.com"]) {
                    NSArray *userNameArr = [[message fromStr] componentsSeparatedByString:@"/"];
                    if([userNameArr count] > 1)
                    {
                        NSString *groupSenderJidStr = [userNameArr objectAtIndex:1];
                        archivedMessage.groupSenderJidStr = groupSenderJidStr;
                    }
                }
            }
            
            //XMPPLogVerbose(@"New archivedMessage: %@", archivedMessage);
            
            if (didCreateNewArchivedMessage) // [archivedMessage isInserted] doesn't seem to work
            {
                //XMPPLogVerbose(@"Inserting message...");
                
                [archivedMessage willInsertObject];       // Override hook
                [self.xmppMessageArchivingCoreDataStorage willInsertMessage:archivedMessage]; // Override hook
                [moc insertObject:archivedMessage];
            }
            else
            {
                //XMPPLogVerbose(@"Updating message...");
                
                [archivedMessage didUpdateObject];       // Override hook
                [self.xmppMessageArchivingCoreDataStorage didUpdateMessage:archivedMessage]; // Override hook
            }
            
            // Create or update contact (if message with actual content)
            
            if ([messageBody length] > 0)
            {
                BOOL didCreateNewContact = NO;
                
                XMPPMessageArchiving_Contact_CoreDataObject *contact = [self.xmppMessageArchivingCoreDataStorage contactForMessage:archivedMessage];
                //XMPPLogVerbose(@"Previous contact: %@", contact);
                
                if (contact == nil)
                {
                    contact = (XMPPMessageArchiving_Contact_CoreDataObject *)
                    [[NSManagedObject alloc] initWithEntity:[self.xmppMessageArchivingCoreDataStorage contactEntity:moc]
                             insertIntoManagedObjectContext:nil];
                    
                    didCreateNewContact = YES;
                }
                
                contact.streamBareJidStr = archivedMessage.streamBareJidStr;
                contact.bareJid = archivedMessage.bareJid;
                
                contact.mostRecentMessageTimestamp = archivedMessage.timestamp;
//                if ([typeStr isEqualToString:@"card"])
//                {
//                    contact.mostRecentMessageBody = @"Card";
//                }
//                else
//                {
                    contact.mostRecentMessageBody = archivedMessage.body;
//                }
                
                contact.mostRecentMessageOutgoing = @(isOutgoing);
                
                if (isOutgoing) {
                    contact.unreadMessageCount = nil;
                } else {
                    contact.unreadMessageCount = [NSString stringWithFormat:@"%ld", [contact.unreadMessageCount.length > 0 ? contact.unreadMessageCount : @"0" integerValue] + 1];
                }
                
                //XMPPLogVerbose(@"New contact: %@", contact);
                
                if (didCreateNewContact) // [contact isInserted] doesn't seem to work
                {
                    //XMPPLogVerbose(@"Inserting contact...");
                    
                    [contact willInsertObject];       // Override hook
                    [self.xmppMessageArchivingCoreDataStorage willInsertContact:contact]; // Override hook
                    [moc insertObject:contact];
                }
                else
                {
                    //XMPPLogVerbose(@"Updating contact...");
                    
                    [contact didUpdateObject];       // Override hook
                    [self.xmppMessageArchivingCoreDataStorage didUpdateContact:contact]; // Override hook
                }
            }
        }
    }];
}

- (NSString*)encryptedString:(NSString*)message
{
    NSError *error;
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [RNEncryptor encryptData:data
                                        withSettings:kRNCryptorAES256Settings
                                            password:@"E987E654K9"
                                               error:&error];
    NSString *encodedString = [encryptedData base64EncodedStringWithOptions:0];
    
    if (encodedString.length > 0) {
        return encodedString;
    }
    
    return nil;
}

- (NSString*)decryptedString:(NSString*)message
{
    NSError *error;
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:message options:0];
    NSData *decryptedData = [RNDecryptor decryptData:decodedData
                                        withPassword:@"E987E654K9"
                                               error:&error];
    NSString *decodedString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    
    if (decodedString.length > 0) {
        return decodedString;
    }
    
    return nil;
}
    
    /*------- Update Delete All Messages Count ------*/
- (void)clearAllMessage:(NSString*)bareJidStr
    {
        
        NSManagedObjectContext *moc = self.xmppMessageArchivingCoreDataStorage.mainThreadManagedObjectContext;
        
        NSEntityDescription *entity = [self.xmppMessageArchivingCoreDataStorage messageEntity:moc];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr == %@",bareJidStr];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray * arr  = [moc executeFetchRequest:fetchRequest error:&error];
        if (arr.count > 0)
        {
            for (int i = 0; i< arr.count; i++)
            {
                XMPPMessageArchiving_Message_CoreDataObject * message = [arr objectAtIndex:i];
                [moc deleteObject:message];
            }
            
            [self updateContactEntityLastMessage:bareJidStr];
            
            NSError *error;
            if ([moc save:&error])
            {
                NSLog(@"Chat message cleared -> %@", bareJidStr);
            }
        }
    }
    
    /*------- Update message Status ------*/
- (void)updateContactEntityLastMessage:(NSString*)bareJidStr
    {
        
        NSManagedObjectContext *moc = self.xmppMessageArchivingCoreDataStorage.mainThreadManagedObjectContext;
        
        NSEntityDescription *entity = [self.xmppMessageArchivingCoreDataStorage messageEntity:moc];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr == %@",bareJidStr];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];    //[fetchRequest setFetchLimit:1];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray * arr  = [moc executeFetchRequest:fetchRequest error:&error];
        if (arr.count > 0)
        {
            XMPPMessageArchiving_Contact_CoreDataObject * contact = [arr objectAtIndex:0];
            NSLog(@"%@", contact.mostRecentMessageBody);
            [moc deleteObject:contact];
            NSError *error;
            if ([moc save:&error])
            {
                NSLog(@"Chat contact cleared -> %@", bareJidStr);
            }
//            NSString *changedBodyStr = [[XMPPStatusManager sharedInstance] returnChangedMessageBodyWithMessageBody:contact.mostRecentMessageBody];
//            [[XMPPMessageArchivingCoreDataStorage sharedInstance] updateContactLastMessage:bareJidStr messageBody:changedBodyStr];
        }
    }

/*-----------  Get all media for a user ---------------*/
- (NSMutableArray*) getAllMediaArray:(NSString *)contactBareJidStr
{
    NSMutableArray *mediaArray = [[NSMutableArray alloc] init];
    
    NSManagedObjectContext *moc = self.xmppMessageArchivingCoreDataStorage.mainThreadManagedObjectContext;
    
    NSEntityDescription *entity = [self.xmppMessageArchivingCoreDataStorage messageEntity:moc];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr == %@",contactBareJidStr];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];    //[fetchRequest setFetchLimit:1];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray * arr  = [moc executeFetchRequest:fetchRequest error:&error];
    
    for (XMPPMessageArchiving_Message_CoreDataObject * message in arr)
    {
        NSLog(@"%@",message.message);
//        NSArray *arrMedia = [[MediaManager sharedInstance] getMediaWithMessageIdWithMessageId:message.messageId];
//
//        if (arrMedia.count > 0)
//        {
//            MediaData *mediaInfo = arrMedia.lastObject;
//            if (mediaInfo.base64String.length > 0)
//            {
//                if ([mediaInfo.mediaType isEqualToString:@"image"])
//                {
//                    [mediaArray addObject:message];
//                }
//            }
//        }
    }
    
    return mediaArray;
}

-(BOOL)IsDuplicateMessage:(NSString *)messageId
{
    NSManagedObjectContext *moc = [self xmppMessageNSManagedObjectContext];
    NSEntityDescription *entity = [self.xmppMessageArchivingCoreDataStorage messageEntity:moc];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageId == %@",messageId];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray * arr  = [moc executeFetchRequest:fetchRequest error:&error];
    if (arr.count > 0)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
