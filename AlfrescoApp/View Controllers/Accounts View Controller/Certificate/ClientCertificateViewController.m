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
 
#import "ClientCertificateViewController.h"
#import "UserAccount.h"
#import "CenterLabelCell.h"
#import "ClientCertificateImportViewController.h"
#import "UIAlertView+ALF.h"
#import "CertificateDocumentFilter.h"

static NSInteger const kDeleteCertificateGroup = 1;
static CGFloat const kTableViewCellHeight = 54.0f;

@interface ClientCertificateViewController ()
@property (nonatomic, strong) UserAccount *account;
@end

@implementation ClientCertificateViewController

- (id)initWithAccount:(UserAccount *)account
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self)
    {
        self.account = account;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self constructTableGroups];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.account.accountCertificate)
    {
        if (indexPath.section == kDeleteCertificateGroup)
        {
            [self deleteCertificate];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
    else
    {
        CertificateDocumentFilter *certificateFilter = [[CertificateDocumentFilter alloc] init];
        DownloadsViewController *downloadsController = [[DownloadsViewController alloc] initWithDocumentFilter:certificateFilter];
        downloadsController.isDownloadPickerEnabled = YES;
        downloadsController.downloadPickerDelegate = self;
        [self.navigationController pushViewController:downloadsController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kTableViewCellHeight;
}

#pragma mark - Downloads Delegates

- (void)downloadPicker:(DownloadsViewController *)picker didPickDocument:(NSString *)documentPath
{
    ClientCertificateImportViewController *certificateImportController = [[ClientCertificateImportViewController alloc] initWithAccount:self.account andCertificatePath:documentPath];
    [self.navigationController popViewControllerAnimated:NO];
    [self.navigationController pushViewController:certificateImportController animated:YES];
}

- (void)downloadPickerDidCancel
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private Methods

- (void)constructTableGroups
{
    if (!self.account.accountCertificate)
    {
        UITableViewCell *addCertificateCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CertificateCell"];
        addCertificateCell.textLabel.text = NSLocalizedString(@"certificate-manage.add-cell.label", @"Certificate Manage - Label for the add certificate cell's label");
        addCertificateCell.selectionStyle = UITableViewCellSelectionStyleBlue;
        addCertificateCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        addCertificateCell.backgroundColor = [UIColor whiteColor];
        addCertificateCell.imageView.image = [UIImage imageNamed:@"certificate-add.png"];
        
        NSArray *tableGroup = @[addCertificateCell];
        self.tableViewData = [NSMutableArray arrayWithArray:@[tableGroup]];
    }
    else
    {
        UITableViewCell *identityCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CertificateCell"];
        identityCell.textLabel.text = self.account.accountCertificate.summary;
        identityCell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"certificate-details.issuer", @"Issuer message for the Certificate details"), self.account.accountCertificate.certificateIssuer];
        identityCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [identityCell.imageView setImage:[UIImage imageNamed:@"certificate.png"]];
        
        CenterLabelCell *deleteCertificateCell = (CenterLabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([CenterLabelCell class]) owner:self options:nil] lastObject];
        deleteCertificateCell.titleLabel.text = NSLocalizedString(@"certificate-details.buttons.delete", @"Delete Certificate");
        deleteCertificateCell.titleLabel.textColor = [UIColor whiteColor];
        deleteCertificateCell.backgroundColor = [UIColor redColor];
        
        NSArray *identityGroup = @[identityCell];
        NSArray *deleteGroup = @[deleteCertificateCell];
        self.tableViewData = [NSMutableArray arrayWithArray:@[identityGroup, deleteGroup]];
    }

    [self.tableView reloadData];
}

- (void)deleteCertificate
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"certificate-details.delete.title", @"Title for the delete certificate prompt")
                                                    message:NSLocalizedString(@"certificate-details.delete.message", @"Message for the delete certificate prompt")
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                          otherButtonTitles:NSLocalizedString(@"certificate-details.delete.confirm", @"Remove button label for the Remove certificate prompt"), nil];
    
    [alert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
        
        if (!isCancelButton)
        {
            self.account.accountCertificate = nil;
            [self constructTableGroups];
        }
    }];
}

@end
