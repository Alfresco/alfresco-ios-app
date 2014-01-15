//
//  PreviewViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemInDetailViewProtocol.h"

@class AlfrescoDocument;
@class AlfrescoPermissions;
@protocol AlfrescoSession;

@interface PreviewViewController : UIViewController <UIWebViewDelegate, ItemInDetailViewProtocol, UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong, readonly, getter = displayedDocument) AlfrescoDocument *document;

- (instancetype)initWithDocument:(AlfrescoDocument *)document documentPermissions:(AlfrescoPermissions *)permissions contentFilePath:(NSString *)contentFilePath session:(id<AlfrescoSession>)session displayOverlayCloseButton:(BOOL)displaycloseButton;
- (instancetype)initWithBundleDocument:(NSString *)document;
- (instancetype)initWithFilePath:(NSString *)filePath finishedLoadingCompletionBlock:(void (^)(UIWebView *webView, BOOL loadedIntoWebView))finishedLoadingBlock;
- (void)clearDisplayedDocument;

@end
