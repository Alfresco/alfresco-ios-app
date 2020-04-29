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
 
#import "ClientCertificateImportViewController.h"
#import "TextFieldCell.h"
#import "AccountManager.h"

@interface ClientCertificateImportViewController ()

@property (nonatomic, strong) NSArray *tableHeaders;
@property (nonatomic, strong) NSArray *tableFooters;
@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) NSString *certificatePath;
@property (nonatomic, strong) UITextField *passcodeTextField;
@property (nonatomic, strong) UIBarButtonItem *importButton;

@end

@implementation ClientCertificateImportViewController

- (id)initWithAccount:(UserAccount *)account andCertificatePath:(NSString *)certificatePath
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self)
    {
        self.account = account;
        self.certificatePath = certificatePath;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.importButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"certificate-import.button.import", @"Import button label")
                                                         style:UIBarButtonItemStyleDone
                                                        target:self
                                                        action:@selector(importButtonAction:)];
    self.importButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = self.importButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel Button Text")
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(cancelButtonAction:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:nil];
    
    [self constructTableGroups];
    self.title = self.certificatePath.lastPathComponent;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableViewData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewData[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.tableViewData[indexPath.section][indexPath.row];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.tableHeaders[section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return self.tableFooters[section];
}

#pragma mark - Private Methods

- (void)constructTableGroups
{
    TextFieldCell *passcodeCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    passcodeCell.titleLabel.text = NSLocalizedString(@"certificate-import.fields.passcode", @"Passcode field label");
    passcodeCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"required");
    passcodeCell.valueTextField.delegate = self;
    self.passcodeTextField = passcodeCell.valueTextField;
    passcodeCell.valueTextField.secureTextEntry = YES;
    passcodeCell.valueTextField.returnKeyType = UIReturnKeyDone;
    passcodeCell.shouldBecomeFirstResponder = YES;
    
    self.tableHeaders = @[NSLocalizedString(@"certificate-import.tableHeader", @"Table header for the Import Certificate View")];
    self.tableFooters = @[NSLocalizedString(@"certificate-import.tableFooter", @"Table footer for the Import Certificate View")];
    NSArray *tableGroup = @[passcodeCell];
    self.tableViewData = [NSMutableArray arrayWithArray:@[tableGroup]];
}

- (void)importButtonAction:(id)sender
{
    [self.passcodeTextField resignFirstResponder];
    AlfrescoLogDebug(@"Importing certificate file: %@", self.certificatePath);
    
    AccountManager *accountManager = [AccountManager sharedManager];
    NSString *passcode = self.passcodeTextField.text;
    NSData *certificateData = [NSData dataWithContentsOfFile:self.certificatePath];
    ImportCertificateStatus status = [accountManager validatePKCS12:certificateData withPasscode:passcode];
    
    if (status == ImportCertificateStatusSucceeded)
    {
        [accountManager saveCertificateIdentityData:certificateData withPasscode:passcode forAccount:self.account];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if (status == ImportCertificateStatusFailed)
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"certificate-import.error.format", @"Message for wrong certificate file"),
                                     NSLocalizedString(@"certificate-import.error.title", @"Import Certificate error title"));
    }
    else if (status == ImportCertificateStatusCancelled)
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"certificate-import.error.authentication", @"Message for wrong passcode"),
                                     NSLocalizedString(@"certificate-import.error.title", @"Import Certificate error title"));
    }
}

- (void)cancelButtonAction:(id)sender
{
    [self.passcodeTextField resignFirstResponder];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITextField Methods

- (void)textFieldDidChange:(NSNotification *)notification
{
    self.importButton.enabled = (self.passcodeTextField.text.length > 0);
}

@end
