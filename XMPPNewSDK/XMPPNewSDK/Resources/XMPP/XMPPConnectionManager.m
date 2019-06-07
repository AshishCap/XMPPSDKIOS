//
//  XMPPConnectionManager.m
//  GoIDD
//
//  Created by CapanicusMacMini on 12/12/17.
//  Copyright © 2017 Lifeline Connect Pty Ltd. All rights reserved.
//

#import "XMPPConnectionManager.h"
//#import "XMPPNewSDK-Swift.h"
#import <CoreData/CoreData.h>

static NSString *mucLightServiceName = @"muclight.chat.goidd.com";
static XMPPConnectionManager* manager = nil;

@implementation XMPPConnectionManager

+ (XMPPConnectionManager*) sharedManager
{
    @synchronized(manager)
    {
        if (manager==nil)
        {
            manager = [[XMPPConnectionManager alloc] init];
        }
    }
    return manager;
}

- (void)setupStream
{
    // Setup xmpp stream
    // The XMPPStream is the base class for all activity.
    // Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
    self.xmppStream = [[XMPPStream alloc] init];
    [self.xmppStream setHostName:@"chat.goidd.com"];
    [self.xmppStream setHostPort:5222];
    self.xmppStream.enableBackgroundingOnSocket = YES;
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    //self.xmppStream.startTLSPolicy = .required
    //[self.xmppStream startTLSPolicy];
    
    if (self.xmppRoster == nil) {
        XMPPRosterCoreDataStorage *xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
        self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
        self.xmppRoster.autoFetchRoster = YES;
        self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
        [self.xmppRoster activate:self.xmppStream];
        [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    self.xmppReconnect = [[XMPPReconnect alloc] init];
    [self.xmppReconnect activate:self.xmppStream];
    [self.xmppReconnect addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    self.xmppAutoPing = [[XMPPAutoPing alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    self.xmppAutoPing.pingInterval = 280;
    [self.xmppAutoPing activate:self.xmppStream];
    [self.xmppAutoPing addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    XMPPStreamManagementMemoryStorage *xmppSMMS = [[XMPPStreamManagementMemoryStorage alloc] init];
    self.xmppStreamManagement = [[XMPPStreamManagement alloc] initWithStorage:xmppSMMS];
    [self.xmppStreamManagement addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppStream supportsStreamManagement];
    [self.xmppStreamManagement activate:self.xmppStream];
    self.xmppStreamManagement.autoResume = YES;
    [self.xmppStreamManagement enableStreamManagementWithResumption:YES maxTimeout:0];
    [self.xmppStreamManagement requestAck];
}

- (void)deallocXmpp
{
    [self.xmppStream removeDelegate:self.xmppStream];
    self.xmppStream = nil;
    
    [self.xmppReconnect removeDelegate:self.xmppStream];
    self.xmppReconnect = nil;
    
    [self.xmppAutoPing removeDelegate:self.xmppStream];
    self.xmppAutoPing = nil;
    
    [self.xmppStreamManagement removeDelegate:self.xmppStream];
    self.xmppStreamManagement = nil;
    
    [self.xmppvCardTempModule removeDelegate:self.xmppStream];
    self.xmppvCardTempModule = nil;
    
    [self.xmppMUCLight removeDelegate:self.xmppStream];
    self.xmppMUCLight = nil;
    
    [self.xmppBlocking removeDelegate:self.xmppStream];
    self.xmppBlocking = nil;
}

/*------- This fuction is used to Connect XMPP With userId and Password -------------*/
- (BOOL)connectWithUserId:(NSString*)jabberID withPassword:(NSString*)myPassword
{
    [self setupStream];
    
    if (![self.xmppStream isDisconnected]) {
        return YES;
    }
    
    if (jabberID == nil || myPassword == nil) {
        
        return NO;
    }
    
    [self.xmppStream setMyJID:[XMPPJID jidWithString:jabberID]];
    self.password = myPassword;
    
    NSError *error = nil;
    if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
    {
        return NO;
    }
    
    return YES;
}

- (void) authenticateUserWIthUSerName:(NSString*)userName withPassword:(NSString*)myPassword
{
    [self connectWithUserId:userName withPassword:myPassword];
}

#pragma mark - Reconenction Delegate

- (void)xmppReconnect:(XMPPReconnect *)sender didDetectAccidentalDisconnect:(SCNetworkReachabilityFlags)connectionFlags
{
    NSLog(@"didDetectAccidentalDisconnect:%u",connectionFlags);
}

- (BOOL)xmppReconnect:(XMPPReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkReachabilityFlags)reachabilityFlags
{
    NSLog(@"shouldAttemptAutoReconnect:%u",reachabilityFlags);
    return YES;
}

#pragma mark - Stream Management Delegate

- (void)xmppStreamManagement:(XMPPStreamManagement *)sender wasEnabled:(NSXMLElement *)enabled{
    NSLog(@"wasEnabled:%@",enabled);
}

- (void)xmppStreamManagement:(XMPPStreamManagement *)sender wasNotEnabled:(NSXMLElement *)failed{
    NSLog(@"wasNotEnabled:%@",failed);
}

- (void)xmppStreamManagement:(XMPPStreamManagement *)sender didReceiveAckForStanzaIds:(NSArray *)stanzaIds{
    NSLog(@"didReceiveAckForStanzaIds:%@",stanzaIds);
}

#pragma mark ---Delegate of Connect
/** This fuction is called when stream is connected */
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSError *error = nil;
    NSLog(@"Stream Connected");
    [self.xmppStream authenticateWithPassword:self.password error:&error];
}

/**
 This fuction is called when User is Authenticated
 */
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [self goOnline];
    
    if ([self.xmppStream isAuthenticated])
    {
        NSLog(@"Stream Authenticated");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"STREAMAUTHENTICATED" object:nil userInfo:nil];
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            // Perform async operation
            dispatch_sync(dispatch_get_main_queue(), ^{
                // Update UI
                [[XMPPUserManager sharedManager] sendUnsendMessages];
            });
        });
        
        self.xmppvCardStorage = [[XMPPvCardCoreDataStorage alloc] initWithInMemoryStore];
        self.xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:self.xmppvCardStorage];
        [self.xmppvCardTempModule activate:self.xmppStream];
        [self.xmppvCardTempModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        XMPPMessageDeliveryReceipts* xmppMessageDeliveryRecipts = [[XMPPMessageDeliveryReceipts alloc] initWithDispatchQueue:dispatch_get_main_queue()];
        xmppMessageDeliveryRecipts.autoSendMessageDeliveryReceipts = YES;
        xmppMessageDeliveryRecipts.autoSendMessageDeliveryRequests = YES;
        [xmppMessageDeliveryRecipts activate:self.xmppStream];
        
        self.xmppMUCLight = [[XMPPMUCLight alloc] initWithDispatchQueue:dispatch_get_main_queue()];
        [self.xmppMUCLight activate:self.xmppStream];
        [self.xmppMUCLight addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.xmppMUCLight discoverRoomsForServiceNamed:mucLightServiceName];
        
        self.xmppBlocking = [[XMPPBlocking alloc] init];
        [self.xmppBlocking activate:self.xmppStream];
        [self.xmppBlocking addDelegate:self delegateQueue:dispatch_get_main_queue()];
        //[[ContactManager sharedInstance] sendPresenceToMatchedContact];
       //[[ContactManager sharedInstance] sendPresenceToMatchedContact];
    }
}

#pragma mark - XMPPMUCLightDelegate Methods

- (void)xmppMUCLight:(nonnull XMPPMUCLight *)sender didDiscoverRooms:(nonnull NSArray<__kindof NSXMLElement*>*)rooms forServiceNamed:(nonnull NSString *)serviceName {
    
    for (NSXMLElement *obj in rooms) {
        NSString *jid = [[obj attributeForName:@"jid"] stringValue];
        NSString *roomName = [[obj attributeForName:@"name"] stringValue];
        
        XMPPMessage *message = [self getXmppMessageForGroupCreationAndUpdation:jid messageBody:@"Group created" roomName:roomName];
        //[[XMPPMessageArchivingCoreDataStorage sharedInstance] insertUpdateNewContact:message outgoing:NO xmppStream:self.xmppStream];
    }
    
}

- (void)xmppMUCLight:(nonnull XMPPMUCLight *)sender failedToDiscoverRoomsForServiceNamed:(nonnull NSString *)serviceName withError:(nonnull NSError *)error {
    NSLog(@"serviceName -> %@", serviceName);
}

- (void)xmppMUCLight:(nonnull XMPPMUCLight *)sender changedAffiliation:(nonnull NSString *)affiliation roomJID:(nonnull XMPPJID *)roomJID {
    [self.xmppMUCLight discoverRoomsForServiceNamed:mucLightServiceName];
}

#pragma mark - XMPPRoomLight Methods

- (void)discoverXMPPMUCLightService {
    [self.xmppMUCLight discoverRoomsForServiceNamed:mucLightServiceName];
}

- (void)fetchMemberListOfRoom:(NSString*)jidStr roomName:(NSString*)roomName
{
    XMPPJID *jid = [XMPPJID jidWithString:jidStr];
    XMPPRoomLight *xmppRoomLight = [[XMPPRoomLight alloc] initWithJID:jid roomname:roomName];
    [xmppRoomLight activate:self.xmppStream];
    
    [xmppRoomLight removeDelegate:self];
    [xmppRoomLight addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    [xmppRoomLight fetchMembersList];
}

- (void)changeRoomName:(NSString*)jidStr roomName:(NSString*)roomName newRoomName:(NSString*)newRoomName
{
    XMPPJID *jid = [XMPPJID jidWithString:jidStr];
    XMPPRoomLight *xmppRoomLight = [[XMPPRoomLight alloc] initWithJID:jid roomname:roomName];
    [xmppRoomLight activate:self.xmppStream];
    
    [xmppRoomLight removeDelegate:self];
    [xmppRoomLight addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    DDXMLElement *query = [[DDXMLElement alloc] initWithName:@"roomname" stringValue:newRoomName];
    [xmppRoomLight setConfiguration:[NSArray arrayWithObject:query]];
}

- (void)leaveXmppRoom:(NSString*)jidStr roomName:(NSString*)roomName
{
    XMPPJID *jid = [XMPPJID jidWithString:jidStr];
    XMPPRoomLight *xmppRoomLight = [[XMPPRoomLight alloc] initWithJID:jid roomname:roomName];
    [xmppRoomLight activate:self.xmppStream];
    
    [xmppRoomLight removeDelegate:self];
    [xmppRoomLight addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    [xmppRoomLight leaveRoomLight];
}

- (void)RemoveUserFromXmppRoom:(NSString*)jidStr roomName:(NSString*)roomName user:(NSString*)user
{
    XMPPJID *jid = [XMPPJID jidWithString:jidStr];
    XMPPRoomLight *xmppRoomLight = [[XMPPRoomLight alloc] initWithJID:jid roomname:roomName];
    [xmppRoomLight activate:self.xmppStream];
    
    [xmppRoomLight removeDelegate:self];
    [xmppRoomLight addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    [xmppRoomLight RemoveMemberFromGroup:user];
}

#pragma mark - XMPPRoomLightDelegate Methods

- (void)xmppRoomLight:(nonnull XMPPRoomLight *)sender didCreateRoomLight:(nonnull XMPPIQ *)iq {
    NSLog(@"iq -> %@", iq);
    
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setValue:[iq fromStr] forKey:@"jidStr"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GROUPCREATIONNOTIFICATION" object:nil userInfo:dic];
}

- (void)xmppRoomLight:(nonnull XMPPRoomLight *)sender configurationChanged:(nonnull XMPPMessage *)message {
    XMPPJID *jid = sender.roomJID;
    NSString *jidStr = [jid bare];
    DDXMLElement *roomnameElement = [message elementForName:@"x"];
    NSString *roomName = [[roomnameElement elementForName:@"roomname"] stringValue];
    
    XMPPMessage *xmppmessage = [self getXmppMessageForGroupCreationAndUpdation:jidStr messageBody:@"Group name updated" roomName:roomName];
    [[XMPPMessageArchivingCoreDataStorage sharedInstance] insertUpdateNewContact:xmppmessage outgoing:NO xmppStream:self.xmppStream];
    
    // Delay 0.5 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GROUPUPDATEONNOTIFICATION" object:nil userInfo:nil];
    });
}

- (void)xmppRoomLight:(nonnull XMPPRoomLight *)sender didFetchMembersList:(nonnull NSArray<NSXMLElement*> *)items {
    //NSLog(@"items -> %@", items);
    
    NSString *groupName = sender.roomname;
    XMPPJID *jid = sender.roomJID;
    NSString *groupJidStr = [jid bare];
/*
    NSManagedObjectContext *context = [[AppUtility sharedInstance] mainManagedObjectContext];//[[AppDelegate shared] persistentContainer].viewContext;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"GroupDetails" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"groupJidStr == %@", groupJidStr];

    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count > 0) {
        for (GroupDetails *groupDetails in fetchedObjects) {
            [context deleteObject:groupDetails];
        }

        if (![context save:&error]) {
            NSLog(@"GroupDetails, couldn't delete: %@", [error localizedDescription]);
            abort();
        } else {
            NSLog(@"GroupDetails deleted successfully");
        }
    }*/

    for (NSXMLElement *obj in items) {
        NSString *participantRole = [[obj attributeForName:@"affiliation"] stringValue];
        NSString *participantJidStr = [obj stringValue];
/*
        GroupDetails *groupDetails = [NSEntityDescription insertNewObjectForEntityForName:@"GroupDetails" inManagedObjectContext:context];

        groupDetails.groupName = groupName;
        groupDetails.groupJidStr = groupJidStr;
        groupDetails.participantRole = participantRole;
        groupDetails.participantJidStr = participantJidStr;

        NSError *error;
        if (![context save:&error]) {
            NSLog(@"GroupDetails, couldn't save: %@", [error localizedDescription]);
            abort();
        } else {
            NSLog(@"GroupDetails saved successfully");
        }*/
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GROUPMEMBERFETCHNOTIFICATION" object:nil userInfo:nil];
}

- (void)xmppRoomLight:(nonnull XMPPRoomLight *)sender didFailToFetchMembersList:(nonnull XMPPIQ *)iq {
    NSLog(@"iq -> %@", iq);
}

- (void)xmppRoomLight:(XMPPRoomLight *)sender didChangeAffiliations:(XMPPIQ *)iqResult
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GROUPUPDATEONNOTIFICATION" object:nil userInfo:nil];
}

- (void)xmppRoomLight:(XMPPRoomLight *)sender didFailToChangeAffiliations:(XMPPIQ *)xmppRoomLight
{
    NSLog(@"%@",xmppRoomLight);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GROUPUPDATEONNOTIFICATION" object:nil userInfo:nil];
}

- (void)xmppRoomLight:(nonnull XMPPRoomLight *)sender didLeaveRoomLight:(nonnull XMPPIQ *)iq {
    NSLog(@"didLeaveRoomLight -> %@", iq);
}

- (void)xmppRoomLight:(nonnull XMPPRoomLight *)sender didFailToLeaveRoomLight:(nonnull XMPPIQ *)iq {
    NSLog(@"didFailToLeaveRoomLight -> %@", iq);
}

#pragma mark - XMPPBlocking Methods

- (void)blockJid:(NSString*)jidStr {
    XMPPJID *xmppJID = [XMPPJID jidWithString:jidStr];
    [self.xmppBlocking blockJID:xmppJID];
}

#pragma mark - XMPPBlockingDelegate Methods

- (void)xmppBlocking:(XMPPBlocking *)sender didBlockJID:(XMPPJID*)xmppJID {
    NSLog(@"didBlockJID -> %@", xmppJID);
}

- (void)xmppBlocking:(XMPPBlocking *)sender didNotBlockJID:(XMPPJID*)xmppJID error:(id)error {
    NSLog(@"didNotBlockJID -> %@", xmppJID);
}

- (void)xmppBlocking:(XMPPBlocking *)sender didUnblockJID:(XMPPJID*)xmppJID {
    NSLog(@"didUnblockJID -> %@", xmppJID);
}

- (void)xmppBlocking:(XMPPBlocking *)sender didNotUnblockJID:(XMPPJID*)xmppJID error:(id)error {
    NSLog(@"didNotUnblockJID -> %@", xmppJID);
}


- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule didReceivevCardTemp:(XMPPvCardTemp *)vCardTemp forJID:(XMPPJID *)jid
{
    NSLog(@"Delegate is called");
    XMPPvCardTemp *vCard = [self.xmppvCardStorage vCardTempForJID:jid xmppStream:self.xmppStream];
    //NSData *imagedata = vCard.photo;
    
    //UIImage * image = [UIImage imageWithData:imagedata];
    NSLog(@"Stored card: %@",vCard);
    NSLog(@"%@", vCard.description);
    NSLog(@"%@", vCard.name);
    NSLog(@"%@", vCard.emailAddresses);
    NSLog(@"%@", vCard.formattedName);
    NSLog(@"%@", vCard.givenName);
    NSLog(@"%@", vCard.middleName);
}

/** This fuction is called when User is not Authenticated */
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    NSLog(@"%@", error);
    NSLog(@"Stream not authenticated");
}

#pragma mark - Stream disconnection

/** This fuction is used to disconnet user */
- (void)disconnect
{
    [self goOffline];
    [self.xmppStream disconnect];
}

#pragma mark ---Delegate of disconnect
/** This fuction is called when stream is disConnected */
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    NSLog(@"Stream Disconnected");
}

#pragma mark - setting presence

/*--------- This fuction is used change the presence to online ------------*/
- (void)goOnline
{
    XMPPPresence *presence = [XMPPPresence presence];
    [self.xmppStream sendElement:presence];
}

/* This fuction is used change the presence to Offline */
- (void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [self.xmppStream sendElement:presence];
}

/*--------- This fuction is used change the presence substate ------------*/
- (void) presenceWithStubState:(NSString*)subState
{
    XMPPPresence *presence = [XMPPPresence presence];// type="available" is implicit
    
    NSXMLElement *status = [NSXMLElement elementWithName:@"status"];
    [status setStringValue:subState];
    [presence addChild:status];
    
    [self.xmppStream sendElement:presence];
}

/*---------- This fuction is called when other user state is changed ------------*/
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSString *presenceType      = [presence type];            // online/offline
    NSString *myUsername        = [[sender myJID] user];
    NSString *presenceFromUser  = [[presence from] user];
    NSString* presenceState     = [presence status];
    
    NSLog(@"%@  is %@ state -> %@",presenceFromUser,presenceType,presenceState);
    // ---------- for update offline/online ----------
    
    if (![presenceFromUser isEqualToString:myUsername])
    {
        if ([presenceType isEqualToString:@"available"]) {
            [self setPresenceOfUser:YES number:presenceFromUser];
//            [XMPPChatSettingManager ];
            //[[XMPPChatSettingManager sharedInstance] UpdateXmppStatusWithPhone:presenceFromUser status:@"1"];
        } else if  ([presenceType isEqualToString:@"unavailable"]) {
            [self setPresenceOfUser:NO number:presenceFromUser];
            //[[XMPPChatSettingManager sharedInstance] UpdateXmppStatusWithPhone:presenceFromUser status:@"0"];
        } else if  ([presenceType isEqualToString:@"subscribe"]) {
            [self.xmppRoster subscribePresenceToUser:[presence from]];
            [self goOnline];
        } else if  ([presenceType isEqualToString:@"subscribed"]) {
            [self.xmppRoster subscribePresenceToUser:[presence from]];
        }
    }
}

