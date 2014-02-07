//
//  ActionViewHandler.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 06/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ActionViewHandler.h"
#import "FavouriteManager.h"
#import "ActionCollectionView.h"
#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "UniversalDevice.h"
#import "Utility.h"
#import "ErrorDescriptions.h"
#import "DownloadManager.h"
#import "PreviewViewController.h"
#import "UIAlertView+ALF.h"

@interface ActionViewHandler () <MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic, weak) UIViewController<ActionViewDelegate> *controller;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoRatingService *ratingService;
@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) UIDocumentInteractionController *documentInteractionController;
@property (nonatomic, strong) id<AlfrescoSession> session;

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
    }
    return self;
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

- (AlfrescoRequest *)pressedEmailActionItem:(ActionCollectionItem *)actionItem
{
    AlfrescoRequest *request = nil;
    
    if ([MFMailComposeViewController canSendMail])
    {
        __weak typeof(self) weakSelf = self;
        
        request = [self retrieveContentOfDocument:(AlfrescoDocument *)self.node completionBlock:^(NSString *fileLocation) {
            if (fileLocation)
            {
                MFMailComposeViewController *emailController = [[MFMailComposeViewController alloc] init];
                emailController.mailComposeDelegate = weakSelf;
                [emailController setSubject:weakSelf.node.name];
                
                // attachment
                NSString *mimeType = [Utility mimeTypeForFileExtension:weakSelf.node.name];
                if (!mimeType)
                {
                    mimeType = @"application/octet-stream";
                }
                NSData *documentData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:[NSURL fileURLWithPath:fileLocation]];
                [emailController addAttachmentData:documentData mimeType:mimeType fileName:weakSelf.node.name];
                
                // content body template
                NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"emailTemplate" ofType:@"html" inDirectory:@"Email Template"];
                NSString *htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
                [emailController setMessageBody:htmlString isHTML:YES];
                
                [UniversalDevice displayModalViewController:emailController onController:self.controller withCompletionBlock:nil];
            }
        }];
    }
    
    return request;
}

- (AlfrescoRequest *)pressedDownloadActionItem:(ActionCollectionItem *)actionItem
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *downloadPath = [[fileManager documentPreviewDocumentFolderPath] stringByAppendingPathComponent:filenameAppendedWithDateModififed(self.node.name, self.node)];
    AlfrescoRequest *downloadRequest = nil;
    
    if ([fileManager fileExistsAtPath:downloadPath])
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
            downloadRequest = [[DownloadManager sharedManager] downloadDocument:(AlfrescoDocument *)self.node contentPath:tempPath session:self.session];
            
            NSError *deleteError = nil;
            [fileManager removeItemAtPath:tempPath error:&deleteError];
            
            if (deleteError)
            {
                AlfrescoLogError(@"Unable to delete file at path: %@", tempPath);
            }
        }
    }
    else
    {
        downloadRequest = [[DownloadManager sharedManager] downloadDocument:(AlfrescoDocument *)self.node contentPath:nil session:self.session];
    }
    
    return downloadRequest;
}

- (AlfrescoRequest *)pressedPrintActionItem:(ActionCollectionItem *)actionItem presentFromView:(UIView *)view inView:(UIView *)inView
{
    return [self retrieveContentOfDocument:(AlfrescoDocument *)self.node completionBlock:^(NSString *fileLocation) {
        if (fileLocation)
        {
            // define a print block
            void (^printBlock)(UIWebView *webView) = ^(UIWebView *webView) {
                NSURL *fileURL = [NSURL fileURLWithPath:fileLocation];
                
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
            CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileLocation.pathExtension, NULL);
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
                PreviewViewController *hiddenPreviewController = [[PreviewViewController alloc] initWithFilePath:fileLocation finishedLoadingCompletionBlock:^(UIWebView *webView, BOOL loadedIntoWebView) {
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
    }];
}

- (AlfrescoRequest *)pressedOpenInActionItem:(ActionCollectionItem *)actionItem presentFromView:(UIView *)view inView:(UIView *)inView
{
    return [self retrieveContentOfDocument:(AlfrescoDocument *)self.node completionBlock:^(NSString *fileLocation) {
        if (fileLocation)
        {
            NSURL *fileURL = [NSURL fileURLWithPath:fileLocation];
            
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
    }];
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
                    NSString *successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.success.message", @"Delete Success Message"), weakSelf.node.name];
                    displayInformationMessageWithTitle(successMessage, NSLocalizedString(@"action.delete.success.title", @"Delete Success Title"));
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

- (AlfrescoRequest *)pressedCreateSubFolder:(ActionCollectionItem *)actionItem inFolder:(AlfrescoFolder *)folder
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
                    
                    NSDictionary *notificationObject = @{kAlfrescoFolderAddedOnServerParentFolderKey : folder, kAlfrescoFolderAddedOnServerSubFolderKey : createdFolder};
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoFolderAddedOnServerNotification object:notificationObject];
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

#pragma mark - Private Functions

- (AlfrescoRequest *)retrieveContentOfDocument:(AlfrescoDocument *)document completionBlock:(void (^)(NSString *fileLocation))completionBlock
{
    AlfrescoRequest *downloadRequest = nil;
    if (completionBlock != NULL)
    {
        AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
        NSString *downloadPath = [[fileManager documentPreviewDocumentFolderPath] stringByAppendingPathComponent:filenameAppendedWithDateModififed(document.name, document)];
        
        if ([fileManager fileExistsAtPath:downloadPath])
        {
            completionBlock(downloadPath);
        }
        else
        {
            NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:downloadPath append:NO];
            
            if ([self.controller respondsToSelector:@selector(displayProgressIndicator)])
            {
                [self.controller displayProgressIndicator];
            }
            downloadRequest = [self.documentService retrieveContentOfDocument:document outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
                if ([self.controller respondsToSelector:@selector(hideProgressIndicator)])
                {
                    [self.controller hideProgressIndicator];
                }
                if (succeeded)
                {
                    completionBlock(downloadPath);
                }
                else
                {
                    // display an error
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
            } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                // progress indicator update
            }];
        }
    }
    
    return downloadRequest;
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
    // TODO: Saveback API's
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    self.documentInteractionController = nil;
}

@end
