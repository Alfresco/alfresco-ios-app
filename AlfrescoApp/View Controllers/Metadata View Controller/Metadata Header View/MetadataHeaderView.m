//
//  MetadataHeaderView.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 13/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "MetadataHeaderView.h"

static CGFloat const kStrokeWidth = 2.0f;

@implementation MetadataHeaderView

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPoint startPoint = CGPointMake(0.0f, self.frame.size.height - kStrokeWidth);
    CGPoint endPoint = CGPointMake(self.frame.size.width, self.frame.size.height - kStrokeWidth);
    
    CGContextSetStrokeColorWithColor(context, [[UIColor blueColor] CGColor]);
    CGContextSetLineWidth(context, kStrokeWidth);
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextDrawPath(context, kCGPathStroke);
}

@end
