//
//  XYBleDataWrapper.m
//  BleTransmit
//
//  Created by Sicrech on 15/12/9.
//  Copyright (c) 2015年 anfer. All rights reserved.
//

#import "XinYuBleDataWrapper.h"


@interface XinYuBleDataWrapper ()

@end

@implementation XinYuBleDataWrapper

+ (XinYuBleDataWrapper *)sharedInstance {
    static dispatch_once_t once;
    static XinYuBleDataWrapper *sharedWrapper;
    dispatch_once(&once, ^ {
        sharedWrapper = [[self alloc] init];
    });
    return sharedWrapper;
}

#pragma mark - Function

+(NSInteger)verifyAge:(NSInteger)age{
    age = age ?: 18;
    age = age > 100?: 18;
    return age;
}

+(NSInteger)verifyUserId:(NSInteger)userId{
    userId = userId ?: 1;
    userId = userId < 65?: 1;
    return userId;
}

+(NSInteger)verifyHeight:(NSInteger)height{
    height = height ?: 170;
    height = height > 240 ?: 170;
    return height;
}

+(NSData *)getTareData{
    return  [self wrapDataWithCommandID:0x03
                                 length:0
                                   data:nil];
}

+(NSData *)dataWithUserId:(NSInteger)userid{
    Byte userByte[1];
    userByte[0] = [self verifyUserId:userid];
    return [NSData dataWithBytes:userByte length:1];
}

+(NSData *)getTimeDataWithDate:(NSDate *)date{
    if (!date) {
        date = [NSDate date];
    }
    
    int timeStamp = [date timeIntervalSince1970];
    Byte sendByte[4];
    sendByte[0] = timeStamp>>24;
    sendByte[1] = timeStamp>>16;
    sendByte[2] = timeStamp>>8;
    sendByte[3] = timeStamp;
    
    int dataLength = sizeof(sendByte);
    return [self wrapDataWithCommandID:0x01 length:dataLength data:[NSData dataWithBytes:sendByte length:dataLength]];
}

+(NSData *)getUnitDataWithUnitType:(XYUnitType)unitType{
    Byte unit[1];
    
    unit[0] = unitType;
    
    return  [self wrapDataWithCommandID:0x02
                                 length:1
                                   data:[NSData dataWithBytes:unit length:1]];
    return nil;
}

+(NSData *)getRequestDataAllHistoryWithUserId:(NSInteger)userId{
    return [self wrapDataWithCommandID:0x05 length:1 data:[self dataWithUserId:userId]];
}

+(NSData *)getBDFatScaleUnitDataWithUnitType:(XYUnitType)unitType{
    
    NSInteger value;
    
    Byte unitByte [3];
    memset(unitByte, 0x00, sizeof(unitByte));
    
    if (unitType == XYUnitKG) {
        
        value = 1;
    } else if(unitType == XYUnitLB){
        
        value = 2;
    }
    else{
        value = 3;
    }
    
    unitByte [0] = 0x82;
    unitByte [1] = value;
    unitByte [2] = 0x00;
    return [NSData dataWithBytes:unitByte length:3 ];
}

+(NSData *)getUserDataWithId:(NSInteger)Id gender:(BOOL)gender height:(NSInteger)height age:(NSInteger)age{
    
    Byte wirteByte [5];
    memset(wirteByte, 0x00, sizeof(wirteByte));
    
    wirteByte [0] = 0x83;
    wirteByte [1] = [self verifyUserId:Id];
    wirteByte [2] = gender;
    wirteByte [3] = [self verifyAge:age];
    wirteByte [4] = [self verifyHeight:height];
    
    NSData *sendData = [NSData dataWithBytes:wirteByte length:5 ];
    return sendData;
}

+(NSData *)wrapDataWithCommandID:(Byte)cid length:(int) len data:(NSData *) da{
   
    Byte sendByte[20];
    /*
     void *memset(void *s, int ch, size_t n);
    
     函数解释：将s中前n个字节 （typedef unsigned int size_t ）用 ch 替换并返回 s 。
     memset：作用是在一段内存块中填充某个给定的值，它是对较大的结构体或数组进行清零操作的一种最快方法[1]  。
     */
    memset(sendByte, 0x00, sizeof(sendByte));
    
    sendByte[0] = 0xFA;
    sendByte[1] = cid;
    sendByte[2] = len;
    
    Byte *tempByte = (Byte *)[da bytes];

    for (int i=0; i<len; i++) {
        sendByte[3+i] = tempByte[i];
    }
    
    return [NSData dataWithBytes:sendByte length:sizeof(sendByte)];
}

+(NSData *)getRequestDataNumberOfHistoryWithUserId:(NSInteger)userId{
    return [self wrapDataWithCommandID:0x04 length:1 data:[self dataWithUserId:userId]];
}

@end
