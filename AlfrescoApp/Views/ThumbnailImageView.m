//
//  ThumbnailImageView.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ThumbnailImageView.h"

static NSTimeInterval const kFadeSpeed = 0.2;

@implementation ThumbnailImageView

- (void)setImageAtPath:(NSString *)imagePath withFade:(BOOL)fadeAnimation;
{
    NSData *imageData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:[NSURL fileURLWithPath:imagePath]];
    
    if (fadeAnimation)
    {
        [UIView animateWithDuration:kFadeSpeed animations:^{
            self.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.image = [UIImage imageWithData:imageData];
            
            [UIView animateWithDuration:kFadeSpeed animations:^{
                self.alpha = 1.0f;
            }];
        }];
    }
    else
    {
        self.image = [UIImage imageWithData:imageData];
    }
}

@end
