//
//  PreviewViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemInDetailViewProtocol.h"
#import <QuickLook/QuickLook.h>

@class AlfrescoDocument;
@class AlfrescoPermissions;
@protocol AlfrescoSession;

@interface PreviewViewController : UIViewController <UIWebViewDelegate, ItemInDetailViewProtocol, UIDocumentInteractionControllerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate>

@property (nonatomic, strong, readonly, getter = displayedDocument) AlfrescoDocument *document;

- (id)initWithDocument:(AlfrescoDocument *)document documentPermissions:(AlfrescoPermissions *)permissions contentFilePath:(NSString *)contentFilePath session:(id<AlfrescoSession>)session;
- (id)initWithBundleDocument:(NSString *)document;
- (void)clearDisplayedDocument;

@end
