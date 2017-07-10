
//  BleTransmit.m
//  BleTransmit
//
//  Created by anfer on 15-2-3.
//  Copyright (c) 2015年 anfer. All rights reserved.
//

#import "BleTransmit.h"
#import "XinYuBleDataParser.h"
#import "XinYuBleDataWrapper.h"


@interface BleTransmit ()

@property (nonatomic,strong) ScanDeviceCompletionHandle scanComplete;
@property (nonatomic,strong) ScanDeviceFailedBlock scanFailed;


@property (nonatomic,strong) CBCentralManager *activeCentralManager; //当前主机
@property (nonatomic,readwrite) NSUInteger currentCentralManagerState;
@property (nonatomic,readwrite) CBPeripheral *activePeripheral;
@property (nonatomic,readwrite) NSMutableArray *peripherals;
@property (nonatomic,readwrite) NSMutableArray *scales;
@property (nonatomic,readwrite) NSArray *servicesUUID;

@property (nonatomic,strong) CBCharacteristic *writeCharacteristic;

@property (nonatomic,strong) NSTimer *scanFailedTimer;

@property (nonatomic, assign) XYDeviceType currentDeviceType;

@property (nonatomic, assign) BOOL isFoundDevice;

- (void)scanWillStop: (NSTimer *) timer;

@end

@interface ScanDevice ()

@property (nonatomic,strong) CBPeripheral *peripheral;
@property (nonatomic,assign) NSInteger rssi;
@property (nonnull, strong) NSString *macAddress;

@end


@implementation ScanDevice

@end
/*----------- 碧德脂肪秤 ------------*/

NSString *const fatScaleServiceUUID =@"FFCC";
NSString *const fatScaleWriteCharacteristicUUID =@"FFC1";
NSString *const fatScaleLockWeightCharacteristicUUID =@"FFC2";
NSString *const fatScaleRealTimeWeightCharacteristicUUID = @"FFC3";


//NSString *const wristBandServiceUUID = @"AAA0";
//NSString *const wristBandWriteCharacteristicUUID = @"AAA6";
//NSString *const wristBandReadCharacteristicUUID = @"AAA7";


/*----------------- 新版透传协议 ---------------*/
NSString *const deviceServiceUUID = @"FFF0";                //服务ID
NSString *const deviceWriteCharacteristicUUID = @"FFF2";    //写数据特征值
NSString *const deviceReadCharacteristicUUID = @"FFF1";     //读数据特征值


@implementation BleTransmit

- (instancetype)init
{
    self = [super init];
    if (self) {
        #pragma mark
        _activeCentralManager = [[CBCentralManager alloc] initWithDelegate:(id<CBCentralManagerDelegate>)self queue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)scan{

    [_activeCentralManager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark 单例蓝牙管理对象
+ (instancetype) sharedInstance{
    static BleTransmit *bleTransmit = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bleTransmit = [[BleTransmit alloc] init];
    });
    return bleTransmit;
}

#pragma mark  懒加载 lazy init 存储周边设备数组
- (NSMutableArray *) peripherals{
    if (!_peripherals) {
        _peripherals = [[NSMutableArray alloc] init];
    }
    return _peripherals;
}

- (NSArray *) servicesUUID{
    if (!_servicesUUID) {

        _servicesUUID = @[[CBUUID UUIDWithString:@"FFCC"],[CBUUID UUIDWithString:@"FFF0"]];
    }
    return _servicesUUID;
}

- (NSMutableArray *) scales{
    if (!_scales) {
        _scales = [[NSMutableArray alloc] init];
    }
    return _scales;
}


#pragma mark 中心设备状态更新
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    self.currentCentralManagerState = [central state];
    
    if ([_activeCentralManager isEqual:central]) {
        
    }
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        
    }
    else if ((central.state == CBCentralManagerStatePoweredOff) || (central.state == CBCentralManagerStateUnsupported)) {

    }
}

#pragma mark （self）开始搜索 以数组返回周边设备对象
-(void)startScanningPeripheralWithDeviceType:(XYDeviceType)type timeout:(float)timeout complete:(ScanDeviceCompletionHandle)complete failed:(ScanDeviceFailedBlock)failed{

    self.scanComplete = complete;
    self.scanFailed = failed;
    
    [self.peripherals removeAllObjects];
    [self.scales removeAllObjects];

    self.isFoundDevice = NO;
    self.currentDeviceType = type;
    
    self.scanFailedTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(scanWillStop:) userInfo:nil repeats:NO];
    
    #pragma mark 搜索周边设备
    [_activeCentralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
}

