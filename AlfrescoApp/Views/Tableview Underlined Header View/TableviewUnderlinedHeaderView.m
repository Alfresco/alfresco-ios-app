//
//  MetadataHeaderView.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 13/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "TableviewUnderlinedHeaderView.h"
#import "UIView+DrawingUtils.h"


static CGFloat const kTableviewUnderlinedHeaderViewHeight = 36.0f;

static CGFloat const kStrokeWidth = 0.5f;
static CGFloat const kSidePadding = 8.0f;
static CGFloat const kBottomPadding = 2.0f;

@implementation TableviewUnderlinedHeaderView

+ (CGFloat)headerViewHeight
{
    return kTableviewUnderlinedHeaderViewHeight;
}

- (void)drawRect:(CGRect)rect
{
    CGPoint startPoint = CGPointMake(kSidePadding, self.frame.size.height - kBottomPadding - kStrokeWidth);
    CGPoint endPoint = CGPointMake(self.frame.size.width - kSidePadding, self.frame.size.height - kBottomPadding - kStrokeWidth);
    
    [self drawLineFromPoint:startPoint toPoint:endPoint lineThickness:kStrokeWidth colour:[UIColor appTintColor]];
}

@end
