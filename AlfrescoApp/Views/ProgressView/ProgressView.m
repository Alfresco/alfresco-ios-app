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
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        NSArray * nib = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
        self = nib.firstObject;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        
    }
    return self;
}

- (IBAction)cancelButtonPressed:(id)sender
{
    NSLog(@"cancel buttong pressed");
}

@end
