//
//  XYBleDataParser.m
//  BleTransmit
//
//  Created by Sicrech on 15/12/9.
//  Copyright (c) 2015年 anfer. All rights reserved.
//

#import "XinYuBleDataParser.h"

typedef void(^ParseValueComplete)(float valueHigh,float valueLow);

#define kUnit_kg @"kg"
#define kUnit_lb @"lb"
#define kUnit_stlb @"st lb"
#define kUnit_g @"g"
#define kUnit_oz @"oz"
#define kUnit_ml @"ml"
#define kUnit_floz @"fl.oz"
#define kUnit_lboz @"lb oz"

#pragma mark - 重量单位转换

#define KG_TO_LB 2.2046226

#define LB_TO_ST 0.0714285714

#define ST_TO_LB 14.00

#define G_TO_OZ 0.03527396

#define OZ_TO_G 28.3495231

#define LB_TO_OZ 16.00

#define KG_TO_500G 2.00

@interface WeightScale()

@property (nonatomic,assign) float weightHigh;
@property (nonatomic,assign) float weightLow;
@property (nonatomic,assign) XYUnitType unit;
@property (nonatomic,assign) XYScaleErrorCode errorCode;
@property (nonatomic,assign) BOOL isMeasured;
@property (nonatomic,assign) NSInteger numOfPoint;
@end

@implementation WeightScale

@end


@interface KitchenScale()

@property (nonatomic,assign) float weightHigh;
@property (nonatomic,assign) float weightLow;
@property (nonatomic,assign) XYUnitType unit;
@property (nonatomic,assign) XYScaleErrorCode errorCode;
@property (nonatomic,assign) BOOL isMeasured;
@property (nonatomic,assign) NSInteger numOfPoint;
@end

@implementation KitchenScale

@end

@interface BloodPressure ()

@property (nonatomic,assign) NSInteger SBP;
@property (nonatomic,assign) NSInteger DBP;
@property (nonatomic,assign) NSInteger heartRate;
@property (nonatomic,assign) XYBloodPressureErrorCode errorCode;
@property (nonatomic,assign) BOOL isMeasured;
@property (nonatomic,assign) NSInteger tempValue;
@property (nonatomic,assign) BOOL isArrhythmia;
@end
@implementation BloodPressure

@end

@interface FatScale ()

@property (nonatomic,assign) float value;
@property (nonatomic,assign) XYScaleErrorCode errorCode;
@property (nonatomic,assign) BOOL isMeasured; //0:测量中   1：测量完成
@property (nonatomic,assign) float fatPercent;
@property (nonatomic,assign) float waterPercent;
@property (nonatomic,assign) float musclePercent;
@property (nonatomic,assign) float basicCalory;
@property (nonatomic,assign) float bone;
@property (nonatomic,assign) XYUnitType unit;
@property (nonatomic,assign) NSInteger numOfPoint;
@property (nonatomic,assign) BOOL sendPersonalInfoSuccess;

@end

@implementation FatScale
@end

@interface FatScaleHistory ()
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, assign) NSTimeInterval timeStamp;
@end

@implementation FatScaleHistory
@end

@interface XinYuBleDataParser()

- (void)parseData:(NSData *)data withEntity:(NSObject *) obj;

//- (NSString *) unitFromCode:(NSUInteger) code;

@end


@implementation XinYuBleDataParser
{
    NSInteger steadyCount;
}

NSString *const kSendCommandSuccess = @"kSendCommandSuccess";
NSString *const kSendCommandFailed = @"kSendCommandFailed";
NSString *const kNumberOfHistoryData = @"kNumberOfHistoryData";
NSString *const kGetHistoryData = @"kGetHistoryData";

+ (XinYuBleDataParser *)sharedParser{
    static dispatch_once_t once;
    static XinYuBleDataParser *sharedWrapper;
    dispatch_once(&once, ^ {
        sharedWrapper = [[XinYuBleDataParser alloc] init];
    });
    return sharedWrapper;
}

+ (XYDeviceType) scaleTypeWithManufacturerData:(NSData *) data{
    
    if (data) {
        Byte *recByte = (Byte *) [data bytes];
        if ((recByte[0] == 0xFA)&&(recByte[1] == 0xFB)){
            if (recByte[4] ==0x00) {
                return XYDeviceWeightScale;
            }
            else if (recByte[4] ==0x01){
                return XYDeviceFatScale;
            }
            else if (recByte[4] ==0x02){
                return XYDeviceKitchenScale;
            }
            else if (recByte[4] ==0x03){
                return XYDeviceBloodPreScale;
            }
        }
        else if (recByte[0] == 0x02 || recByte[0] == 0x01 || recByte[0] == 0x06){
            return XYDeviceBDFatScale;
        }
        else if (recByte[0] == 0xb4 && recByte[2] == 0xb1 ){
            return XYDeviceBDFatScale;
        }
        return XYDeviceUnknow;
    }
    return XYDeviceUnknow;
}

