//
//  ActionViewHandler.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 06/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "ActionViewHandler.h"
#import "FavouriteManager.h"
#import "ActionCollectionView.h"
#import "UniversalDevice.h"
#import "ErrorDescriptions.h"
#import "DownloadManager.h"
#import "UIAlertView+ALF.h"
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
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (AlfrescoRequest *)pressedLikeActionItem:(ActionCollectionItem *)actionItem
{
    return [self.ratingService likeNode:self.node completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnlike,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unlike", @"Unlike Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-liked.png"};
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
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-unliked.png"};
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
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-favourited.png"};
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
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-unfavourited.png"};
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
            
            // attachment
            NSString *mimeType = [Utility mimeTypeForFileExtension:filePath.lastPathComponent];
            if (!mimeType)
            {
                mimeType = @"application/octet-stream";
            }
            NSData *documentData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
            [emailController addAttachmentData:documentData mimeType:mimeType fileName:filePath.lastPathComponent];
            
            // content body template
            NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"emailTemplate" ofType:@"html" inDirectory:@"Email Template"];
            NSString *htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
            [emailController setMessageBody:htmlString isHTML:YES];
            
            emailController.modalPresentationStyle = UIModalPresentationPageSheet;
            
            [self.controller presentViewController:emailController animated:YES completion:nil];
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
        downloadRequest = [[DownloadManager sharedManager] downloadDocument:(AlfrescoDocument *)self.node contentPath:nil session:self.session completionBlock:nil];
    }
    
    return downloadRequest;
}

- (AlfrescoRequest *)pressedPrintActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath documentLocation:(InAppDocumentLocation)location presentFromView:(UIView *)view inView:(UIView *)inView
{
    void (^printBlock)(NSString *filePath) = ^(NSString *filePath) {
        if (filePath)
        {
            // define a print block
            void (^printBlock)(UIWebView *webView) = ^(UIWebView *webView) {
                NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                
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
            
            // determine whether to use defult OS printing
            NSSet *printableUTIs = [UIPrintInteractionController printableUTIs];
            CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)filePath.pathExtension, NULL);
            __block BOOL useNativePrinting = NO;
            [printableUTIs enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                if (UTTypeConformsTo(UTI, (__bridge CFStringRef)obj))
                {
                    useNativePrinting = YES;
                    *stop = YES;
                }
            }];
            CFRelease(UTI);
            
            if (useNativePrinting)
            {
                printBlock(nil);
            }
            else
            {
                FilePreviewViewController *hiddenPreviewController = [[FilePreviewViewController alloc] initWithFilePath:filePath document:nil loadingCompletionBlock:^(UIWebView *webView, BOOL loadedIntoWebView) {
                    if (loadedIntoWebView)
                    {
                        printBlock(webView);
                    }
                }];
                hiddenPreviewController.view.hidden = YES;
                [self.controller addChildViewController:hiddenPreviewController];
                [self.controller.view addSubview:hiddenPreviewController.view];
                [hiddenPreviewController didMoveToParentViewController:self.controller];
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
            NSString *fileLocation = [previewManager filePathForDocument:(AlfrescoDocument *)self.node];
            printBlock(fileLocation);
        }
        else
        {
            if (![previewManager isCurrentlyDownloadingDocument:(AlfrescoDocument *)self.node])
            {
                request = [[DocumentPreviewManager sharedManager] downloadDocument:(AlfrescoDocument *)self.node session:self.session];
            }
            [self addCompletionBlock:printBlock];
        }
    }
    else
    {
        printBlock(documentPath);
    }
    
    return request;
}

- (AlfrescoRequest *)pressedOpenInActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath documentLocation:(InAppDocumentLocation)location presentFromView:(UIView *)view inView:(UIView *)inView
{
    void (^displayOpenInBlock)(NSString *filePath) = ^(NSString *filePath) {
        if (filePath)
        {
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            
            if (!self.documentInteractionController)
            {
                UIDocumentInteractionController *docController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
                docController.delegate = self;
                self.documentInteractionController = docController;
            }
            
            BOOL canOpenIn = [self.documentInteractionController presentOpenInMenuFromRect:view.frame inView:inView animated:YES];
            
            if (!canOpenIn)
            {
                NSString *cantOpenMessage = NSLocalizedString(@"document.open-in.noapps.message", @"No Apps Message");
                NSString *cantOpenTitle = NSLocalizedString(@"document.open-in.noapps.title", @"No Apps Title");
                displayInformationMessageWithTitle(cantOpenMessage, cantOpenTitle);
            }
        }
    };
    
    self.documentLocation = location;
    
    AlfrescoRequest *request = nil;
    
    DocumentPreviewManager *previewManager = [DocumentPreviewManager sharedManager];
    if (self.documentLocation == InAppDocumentLocationFilesAndFolders)
    {
        NSString *fileLocation = [previewManager filePathForDocument:(AlfrescoDocument *)self.node];
        displayOpenInBlock(fileLocation);
    }
    else if (self.documentLocation == InAppDocumentLocationLocalFiles)
    {
        displayOpenInBlock(documentPath);
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
    UIAlertView *renameAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"action.rename.alert.title", @"Rename")
                                                          message:NSLocalizedString(@"action.rename.alert.message", @"Rename document to, message")
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    renameAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [renameAlert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
        if (!isCancelButton)
        {
            NSString *newName = [[renameAlert textFieldAtIndex:0] text];
            
            if (newName)
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
        }
    }];
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
    
    if ([application hasPrefix:kQuickofficeApplicationBundleIdentifierPrefix])
    {
        UserAccount *currentAccount = [[AccountManager sharedManager] selectedAccount];
        SaveBackMetadata *savebackMetadata = [[SaveBackMetadata alloc] initWithAccountID:currentAccount.accountIdentifier nodeRef:self.node.identifier originalFileLocation:filePath documentLocation:self.documentLocation];
        
        annotationDictionary = @{kQuickofficeApplicationSecretUUIDKey : ALFRESCO_QUICKOFFICE_PARTNER_KEY,
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
