#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "RNCryptor+Private.h"
#import "RNCryptor.h"
#import "RNCryptorEngine.h"
#import "RNDecryptor.h"
#import "RNEncryptor.h"
#import "ChatContact.h"
#import "ChatMessageHistory.h"
#import "ChatMessages.h"
#import "XMPPConnectionManager.h"
#import "XMPPUserManager.h"
#import "XMPPNewSDK.h"

FOUNDATION_EXPORT double XMPPNewSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char XMPPNewSDKVersionString[];

