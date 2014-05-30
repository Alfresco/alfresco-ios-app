//
//  ALFPreviewController.h
//  AlfrescoApp
//
//  Created by Mike Hatfield on 30/05/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <QuickLook/QuickLook.h>

@protocol ALFPreviewControllerDelegate;

@interface ALFPreviewController : QLPreviewController
@property (nonatomic, weak) id<ALFPreviewControllerDelegate> gestureDelegate;
@end


@protocol ALFPreviewControllerDelegate <NSObject>
@optional

/**
 * @abstract Invoked on single tap
 */
- (void)previewControllerWasTapped:(ALFPreviewController *)controller;

@end

