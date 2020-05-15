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
 
#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "ActionViewHandler.h"
#import "FavouriteManager.h"
#import "ActionCollectionView.h"
#import "UniversalDevice.h"
#import "ErrorDescriptions.h"
#import "DownloadManager.h"
#import "DownloadsViewController.h"
#import "NavigationViewController.h"
#import "UploadFormViewController.h"
#import "RealmSyncManager.h"
#import "CreateTaskViewController.h"
#import "DocumentPreviewManager.h"
#import "TextFileViewController.h"
#import "AccountManager.h"
#import "SaveBackMetadata.h"
#import "NewVersionViewController.h"
#import "PrintingWebView.h"
#import "RealmSyncNodeInfo.h"
#import "RealmManager.h"
#import "AFPItemIdentifier.h"
@import WebKit;

@interface ActionViewHandler () <MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, DownloadsPickerDelegate, UploadFormViewControllerDelegate>

@property (nonatomic, weak) UIViewController<ActionViewDelegate> *controller;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoRatingService *ratingService;
@property (nonatomic, strong) UIDocumentInteractionController *documentInteractionController;
@property (nonatomic, strong) NavigationViewController *downloadPickerNavigationController;
@property (nonatomic, strong) NSMutableArray *queuedCompletionBlocks;
@property (nonatomic, assign) InAppDocumentLocation documentLocation;

@end

@implementation ActionViewHandler
{
    NSString *_emailedFileMimetype;
}

- (instancetype)initWithAlfrescoNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session controller:(UIViewController<ActionViewDelegate> *)controller;
{
    self = [self init];
    if (self)
    {
        self.node = node;
        self.session = session;
        [self setupServicesForSession:session];
        self.controller = controller;
        self.queuedCompletionBlocks = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete:) name:kDocumentPreviewManagerDocumentDownloadCompletedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadCancelled:) name:kDocumentPreviewManagerDocumentDownloadCancelledNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDocumentCompleted:) name:kAlfrescoDocumentEditedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupServicesForSession:(id<AlfrescoSession>)session
{
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    self.ratingService = [[AlfrescoRatingService alloc] initWithSession:session];
}

- (void)editingDocumentCompleted:(NSNotification *)notification
{
    self.node = notification.object;
}

