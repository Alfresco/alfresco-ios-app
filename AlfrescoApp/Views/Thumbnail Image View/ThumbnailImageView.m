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

- (void)updateContentMode
{
    self.contentMode = [self contentModeForImage:self.image];
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