+(NSString *)parseMacAddress:(NSData *)advertiseData{
    
    NSString *str = [NSString stringWithFormat:@"%@",advertiseData];
    //去掉收尾的空白字符和换行字符
    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //替换
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"<" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@">" withString:@""];

    NSMutableString *mac = [[NSMutableString alloc]initWithCapacity:17];
    NSInteger length = [str length];
    for (NSInteger i = length - 12; i < length; (i += 2)) {
        [mac appendString:[str substringWithRange:NSMakeRange(i, 2)]];
        if (i != (length - 2)) {
            [mac appendString:@":"];
        }
    }
    MYLOG(@"\nmac = %@",mac);
    return mac;
}

+ (NSObject *)parseDeviceData:(XYDeviceType)deviceType data:(NSData *)data{
    
    NSObject *parseData;
    
    switch (deviceType) {
        case XYDeviceWeightScale: {
            parseData = [self parseWeightScaleData:data];
            break;
        }
        case XYDeviceFatScale: {
            parseData = [self parseFatScaleData:data];
            break;
        }
        case XYDeviceBDFatScale: {
            parseData = [self parseBDFatScaleData:data];
            break;
        }
        case XYDeviceBloodPreScale: {
            parseData = [self parseBloodPressureData:data];
            break;
        }
        case XYDeviceKitchenScale: {
            parseData = [self parseKitchenScaleData:data];
            break;
        }
        case XYDeviceUnknow: {
            break;
        }
    }
    return parseData;
}

//解析碧德协议数据
+ (FatScale *) parseBDFatScaleData:(NSData *) data{

    FatScale *fatScale = [[FatScale alloc] init];
    Byte *weightByte = (Byte *)[data bytes];
    //不稳定
    if (weightByte[0]==0x01) {
        
        fatScale.value = ((weightByte[1])|weightByte[2]<<8)/10.f;
        fatScale.isMeasured = NO;
    }
    //稳定
    else if (weightByte[0]==0x02){
        fatScale.value = ((weightByte[1])|weightByte[2]<<8)/10.f;
        fatScale.errorCode = [self parseBDFatScaleErrorCode:weightByte[3]];
        fatScale.fatPercent = ((weightByte[5]<<8)|weightByte[4])/10.f;
        fatScale.waterPercent = ((weightByte[7]<<8)|weightByte[6])/10.f;
        fatScale.musclePercent = ((weightByte[9]<<8)|weightByte[8])/10.f;
        fatScale.basicCalory = ((weightByte[11]<<8)|weightByte[10])/10.f;
        fatScale.bone = weightByte[12]/10.f;
        fatScale.isMeasured = YES;
    }
    else if ((weightByte[0] ==  0x06) &&
             (weightByte[1] ==  0x00) &&
             (weightByte[2] ==  0x00)){
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kSendCommandSuccess object:nil];
        return nil;
    };
    return fatScale;
}

+ (XYScaleErrorCode)parseBDFatScaleErrorCode:(NSInteger)errorCode{
    
    switch (errorCode) {
        case 1:
        {
            return XYScaleErrorCodeOverWeight;
        }
            break;
        case 4:
        case 12:
        {
            return XYScaleErrorCodeBodyImpedanceUnusual;
        }
            break;
        default:
            break;
    }
    return XYScaleErrorCodeNoError;
}

+ (FatScale *)parseFatScaleData:(NSData *) data{
    FatScale *fat = [[FatScale alloc] init];
    [[self sharedParser] parseData:data withEntity:fat];
    return fat;
}

+ (WeightScale *)parseWeightScaleData:(NSData *) data{
    WeightScale *weight = [[WeightScale alloc] init];
    [[self sharedParser] parseData:data withEntity:weight];
    return weight;
}

+ (BloodPressure *)parseBloodPressureData:(NSData *) data{
    BloodPressure *blood = [[BloodPressure alloc] init];
    [[self sharedParser] parseData:data withEntity:blood];
    return blood;
}

+(KitchenScale *)parseKitchenScaleData:(NSData *)data{
    KitchenScale *kitchen = [[KitchenScale alloc] init];
    [[self sharedParser] parseData:data withEntity:kitchen];
    return kitchen;
}

