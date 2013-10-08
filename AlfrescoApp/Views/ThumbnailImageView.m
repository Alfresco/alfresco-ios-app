//
//  ThumbnailImageView.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ThumbnailImageView.h"

@implementation ThumbnailImageView

- (void)setImageAtSecurePath:(NSString *)imagePath
{
    NSData *imageData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:[NSURL fileURLWithPath:imagePath]];
    
    NSTimeInterval fadeSpeed = 0.2;
    [UIView animateWithDuration:fadeSpeed animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.image = [UIImage imageWithData:imageData];
        
        [UIView animateWithDuration:fadeSpeed animations:^{
            self.alpha = 1.0f;
        }];
    }];
}

@end
