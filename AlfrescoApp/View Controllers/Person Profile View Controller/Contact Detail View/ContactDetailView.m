/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile iOS App.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/

#import "ContactDetailView.h"

@implementation ContactDetailView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.lineWidth = 0.5f;
    self.lineColor = [UIColor lightGrayColor];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [self.lineColor CGColor]);
    CGContextSetLineWidth(context, self.lineWidth);
    CGContextMoveToPoint(context, 0, self.frame.size.height - self.lineWidth);
    CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height - self.lineWidth);
    CGContextDrawPath(context, kCGPathStroke);
}

@end
