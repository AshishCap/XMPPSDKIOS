//
//  ChatMessageHistory.h
//  GoIDD
//
//  Created by apple on 20/06/17.
//  Copyright © 2017 GoIDD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatMessageHistory : NSObject

@property (nonatomic, strong) NSString * chatBaseContact;  // Shadow (binary data, written to disk)

@property (nonatomic, strong) NSString * body;
@property (nonatomic, strong) NSString * date;
@property (nonatomic, strong) NSString * time;
@property (nonatomic, strong) NSString * chatname;
@property (nonatomic, strong) NSString * chatstatus;
@property (nonatomic, strong) NSString * orignalSender;
@property (nonatomic, strong) NSString * readstatus;
@property (nonatomic, strong) NSString * receiver;
@property (nonatomic, strong) NSString * sender;
@property (nonatomic, strong) NSString * translate;
@property (nonatomic, strong) NSString * messagetype;
@property (nonatomic, strong) NSString * chattype;
@property (nonatomic, strong) NSString * translatedText;
@property (nonatomic, strong) NSString * userLanguageCode;
@property (nonatomic, strong) NSString * isMultilingualChat;

- (id) init:(NSString*)content;
@end