- (AlfrescoRequest *)pressedLikeActionItem:(ActionCollectionItem *)actionItem
{
    __weak typeof(self) weakSelf = self;
    
    return [self.ratingService likeNode:self.node completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                              action:kAnalyticsEventActionLike
                                                               label:[weakSelf analyticsLabel]
                                                               value:@1];
            
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnlike,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unlike", @"Unlike Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-unlike.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierLike userInfo:userInfo];
        }
        else
        {
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

- (AlfrescoRequest *)pressedUnlikeActionItem:(ActionCollectionItem *)actionItem
{
    __weak typeof(self) weakSelf = self;
    
    return [self.ratingService unlikeNode:self.node completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                              action:kAnalyticsEventActionUnlike
                                                               label:[weakSelf analyticsLabel]
                                                               value:@1];
            
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierLike,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.like", @"Like Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-like.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierUnlike userInfo:userInfo];
        }
        else
        {
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

- (AlfrescoRequest *)pressedFavouriteActionItem:(ActionCollectionItem *)actionItem
{
    __weak typeof(self) weakSelf = self;
    
    return [[FavouriteManager sharedManager] addFavorite:self.node session:self.session completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                              action:kAnalyticsEventActionFavorite
                                                               label:[weakSelf analyticsLabel]
                                                               value:@1];
            
            [weakSelf informFavoritesEnumerator];
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnfavourite,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unfavourite", @"Unfavourite Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-unfavorite.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierFavourite userInfo:userInfo];
            
        }
        else
        {
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

- (AlfrescoRequest *)pressedUnfavouriteActionItem:(ActionCollectionItem *)actionItem
{
    __weak typeof(self) weakSelf = self;
    
    return [[FavouriteManager sharedManager] removeFavorite:self.node session:self.session completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                              action:kAnalyticsEventActionUnfavorite
                                                               label:[weakSelf analyticsLabel]
                                                               value:@1];
            
            [weakSelf informFavoritesEnumerator];
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierFavourite,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.favourite", @"Favourite Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-favorite.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierUnfavourite userInfo:userInfo];
        }
        else
        {
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

- (AlfrescoRequest *)pressedEmailActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath documentLocation:(InAppDocumentLocation)location
{
    __weak typeof(self) weakSelf = self;
    void (^displayEmailBlock)(NSString *filePath) = ^(NSString *filePath) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (filePath && [MFMailComposeViewController canSendMail])
        {
            MFMailComposeViewController *emailController = [[MFMailComposeViewController alloc] init];
            emailController.mailComposeDelegate = self;
            [emailController setSubject:filePath.lastPathComponent];
            
            // Attachment
            NSString *mimeType = [Utility mimeTypeForFileExtension:filePath.pathExtension];
            if (!mimeType)
            {
                mimeType = @"application/octet-stream";
            }
            strongSelf->_emailedFileMimetype = mimeType;
            
            NSData *documentData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
            [emailController addAttachmentData:documentData mimeType:mimeType fileName:filePath.lastPathComponent];
            
            // Content body template
            NSString *footer = [NSString stringWithFormat:NSLocalizedString(@"mail.footer", @"Sent from..."), @"<a href=\"http://itunes.apple.com/app/alfresco/id459242610?mt=8\">Alfresco Mobile</a>"];
            NSString *messageBody = [NSString stringWithFormat:@"<br><br>%@", footer];
            [emailController setMessageBody:messageBody isHTML:YES];
            emailController.modalPresentationStyle = UIModalPresentationPageSheet;
            
            [strongSelf.controller presentViewController:emailController animated:YES completion:nil];
        }
        else
        {
            displayErrorMessageWithTitle(NSLocalizedString(@"error.no.email.accounts.message", @"No mail accounts"), NSLocalizedString(@"error.no.email.accounts.title", @"No mail accounts"));
        }
    };
    
    self.documentLocation = location;
    
    AlfrescoRequest *request = nil;
    
    DocumentPreviewManager *previewManager = [DocumentPreviewManager sharedManager];
    if (self.documentLocation == InAppDocumentLocationFilesAndFolders)
    {
        if ([previewManager hasLocalContentOfDocument:(AlfrescoDocument *)self.node])
        {
            NSString *fileLocation = [previewManager filePathForDocument:(AlfrescoDocument *)self.node];
            displayEmailBlock(fileLocation);
        }
        else
        {
            if (![previewManager isCurrentlyDownloadingDocument:(AlfrescoDocument *)self.node])
            {
                request = [[DocumentPreviewManager sharedManager] downloadDocument:(AlfrescoDocument *)self.node session:self.session];
            }
            [self addCompletionBlock:displayEmailBlock];
        }
    }
    else
    {
        displayEmailBlock(documentPath);
    }
    
    return request;
}

