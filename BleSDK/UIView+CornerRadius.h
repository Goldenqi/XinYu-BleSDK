//
//  UIView+CornerRadius.h
//  HealthTrack
//
//  Created by 金琦 on 16/3/17.
//  Copyright © 2016年 JinQi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (CornerRadius)

@property (nonatomic,assign) IBInspectable CGFloat cornerRadius;

@property (nonatomic,assign) IBInspectable CGFloat borderWidth;

@property (nonatomic,strong) IBInspectable UIColor *borderColor;


@end
