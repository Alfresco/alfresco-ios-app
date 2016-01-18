/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
#import "SyncManager.h"
#import "CreateTaskViewController.h"
#import "DocumentPreviewManager.h"
#import "FilePreviewViewController.h"
#import "TextFileViewController.h"
#import "AccountManager.h"
#import "SaveBackMetadata.h"
#import "NewVersionViewController.h"
#import "PrintingWebView.h"

@interface ActionViewHandler () <MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, DownloadsPickerDelegate, UploadFormViewControllerDelegate>

@property (nonatomic, weak) UIViewController<ActionViewDelegate> *controller;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoRatingService *ratingService;
@property (nonatomic, strong) UIDocumentInteractionController *documentInteractionController;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSMutableArray *queuedCompletionBlocks;
@property (nonatomic, assign) InAppDocumentLocation documentLocation;

@end

@implementation ActionViewHandler

- (instancetype)initWithAlfrescoNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session controller:(UIViewController<ActionViewDelegate> *)controller;
{
    self = [self init];
    if (self)
    {
        self.node = node;
        self.session = session;
        self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
        self.ratingService = [[AlfrescoRatingService alloc] initWithSession:session];
        self.controller = controller;
        self.queuedCompletionBlocks = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadComplete:) name:kDocumentPreviewManagerDocumentDownloadCompletedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadCancelled:) name:kDocumentPreviewManagerDocumentDownloadCancelledNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDocumentCompleted:) name:kAlfrescoDocumentEditedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)editingDocumentCompleted:(NSNotification *)notification
{
    self.node = notification.object;
}

- (AlfrescoRequest *)pressedLikeActionItem:(ActionCollectionItem *)actionItem
{
    return [self.ratingService likeNode:self.node completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnlike,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unlike", @"Unlike Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-unlike.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierLike userInfo:userInfo];
        }
    }];
}

- (AlfrescoRequest *)pressedUnlikeActionItem:(ActionCollectionItem *)actionItem
{
    return [self.ratingService unlikeNode:self.node completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierLike,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.like", @"Like Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-like.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierUnlike userInfo:userInfo];
        }
    }];
}

- (AlfrescoRequest *)pressedFavouriteActionItem:(ActionCollectionItem *)actionItem
{
    return [[FavouriteManager sharedManager] addFavorite:self.node session:self.session completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnfavourite,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unfavourite", @"Unfavourite Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-unfavorite.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierFavourite userInfo:userInfo];
        }
    }];
}

- (AlfrescoRequest *)pressedUnfavouriteActionItem:(ActionCollectionItem *)actionItem
{
    return [[FavouriteManager sharedManager] removeFavorite:self.node session:self.session completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierFavourite,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.favourite", @"Favourite Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-favorite.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierUnfavourite userInfo:userInfo];
        }
    }];
}

