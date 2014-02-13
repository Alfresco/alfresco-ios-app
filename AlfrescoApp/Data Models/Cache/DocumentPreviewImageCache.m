//
//  DocumentPreviewImageCache.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 11/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "DocumentPreviewImageCache.h"

@implementation DocumentPreviewImageCache

@dynamic documentPreviewImageData;
@dynamic dateAdded;
@dynamic identifier;

- (UIImage *)documentPreviewImage
{
    UIImage *documentPreviewImage = nil;
    if (self.documentPreviewImageData)
    {
        documentPreviewImage = [UIImage imageWithData:self.documentPreviewImageData];
    }
    return documentPreviewImage;
}

@end
