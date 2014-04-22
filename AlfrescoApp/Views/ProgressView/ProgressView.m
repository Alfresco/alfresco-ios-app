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
        self = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil].firstObject;
    }
    return self;
}

@end