- (AlfrescoRequest *)pressedEmailActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath documentLocation:(InAppDocumentLocation)location
{
    void (^displayEmailBlock)(NSString *filePath) = ^(NSString *filePath) {
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
            NSData *documentData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
            [emailController addAttachmentData:documentData mimeType:mimeType fileName:filePath.lastPathComponent];
            
            // Content body template
            NSString *footer = [NSString stringWithFormat:NSLocalizedString(@"mail.footer", @"Sent from..."), @"<a href=\"http://itunes.apple.com/app/alfresco/id459242610?mt=8\">Alfresco Mobile</a>"];
            NSString *messageBody = [NSString stringWithFormat:@"<br><br>%@", footer];
            [emailController setMessageBody:messageBody isHTML:YES];
            emailController.modalPresentationStyle = UIModalPresentationPageSheet;
            
            [self.controller presentViewController:emailController animated:YES completion:nil];
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
            downloadRequest = [[DownloadManager sharedManager] downloadDocument:(AlfrescoDocument *)self.node contentPath:tempPath session:self.session completionBlock:^(NSString *filePath) {
                // delete the copied file in the completion block to avoid deleting it too early (MOBILE-2533)
                NSError *deleteError = nil;
                if (![fileManager removeItemAtPath:tempPath error:&deleteError])
                {
                    AlfrescoLogError(@"Unable to delete file at path: %@", tempPath);
                }
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
            void (^innerPrintBlock)(UIWebView *webView) = ^(UIWebView *webView) {
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
                printController.showsPageRange = YES;
                
                UIPrintInteractionCompletionHandler printCompletionHandler = ^(UIPrintInteractionController *printController, BOOL completed, NSError *printError) {
                    if (!completed && printError)
                    {
                        AlfrescoLogError(@"Unable to print document %@ with error: %@", fileURL.path, printError.localizedDescription);
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
        }
    };
    
    self.documentLocation = location;
    
    AlfrescoRequest *request = nil;
    DocumentPreviewManager *previewManager = [DocumentPreviewManager sharedManager];

    if (self.documentLocation == InAppDocumentLocationLocalFiles || self.documentLocation == InAppDocumentLocationSync || [[SyncManager sharedManager] isNodeInSyncList:self.node])
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
    UIAlertView *confirmDeletion = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"action.delete.confirmation.title", @"Delete Confirmation Title")
                                                              message:NSLocalizedString(@"action.delete.confirmation.message", @"Delete Confirmation Message")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                    otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    [confirmDeletion showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
        if (!isCancelButton)
        {
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
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDocumentDeletedOnServerNotification object:weakSelf.node];
                    [UniversalDevice clearDetailViewController];
                    SyncManager *syncManager = [SyncManager sharedManager];
                    if ([syncManager isNodeInSyncList:weakSelf.node])
                    {
                        [syncManager deleteNodeFromSync:weakSelf.node withCompletionBlock:^(BOOL savedLocally) {
                            
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
        }
    }];
    
    return deleteRequest;
}

- (void)pressedDeleteLocalFileActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath
{
    UIAlertView *confirmDeletion = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"action.delete.confirmation.title", @"Delete Confirmation Title")
                                                              message:NSLocalizedString(@"action.delete.confirmation.message", @"Delete Confirmation Message")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                    otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    [confirmDeletion showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
        if (!isCancelButton)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDeleteLocalDocumentNotification object:documentPath];
            [UniversalDevice clearDetailViewController];
        }
    }];
}

- (AlfrescoRequest *)pressedCreateSubFolderActionItem:(ActionCollectionItem *)actionItem inFolder:(AlfrescoFolder *)folder
{
    __block AlfrescoRequest *createFolderRequest = nil;
    UIAlertView *createFolderAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"browser.alertview.addfolder.title", @"Create Folder Title")
                                                                message:NSLocalizedString(@"browser.alertview.addfolder.message", @"Create Folder Message")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                      otherButtonTitles:NSLocalizedString(@"browser.alertview.addfolder.create", @"Create Folder"), nil];
    createFolderAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [createFolderAlert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
        if (!isCancelButton)
        {
            NSString *desiredFolderName = [[createFolderAlert textFieldAtIndex:0] text];
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
        }
    }];
    
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
    NavigationViewController *downloadPickerNavigationController = [[NavigationViewController alloc] initWithRootViewController:downloadPicker];
    
    if (IS_IPAD)
    {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:downloadPickerNavigationController];
        [self.popover presentPopoverFromRect:view.frame inView:inView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        [UniversalDevice displayModalViewController:downloadPickerNavigationController onController:self.controller withCompletionBlock:nil];
    }
}

- (void)pressedSendForReviewActionItem:(ActionCollectionItem *)actionItem node:(AlfrescoDocument *)document
{
    CreateTaskViewController *createTaskViewController = [[CreateTaskViewController alloc] initWithSession:self.session workflowType:WorkflowTypeReview attachments:@[document]];
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

#pragma mark - MFMailComposeViewControllerDelegate Functions

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
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
        if (self.popover.isPopoverVisible)
        {
            [self.popover dismissPopoverAnimated:YES];
            self.popover = nil;
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

@end