- (AlfrescoRequest *)pressedDownloadActionItem:(ActionCollectionItem *)actionItem
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *downloadPath = [[DocumentPreviewManager sharedManager] filePathForDocument:(AlfrescoDocument *)self.node];
    AlfrescoRequest *downloadRequest = nil;
    
    if ([[DocumentPreviewManager sharedManager] hasLocalContentOfDocument:(AlfrescoDocument *)self.node])
    {
        // rename the file to remove the date modified suffix, and then copy it to downloads
        NSString *tempPath = [[fileManager documentPreviewDocumentFolderPath] stringByAppendingPathComponent:self.node.name];
        
        NSError *tempFileError = nil;
        [fileManager copyItemAtPath:downloadPath toPath:tempPath error:&tempFileError];
        
        if (tempFileError)
        {
            AlfrescoLogError(@"Unable to copy file from path: %@ to path: %@", downloadPath, tempPath);
        }
        else
        {
            downloadRequest = [[DownloadManager sharedManager] downloadDocument:(AlfrescoDocument *)self.node contentPath:tempPath session:self.session completionBlock:^(NSString *filePath)
            {
                // delete the copied file in the completion block to avoid deleting it too early (MOBILE-2533)
                NSError *deleteError = nil;
                if (![fileManager removeItemAtPath:tempPath error:&deleteError])
                {
                    AlfrescoLogError(@"Unable to delete file at path: %@", tempPath);
                }
                
                [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                                  action:kAnalyticsEventActionDownload
                                                                   label:((AlfrescoDocument *)self.node).contentMimeType
                                                                   value:@1
                                                            customMetric:AnalyticsMetricFileSize
                                                             metricValue:@(((AlfrescoDocument *)self.node).contentLength)];
            }];
        }
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDocumentPreviewManagerWillStartLocalDocumentDownloadNotification
                                                            object:(AlfrescoDocument *)self.node
                                                          userInfo:@{kDocumentPreviewManagerDocumentIdentifierNotificationKey : self.node.name}];
        
        void (^saveToDownloadsBlock)(NSString *filePath) = ^(NSString *filePath) {
            if (filePath)
            {
                [[DownloadManager sharedManager] saveDocument:(AlfrescoDocument *)self.node documentName:self.node.name contentPath:filePath completionBlock:nil];
                
                [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                                  action:kAnalyticsEventActionDownload
                                                                   label:((AlfrescoDocument *)self.node).contentMimeType
                                                                   value:@1
                                                            customMetric:AnalyticsMetricFileSize
                                                             metricValue:@(((AlfrescoDocument *)self.node).contentLength)];
            }
        };
        
        if (![[DocumentPreviewManager sharedManager] isCurrentlyDownloadingDocument:(AlfrescoDocument *)self.node])
        {
            downloadRequest = [[DocumentPreviewManager sharedManager] downloadDocument:(AlfrescoDocument *)self.node session:self.session];
        }
        [self addCompletionBlock:saveToDownloadsBlock];
    }
    
    return downloadRequest;
}

- (AlfrescoRequest *)pressedPrintActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath documentLocation:(InAppDocumentLocation)location presentFromView:(UIView *)view inView:(UIView *)inView
{
    __block void (^printFileBlock)(NSString *filePath) = ^(NSString *filePath) {
        if (filePath)
        {
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];

            // Define a print block
            void (^innerPrintBlock)(WKWebView *webView) = ^(WKWebView *webView) {
                UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
                
                UIPrintInfo *printInfo = [UIPrintInfo printInfo];
                printInfo.outputType = UIPrintInfoOutputGeneral;
                printInfo.jobName = self.node.name;
                
                printController.printInfo = printInfo;
                if (webView)
                {
                    printController.printFormatter = [webView viewPrintFormatter];
                }
                else
                {
                    printController.printingItem = fileURL;
                }
                
                UIPrintInteractionCompletionHandler printCompletionHandler = ^(UIPrintInteractionController *printController, BOOL completed, NSError *printError) {
                    if (!completed && printError)
                    {
                        AlfrescoLogError(@"Unable to print document %@ with error: %@", fileURL.path, printError.localizedDescription);
                    }
                    else
                    {
                        [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                                          action:kAnalyticsEventActionPrint
                                                                           label:[Utility mimeTypeForFileExtension:filePath.pathExtension]
                                                                           value:@1];
                    }
                };
                
                if (IS_IPAD)
                {
                    [printController presentFromRect:view.frame inView:inView animated:YES completionHandler:printCompletionHandler];
                }
                else
                {
                    [printController presentAnimated:YES completionHandler:printCompletionHandler];
                }
            };
            
            // Determine whether to use default OS printing or a hidden WebView
            if ([UIPrintInteractionController canPrintURL:fileURL])
            {
                innerPrintBlock(nil);
            }
            else
            {
                PrintingWebView *printWebView = [[PrintingWebView alloc] initWithOwningView:activeView()];
                [printWebView printFileURL:fileURL completionBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded)
                    {
                        innerPrintBlock(printWebView);
                    }
                    else if (error)
                    {
                        // Only display if there's an error object - it's suppressed if the user cancels the action
                        displayWarningMessageWithTitle(NSLocalizedString(@"error.print.failed.message", @"Print failed"), NSLocalizedString(@"action.print", @"Print"));
                    }
                }];
            }
        }
    };
    
    self.documentLocation = location;
    
    AlfrescoRequest *request = nil;
    
    DocumentPreviewManager *previewManager = [DocumentPreviewManager sharedManager];
    if (self.documentLocation == InAppDocumentLocationFilesAndFolders)
    {
        if ([previewManager hasLocalContentOfDocument:(AlfrescoDocument *)self.node])
        {
            printFileBlock([previewManager filePathForDocument:(AlfrescoDocument *)self.node]);
        }
        else
        {
            if (![previewManager isCurrentlyDownloadingDocument:(AlfrescoDocument *)self.node])
            {
                request = [[DocumentPreviewManager sharedManager] downloadDocument:(AlfrescoDocument *)self.node session:self.session];
            }
            [self addCompletionBlock:printFileBlock];
        }
    }
    else
    {
        printFileBlock(documentPath);
    }
    
    return request;
}

