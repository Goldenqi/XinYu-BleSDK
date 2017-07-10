//
//  XYBleDataWrapper.h
//  BleTransmit
//
//  Created by Sicrech on 15/12/9.
//  Copyright (c) 2015年 anfer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnumerationType.h"

@interface XinYuBleDataWrapper : NSObject

/**
 *  获取蓝牙设备设置单位命令
 */
+ (NSData *)getUnitDataWithUnitType:(XYUnitType)unitType;

/**
 *  去皮命令
 */
+ (NSData *)getTareData;

/**
 *  @return 碧德协议 设置单位
 */
+(NSData *)getBDFatScaleUnitDataWithUnitType:(XYUnitType)unitType;

/**
 *  @return 碧德协议 设置个人信息
 */
+ (NSData *)getUserDataWithId:(NSInteger)Id gender:(BOOL)gender height:(NSInteger)height age:(NSInteger)age;

/**
 *  @return 新统一协议 设置个人信息命令
 */
+ (NSData *)getNewProtocolUserDataWithId:(NSInteger)Id gender:(BOOL)gender height:(NSInteger)height age:(NSInteger)age;

/**
 设置设备时间命令

 @param date
 @return
 */
+ (NSData *)getTimeDataWithDate:(NSDate *)date;

/**
 获取按UserId请求历史记录条数命令

 @param userId
 @return
 */
+ (NSData *)getRequestDataNumberOfHistoryWithUserId:(NSInteger)userId;

/**
 获取按UserId请求所有历史记录命令

 @param userId
 @return
 */
+ (NSData *)getRequestDataAllHistoryWithUserId:(NSInteger)userId;


@end
