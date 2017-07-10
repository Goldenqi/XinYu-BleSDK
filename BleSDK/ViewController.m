//
//  ViewController.m
//  BleSDK
//
//  Created by 金琦 on 16/9/9.
//  Copyright © 2016年 JinQi. All rights reserved.
//

#import "ViewController.h"
//#import <BleSDKFramework/BleSDKFramework.h>
#import "BluetoothManager.h"

///Users/jinqi/百度云同步盘/工作/123科技项目/BleSDK/BleSDK/SDK/libBleSDKStaticLibrary_device.a
@interface ViewController ()<BluetoothManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *connectLabel;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (strong, nonatomic) BluetoothManager *bleManager;
@property (strong, nonatomic) NSTimer *fatResultTimer;
@property (strong, nonatomic) NSTimer *sendUserInfoTimer;
@property (strong, nonatomic) NSArray *fatResultTitleArr;
@property (strong, nonatomic) NSArray *fatValueArr;
@property (weak, nonatomic) IBOutlet UIButton *scanBtn;

@end

@implementation ViewController

-(NSArray *)fatResultTitleArr{
    if (!_fatResultTitleArr) {
        _fatResultTitleArr = @[@"体重：",
                               @"脂肪：",
                               @"骨骼：",
                               @"水分：",
                               @"卡路里：",
                               @"肌肉："];
    }
    return _fatResultTitleArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.bleManager = [BluetoothManager sharedInstance];
    self.bleManager.delegate = self;
    self.bleManager.currentDeviceType = XYDeviceWeightScale;
}

#pragma mark - BluetoothManagerDelegate代理
-(void)bluetoothManagerUpdateCenteralManagerState:(CBCentralManagerState)state{
    switch (state) {
        case CBCentralManagerStateUnknown: {
            self.connectLabel.text = @"状态未知";
            break;
        }
        case CBCentralManagerStateResetting: {
            self.connectLabel.text = @"重新设置";
            break;
        }
        case CBCentralManagerStateUnsupported: {
            self.connectLabel.text = @"设备不支持蓝牙";
            break;
        }
        case CBCentralManagerStateUnauthorized: {
            self.connectLabel.text = @"用户未授权";
            break;
        }
        case CBCentralManagerStatePoweredOff: {
            self.connectLabel.text = @"蓝牙电源关闭";
            break;
        }
        case CBCentralManagerStatePoweredOn: {
            self.connectLabel.text = @"蓝牙电源打开";
            break;
        }
    }
}

-(void)bluetoothManagerDidConnectPeripheral{
    self.connectLabel.text = @"连接成功";
    self.scanBtn.selected = YES;
    if (self.bleManager.currentDeviceType == XYDeviceBDFatScale ||
        self.bleManager.currentDeviceType == XYDeviceFatScale) {
        
        self.sendUserInfoTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(sendUserInfoCommand) userInfo:nil repeats:YES];
        
        [self.bleManager requestNmuberOfHistoryDataWithUserId:1 complete:^(NSInteger number) {
            [self requesHistoryData];
        }];
    }
}

-(void)requesHistoryData{
    [self.bleManager requestHistoryDataWithUserId:1 complete:^(NSArray *dataArr) {
        
    }];
}

-(void)bluetoothManagerDidDisconnectPeripheral{
    self.connectLabel.text = @"断开连接，准备扫描...";
    self.scanBtn.selected = NO;
}

-(void)bluetoothManagerDidRecieveMeasureResult:(NSObject *)result{
    
    if (self.bleManager.currentDeviceType == XYDeviceBDFatScale) {
        
        FatScale *fat = (FatScale *)result;

        if (fat.isMeasured) {
            
            [self appearFatScaleMeasuredResult:fat];
        } else {
            [self stopAppearFatResult];
            self.resultLabel.text = [NSString stringWithFormat:@"%.1f kg",fat.value];
        }
    }
    else if (self.bleManager.currentDeviceType == XYDeviceWeightScale) {
        
        WeightScale *weight = (WeightScale *)result;
        
        if (weight.weightLow == 0) {
            self.resultLabel.text = [NSString stringWithFormat:@"%.1f",weight.weightHigh];
        }
        else{
            self.resultLabel.text = [NSString stringWithFormat:@"%.1f  : %.1f ",weight.weightHigh,weight.weightLow];
        }
    }
    else if (self.bleManager.currentDeviceType == XYDeviceKitchenScale) {
        
        KitchenScale *kitchen = (KitchenScale *)result;
        
        if (kitchen.weightLow == 0) {
            self.resultLabel.text = [NSString stringWithFormat:@"%.1f",kitchen.weightHigh];
        }
        else{
            self.resultLabel.text = [NSString stringWithFormat:@"%.1f  : %.1f ",kitchen.weightHigh,kitchen.weightLow];
        }
    }
    else{
        BloodPressure *blood = (BloodPressure *)result;
        
        if (!blood.isMeasured) {
            self.resultLabel.text = [NSString stringWithFormat:@"%ld",blood.tempValue];
        }
        else{
            self.resultLabel.text = [NSString stringWithFormat:@"%ld %ld %ld",blood.SBP,blood.SBP,blood.heartRate];
        }
    }
}

