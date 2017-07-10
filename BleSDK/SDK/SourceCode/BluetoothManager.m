//
//  BluetoothManager.m
//  WeightBloodScaleBlePortTest
//
//  Created by 金琦 on 16/9/9.
//  Copyright © 2016年 JinQi. All rights reserved.
//

#import "BluetoothManager.h"
#import "XinYuBleDataWrapper.h"

@interface BluetoothManager () <BleTransmitDelegate>

@property (nonatomic, strong) BleTransmit *bleTransmit;

@property (nonatomic, weak) RequestHistoryDataNmuberCompletionHandle numberBlock;
@property (nonatomic, weak) RequestHistoryDataCompletionHandle dataBlock;
@property (nonatomic, strong) NSMutableArray *dataArr;
@end

@implementation BluetoothManager 
{
    BOOL isAddObserverForRequestNumberOfHistoryData;
    NSInteger numberOfHistoryData;
}

#pragma mark - init

-(NSMutableArray *)dataArr{
    if (!_dataArr) {
        _dataArr = [[NSMutableArray alloc]init];
    }
    return _dataArr;
}

+ (instancetype) sharedInstance{
    static BluetoothManager *bluetoothManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bluetoothManager = [[BluetoothManager alloc] init];
    });
    return bluetoothManager;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        self.bleTransmit = [BleTransmit sharedInstance];
        [self.bleTransmit addObserver:self forKeyPath:@"currentCentralManagerState" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
        self.bleTransmit.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendCommandSuccess) name:kSendCommandSuccess object:nil];
        isAddObserverForRequestNumberOfHistoryData = NO;
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"currentCentralManagerState"]) {
        [self.delegate bluetoothManagerUpdateCenteralManagerState:self.bleTransmit.currentCentralManagerState];
    }
}

#pragma mark - Function
-(void)startScanningPeripheralWithDeviceType:(XYDeviceType)type timeout:(float)timeout complete:(ScanDeviceCompletionHandle)complete failed:(ScanDeviceFailedBlock)failed{
    
    self.currentDeviceType = type;
    MYLOG(@"self.currentDeviceType = %ld",(long)self.currentDeviceType);
    
    [self.bleTransmit startScanningPeripheralWithDeviceType:type timeout:timeout complete:^(NSArray *results) {
        complete(results);
    } failed:^{
        failed();
    }];
}

-(void)connectPeripheral:(CBPeripheral *)peripheral{
    [self.bleTransmit connectPeripheral:peripheral];
}

-(void)cancelConnectPeripheral{
    [self.bleTransmit cancelConnectWithPeripheral];
}

-(void) setUnit:(XYUnitType)unitType Scale:(XYDeviceType)deviceType{
    
    if (unitType < 3) {
        
        if (deviceType == XYDeviceBDFatScale) {
            [self.bleTransmit sendData:[XinYuBleDataWrapper getBDFatScaleUnitDataWithUnitType:unitType]];
        }
        else if (deviceType == XYDeviceWeightScale){
            [self.bleTransmit sendData:[XinYuBleDataWrapper getUnitDataWithUnitType:unitType]];
        }
    }
    else{
        if (deviceType == XYDeviceKitchenScale) {
            [self.bleTransmit sendData:[XinYuBleDataWrapper getUnitDataWithUnitType:unitType]];
        }
    }
    [self.bleTransmit sendData:[XinYuBleDataWrapper getUnitDataWithUnitType:XYUnitG]];
}

-(void)setUserId:(NSInteger)Id gender:(BOOL)gender height:(NSInteger)height age:(NSInteger)age{
    
    if (self.currentDeviceType == XYDeviceBDFatScale) {
        NSData *sendData = [XinYuBleDataWrapper getUserDataWithId:Id gender:gender height:height age:age];
        
        [self.bleTransmit sendData:sendData];
        [self.bleTransmit sendData:[XinYuBleDataWrapper getUnitDataWithUnitType:XYUnitG]];
    }
}

-(void)tareToZero{
    if (self.currentDeviceType == XYDeviceKitchenScale) {
        [self.bleTransmit sendData:[XinYuBleDataWrapper getTareData]];
    }
}

-(void)setTime:(NSDate *)date{
    NSData *data = [XinYuBleDataWrapper getTimeDataWithDate:date];
    [self.bleTransmit sendData:data];
}

#pragma mark - HistoryData
-(void)requestNmuberOfHistoryDataWithUserId:(NSInteger)userId complete:(RequestHistoryDataNmuberCompletionHandle)block{
    if (!isAddObserverForRequestNumberOfHistoryData) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getNumber:) name:kNumberOfHistoryData object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getHistoryData:) name:kGetHistoryData object:nil];
    }
    numberOfHistoryData = 0;
    self.numberBlock = block;
    NSData *requestData = [XinYuBleDataWrapper getRequestDataNumberOfHistoryWithUserId:userId];
    [self.bleTransmit sendData:requestData];
}

-(void)getNumber:(NSNotification *)notify{
    if ([notify.object isMemberOfClass:[NSNumber class]]) {
        NSNumber *number = notify.object;
        numberOfHistoryData = [number integerValue];
        self.numberBlock(numberOfHistoryData);
    }
}

-(void)requestHistoryDataWithUserId:(NSInteger)userId complete:(RequestHistoryDataCompletionHandle)block{
    self.dataBlock = block;
    NSData *requestData = [XinYuBleDataWrapper getRequestDataAllHistoryWithUserId:userId];
    [self.bleTransmit sendData:requestData];
}

-(void)getHistoryData:(NSNotification *)notify{
    if ([notify.object isMemberOfClass:[FatScaleHistory class]]) {
        FatScaleHistory *data = notify.object;
        [self.dataArr addObject:data];
        if (_dataArr.count == numberOfHistoryData) {
            self.dataBlock(_dataArr);
        }
    }
}

#pragma mark - BleTransmit代理
-(void)centralDidConnectPeripheral{
    [self.delegate bluetoothManagerDidConnectPeripheral];
}

-(void)centralDidFailToConnectPeripheral{
    [self.delegate bluetoothManagerDidDisconnectPeripheral];
}

-(void)peripheralUpdateValue:(NSData *)data{

    NSObject *measureData;
    
    measureData = [XinYuBleDataParser parseDeviceData:self.currentDeviceType data:data];
    
    [self.delegate bluetoothManagerDidRecieveMeasureResult:measureData];
}

-(void)sendCommandSuccess{
    
    [self.delegate bluetoothManagerDidSendMessageToScale];
}
@end
