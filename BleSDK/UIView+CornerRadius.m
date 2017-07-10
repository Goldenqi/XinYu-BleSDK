//
//  UIView+CornerRadius.m
//  HealthTrack
//
//  Created by 金琦 on 16/3/17.
//  Copyright © 2016年 JinQi. All rights reserved.
//

#import "UIView+CornerRadius.h"

@implementation UIView (CornerRadius)

-(void)setCornerRadius:(CGFloat)cornerRadius{
    
    self.layer.cornerRadius = cornerRadius;
    self.layer.masksToBounds = cornerRadius > 0;
}

-(CGFloat)cornerRadius{
    return self.layer.cornerRadius;
}

-(void)setBorderWidth:(CGFloat)borderWidth{

    self.layer.borderWidth = borderWidth;
    self.layer.masksToBounds = borderWidth > 0;
}

-(CGFloat)borderWidth{
    return self.layer.borderWidth;
}


-(void)setBorderColor:(UIColor *)borderColor{
    
    self.layer.borderColor = borderColor.CGColor;
//    self.layer.masksToBounds = borderWidth > 0;
}

-(UIColor *)borderColor{
    return (UIColor *)self.layer.borderColor;
}
@end
