//
//  FullScreenAnimationController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 04/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FullScreenAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL isGoingIntoFullscreenMode;
// Defaults to 1 if this is not set
@property (nonatomic, assign) NSTimeInterval presentationSpeed;
// Defaults to 0.3 id this is not set
@property (nonatomic, assign) NSTimeInterval dismissalSpeed;

@end