- (void)setPresenceOfUser:(BOOL)isOnline number:(NSString*)number
{
    /*NSString *jidStr = [NSString stringWithFormat:@"%@@%@", number, [self.xmppStream hostName]];
     [[XMPPMessageArchivingCoreDataStorage sharedInstance] userOnlineOffline:jidStr isOnline:isOnline];
     
     // Delay 0.5 seconds
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
     NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
     [dic setValue:jidStr forKey:@"jidStr"];
     [[NSNotificationCenter defaultCenter] postNotificationName:@"SYNCEDCONTACTUPDATENOTIFICATION" object:nil userInfo:dic];
     });*/
}

#pragma mark - subscription
- (void) sendSubscribeMessageToUser:(NSString*)userID
{
    XMPPJID * jbid          = [XMPPJID jidWithString:userID];
    XMPPPresence *presence  = [XMPPPresence presenceWithType:@"subscribe" to:jbid];
    [self.xmppStream sendElement:presence];
}


#pragma mark ---delegates of registrtaion


/* This fuction is called when new user is registered */
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    
}

/*------- This fuction is called when registeration process failed --------------*/
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
    
}

#pragma mark  Send message--------------------------------------------------------------

- (void)sendXmppMessage:(XMPPMessage*)message
{
    [self.xmppStream sendElement:message];
    
    NSString *messageId = [[message attributeForName:@"id"] stringValue];
    //if (![[AppUtility sharedInstance] isNullOrEmptyWithString:messageId]) {
        if (self.xmppStream.isAuthenticated) {
            [[XMPPMessageArchivingCoreDataStorage sharedInstance] updateMessageStatus:messageId status:@"1"];
        }
    //}
}

