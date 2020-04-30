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
 
#import "NewVersionViewController.h"
#import "NewVersionLabelCell.h"
#import "NewVersionToggleCell.h"
#import "NewVersionTextViewCell.h"
#import "DownloadsViewController.h"
#import "RealmSyncManager.h"
#import "AccountManager.h"

@interface NewVersionViewController () <DownloadsPickerDelegate>

// Pointers to cell subviews
@property (nonatomic, weak) UITextField *fileNameTextField;
@property (nonatomic, weak) UISwitch *majorMinorVersionToggle;
@property (nonatomic, weak) TextView *commentTextView;

@property (nonatomic, weak) UIBarButtonItem *uploadButton;

// Data Model
@property (nonatomic, strong) NSArray *cells;
@property (nonatomic, weak) AlfrescoRequest *uploadRequest;
@property (nonatomic, strong) AlfrescoDocument *document;
@property (nonatomic, strong) AlfrescoVersionService *versionService;
@property (nonatomic, strong) NSString *filePathToUploadDocument;

@end

@implementation NewVersionViewController

- (instancetype)initWithDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session
{
    self = [self initWithSession:session];
    if (self)
    {
        self.document = document;
        self.versionService = [[AlfrescoVersionService alloc] initWithSession:session];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"new.version.title", @"New Version Title");
    
    self.allowsPullToRefresh = NO;
    
    [self createCells];
    
    UIBarButtonItem *uploadButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"new.version.upload", @"Upload") style:UIBarButtonItemStylePlain target:self action:@selector(uploadNewVersion:)];
    uploadButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = uploadButton;
    self.uploadButton = uploadButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissController:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewDocumentCreateUpdateForm];
}

#pragma mark - Private Functions

- (void)createCells
{
    NewVersionLabelCell *fileTitleNameCell = (NewVersionLabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([NewVersionLabelCell class]) owner:self options:nil] lastObject];
    fileTitleNameCell.titleLabel.text = NSLocalizedString(@"new.version.file.title", @"Select File Title");
    fileTitleNameCell.valueTextField.placeholder = NSLocalizedString(@"new.version.file.placeholder", @"Select File Placeholder");
    
    NewVersionToggleCell *majorMinorVersionCell = (NewVersionToggleCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([NewVersionToggleCell class]) owner:self options:nil] lastObject];
    majorMinorVersionCell.titleLabel.text = NSLocalizedString(@"new.version.major.version.title", @"Major Change Title");
    majorMinorVersionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NewVersionTextViewCell *commentCell = (NewVersionTextViewCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([NewVersionTextViewCell class]) owner:self options:nil] lastObject];
    commentCell.titleLabel.text = NSLocalizedString(@"new.version.comment.title", @"Comment Title");
    commentCell.valueTextView.placeholderText = NSLocalizedString(@"new.version.commet.placeholder", @"Add Comment Placeholder");
    commentCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Pointers
    self.fileNameTextField = fileTitleNameCell.valueTextField;
    self.majorMinorVersionToggle = majorMinorVersionCell.valueSwitch;
    self.commentTextView = commentCell.valueTextView;
    
    self.cells = @[fileTitleNameCell, majorMinorVersionCell, commentCell];
}

