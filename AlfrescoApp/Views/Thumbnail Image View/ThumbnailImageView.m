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

- (void)setImage:(UIImage *)image withFade:(BOOL)fadeAnimation
{
    [self setImage:image withFade:fadeAnimation switchingToContentMode:[self contentModeForImage:image]];
}

- (void)setImage:(UIImage *)image withFade:(BOOL)fadeAnimation switchingToContentMode:(UIViewContentMode)contentMode
{
    if (fadeAnimation)
    {
        [UIView animateWithDuration:kFadeSpeed animations:^{
            self.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.contentMode = contentMode;
            self.image = image;
            
            [UIView animateWithDuration:kFadeSpeed animations:^{
                self.alpha = 1.0f;
            }];
        }];
    }
    else
    {
        self.contentMode = contentMode;
        self.image = image;
    }
}

- (void)setImageAtPath:(NSString *)imagePath withFade:(BOOL)fadeAnimation;
{
    NSData *imageData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:[NSURL fileURLWithPath:imagePath]];
    UIImage *image = [UIImage imageWithData:imageData];
    
    if (fadeAnimation)
    {
        [UIView animateWithDuration:kFadeSpeed animations:^{
            self.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.contentMode = [self contentModeForImage:image];
            self.image = image;
            
            [UIView animateWithDuration:kFadeSpeed animations:^{
                self.alpha = 1.0f;
            }];
        }];
    }
    else
    {
        self.contentMode = [self contentModeForImage:image];
        self.image = image;
    }
}

#pragma mark - Private Functions

- (UIViewContentMode)contentModeForImage:(UIImage *)image
{
    UIViewContentMode contentMode = UIViewContentModeCenter;

    float imageArea = image.size.width * image.size.height;
    float imageViewArea = self.bounds.size.width * self.bounds.size.height;
    
    if (imageArea > imageViewArea)
    {
        contentMode = UIViewContentModeScaleAspectFit;
    }
    
    return contentMode;
}

@end
