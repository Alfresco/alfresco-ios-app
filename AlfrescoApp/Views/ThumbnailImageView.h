//
//  ThumbnailImageView.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThumbnailImageView : UIImageView

- (void)setImageAtPath:(NSString *)imagePath withFade:(BOOL)fadeAnimation;

@end