- (AlfrescoRequest *)pressedOpenInActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath documentLocation:(InAppDocumentLocation)location presentFromView:(UIView *)view inView:(UIView *)inView
{
    void (^displayOpenInBlock)(NSString *filePath) = ^(NSString *filePath) {
        if (filePath)
        {
            if (!self.documentInteractionController)
            {
                UIDocumentInteractionController *docController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
                docController.delegate = self;
                self.documentInteractionController = docController;
            }
            
            if (![self.documentInteractionController presentOpenInMenuFromRect:view.frame inView:inView animated:YES])
            {
                displayWarningMessageWithTitle(NSLocalizedString(@"document.open-in.noapps.message", @"No Apps Message"), NSLocalizedString(@"document.open-in.noapps.title", @"No Apps Title"));
            }
            
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                              action:kAnalyticsEventActionOpen
                                                               label:((AlfrescoDocument *)self.node).contentMimeType
                                                               value:@1
                                                        customMetric:AnalyticsMetricFileSize
                                                         metricValue:@(((AlfrescoDocument *)self.node).contentLength)];
        }
    };
    
    self.documentLocation = location;
    
    AlfrescoRequest *request = nil;
    DocumentPreviewManager *previewManager = [DocumentPreviewManager sharedManager];

    if (self.documentLocation == InAppDocumentLocationLocalFiles || self.documentLocation == InAppDocumentLocationSync || [self.node isNodeInSyncList])
    {
        displayOpenInBlock(documentPath);
    }
    else if (self.documentLocation == InAppDocumentLocationFilesAndFolders)
    {
        NSString *fileLocation = [previewManager filePathForDocument:(AlfrescoDocument *)self.node];
        displayOpenInBlock(fileLocation);
    }
    else
    {
        if (![previewManager isCurrentlyDownloadingDocument:(AlfrescoDocument *)self.node])
        {
            request = [[DocumentPreviewManager sharedManager] downloadDocument:(AlfrescoDocument *)self.node session:self.session];
        }
        [self addCompletionBlock:displayOpenInBlock];
    }
    return request;
}

- (AlfrescoRequest *)pressedEditActionItem:(ActionCollectionItem *)actionItem forDocumentWithContentPath:(NSString *)contentPath
{
    void (^displayEditController)(NSString *filePath) = ^(NSString *filePath) {
        TextFileViewController *textFileController = [[TextFileViewController alloc] initWithEditDocument:(AlfrescoDocument *)self.node contentFilePath:filePath session:self.session];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:textFileController];
        [self.controller presentViewController:navigationController animated:YES completion:nil];
    };
    
    AlfrescoRequest *request = nil;
    
    if (contentPath)
    {
        displayEditController(contentPath);
    }
    else
    {
        DocumentPreviewManager *previewManager = [DocumentPreviewManager sharedManager];
        if ([previewManager hasLocalContentOfDocument:(AlfrescoDocument *)self.node])
        {
            NSString *fileLocation = [previewManager filePathForDocument:(AlfrescoDocument *)self.node];
            displayEditController(fileLocation);
        }
        else
        {
            if (![previewManager isCurrentlyDownloadingDocument:(AlfrescoDocument *)self.node])
            {
                request = [[DocumentPreviewManager sharedManager] downloadDocument:(AlfrescoDocument *)self.node session:self.session];
            }
            [self addCompletionBlock:displayEditController];
        }
    }
    
    return request;
}

