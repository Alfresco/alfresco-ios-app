//
//  UIView+DrawingUtils.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 16/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "UIView+DrawingUtils.h"

@implementation UIView (DrawingUtils)

- (void)drawLineFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint lineThickness:(CGFloat)lineThinkness colour:(UIColor *)lineColour
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [lineColour CGColor]);
    CGContextSetLineWidth(context, lineThinkness);
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextDrawPath(context, kCGPathStroke);
}

@end