#pragma mark  recieve message
/* This fuction is called when new message arrived */

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    if ([message isErrorMessage] || [[message fromStr] containsString:sender.myJID.bare]) {
        return;
    }
    
    if ([message hasReceiptResponse])
    {
        NSLog(@"Receipt received...");
        DDXMLElement *status_content = [message elementForName:@"received"];
        NSString *messageId  =  [[status_content attributeForName:@"id"] stringValue];
        //if (![[AppUtility sharedInstance] isNullOrEmptyWithString:messageId]) {
            [[XMPPMessageArchivingCoreDataStorage sharedInstance] updateMessageStatus:messageId status:@"2"];
        //}
    }
    else if ([message hasComposingChatState])
    {
        if ([[message fromStr] containsString:mucLightServiceName]) {
            return;
        }
        
        XMPPJID * jid = [XMPPJID jidWithString:[[message attributeForName:@"from"] stringValue]];
        NSString *from_jidStr = [jid bare];
        
        NSLog(@"Typing received -> %@", from_jidStr);
        
        NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
        [dic setValue:from_jidStr forKey:@"fromStr"];
        [dic setValue:@"Typing" forKey:@"Status"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TYPINGNOTIFICATION" object:nil userInfo:dic];
    }
    else
    {
        // A simple example of inbound message handling.
        if ([message body])
        {
            NSString *messageBody = [[message elementForName:@"body"] stringValue];
            messageBody = [[XMPPUserManager sharedManager] decryptedString:messageBody];
            NSString *typeString = [[message attributeForName:@"type"] stringValue];
            if ([messageBody length] > 0 && ![messageBody isEqualToString:@"##Message Deleted##"])
            {
                DDXMLElement *imageElement = nil;
                NSString *mediaType = @"";
                
                if([[message elementForName:@"image"] stringValue] != nil)
                {
                    imageElement = [message elementForName:@"image"];
                    mediaType = @"image";
                }
                else if([[message elementForName:@"video"] stringValue] != nil)
                {
                    imageElement = [message elementForName:@"video"];
                    mediaType = @"video";
                }
                else if([[message elementForName:@"audio"] stringValue] != nil)
                {
                    imageElement = [message elementForName:@"audio"];
                    mediaType = @"audio";
                }
                else if([[message elementForName:@"document"] stringValue] != nil)
                {
                    imageElement = [message elementForName:@"document"];
                    mediaType = @"document";
                }
                else if([[message elementForName:@"card"] stringValue] != nil)
                {
                    imageElement = [message elementForName:@"card"];
                    mediaType = @"card";
                }
                else if([[message elementForName:@"sticker"] stringValue] != nil)
                {
                    imageElement = [message elementForName:@"sticker"];
                    mediaType = @"sticker";
                }
                else if([[message elementForName:@"location"] stringValue] != nil)
                {
                    imageElement = [message elementForName:@"location"];
                    mediaType = @"location";
                }
                else if([[message elementForName:@"GroupAvtar"] stringValue] != nil)
                {
                    imageElement = [message elementForName:@"GroupAvtar"];
                    mediaType = @"GroupAvtar";
                }
                
                if(imageElement != nil)
                {
                    NSString *mediaUrl = [[imageElement elementForName:@"url"] stringValue];
                    mediaUrl = [mediaUrl stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    mediaUrl = [[XMPPUserManager sharedManager] decryptedString:mediaUrl];
                    if ([mediaUrl length] > 0)
                    {
                        NSString *thumbnailData = @"";
//                        if([mediaType isEqualToString:@"video"])
//                        {
//                            UIImage *thumbImage = [[AppUtility sharedInstance] generateThumbnailImage:[[NSURL alloc] initWithString:mediaUrl]];
//                            if (thumbImage) {
//                                thumbnailData = [[AppUtility sharedInstance] getThumbnailDataOfImageWithImage:thumbImage];
//                            }
//                            else
//                            {
//                                thumbnailData = [[AppUtility sharedInstance] getThumbnailDataOfImageWithImage:[UIImage imageNamed:@"download_image_icon"]];
//                            }
//
//                        }
//                        else if([mediaType isEqualToString:@"image"]) {
//                            thumbnailData = [[AppUtility sharedInstance] getThumbnailDataOfImageWithImage:[UIImage imageNamed:@"download_image_icon"]];
//                        }
//                        else if([mediaType isEqualToString:@"GroupAvtar"]) {
//                            thumbnailData = [[AppUtility sharedInstance] getThumbnailDataOfImageWithImage:[UIImage imageNamed:@"download_image_icon"]];
//                        }
                        
                        if([mediaType isEqualToString:@"GroupAvtar"])
                        {
                            NSString *groupJIDString = @"";
                            if ([[message fromStr] containsString:@"muclight.chat.goidd.com"]) {
                                NSArray *userNameArr = [[message fromStr] componentsSeparatedByString:@"/"];
                                if([userNameArr count] > 1)
                                {
                                    NSString *groupSenderJidStr = [userNameArr objectAtIndex:0];
                                    groupJIDString = groupSenderJidStr;
                                }
                            }
                            NSString *str = [NSString stringWithFormat:@"%@%@",mediaType, groupJIDString];
                            //[[MediaManager sharedInstance] updateMediaWithMessageId:message.elementID mediaUrl:mediaUrl thumbnailData:thumbnailData mediaType:str];
                        }
                        else
                        {
                            //[[MediaManager sharedInstance] saveMediaWithMessageId:message.elementID mediaUrl:mediaUrl thumbnailData:thumbnailData mediaType:mediaType];
                        }
                        //Save media data into different table
                        
                    }
                }
                if ([mediaType isEqualToString:@"GroupAvtar"])
                {
                    //[[XMPPUserManager sharedManager] customArchiveMessage:message outgoing:NO xmppStream:sender];
                }
                else
                {
                    NSString *messageId = [[message attributeForName:@"id"] stringValue];
                    if (![[XMPPUserManager sharedManager] IsDuplicateMessage:messageId])
                    {
                        [[XMPPUserManager sharedManager] customArchiveMessage:message outgoing:NO xmppStream:sender];
                    }
                }
                
                XMPPJID * jid = [XMPPJID jidWithString:[message fromStr]];
                NSString *from_jidStr = [jid bare];
                if ([[message fromStr] containsString:mucLightServiceName]) {
                    from_jidStr = [jid full];
                }
                
//                if (![[AppUtility sharedInstance] isNullOrEmptyWithString:from_jidStr])
//                {
////                    if([typeString isEqualToString:@"card"])
////                    {
////                        messageBody = @"Card";
////                    }
//                    [[AppDelegate shared] triggerNotificationFrom:from_jidStr message:messageBody identifier:@"com.GoIDD.chatNotification"];
//                }
            }
            else {
                if ([messageBody isEqualToString:@"##Message Deleted##"]) {
//                    if (![[AppUtility sharedInstance] isNullOrEmptyWithString:message.elementID]) {
//                        [[AppUtility sharedInstance] deleteChatForEveryone:message.elementID];
                    }
                }
            }
//        }
    }
}

- (void)sendXmppTypingMessage:(NSString*)toAddress
{
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"to" stringValue: toAddress];
    
//    if([[AppUtility sharedInstance] isGroupMessageJidWithJid:toAddress]) {
//        [message addAttributeWithName:@"type" stringValue:@"groupchat"];
//    } else {
        [message addAttributeWithName:@"type" stringValue:@"chat"];
//    }
    
    NSXMLElement *composing = [NSXMLElement elementWithName:@"composing"];
    [composing addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/chatstates"];
    
    [message addChild:composing];
    
    [self.xmppStream sendElement:message];
}

- (XMPPMessage*)getXmppMessageForGroupCreationAndUpdation:(NSString*)toAddress messageBody:(NSString*)messageBody roomName:(NSString*)roomName {
    XMPPMessage *body = [XMPPMessage elementWithName:@"body"];
    [body setStringValue:messageBody];
    
    XMPPMessage *message = [[XMPPMessage alloc] initWithName:@"message"];
    [message addAttributeWithName:@"to" stringValue:toAddress];
    [message addAttributeWithName:@"groupName" stringValue:roomName];
    [message addChild:body];
    
    return message;
}

- (XMPPMessage*)getXmppMessageForGroupAvtarChange:(NSString*)toAddress URL:(NSString*)url roomName:(NSString*)roomName {
    XMPPMessage *body = [XMPPMessage elementWithName:@"body"];
    [body setStringValue:url];
    
    XMPPMessage *message = [[XMPPMessage alloc] initWithName:@"message"];
    [message addAttributeWithName:@"to" stringValue:toAddress];
    [message addAttributeWithName:@"groupName" stringValue:roomName];
    [message addChild:body];
    
    return message;
}

- (XMPPMessage *)getXmppMessage:(NSString*)toAddress withContents:(NSString*)content messageid:(NSString*)messageID
{
    XMPPMessage *body = [XMPPMessage elementWithName:@"body"];
    [body setStringValue:content];
    
    XMPPMessage *message = [XMPPMessage elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addAttributeWithName:@"to" stringValue:toAddress];
    
//    if([[AppUtility sharedInstance] isGroupMessageJidWithJid:toAddress]) {
//        [message addAttributeWithName:@"type" stringValue:@"groupchat"];
//    } else {
        [message addAttributeWithName:@"type" stringValue:@"chat"];
//    }
    
    [message addChild:body];
    return message;
}

- (XMPPMessage *)getXmppTranslatedMessage:(NSString*)toAddress withContents:(NSString*)content translatedString:(NSString*)translatedText language:(NSString*)language messageid:(NSString*)messageID
{
    XMPPMessage *body = [XMPPMessage elementWithName:@"body"];
    [body setStringValue:content];
    
    XMPPMessage *message = [XMPPMessage elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addAttributeWithName:@"to" stringValue:toAddress];
    
    XMPPMessage *translatedMessage = [XMPPMessage elementWithName:@"translation"];
    [translatedMessage addAttributeWithName:@"xmlns" stringValue:[NSString stringWithFormat:@"jabber:translation"]];
    
    XMPPMessage *translatedTextElement = [XMPPMessage elementWithName:@"translatedtext"];
    [translatedTextElement setStringValue:translatedText];
    XMPPMessage *languageElement = [XMPPMessage elementWithName:@"language"];
    [languageElement setStringValue:language];
    
//    if([[AppUtility sharedInstance] isGroupMessageJidWithJid:toAddress]) {
//        [message addAttributeWithName:@"type" stringValue:@"groupchat"];
//    } else {
        [message addAttributeWithName:@"type" stringValue:@"chat"];
//    }
    
    [translatedMessage addChild:languageElement];
    [translatedMessage addChild:translatedTextElement];
    [message addChild:body];
    [message addChild:translatedMessage];
    return message;
}

- (XMPPMessage *)getXmppCardMessage:(NSString*)toAddress withContents:(NSString*)content messageid:(NSString*)messageID
{
    XMPPMessage *body = [XMPPMessage elementWithName:@"body"];
    [body setStringValue:content];
    
    XMPPMessage *message = [XMPPMessage elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addAttributeWithName:@"to" stringValue:toAddress];
    
//    if([[AppUtility sharedInstance] isGroupMessageJidWithJid:toAddress]) {
//        [message addAttributeWithName:@"type" stringValue:@"card"];
//    } else {
        [message addAttributeWithName:@"type" stringValue:@"card"];
//    }
    
    [message addChild:body];
    return message;
}

- (XMPPMessage *)getXmppMessageForMedia:(NSString*)toAddress message:(NSString*)mediaUrl messageid:(NSString*)messageID andImageData:(NSString*)data type:(NSString*)mediaType
{
    if([mediaUrl length]> 0)
    {
        //Add image
        XMPPMessage *image = [XMPPMessage elementWithName:mediaType];
        [image addAttributeWithName:@"xmlns" stringValue:[NSString stringWithFormat:@"jabber:%@",mediaType]];
        
        
        XMPPMessage *body = [XMPPMessage elementWithName:@"body"];
        NSString *bodyMessage = @"";
        
        if([mediaType isEqualToString:@"audio"])
        {
            bodyMessage = @"audio";
        }
        else if([mediaType isEqualToString:@"image"])
        {
            bodyMessage = @"image";
        }
        else if([mediaType isEqualToString:@"video"])
        {
            bodyMessage = @"video";
        }
        else if([mediaType isEqualToString:@"document"])
        {
            bodyMessage = @"document";
        }
        else if([mediaType isEqualToString:@"card"])
        {
            bodyMessage = @"card";
        }
        else if([mediaType isEqualToString:@"sticker"])
        {
            bodyMessage = @"sticker";
        }
        else if([mediaType isEqualToString:@"location"])
        {
            bodyMessage = @"location";
        }
        else if([mediaType isEqualToString:@"audio"])
        {
            bodyMessage = @"audio";
        }
        else if([mediaType isEqualToString:@"GroupAvtar"])
        {
            bodyMessage = @"Group avtar changed";
        }
        
        bodyMessage = [[XMPPUserManager sharedManager] encryptedString:bodyMessage];
        [body setStringValue:bodyMessage];
        
        //Add image url
        XMPPMessage *fileUrl = [XMPPMessage elementWithName:@"url" stringValue:mediaUrl];
        [image addChild:fileUrl];
        
        //Add image thumb
        if(data.length > 0 && [mediaType isEqualToString:@"video"])
        {
            //XMPPMessage *thumbUrl = [XMPPMessage elementWithName:@"thumb" stringValue:data];
            //[image addChild:thumbUrl];
        }
        
        XMPPMessage *message = [[XMPPMessage alloc] initWithName:@"message"];
        [message addAttributeWithName:@"id" stringValue:messageID];
        [message addAttributeWithName:@"to" stringValue:toAddress];
        
//        if([[AppUtility sharedInstance] isGroupMessageJidWithJid:toAddress]) {
//            [message addAttributeWithName:@"type" stringValue:@"groupchat"];
//        } else {
            [message addAttributeWithName:@"type" stringValue:@"chat"];
//        }
        
        [message addChild:image];
        [message addChild:body];
        
        return message;
    }
    return nil;
}

@end