- (AlfrescoRequest *)pressedDeleteActionItem:(ActionCollectionItem *)actionItem
{
    __block AlfrescoRequest *deleteRequest = nil;
    
    void (^deleteBlock)(void) = ^void(){
        if ([self.controller respondsToSelector:@selector(displayProgressIndicator)])
        {
            [self.controller displayProgressIndicator];
        }
        __weak typeof(self) weakSelf = self;
        deleteRequest = [self.documentService deleteNode:self.node completionBlock:^(BOOL succeeded, NSError *error) {
            if ([self.controller respondsToSelector:@selector(hideProgressIndicator)])
            {
                [self.controller hideProgressIndicator];
            }
            if (succeeded)
            {
                [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                                  action:kAnalyticsEventActionDelete
                                                                   label:[weakSelf analyticsLabel]
                                                                   value:@1];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDocumentDeletedOnServerNotification object:weakSelf.node];
                [UniversalDevice clearDetailViewController];
                RealmSyncManager *syncManager = [RealmSyncManager sharedManager];
                if ([weakSelf.node isNodeInSyncList])
                {
                    [syncManager deleteNodeFromSync:weakSelf.node deleteRule:DeleteRuleAllNodes withCompletionBlock:^(BOOL savedLocally) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *successMessage = @"";
                            if (savedLocally)
                            {
                                successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.success.message.sync", @"Delete Success Message"), weakSelf.node.name];
                            }
                            else
                            {
                                successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.success.message", @"Delete Success Message"), weakSelf.node.name];
                            }
                            displayInformationMessageWithTitle(successMessage, NSLocalizedString(@"action.delete.success.title", @"Delete Success Title"));
                        });
                    }];
                }
                else
                {
                    NSString *successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.success.message", @"Delete Success Message"), weakSelf.node.name];
                    displayInformationMessageWithTitle(successMessage, NSLocalizedString(@"action.delete.success.title", @"Delete Success Title"));
                }
            }
            else
            {
                NSString *failedMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.failed.message", @"Delete Failed Message"), weakSelf.node.name];
                displayErrorMessageWithTitle(failedMessage, NSLocalizedString(@"action.delete.failed.title", @"Delete Failed Title"));
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    };
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"action.delete.confirmation.title", @"Delete Confirmation Title")
                                                                             message:NSLocalizedString(@"action.delete.confirmation.message", @"Delete Confirmation Message")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No")
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil];
    [alertController addAction:noAction];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          deleteBlock();
                                                      }];
    [alertController addAction:yesAction];
    [[UniversalDevice topPresentedViewController] presentViewController:alertController animated:YES completion:nil];
    
    return deleteRequest;
}

- (void)pressedDeleteLocalFileActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath
{
    void (^deleteBlock)(void) = ^void(){
        NSString *mimetype = [Utility mimeTypeForFileExtension:documentPath.pathExtension];
        [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                          action:kAnalyticsEventActionDelete
                                                           label:mimetype
                                                           value:@1];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDeleteLocalDocumentNotification object:documentPath];
        [UniversalDevice clearDetailViewController];
    };
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"action.delete.confirmation.title", @"Delete Confirmation Title")
                                                                             message:NSLocalizedString(@"action.delete.confirmation.message", @"Delete Confirmation Message")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No")
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil];
    [alertController addAction:noAction];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes")
                                                        style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                            deleteBlock();
                                                        }];
    [alertController addAction:yesAction];
    [[UniversalDevice topPresentedViewController] presentViewController:alertController animated:YES completion:nil];
}

