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

#import "ClientCertificateDownloadViewController.h"
#import "TextFieldCell.h"

@interface ClientCertificateDownloadViewController() <UITableViewDataSource, UITextFieldDelegate, NSURLSessionDownloadDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *tableCells;
@property (nonatomic, strong) UIBarButtonItem *downloadButton;
@property (nonatomic, strong) UITextField *urlTextField;
@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) MBProgressHUD *hud;
@end

@implementation ClientCertificateDownloadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    tableView.dataSource = self;
    tableView.autoresizesSubviews = YES;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:tableView];
    self.tableView = tableView;

    TextFieldCell *urlCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    urlCell.selectionStyle = UITableViewCellSelectionStyleNone;
    urlCell.titleLabel.text = NSLocalizedString(@"certificate-download.field.url", @"URL");
    urlCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"required");
    urlCell.valueTextField.returnKeyType = UIReturnKeyNext;
    urlCell.valueTextField.delegate = self;
    urlCell.valueTextField.keyboardType = UIKeyboardTypeURL;
    urlCell.shouldBecomeFirstResponder = YES;
    self.urlTextField = urlCell.valueTextField;

    TextFieldCell *usernameCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    usernameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    usernameCell.titleLabel.text = NSLocalizedString(@"login.username.cell.label", @"Username Cell Text");
    usernameCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.optional", @"optional");
    usernameCell.valueTextField.returnKeyType = UIReturnKeyNext;
    usernameCell.valueTextField.delegate = self;
    self.usernameTextField = usernameCell.valueTextField;
    
    TextFieldCell *passwordCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    passwordCell.selectionStyle = UITableViewCellSelectionStyleNone;
    passwordCell.titleLabel.text = NSLocalizedString(@"login.password.cell.label", @"Password Cell Text");
    passwordCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.optional", @"optional");
    passwordCell.valueTextField.returnKeyType = UIReturnKeyDone;
    passwordCell.valueTextField.secureTextEntry = YES;
    passwordCell.valueTextField.delegate = self;
    self.passwordTextField = passwordCell.valueTextField;
    
    self.tableCells = @[urlCell, usernameCell, passwordCell];
    
    self.title = NSLocalizedString(@"certificate-download.title", @"Web Server");

    UIBarButtonItem *downloadBarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"action.download", @"Download")
                                                                          style:UIBarButtonItemStyleDone
                                                                         target:self
                                                                         action:@selector(downloadAction:)];
    downloadBarButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = downloadBarButton;
    self.downloadButton = downloadBarButton;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)createAndDisplayHUD
{
    if (!self.hud)
    {
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.label.text = NSLocalizedString(@"action.print", @"Print");
        hud.detailsLabel.text = NSLocalizedString(@"login.hud.cancel.label", @"Tap To Cancel");
        hud.graceTime = 1.0;
        hud.mode = MBProgressHUDModeDeterminate;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleProgressTap:)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [hud addGestureRecognizer:tap];
        
        [self.view addSubview:hud];
        self.hud = hud;
    }

    self.hud.progress = 0;
    [self.hud showAnimated:YES];
}

- (void)hideHUD
{
    self.hud.progress = 1;
    [self.hud hideAnimated:YES];
}

- (void)displayError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error.code == NSURLErrorUserAuthenticationRequired)
        {
            displayErrorMessage(NSLocalizedString(@"error.login.failed", @"Login failed"));
        }
        else
        {
            displayErrorMessage(error.localizedDescription);
        }
    });
}

- (void)downloadAction:(id)sender
{
    [self createAndDisplayHUD];
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    if (self.usernameTextField.text.length > 0)
    {
        NSString *userPasswordString = [NSString stringWithFormat:@"%@:%@", self.usernameTextField.text, self.passwordTextField.text];
        NSString *authString = [NSString stringWithFormat:@"Basic %@", [[userPasswordString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0]];
        
        sessionConfiguration.HTTPAdditionalHeaders = @{@"Authorization": authString};
    }
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    self.downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:self.urlTextField.text]];
    [self.downloadTask resume];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableCells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.tableCells[indexPath.row];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.urlTextField)
    {
        [self.usernameTextField becomeFirstResponder];
    }
    else if (textField == self.usernameTextField)
    {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField)
    {
        [self.passwordTextField resignFirstResponder];
        
        if (self.downloadButton.enabled)
        {
            [self downloadAction:self.downloadButton];
        }
    }
    return YES;
}

#pragma mark - NSNotification

- (void)textFieldDidChange:(NSNotification *)notification
{
    self.downloadButton.enabled = (self.urlTextField.text.length > 0);
}

#pragma mark - UIGestureRecognizer

- (void)handleProgressTap:(UIGestureRecognizer *)gesture
{
    [self hideHUD];
    [self.downloadTask cancel];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    [self hideHUD];
    
    NSError *error = downloadTask.error;
    if (error)
    {
        if (error.code != NSURLErrorCancelled)
        {
            [self displayError:error];
        }
    }
    else if (self.delegate && [self.delegate respondsToSelector:@selector(clientCertificateDownload:didDownloadCertificateAtPath:)])
    {
        NSString *filename = [[downloadTask.originalRequest.URL path] lastPathComponent];
        if ([filename pathExtension].length == 0)
        {
            filename = [filename stringByAppendingFormat:@".%@", [Utility fileExtensionFromMimeType:downloadTask.response.MIMEType]];
        }
        NSString *destinationPath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
        [[AlfrescoFileManager sharedManager] removeItemAtPath:destinationPath error:nil];
        [[AlfrescoFileManager sharedManager] copyItemAtPath:location.path toPath:destinationPath error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate clientCertificateDownload:self didDownloadCertificateAtPath:destinationPath];
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    // No-op as this class does not support resuming
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    float progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.hud setProgress:progress];
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self hideHUD];
    
    if (error && error.code != NSURLErrorCancelled)
    {
        [self displayError:error];
    }
}

@end
