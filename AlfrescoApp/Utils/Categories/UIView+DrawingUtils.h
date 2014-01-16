//
//  UIView+DrawingUtils.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 16/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (DrawingUtils)

- (void)drawLineFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint lineThickness:(CGFloat)lineThinkness colour:(UIColor *)lineColour;

@end
