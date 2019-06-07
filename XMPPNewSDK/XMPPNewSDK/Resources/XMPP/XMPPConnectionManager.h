//
//  XMPPConnectionManager.h
//  GoIDD
//
//  Created by CapanicusMacMini on 12/12/17.
//  Copyright © 2017 Lifeline Connect Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPFramework/XMPPFramework.h>
#import "XMPPUserManager.h"

@interface XMPPConnectionManager : NSObject<XMPPStreamManagementDelegate, XMPPStreamDelegate, XMPPMUCLightDelegate, XMPPRoomLightDelegate, XMPPBlockingDelegate>

@property (nonatomic, strong) NSString                  * password;

@property (nonatomic, strong) XMPPStream                * xmppStream;
@property (nonatomic, strong) XMPPMUCLight              * xmppMUCLight;
@property (nonatomic, strong) XMPPRoster                * xmppRoster;
@property (nonatomic, strong) XMPPReconnect             * xmppReconnect;
@property (nonatomic, strong) XMPPAutoPing              * xmppAutoPing;
@property (nonatomic, strong) XMPPStreamManagement      * xmppStreamManagement;
@property (nonatomic, strong) XMPPvCardCoreDataStorage  * xmppvCardStorage;
@property (nonatomic, strong) XMPPvCardTempModule       * xmppvCardTempModule;
@property (nonatomic, strong) XMPPBlocking              * xmppBlocking;
@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage   * xmppMessageArchivingCoreDataStorage;


+ (XMPPConnectionManager *) sharedManager;


/**-------- connecting stream of Xmpp server */
- (void) setupStream;

/**-------- Dealloc stream of Xmpp server */
- (void)deallocXmpp;

/**
 Connect user to Xmpp server
 @param jabberID    login user name
 @param myPassword  login password
 */
- (BOOL)connectWithUserId:(NSString*)jabberID withPassword:(NSString*)myPassword;

/**
 Connect user to Xmpp server
 @param userName    login user name
 @param myPassword  login password
 */
- (void) authenticateUserWIthUSerName:(NSString*)userName withPassword:(NSString*)myPassword;


/*-------- disconnect user from Xmpp server ----------- */
- (void) disconnect;

/*---------- changes the presence to online -----------*/
- (void) goOnline;

/*------- changes the presence to offline ------------- */
- (void) goOffline;


/**
 send message to other user with content
 @param toAdress destination address
 @param content  content of message
 */
- (void)sendXmppMessage:(XMPPMessage*)message;

/**
 This method is used for sending subscribe invitation to user
 @param userID destination address
 */
- (void) sendSubscribeMessageToUser:(NSString*)userID;

/**
 This method is used for setting substate of presence
 @param subState substate of user
 */
- (void) presenceWithStubState:(NSString*)subState;

/**
 This method is used to send message to group
 */

- (void)sendXmppTypingMessage:(NSString*)toAddress;
- (XMPPMessage*)getXmppMessageForGroupCreationAndUpdation:(NSString*)toAddress messageBody:(NSString*)messageBody roomName:(NSString*)roomName;
- (XMPPMessage *)getXmppMessage:(NSString*)toAddress withContents:(NSString*)content messageid:(NSString*)messageID;
- (XMPPMessage *)getXmppTranslatedMessage:(NSString*)toAddress withContents:(NSString*)content translatedString:(NSString*)translatedText language:(NSString*)language messageid:(NSString*)messageID;
- (XMPPMessage *)getXmppMessageForMedia:(NSString*)toAddress message:(NSString*)mediaUrl messageid:(NSString*)messageID andImageData:(NSString*)data type:(NSString*)mediaType;
- (XMPPMessage *)getXmppCardMessage:(NSString*)toAddress withContents:(NSString*)content messageid:(NSString*)messageID;
- (XMPPMessage*)getXmppMessageForGroupAvtarChange:(NSString*)toAddress URL:(NSString*)url roomName:(NSString*)roomName;
    

- (void)blockJid:(NSString*)jidStr;
- (void)discoverXMPPMUCLightService;
- (void)fetchMemberListOfRoom:(NSString*)jidStr roomName:(NSString*)roomName;
- (void)leaveXmppRoom:(NSString*)jidStr roomName:(NSString*)roomName;
- (void)RemoveUserFromXmppRoom:(NSString*)jidStr roomName:(NSString*)roomName user:(NSString*)user;
- (void)changeRoomName:(NSString*)jidStr roomName:(NSString*)roomName newRoomName:(NSString*)newRoomName;


@end