#pragma mark 扫描停止
- (void)scanWillStop: (NSTimer *) timer{

    [self stopCentralScan];
    
    if (!self.isFoundDevice) {
        self.scanFailed();
    }
}

#pragma mark - 发现设备
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    
    MYLOG(@"ad-DATA == %@",[advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey]);
    
    XYDeviceType tempType = [XinYuBleDataParser scaleTypeWithManufacturerData:[advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey]];
    
    if (tempType == XYDeviceUnknow) {
        return;
    }
    
    if (![self.peripherals containsObject:peripheral]) {
        
        if (self.currentDeviceType == XYDeviceBDFatScale) {
            if (tempType == XYDeviceBDFatScale || tempType == XYDeviceFatScale) {
                [self didDiscoverPeripheral:peripheral
                          advertisementData:advertisementData
                                       RSSI:RSSI];
            }
        }
        else{
            if (tempType == self.currentDeviceType) {
                [self didDiscoverPeripheral:peripheral
                          advertisementData:advertisementData
                                       RSSI:RSSI];
            }
        }
    }
}

-(void)didDiscoverPeripheral:(CBPeripheral *)peripheral
           advertisementData:(NSDictionary *)advertisementData
                        RSSI:(NSNumber *)RSSI {
    
    self.isFoundDevice = YES;
    
    ScanDevice *device = [[ScanDevice alloc]init];
    device.peripheral = peripheral;
    device.rssi = [RSSI integerValue];
    device.macAddress = [XinYuBleDataParser parseMacAddress:[advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey]];
    
    [self.peripherals addObject:peripheral];
    [self.scales addObject:device];
    
    [self filterBleDevice];
}

//按设备距离递增排序
- (void) filterBleDevice{
    
    if (self.scanFailedTimer) {
        [self.scanFailedTimer invalidate];
    }
    
    if (self.scales.count <= 1) {

        self.scanComplete(self.scales);
    }else{
        //按RSSI 降序排序
        [self.scales sortUsingComparator:^NSComparisonResult(ScanDevice *obj1, ScanDevice *obj2) {
            if (obj1.rssi < obj2.rssi) {
                return NSOrderedDescending;
            }
            return NSOrderedAscending;
        }];

        self.scanComplete(self.scales);
    }
}

#pragma mark - 连接设备
- (void) connectPeripheral:(CBPeripheral *) peripheral{
    
    if (peripheral.state == CBPeripheralStateDisconnected){
        
        [self stopCentralScan];
        
        // 连接设备
        [_activeCentralManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey : @YES}];
	}
}

#pragma mark - 获取系统配对设备
-(NSArray *)getSystemLinkPeripheral{
    
//    NSArray *serviceUUID = @[[CBUUID UUIDWithString:wristBandServiceUUID]];
//    
//    NSArray *arr =  [self.activeCentralManager retrieveConnectedPeripheralsWithServices:serviceUUID];
//
//    LOG(@"arr = %@",arr);    
    return nil;
}

-(void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals{
    
//    LOG(@"centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals");
}

#pragma mark - 连接上外设
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    self.scanFailed = nil;
    
    self.activePeripheral = peripheral;
    self.activePeripheral.delegate = self;
  
    [self.activePeripheral discoverServices:nil];
    
    [self stopCentralScan];
}

#pragma mark - 连接外设失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
//    LOG(@"\n连接外设失败Error : %@",error);
    
    [self.delegate centralDidFailToConnectPeripheral];
}

#pragma mark - 已经发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
   
    for (CBService *service in peripheral.services) {
        
        //新版统一透传协议
        if ([service.UUID isEqual:[CBUUID UUIDWithString:deviceServiceUUID]]) {
            [peripheral discoverCharacteristics:nil forService:service];
            break;
        }
        //碧德透传协议
        else  if ([service.UUID isEqual:[CBUUID UUIDWithString:fatScaleServiceUUID]]) {
            [peripheral discoverCharacteristics:nil forService:service];
            break;
        }
    }
}

