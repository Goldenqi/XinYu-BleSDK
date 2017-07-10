//
//  XYBleDataParser.h
//  BleTransmit
//
//  Created by Sicrech on 15/12/9.
//  Copyright (c) 2015年 anfer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnumerationType.h"

//#define kSendCommandSuccess @"kSendCommandSuccess"
//#define kSendCommandFailed @"kSendCommandFailed"


@class WeightScale,BloodPressure,KitchenScale,FatScale;

FOUNDATION_EXTERN NSString *const kSendCommandSuccess;
FOUNDATION_EXTERN NSString *const kSendCommandFailed;
FOUNDATION_EXTERN NSString *const kNumberOfHistoryData; 
FOUNDATION_EXTERN NSString *const kGetHistoryData;


@interface XinYuBleDataParser : NSObject

/**
 *  根据广播包返回设备类型
 *
 *  @param data 广播数据中的ManufactureData;
 *
 *  @return 设备类型
 */
+ (XYDeviceType) scaleTypeWithManufacturerData:(NSData *) data;

+ (NSObject *) parseDeviceData:(XYDeviceType)deviceType data:(NSData *)data;

+ (NSString *) parseMacAddress:(NSData *)advertiseData;

@end

@interface WeightScale : NSObject
/**
 *  重量 单位为"kg"、"lb" 时 weightHigh为相应的数值 weightLow为0
        单位为复合单位"st:lb" 时  weightHigh为"st"的数值 weightLow为"lb"的数值
 */
@property (nonatomic, assign, readonly) float weightHigh;
@property (nonatomic, assign, readonly) float weightLow;

/**
 *  kg、lb、st:lb
 */
@property (nonatomic, assign, readonly) XYUnitType unit;

@property (nonatomic, assign, readonly) XYScaleErrorCode errorCode;

/*!
 *  @property isMeasured
 *
 *  @discussion 0:正在测量  1:测量完成
 */
@property (nonatomic, assign, readonly) BOOL isMeasured;

@end


@interface KitchenScale : NSObject
/**
 *  重量 单位为"g"、"fl.oz"、 "ml"时 weightHigh为相应的数值 weightLow为0
        单位为复合单位"lb:oz" 时  weightHigh为"lb"的数值 weightLow为"oz"的数值
 */
@property (nonatomic, assign, readonly) float weightHigh;
@property (nonatomic, assign, readonly) float weightLow;

/**
 *  g、fl.oz、ml、lb：oz
 */
@property (nonatomic, assign, readonly) XYUnitType unit;

@property (nonatomic, assign, readonly) XYScaleErrorCode errorCode;

/**
 *  0:测量中   
    1：测量完成
 */
@property (nonatomic, assign, readonly) BOOL isMeasured;

@end


@interface FatScale : NSObject

/**
 *  value重量数值，单位始终为kg
 */
@property (nonatomic, assign, readonly) float value;
@property (nonatomic, assign, readonly) XYScaleErrorCode errorCode;
@property (nonatomic, assign, readonly) BOOL isMeasured; //0:测量中   1：测量完成
@property (nonatomic, assign, readonly) float fatPercent;
@property (nonatomic, assign, readonly) float waterPercent;
@property (nonatomic, assign, readonly) float musclePercent;
@property (nonatomic, assign, readonly) float basicCalory;
@property (nonatomic, assign, readonly) float bone;
@property (nonatomic, assign, readonly) BOOL sendPersonalInfoSuccess;
@property (nonatomic, assign, readonly) XYUnitType unit;
@property (nonatomic, assign, readonly) NSInteger numOfPoint;
@end

@interface FatScaleHistory : FatScale
@property (nonatomic, assign, readonly) NSInteger userId;
@property (nonatomic, assign, readonly) NSTimeInterval timeStamp;
@end

@interface BloodPressure : NSObject

/**
 *  高压 单位HHmg
 */
@property (nonatomic, assign, readonly) NSInteger SBP;

/**
 *  低压 单位HHmg
 */
@property (nonatomic, assign, readonly) NSInteger DBP;

/**
 *  心率 单位bmp
 */
@property (nonatomic, assign, readonly) NSInteger heartRate;

/*
 *  错误类型
 */
@property (nonatomic, assign, readonly) XYBloodPressureErrorCode errorCode;

/*!
 *  @property isMeasured
 *
 *  @discussion 0:正在测试 1:测试完成
 */
@property (nonatomic, assign, readonly) BOOL isMeasured;

/*!
 *  @property tempValue
 *
 *  @discussion 测量过程中的临时数值
 */
@property (nonatomic, assign, readonly) NSInteger tempValue;

/*!
 *  @property isArrhythmia
 *
 *  @discussion 0:心率正常 1:心率不齐
 */
@property (nonatomic, assign, readonly) BOOL isArrhythmia;

@end