- (void)parseData:(NSData *)data withEntity:(NSObject *) obj{

    if ([data length] == 20) {
        
        Byte *recByte = (Byte *) [data bytes];
        
        switch (recByte[1]) {
           
            case 0x00:
                [[NSNotificationCenter defaultCenter] postNotificationName:kSendCommandSuccess object:nil];
                break;
            case 0x01:
                
                break;
            case 0x02:
                
                break;
            case 0x03:
                
                break;
            //临时重量
            case 0x04:{
                
                if ([obj isKindOfClass:[WeightScale class]]) {
                    
                    WeightScale *temp = (WeightScale *)obj;
                    temp.errorCode = recByte[2];
                    temp.unit = recByte[3];
                    temp.numOfPoint = recByte[4];
                    
                    [self parseValueWithValue:((recByte[5]<<8)|recByte[6]) unit:temp.unit numberOfPoint:temp.numOfPoint complete:^(float valueHigh, float valueLow) {
                        
                        temp.weightHigh = valueHigh;
                        temp.weightLow = valueLow;
                    }];
                    
                    temp.isMeasured = NO;
                }
                else if ([obj isKindOfClass:[FatScale class]]){
                    
                    FatScale *temp = (FatScale *)obj;
                    temp.unit = recByte[3];
                    temp.errorCode = recByte[2];
                    temp.numOfPoint = recByte[4];
                    [self parseValueWithValue:((recByte[5]<<8)|recByte[6]) unit:temp.unit numberOfPoint:temp.numOfPoint complete:^(float valueHigh, float valueLow) {
                        if (valueLow > 0) {
                            temp.value = (valueHigh * ST_TO_LB + valueLow) / KG_TO_LB;
                        }else{
                            temp.value = valueHigh;
                        }
                    }];
                    temp.isMeasured = NO;
                }
                else if ([obj isKindOfClass:[KitchenScale class]]){
                    
                    KitchenScale *kitchen = (KitchenScale *)obj;
                    kitchen.errorCode = recByte[2];
                    kitchen.unit = recByte[3];
                    kitchen.numOfPoint = recByte[4];
                    [self parseValueWithValue:((recByte[5]<<8)|recByte[6]) unit:kitchen.unit numberOfPoint:kitchen.numOfPoint complete:^(float valueHigh, float valueLow) {
                        
                        kitchen.weightHigh = valueHigh;
                        kitchen.weightLow = valueLow;
                    }];
                    kitchen.isMeasured = NO;
                }
            }
                break;
            //稳定重量
            case 0x05:{
                
                if ([obj isKindOfClass:[WeightScale class]]) {
                    WeightScale *temp = (WeightScale *)obj;
                    temp.errorCode = recByte[2];
                    temp.unit = recByte[3];
                    temp.numOfPoint = recByte[4];
                    temp.isMeasured = YES;
                    
                    [self parseValueWithValue:((recByte[5]<<8)|recByte[6]) unit:temp.unit numberOfPoint:temp.numOfPoint complete:^(float valueHigh, float valueLow) {
                        
                        temp.weightHigh = valueHigh;
                        temp.weightLow = valueLow;
                    }];
                }
                else if ([obj isKindOfClass:[FatScale class]]){
                    FatScale *temp = (FatScale *)obj;
                    temp.errorCode = recByte[2];
                    temp.unit = recByte[3];
                    temp.numOfPoint = recByte[4];
                    [self parseValueWithValue:((recByte[5]<<8)|recByte[6]) unit:temp.unit numberOfPoint:temp.numOfPoint complete:^(float valueHigh, float valueLow) {
                        if (valueLow > 0) {
                            temp.value = (valueHigh * ST_TO_LB + valueLow) / KG_TO_LB;
                        }else{
                            temp.value = valueHigh;
                        }
                    }];
                    temp.fatPercent = ((recByte[7]<<8)|recByte[8])/10.f;
                    temp.waterPercent = ((recByte[9]<<8)|recByte[10])/10.f;
                    temp.musclePercent = ((recByte[11]<<8)|recByte[12])/10.f;
                    temp.basicCalory = ((recByte[13]<<8)|recByte[14])/10.f;
                    temp.bone = recByte[15]/10.f;
                    temp.isMeasured = YES;
                }
                else if ([obj isKindOfClass:[KitchenScale class]]){
                    
                    KitchenScale *kitchen = (KitchenScale *)obj;
                   
                    kitchen.errorCode = recByte[2];
                    kitchen.unit = recByte[3];
                    kitchen.numOfPoint = recByte[4];
                   
                    [self parseValueWithValue:((recByte[5]<<8)|recByte[6]) unit:kitchen.unit numberOfPoint:kitchen.numOfPoint complete:^(float valueHigh, float valueLow) {
                        
                        kitchen.weightHigh = valueHigh;
                        kitchen.weightLow = valueLow;
                    }];

                    kitchen.isMeasured = YES;
                }
            }
                break;
            case 0x06:{
                if ([obj isKindOfClass:[FatScale class]]){
                    FatScaleHistory *temp = [[FatScaleHistory alloc]init];
                    temp.userId = recByte[2];
                    temp.unit = recByte[3];
                    temp.numOfPoint = recByte[4];
                    [self parseValueWithValue:((recByte[5]<<8)|recByte[6]) unit:temp.unit numberOfPoint:temp.numOfPoint complete:^(float valueHigh, float valueLow) {
                        if (valueLow > 0) {
                            temp.value = (valueHigh * ST_TO_LB + valueLow) / KG_TO_LB;
                        }else{
                            temp.value = valueHigh;
                        }
                    }];
                    temp.fatPercent = ((recByte[7]<<8)|recByte[8])/10.f;
                    temp.waterPercent = ((recByte[9]<<8)|recByte[10])/10.f;
                    temp.musclePercent = ((recByte[11]<<8)|recByte[12])/10.f;
                    temp.basicCalory = ((recByte[13]<<8)|recByte[14])/10.f;
                    temp.bone = recByte[15]/10.f;
                    temp.isMeasured = YES;
                    temp.timeStamp = (recByte[16]<<24)|(recByte[17]<<16)|(recByte[18]<<8)|recByte[19];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGetHistoryData object:temp];
                }
            }
                break;
            case 0x07:
            {
                NSInteger number = recByte[3];
                if (number > 0) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNumberOfHistoryData object:[NSNumber numberWithUnsignedInteger:number]];
                }
            }
                break;
            case 0x08:
            {
                
            }
                break;
            case 0x09:
            {
                BloodPressure *bp = (BloodPressure *) obj;
                bp.errorCode = recByte[2];
                bp.isMeasured = recByte[3];
                bp.isArrhythmia = recByte[4];
                bp.SBP = (recByte[5]<<8)|recByte[6];
                bp.DBP =(recByte[7]<<8)|recByte[8];
                
                if(recByte[3]==0){
                    bp.tempValue =(recByte[7]<<8)|recByte[8];
                }
                bp.heartRate =(recByte[9]<<8)|recByte[10];
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark - 解析重量数据
-(void)parseValueWithValue:(NSInteger)value unit:(XYUnitType)unit numberOfPoint:(NSInteger)number complete:(ParseValueComplete)complete{
    
    if (unit == XYUnitSTLB || unit == XYUnitLBOZ) {
        [self analysisComlexUnitWithWeightValue:value pointNumber:number complete:^(NSInteger frontNum, float afterNumr) {
            
            complete(frontNum,afterNumr);
        }];
    }
    else{
        complete((value / powf(10.f, number)),0);
    }
}

typedef void(^AnalysisComplexUnitCompletionHandle)(NSInteger frontNum, float afterNumr);

/**
 *  通过小数点，分解复合单位数据
 *
 *  @param weight   源数据
 *  @param pointNum 小数点
 *  @param block    返回分解后的复合单位数字
 */
- (void)analysisComlexUnitWithWeightValue:(NSInteger)weight pointNumber:(NSInteger)pointNum complete:(AnalysisComplexUnitCompletionHandle)block{
    
    //小数点 还原Data
    NSData *pointData = [NSData dataWithBytes:&pointNum length:1];
    
    Byte *pointByte = (Byte *)[pointData bytes];
    
    //分解高低位数字
    NSInteger n = (pointByte[0]&0xf0)>>4;
    
    NSInteger m = (pointByte[0]&0x0f);
    
    //处理源数据
    NSInteger frontNum = weight / powf(10.f, n);
    
    float afterNumr = ((NSInteger)weight % (NSInteger)pow(10, n)) / powf(10.f, m);
    
    block(frontNum, afterNumr);
}


#pragma mark - 解析血压计错误码
+ (NSString *)parseBloodErrorCode:(NSInteger)errorCode{
   
    switch (errorCode) {
        case 1:
        {
            return @"传感器信号异常";
        }
            break;
        case 2:
        {
            return @"检测不到脉搏或袖带空气未排空。";
        }
            break;
        case 3:
        {
            return @"加压或减压的时候有漏气情况";
        }
            break;
        case 4:
        {
            return @"腕带过松或漏气。";
        }
            break;
        case 5:
        {
            return @"腕带过紧或气路堵塞";
        }
            break;
        case 6:
        {
            return @"测量中压力干扰严重";
        }
            break;
        case 7:
        {
            return @"压力值超过300mm汞柱";
        }
            break;
        case 8:
        {
            return @"标定数据异常或存 储IC异常";
        }
            break;
        case 9:
        {
            return @"IC key错误。";
        }
            break;
            
        default:
            break;
    }
    return nil;
}

#pragma mark - 解析体重秤错误码
+ (NSString *)parseScaleErrorCode:(NSInteger)errorCode{
   
    switch (errorCode) {
        case 1:
        {
            return @"OverWeight";
        }
            break;
        case 3:
        {
            return @"LowPower";
        }
            break;
            
        default:
            break;
    }
    return nil;
}
    

@end
