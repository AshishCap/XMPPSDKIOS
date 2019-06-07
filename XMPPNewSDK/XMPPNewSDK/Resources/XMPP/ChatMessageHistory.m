//
//  ChatMessageHistory.m
//  GoIDD
//
//  Created by apple on 20/06/17.
//  Copyright © 2017 GoIDD. All rights reserved.
//

#import "ChatMessageHistory.h"

@implementation ChatMessageHistory

- (id) init:(NSString*)content
{
    if (self=[super init])
    {
        NSData *jsonData        = [content dataUsingEncoding:NSUTF8StringEncoding];
        //let data = str.data(using: .utf8)
        NSDictionary *json      = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
//        self.chatBaseContact    = [json valueForKey:@"chatBaseContact"];
//        self.body               = [json valueForKey:@"body"];
//        self.date               = [json valueForKey:@"Date"];
//        self.time               = [json valueForKey:@"Time"];
//        self.chatname           = [json valueForKey:@"chatname"];
//        self.chatstatus         = [json valueForKey:@"chatstatus"];
//        self.readstatus         = [json valueForKey:@"readstatus"];
//        self.receiver           = [json valueForKey:@"receiver"];
//        self.sender             = [json valueForKey:@"sender"];
//        self.translate          = [json valueForKey:@"translatedCode"];
        self.messagetype        = [json valueForKey:@"type"];
//        self.chattype           = [json valueForKey:@"chattype"];
//        self.orignalSender      = [json valueForKey:@"orignalSender"];
//        self.translatedText     = [json valueForKey:@"translatedText"];
//        self.userLanguageCode   = [json valueForKey:@"userLanguageCode"];
//        self.isMultilingualChat   = [json valueForKey:@"isMultilingualChat"];
    }
    return self;
}
@end
