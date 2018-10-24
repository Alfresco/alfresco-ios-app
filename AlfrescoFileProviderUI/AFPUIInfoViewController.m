/*******************************************************************************
 * Copyright (C) 2005-2018 Alfresco Software Limited.
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

#import "AFPUIInfoViewController.h"
#import "AFPUIConstants.h"

@interface AFPUIInfoViewController()

@property (weak, nonatomic) IBOutlet UIBarButtonItem        *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet UILabel                *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel                *messageLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint     *toolbarHeightConstraint;
@property (assign, nonatomic) CGFloat                       initialToolbarHeight;

@end

@implementation AFPUIInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cancelBarButtonItem.title = NSLocalizedString(@"fileproviderui.button.cancel.title", @"Cancel button");
    
    switch (self.controllerType)
    {
        case AFPUIInfoViewControllerTypePIN:
        {
            self.titleLabel.text = NSLocalizedString(@"fileproviderui.security.passcode.enabled.title", @"Passcode message title");
            self.messageLabel.text = NSLocalizedString(@"fileproviderui.security.passcode.message", @"Passcode message text");
        }
            break;
            
        case AFPUIInfoViewControllerTypeBasicAuth:
        {
            self.titleLabel.text = NSLocalizedString(@"fileproviderui.security.credentials.invalid.title", @"Invalid credentials title");
            self.messageLabel.text = NSLocalizedString(@"fileproviderui.security.credentials.invalid.message", @"Invalid credentials text");
        }
            break;
            
        default: break;
    }
    
    self.initialToolbarHeight = kUIExtensionToolbarHeight;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (@available(iOS 11.0, *))
    {
        self.toolbarHeightConstraint.constant = self.initialToolbarHeight + self.view.safeAreaInsets.top;
    }
}
    
- (IBAction)cancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:NO
                             completion:nil];
    
    if ([self.delegate respondsToSelector:@selector(userDidCancelledInfoScreen)])
    {
        [self.delegate userDidCancelledInfoScreen];
    }
}

@end