-(void)bluetoothManagerDidSendMessageToScale{
    self.connectLabel.text = @"发送命令成功";
    
    if (self.sendUserInfoTimer) {
        [self.sendUserInfoTimer invalidate];
        self.sendUserInfoTimer = nil;
    }
}

#pragma mark - 脂肪秤数据显示
-(NSString *)floatToString:(CGFloat)value{
    return [NSString stringWithFormat:@"%.1f",value];
}

-(NSArray *)creatFatValueArr:(FatScale *)fatResult{
    
    if (!fatResult) {
        return @[@"0",@"0",@"0",@"0",@"0",@"0"];
    }
    return  @[
              [self floatToString:fatResult.value],
              [self floatToString:fatResult.fatPercent],
              [self floatToString:fatResult.bone],
              [self floatToString:fatResult.waterPercent],
              [self floatToString:fatResult.basicCalory],
              [self floatToString:fatResult.musclePercent],
              ];
}

-(void)appearFatScaleMeasuredResult:(FatScale *)fatResult{
    
    self.fatValueArr = [self creatFatValueArr:fatResult];
    [self starTimer];
}

-(void)starTimer{
    if (!self.fatResultTimer) {
        self.fatResultTimer = [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(appearFatValue) userInfo:nil repeats:YES];
        [self.fatResultTimer fire];
    }
    [self.fatResultTimer setFireDate:[NSDate distantPast]];
}

NSInteger i = 0;
-(void)appearFatValue{
    
    self.resultLabel.text = [NSString stringWithFormat:@"%@%@",self.fatResultTitleArr[i],self.fatValueArr[i]];
    
    if ((++i) == 6) {
        i = 0;
    }
}

-(void)stopAppearFatResult{
    [self.fatResultTimer setFireDate:[NSDate distantFuture]];
}

#pragma mark - 控制面板按钮
-(void)scanDevice{
    
    self.connectLabel.text = @"扫描3秒...";
    
    [self.bleManager startScanningPeripheralWithDeviceType:self.bleManager.currentDeviceType timeout:3.f complete:^(NSArray *results) {
        
        ScanDevice *device = [results firstObject];
        NSLog(@"device = %@",device.macAddress);
        [self.bleManager connectPeripheral:device.peripheral];
        
    } failed:^{
        
        self.scanBtn.selected = NO;
        self.connectLabel.text = @"扫描失败";
    }];
}

-(void)sendUserInfoCommand{
    
    self.connectLabel.text = @"发送个人信息命令...";
    
    [self.bleManager setUserId:1
                        gender:1
                        height:170
                           age:25];
}

- (IBAction)cancelConnect:(id)sender {
    self.scanBtn.selected = NO;
    [self.bleManager cancelConnectPeripheral];
}

- (IBAction)changeDevice:(UISegmentedControl *)sender {

    [_bleManager cancelConnectPeripheral];
    
    self.scanBtn.selected = NO;
    
    self.bleManager.currentDeviceType = sender.selectedSegmentIndex;
  
    if (self.bleManager.currentDeviceType != XYDeviceBDFatScale) {
        [self.sendUserInfoTimer invalidate];
        self.sendUserInfoTimer = nil;
       
        [self stopAppearFatResult];
        self.resultLabel.text = @"0";
    }
    
    [self scanDevice];
}

- (IBAction)reScan:(UIButton *)sender {
   
    if (self.scanBtn.selected) {
        return;
    }
    [self scanDevice];
}

- (IBAction)changeUnit:(UISegmentedControl *)sender {
    
    self.connectLabel.text = @"发送改变单位命令...";
    
    XYUnitType unit = sender.selectedSegmentIndex;
    
    if (sender.tag == 100) {
        if (sender.selectedSegmentIndex == 3) {
            unit = XYUnit500G;
        }
    }
    else{
        unit += 3;
    }
    
    [self.bleManager setUnit:unit
                       Scale:self.bleManager.currentDeviceType];
}

- (IBAction)kitchenTare:(UIButton *)sender {
    self.connectLabel.text = @"发送去皮命令...";
    [self.bleManager tareToZero];
}
#pragma mark

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)start:(UIButton *)sender {
    [self appearFatScaleMeasuredResult:nil];
}
- (IBAction)stop:(UIButton *)sender {
    [self stopAppearFatResult];
}

@end