- (AlfrescoRequest *)pressedCreateSubFolderActionItem:(ActionCollectionItem *)actionItem inFolder:(AlfrescoFolder *)folder
{
    __block AlfrescoRequest *createFolderRequest = nil;
    
    void (^createFolderBlock)(NSString *) = ^void(NSString *desiredFolderName){
        createFolderRequest = [self.documentService createFolderWithName:desiredFolderName inParentFolder:folder properties:nil completionBlock:^(AlfrescoFolder *createdFolder, NSError *error) {
            if (createdFolder)
            {
                NSString *folderCreatedMessage = [NSString stringWithFormat:NSLocalizedString(@"action.subfolder.success.message", @"Created Message"), desiredFolderName];
                displayInformationMessageWithTitle(folderCreatedMessage, NSLocalizedString(@"action.subfolder.success.title", @"Created Title"));
                
                NSDictionary *notificationObject = @{kAlfrescoNodeAddedOnServerParentFolderKey : folder, kAlfrescoNodeAddedOnServerSubNodeKey : createdFolder};
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoNodeAddedOnServerNotification object:notificationObject];
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"action.subfolder.failure.title", @"Creation Failed"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    };
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"browser.alertview.addfolder.title", @"Create Folder Title")
                                                                             message:NSLocalizedString(@"browser.alertview.addfolder.message", @"Create Folder Message")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alertController addAction:cancelAction];
    UIAlertAction *createFolderAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.alertview.addfolder.create", @"Create Folder")
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
                                                                   NSString *folderName = [alertController.textFields.firstObject text];
                                                                   createFolderBlock(folderName);
                                                               }];
    [alertController addAction:createFolderAction];
    [alertController addTextFieldWithConfigurationHandler:nil];
    [[UniversalDevice topPresentedViewController] presentViewController:alertController animated:YES completion:nil];

    return createFolderRequest;
}

- (void)pressedRenameActionItem:(ActionCollectionItem *)actionItem atPath:(NSString *)path
{
    __block NSString *passedPath = path;
    
    UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"action.rename.alert.message", @"Rename document to, message") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [renameAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) { }];
    [renameAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { }]];
    [renameAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"action.rename.alert.title", @"Rename") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *newName = [renameAlert.textFields[0] text];
        
        if (newName && newName.length > 0)
        {
            newName = [newName stringByAppendingPathExtension:path.pathExtension];
            NSString *newPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:newName];
            
            [[DownloadManager sharedManager] renameLocalDocument:path.lastPathComponent toName:newName];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoLocalDocumentRenamedNotification object:path userInfo:@{kAlfrescoLocalDocumentNewName : newPath}];
            
            NSString *successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.rename.success.message", @"Rename Success Message"), path.lastPathComponent, newName];
            displayInformationMessageWithTitle(successMessage, NSLocalizedString(@"action.rename.success.title", @"Rename Success Title"));
            self.controller.title = newName;
            passedPath = newPath;
        }
    }]];
    
    [self.controller presentViewController:renameAlert animated:YES completion:nil];
}

- (void)pressedUploadActionItem:(ActionCollectionItem *)actionItem presentFromView:(UIView *)view inView:(UIView *)inView
{
    DownloadsViewController *downloadPicker = [[DownloadsViewController alloc] init];
    downloadPicker.isDownloadPickerEnabled = YES;
    downloadPicker.downloadPickerDelegate = self;
    self.downloadPickerNavigationController = [[NavigationViewController alloc] initWithRootViewController:downloadPicker];
    
    if (IS_IPAD)
    {
        self.downloadPickerNavigationController.modalPresentationStyle = UIModalPresentationPopover;
        self.downloadPickerNavigationController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        self.downloadPickerNavigationController.popoverPresentationController.sourceView = inView;
        self.downloadPickerNavigationController.popoverPresentationController.sourceRect = view.frame;
        
        [[UniversalDevice topPresentedViewController] presentViewController:self.downloadPickerNavigationController animated:YES completion:nil];
    }
    else
    {
        [UniversalDevice displayModalViewController:self.downloadPickerNavigationController onController:self.controller withCompletionBlock:nil];
    }
}

- (void)pressedSendForReviewActionItem:(ActionCollectionItem *)actionItem node:(AlfrescoDocument *)document
{
    CreateTaskViewController *createTaskViewController = [[CreateTaskViewController alloc] initWithSession:self.session workflowType:WorkflowTypeReview attachments:@[document] documentReview:YES];
    NavigationViewController *createTaskNavigationController = [[NavigationViewController alloc] initWithRootViewController:createTaskViewController];
    createTaskNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.controller presentViewController:createTaskNavigationController animated:YES completion:nil];
}