- (void)dismissController:(UIBarButtonItem *)sender
{
    [self.uploadRequest cancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldEnableUploadButton
{
    BOOL uploadButtonShouldBeEnabled = NO;
    
    if (self.filePathToUploadDocument && [[AlfrescoFileManager sharedManager] fileExistsAtPath:self.filePathToUploadDocument])
    {
        uploadButtonShouldBeEnabled = YES;
    }
    
    return uploadButtonShouldBeEnabled;
}

- (void)uploadNewVersion:(UIBarButtonItem *)sender
{
    sender.enabled = NO;
    
    [self showHUDWithMode:MBProgressHUDModeDeterminate];
    self.uploadRequest = [self.versionService checkoutDocument:self.document completionBlock:^(AlfrescoDocument *checkoutDocument, NSError *checkoutError) {
        if (checkoutError)
        {
            [self hideHUD];
            sender.enabled = YES;
            
            NSString *checkoutErrorTitle = NSLocalizedString(@"error.new.version.unable.to.checkout.title", @"Checkout Title");
            NSString *checkoutErrorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.new.version.unable.to.checkout.message", @"Checkout Error Message"), self.document.name, checkoutError.localizedDescription];
            displayErrorMessageWithTitle(checkoutErrorMessage, checkoutErrorTitle);
            [Notifier notifyWithAlfrescoError:checkoutError];
        }
        else
        {
            NSString *comment = nil;
            if (self.commentTextView.text && ![self.commentTextView.text isEqualToString:self.commentTextView.placeholderText])
            {
                comment = self.commentTextView.text;
            }
            
            NSError *attributeError = nil;
            NSDictionary *fileAttributes = [[AlfrescoFileManager sharedManager] attributesOfItemAtPath:self.filePathToUploadDocument error:&attributeError];
            
            if (attributeError)
            {
                AlfrescoLogError(@"Unable to get the attributes for the item at path: %@", self.filePathToUploadDocument);
            }
            
            NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:self.filePathToUploadDocument];
            [inputStream open];
            unsigned long long fileLength = [(NSNumber *)fileAttributes[kAlfrescoFileSize] unsignedLongLongValue];
            AlfrescoContentStream *contentStream = [[AlfrescoContentStream alloc] initWithStream:inputStream mimeType:[Utility mimeTypeForFileExtension:self.filePathToUploadDocument.pathExtension] length:fileLength];
            
            [self.versionService checkinDocument:checkoutDocument asMajorVersion:self.majorMinorVersionToggle.isOn contentStream:contentStream properties:nil comment:comment completionBlock:^(AlfrescoDocument *updatedDocument, NSError *updateError) {
                [self hideHUD];
                sender.enabled = YES;
                
                if (updateError)
                {
                    NSString *checkinErrorTitle = NSLocalizedString(@"error.new.version.unable.to.checkin.title", @"Checkin Title");
                    NSString *checkinErrorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.new.version.unable.to.checkin.message", @"Checkin Error Message"), self.document.name, checkoutError.localizedDescription];
                    displayErrorMessageWithTitle(checkinErrorMessage, checkinErrorTitle);
                }
                else
                {
                    [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                                      action:kAnalyticsEventActionUpdate
                                                                       label:self.document.contentMimeType
                                                                       value:@1
                                                                customMetric:AnalyticsMetricFileSize
                                                                 metricValue:@(self.document.contentLength)];
                    
                    [[RealmSyncCore sharedSyncCore] didUploadNewVersionForDocument:checkoutDocument updatedDocument:updatedDocument fromPath:self.filePathToUploadDocument forAccountIdentifier:[AccountManager sharedManager].selectedAccount.accountIdentifier];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDocumentUpdatedOnServerNotification object:updatedDocument userInfo:@{kAlfrescoDocumentUpdatedFromDocumentParameterKey : self.document}];
                    });
                    
                    [self.navigationController dismissViewControllerAnimated:YES completion:^{
                        NSString *checkinSuccessTitle = NSLocalizedString(@"new.version.upload.successful.title", @"Checkin Success Title");
                        NSString *checkinSuccessMessage = [NSString stringWithFormat:NSLocalizedString(@"new.version.upload.successful.message", @"Checkin Success Message"), self.document.name];
                        displayInformationMessageWithTitle(checkinSuccessMessage, checkinSuccessTitle);
                    }];
                }
            } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                self.progressHUD.progress = (bytesTotal != 0) ? (float)bytesTransferred / (float)bytesTotal : 0;
            }];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cells[indexPath.row];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = (UITableViewCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Get the actual height required for the cell
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableView *selectedCell = self.cells[indexPath.row];
    
    if ([selectedCell isKindOfClass:[NewVersionLabelCell class]])
    {
        DownloadsViewController *downloadsViewController = [[DownloadsViewController alloc] initWithSession:self.session];
        downloadsViewController.downloadPickerDelegate = self;
        downloadsViewController.isDownloadPickerEnabled = YES;
        [self.navigationController pushViewController:downloadsViewController animated:YES];
    }
}

- (void)downloadPicker:(DownloadsViewController *)picker didPickDocument:(NSString *)documentPath
{
    if (documentPath)
    {
        self.fileNameTextField.text = documentPath.lastPathComponent;
        self.filePathToUploadDocument = documentPath;
        self.uploadButton.enabled = [self shouldEnableUploadButton];
        [picker.navigationController popViewControllerAnimated:YES];
    }
}

@end
