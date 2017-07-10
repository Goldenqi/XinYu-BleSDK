//
//  BluetoothManager.h
//  WeightBloodScaleBlePortTest
//
//  Created by 金琦 on 16/9/9.
//  Copyright © 2016年 JinQi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BleTransmit.h"
#import "XinYuBleDataParser.h"
#import "EnumerationType.h"

///fewfewfw
@protocol BluetoothManagerDelegate <NSObject>

@required
/**
 *  连接设备成功
 */
-(void) bluetoothManagerDidConnectPeripheral;

/**
 *  连接设备失败，断开连接
 */
-(void) bluetoothManagerDidDisconnectPeripheral;

/**
 *  手机端蓝牙状态
 *
 *  @param state 蓝牙状态
 */
-(void) bluetoothManagerUpdateCenteralManagerState:(CBCentralManagerState)state;

/**
 *  获得经过解析的测量数据模型
 *
 *  @param result WeightScale，BloodPressure，KitchenScale，FatScale
 */
-(void) bluetoothManagerDidRecieveMeasureResult:(NSObject *)result;

/**
 *  向设备发送命令成功
 */
-(void) bluetoothManagerDidSendMessageToScale;

@end

typedef void(^RequestHistoryDataNmuberCompletionHandle)(NSInteger number);
typedef void(^RequestHistoryDataCompletionHandle)(NSArray *dataArr);


@interface BluetoothManager : NSObject

@property (nonatomic, assign) XYDeviceType currentDeviceType;

@property (nonatomic, weak) id<BluetoothManagerDelegate>delegate;

+ (instancetype)sharedInstance;

/**
 *  扫描外设，扫描到即返回按距离递增的设备数组,如果在超时时间内没有搜索到设备返回错误
 *
 *  @param type 扫描设备类型
 *  @param timeout 超时时间
 *  @param complete   成功返回设备数组
 *  @param failed  失败回调
 */
- (void)startScanningPeripheralWithDeviceType:(XYDeviceType)type timeout:(float) timeout complete:(ScanDeviceCompletionHandle)complete failed:(ScanDeviceFailedBlock)failed;

/**
 连接外设，连接成功自动停止扫描
 */
- (void)connectPeripheral:(CBPeripheral *) peripheral;

/**
 取消连接
 */
- (void)cancelConnectPeripheral;

/**
 *  改变设备单位
 *  厨房秤支持：g、ml、oz、lb:oz
 *  体重秤脂肪秤支持：kg、lb、st:lb
 *  @param unitType   单位类型
 *  @param deviceType 设备类型
 */
- (void)setUnit:(XYUnitType)unitType Scale:(XYDeviceType)deviceType ;

/**
 *  向脂肪秤设置个人信息
 *
 *  @param Id     用户id
 *  @param gender 性别
 *  @param height 身高
 *  @param age    年龄
 */
- (void)setUserId:(NSInteger)Id gender:(BOOL)gender height:(NSInteger)height age:(NSInteger)age;

/**
 *  厨房秤去皮
 */
- (void)tareToZero;

/**
 设置设备时间

 @param date
 */
- (void)setTime:(NSDate *) date;

- (void)requestNmuberOfHistoryDataWithUserId:(NSInteger)userId complete:(RequestHistoryDataNmuberCompletionHandle)block;

/**
 获取设备历史数据

 @param userId 用户id
 */
- (void)requestHistoryDataWithUserId:(NSInteger)userId complete:(RequestHistoryDataCompletionHandle)block;


@end