- (void)pressedUploadNewVersion:(ActionCollectionItem *)actionItem node:(AlfrescoDocument *)document
{
    NewVersionViewController *newViewController = [[NewVersionViewController alloc] initWithDocument:document session:self.session];
    NavigationViewController *newVersionNavigationController = [[NavigationViewController alloc] initWithRootViewController:newViewController];
    newVersionNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.controller presentViewController:newVersionNavigationController animated:YES completion:nil];
}

- (void)pressedSyncActionItem:(ActionCollectionItem *)actionItem
{
    __weak typeof(self) weakSelf = self;
    
    [[RealmSyncManager sharedManager] addNodeToSync:self.node withCompletionBlock:^(BOOL completed){
        if (completed)
        {
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                              action:kAnalyticsEventActionSync
                                                               label:[weakSelf analyticsLabel]
                                                               value:@1];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnsync,
                                           kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unsync", @"Unsync Action"),
                                           kActionCollectionItemUpdateItemImageKey : @"actionsheet-unsync.png"};
                [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierSync userInfo:userInfo];
                [[NSNotificationCenter defaultCenter] postNotificationName:kTopLevelSyncDidAddNodeNotification object:weakSelf.node];
            });
        }
    }];
}

- (void)pressedUnsyncActionItem:(ActionCollectionItem *)actionItem
{
    __weak typeof(self) weakSelf = self;
    [[RealmSyncManager sharedManager] unsyncNode:self.node withCompletionBlock:^(BOOL completed) {
        
        [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                          action:kAnalyticsEventActionUnSync
                                                           label:[weakSelf analyticsLabel]
                                                           value:@1];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierSync,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.sync", @"Sync Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-sync.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierUnsync userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:kTopLevelSyncDidRemoveNodeNotification object:weakSelf.node];
        });
    }];
}

#pragma mark - DocumentPreviewManager Notification Callbacks

- (void)downloadComplete:(NSNotification *)notification
{
    NSString *displayedDocumentIdentifier = [[DocumentPreviewManager sharedManager] documentIdentifierForDocument:(AlfrescoDocument *)self.node];
    NSString *notificationDocumentIdentifier = notification.userInfo[kDocumentPreviewManagerDocumentIdentifierNotificationKey];
    
    if ([displayedDocumentIdentifier isEqualToString:notificationDocumentIdentifier])
    {
        [self runAndRemoveAllCompletionBlocksWithFilePath:[[DocumentPreviewManager sharedManager] filePathForDocument:(AlfrescoDocument *)self.node]];
    }
}

- (void)downloadCancelled:(NSNotification *)notification
{
    [self.queuedCompletionBlocks removeAllObjects];
}

#pragma mark - Private Functions

- (void)sessionRefreshed:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    [self setupServicesForSession:session];
}

- (void)addCompletionBlock:(DocumentPreviewManagerFileSavedBlock)completionBlock
{
    DocumentPreviewManagerFileSavedBlock retainedBlock = [completionBlock copy];
    [self.queuedCompletionBlocks addObject:retainedBlock];
}

- (void)runAndRemoveAllCompletionBlocksWithFilePath:(NSString *)filePath
{
    [self.queuedCompletionBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DocumentPreviewManagerFileSavedBlock currentBlock = (DocumentPreviewManagerFileSavedBlock)obj;
        currentBlock(filePath);
    }];
    [self.queuedCompletionBlocks removeAllObjects];
}

- (NSString *) analyticsLabel
{
    NSString *analyticsLabel = nil;
    
    if ([self.node isKindOfClass:[AlfrescoDocument class]])
    {
        analyticsLabel = ((AlfrescoDocument *)self.node).contentMimeType;
    }
    else if ([self.node isKindOfClass:[AlfrescoFolder class]])
    {
        analyticsLabel = kAnalyticsEventLabelFolder;
    }
    
    return analyticsLabel;
}

