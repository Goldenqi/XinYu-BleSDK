//
//  EnumerationType.h
//  WeightBloodScaleBlePortTest
//
//  Created by 金琦 on 16/9/8.
//  Copyright © 2016年 JinQi. All rights reserved.
//

#ifndef EnumerationType_h
#define EnumerationType_h

typedef NS_ENUM(NSInteger, XYDeviceType) {
    XYDeviceWeightScale = 0 ,
    XYDeviceBDFatScale , //旧碧得协议
    XYDeviceBloodPreScale ,
    XYDeviceKitchenScale ,
    XYDeviceFatScale ,
    XYDeviceUnknow
};

typedef NS_ENUM(NSInteger, XYUnitType) {
    
    XYUnitKG = 0 ,  //千克
    XYUnitLB,       //磅
    XYUnitSTLB , //英石
    XYUnitG ,   //克
    XYUnitML ,  //毫升
    XYUnitOZ,   //盎司
    XYUnitLBOZ,
    XYUnit500G
};

typedef NS_ENUM(NSInteger, XYScaleErrorCode) {

    XYScaleErrorCodeNoError = 0,
    XYScaleErrorCodeOverWeight,    //超重
    XYScaleErrorCodeNegativeValue,  //负值
    XYScaleErrorCodeLowPower,       //低电压
    XYScaleErrorCodeBodyImpedanceUnusual = 5   //人体阻抗异常
};

typedef NS_ENUM(NSInteger, XYBloodPressureErrorCode) {
    
    XYBloodPressureNormal = 0,
    XYBloodPressureSensorSignalAbnormalities,    //传感器异常
    XYBloodPressureNoPulseOrAirInCuffNotEmptied,  //检测不到脉搏或袖带空气未排空
    XYBloodPressureLeakingSituationDuringPressureOrVacuum,    //加压或减压的时候有漏气情况
    XYBloodPressureWristStrapTooLooseOrleak,    //腕带过松或漏气
    XYBloodPressureWristStrapTooTightOrBlockageInGasPath,    //腕带过紧或气路堵塞
    XYBloodPressureSeriouslyInterferenceDuringPressureMeasurement,    //测量中压力干扰严重
    XYBloodPressurePressureMoreThan300mmHg,    //压力值超过300mm汞柱
    XYBloodPressureCalibrationDataOrSavedICAnomaly,    //标定数据异常或存 储IC异常
    XYBloodPressureICKeyError    //IC key错误
};

#ifdef DEBUG

#define MYLOG(...) NSLog(__VA_ARGS__);

#else

#define MYLOG(...);

#endif

#endif /* EnumerationType_h */
