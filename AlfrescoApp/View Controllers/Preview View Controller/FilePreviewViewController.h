//
//  FilePreviewViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 03/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "FullScreenAnimationController.h"
#import "NodeUpdatableProtocol.h"

@interface FilePreviewViewController : UIViewController <FullScreenAnimationControllerProtocol, NodeUpdatableProtocol>

@property (nonatomic, assign) BOOL useControllersPreferStatusBarHidden;

- (instancetype)initWithDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session;
- (instancetype)initWithFilePath:(NSString *)filePath document:(AlfrescoDocument *)document;

@end