#pragma mark - MFMailComposeViewControllerDelegate Functions

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (result == MFMailComposeResultSent)
    {
        [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                          action:kAnalyticsEventActionEmail
                                                           label:_emailedFileMimetype
                                                           value:@1];
    }
    
    _emailedFileMimetype = nil;
    
    if (result != MFMailComposeResultFailed)
    {
        [controller dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate Functions

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    return self.controller;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    NSDictionary *annotationDictionary = nil;
    NSString *filePath = controller.URL.path;
    
    if ([application hasPrefix:kQuickofficeApplicationBundleIdentifierPrefix] && QUICKOFFICE_PARTNER_KEY.length > 0)
    {
        UserAccount *currentAccount = [[AccountManager sharedManager] selectedAccount];
        SaveBackMetadata *savebackMetadata = [[SaveBackMetadata alloc] initWithAccountID:currentAccount.accountIdentifier nodeRef:self.node.identifier originalFileLocation:filePath documentLocation:self.documentLocation];
        
        annotationDictionary = @{kQuickofficeApplicationSecretUUIDKey : QUICKOFFICE_PARTNER_KEY,
                                 kQuickofficeApplicationInfoKey : @{kAlfrescoInfoMetadataKey : savebackMetadata.dictionaryRepresentation},
                                 kQuickofficeApplicationIdentifierKey : kAppIdentifier,
                                 kQuickofficeApplicationDocumentExtensionKey : kQuickofficeApplicationDocumentExtension,
                                 kQuickofficeApplicationDocumentUTIKey : kQuickofficeApplicationDocumentUTI};
    }
    else
    {
        // TODO: Custom Save Back Parameters
    }
    
    controller.annotation = annotationDictionary;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    self.documentInteractionController = nil;
}

#pragma mark - DocumentPickerDelegate Functions

- (void)downloadPicker:(DownloadsViewController *)picker didPickDocument:(NSString *)documentPath
{
    UploadFormViewController *uploadFormController = [[UploadFormViewController alloc] initWithSession:self.session
                                                                                    uploadDocumentPath:documentPath
                                                                                              inFolder:(AlfrescoFolder *)self.node
                                                                                        uploadFormType:UploadFormTypeDocument
                                                                                              delegate:self];
    NavigationViewController *uploadFormNavigationController = [[NavigationViewController alloc] initWithRootViewController:uploadFormController];
    
    void (^displayUploadViewController)(void) = ^{
        [UniversalDevice displayModalViewController:uploadFormNavigationController onController:self.controller withCompletionBlock:nil];
    };
    
    if (IS_IPAD)
    {
        if (self.downloadPickerNavigationController.popoverPresentationController)
        {
            [self.downloadPickerNavigationController dismissViewControllerAnimated:YES completion:nil];
            self.downloadPickerNavigationController = nil;
            displayUploadViewController();
        }
    }
    else
    {
        [self.controller dismissViewControllerAnimated:YES completion:displayUploadViewController];
    }
}

- (void)downloadPickerDidCancel
{
    [self.controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UploadFormViewControllerDelegate Functions

- (void)didFinishUploadingNode:(AlfrescoNode *)node fromLocation:(NSURL *)locationURL
{
    NSDictionary *notificationObject = @{kAlfrescoNodeAddedOnServerParentFolderKey : self.node, kAlfrescoNodeAddedOnServerSubNodeKey : node, kAlfrescoNodeAddedOnServerContentLocationLocally : locationURL};
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoNodeAddedOnServerNotification object:notificationObject];
}

#pragma mark - File Provider support
- (void)informFavoritesEnumerator
{
    UserAccount *currentAccount = [[AccountManager sharedManager] selectedAccount];
    NSFileProviderItemIdentifier favoriteFolderItemIdentifier = [AFPItemIdentifier itemIdentifierForSuffix:kFileProviderFavoritesFolderIdentifierSuffix andAccount:currentAccount];
    [[NSFileProviderManager defaultManager] signalEnumeratorForContainerItemIdentifier:favoriteFolderItemIdentifier completionHandler:^(NSError * _Nullable error) {
        if (error != NULL)
        {
            AlfrescoLogError(@"ERROR: Couldn't signal enumerator for changes %@", error);
        }
    }];
}

@end
