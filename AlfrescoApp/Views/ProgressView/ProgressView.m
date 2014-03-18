//
//  ProgressView.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 13/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ProgressView.h"

@implementation ProgressView

- (id)init
{
    self = [super init];
    if (self)
    {
        NSArray * nib = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
        self = nib.firstObject;
    }
    return self;
}

@end
