//
//  AlfrescoDocument+ALF.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AlfrescoDocument+ALF.h"
#import <objc/runtime.h>

@implementation AlfrescoDocument (ALF)

- (void)setIsDownloaded:(BOOL)isDownloaded
{
    objc_setAssociatedObject(self, @selector(isDownloaded), [NSNumber numberWithBool:isDownloaded], OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)isDownloaded
{
    return [objc_getAssociatedObject(self, @selector(isDownloaded)) boolValue];
}

@end