#pragma mark  - 扫描特征值
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    if (!error) {
        //新版透传协议
        if ([service.UUID isEqual:[CBUUID UUIDWithString:deviceServiceUUID]]){
            
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:deviceReadCharacteristicUUID]]) {
                    //特征值以通知形式 使能特征值
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:deviceWriteCharacteristicUUID]]) {
                    
                    _writeCharacteristic = characteristic;
                    
                    [self.delegate centralDidConnectPeripheral];
                }
            }
        }
        //碧德协议
        else if ([service.UUID isEqual:[CBUUID UUIDWithString:fatScaleServiceUUID]]){
            
            for (CBCharacteristic *characteristic in service.characteristics) {
                
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:fatScaleRealTimeWeightCharacteristicUUID]]) {
                    //特征值以通知形式 使能特征值
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:fatScaleLockWeightCharacteristicUUID]]){
                   
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:fatScaleWriteCharacteristicUUID]]) {
                
                    _writeCharacteristic = characteristic;
                    
                    [self.delegate centralDidConnectPeripheral];
                }
            }
        }
    }
}

#pragma mark （self）- 取消连接
- (void) cancelConnectWithPeripheral{
    if (self.activePeripheral) {
        [_activeCentralManager cancelPeripheralConnection:self.activePeripheral];
        _writeCharacteristic = nil;
    }
}

#pragma mark - 中心设备断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    [self.delegate centralDidFailToConnectPeripheral];
    
    if ([_writeCharacteristic.UUID isEqual:[CBUUID UUIDWithString:deviceWriteCharacteristicUUID]] || [_writeCharacteristic.UUID isEqual:[CBUUID UUIDWithString:fatScaleWriteCharacteristicUUID]]) {
        // 更新状态 自动重连
        [self connectPeripheral:peripheral];
    }
}

#pragma mark - 发送数据
- (void)sendData:(NSData *)data{
 
    [self writeValue:self.activePeripheral characteristic:_writeCharacteristic data:data];
}


#pragma mark - 透连模式通过特征值接收数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (!error) {
        
        //新版透传协议
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:deviceReadCharacteristicUUID]]){
            [self.delegate peripheralUpdateValue:characteristic.value];
        }
        //碧德透传协议
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:fatScaleRealTimeWeightCharacteristicUUID]] || [characteristic.UUID isEqual:[CBUUID UUIDWithString:fatScaleLockWeightCharacteristicUUID]]){
            
            [self.delegate peripheralUpdateValue:characteristic.value];
        }
    }
    else {
    }
}

#pragma mark - 写数据到特征值
- (void) writeValue:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic data:(NSData *)data{
   
    if (data != nil) {
       
        if ([peripheral isEqual:_activePeripheral] && peripheral.state==CBPeripheralStateConnected)
        {
            if (characteristic != nil) {
                
                if(characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse)
                {
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
                }else
                {
                    //有回复的
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                }
            }
        }
    }
}

/*
// 从特征值读取数据
-(void) readValue:(CBPeripheral *)peripheral characteristicUUID:(CBCharacteristic *)characteristic{
    if ([peripheral isEqual:_activePeripheral] && [peripheral isConnected])
    {
        if (characteristic != nil) {
            NSLog(@"成功从特征值:%@ 读数据\n", characteristic);
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
}
*/

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"DidUpdateRssi:%ld",(long)peripheral.RSSI.integerValue);
}

- (void)stopCentralScan{
    
    [self.activeCentralManager stopScan];
   
//    [self.scanTimer setFireDate:[NSDate distantFuture]];
    
        /*
        for (NSInteger i = 0; i < self.peripherals.count; i++) {
           
            CBPeripheral *peripheral = [self.peripherals objectAtIndex:i];
           
            ScanDevice *device = [self.scales objectAtIndex:i];
            
            NSString *uuidStr = [peripheral.identifier UUIDString];
            
            if ([uuidStr isEqualToString:[self.activePeripheral.identifier UUIDString]]) {
                [self.peripherals removeObject:peripheral];
            }
            
            if ([uuidStr isEqualToString:[device.peripheral.identifier UUIDString]]) {
                [self.scales removeObject:device];
            }
        }
        */
}
@end
