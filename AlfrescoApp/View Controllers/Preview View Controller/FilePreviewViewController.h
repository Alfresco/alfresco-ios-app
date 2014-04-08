//
//  FilePreviewViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 03/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilePreviewViewController : UIViewController

- (instancetype)initWithDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session;
- (instancetype)initWithFilePath:(NSString *)filePath loadingCompletionBlock:(void (^)(UIWebView *webView, BOOL loadedIntoWebView))loadingCompleteBlock;

@end
