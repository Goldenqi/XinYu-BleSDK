//
//  BleTransmit.h
//  BleTransmit
//
//  Created by anfer on 15-2-3.
//  Copyright (c) 2015年 anfer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "EnumerationType.h"

@protocol BleTransmitDelegate <NSObject>

@required
-(void)centralDidConnectPeripheral;

@required
-(void)centralDidFailToConnectPeripheral;

@required
-(void)peripheralUpdateValue:(NSData *_Nonnull)data;

@end

typedef void(^ScanDeviceCompletionHandle)(NSArray *results);
typedef void(^ScanDeviceFailedBlock)();

@interface BleTransmit : NSObject <CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic,readonly) CBPeripheral *activePeripheral;  //读取当前连接外设
@property (nonatomic,readonly) NSUInteger currentCentralManagerState; //读取主机状态

@property (nonatomic, weak) id<BleTransmitDelegate>delegate;

//读取扫描到的蓝牙设备
@property (nonatomic,readonly) NSMutableArray *peripherals;


+ (instancetype) sharedInstance;

/**
 *  扫描外设，扫描到即返回按距离递增的设备数组,如果在超时时间内没有搜索到设备返回错误
 *  
 *  @param type 扫描设备类型
 *  @param timeout 超时时间
 *  @param complete   成功返回设备数组
 *  @param failed  失败回调
 */
- (void) startScanningPeripheralWithDeviceType:(XYDeviceType)type timeout:(float) timeout complete:(ScanDeviceCompletionHandle)complete failed:(ScanDeviceFailedBlock)failed;

/**
 取消扫描
 */
-(void)stopCentralScan;

/**
 连接外设，连接成功自动停止扫描
 */
- (void) connectPeripheral:(CBPeripheral *) peripheral;

/**
 取消连接
 */
- (void) cancelConnectWithPeripheral;

/**
 向透传设备发送数据
 */
- (void) sendData:(NSData *) data;

/**
 获取系统已经配对的设备
 */
-(NSArray *)getSystemLinkPeripheral;

@end

@interface ScanDevice : NSObject

@property (nonatomic,strong,readonly) CBPeripheral *peripheral;

@property (nonnull, strong, readonly) NSString *macAddress;

@end

