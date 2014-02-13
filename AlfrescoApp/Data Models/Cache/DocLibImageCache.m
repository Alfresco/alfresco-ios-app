//
//  DocLibImageCache.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 11/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "DocLibImageCache.h"

@implementation DocLibImageCache

@dynamic docLibImageData;
@dynamic dateAdded;
@dynamic identifier;

- (UIImage *)docLibImage
{
    UIImage *docLibImage = nil;
    if (self.docLibImageData)
    {
        docLibImage = [UIImage imageWithData:self.docLibImageData];
    }
    return docLibImage;
}

@end
