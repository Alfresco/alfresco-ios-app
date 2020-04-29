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
 
#import "FailedTransferDetailViewController.h"
#import <objc/message.h>

static const CGFloat kFailedTransferDetailPadding = 10.0f;
static const CGFloat kFailedTransferDetailHeight = 400.;
static const CGFloat kFailedTransferDetailWidth = 272.;

@interface FailedTransferDetailViewController ()
@property (nonatomic, strong) NSString *titleText;
@property (nonatomic, strong) NSString *messageText;
@end

@implementation FailedTransferDetailViewController

- (id)initWithTitle:(NSString *)title message:(NSString *)message retryCompletionBlock:(FailedTransferRetryCompletionBlock)retryCompletionBlock
{
    self = [super init];
    if (self)
    {
        self.titleText = title;
        self.messageText = message;
        self.retryCompletionBlock = retryCompletionBlock;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kFailedTransferDetailWidth, kFailedTransferDetailHeight)];
    containerView.backgroundColor = [UIColor whiteColor];
    
    CGFloat subViewWidth = kFailedTransferDetailWidth - (kFailedTransferDetailPadding * 2);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFailedTransferDetailPadding, kFailedTransferDetailPadding, subViewWidth, 0)];
    [titleLabel setFont:[UIFont systemFontOfSize:19.0f]];
    [titleLabel setText:self.titleText];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    CGRect titleFrame = titleLabel.frame;
    titleFrame.size.height = [titleLabel sizeThatFits:CGSizeMake(subViewWidth, kFailedTransferDetailHeight)].height;
    [titleLabel setFrame:titleFrame];
    [containerView addSubview:titleLabel];
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFailedTransferDetailPadding, titleFrame.size.height + (kFailedTransferDetailPadding * 2), subViewWidth, 0)];
    [descriptionLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel setText:self.messageText];
    [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
    [descriptionLabel setBackgroundColor:[UIColor clearColor]];
    CGRect descriptionFrame = descriptionLabel.frame;
    descriptionFrame.size.height = [descriptionLabel sizeThatFits:CGSizeMake(subViewWidth, kFailedTransferDetailHeight)].height;
    [descriptionLabel setFrame:descriptionFrame];
    [containerView addSubview:descriptionLabel];
    
    
    UIButton *retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [retryButton.titleLabel setFont:[UIFont systemFontOfSize:17.0f]];
    retryButton.tintColor = [UIColor appTintColor];
    [retryButton setTitle:NSLocalizedString(@"Retry", @"Retry") forState:UIControlStateNormal];
    [retryButton setTitleColor:retryButton.tintColor forState:UIControlStateNormal];
    retryButton.layer.cornerRadius = 4.0f;
    retryButton.layer.borderWidth = 1.0f;
    retryButton.layer.borderColor = retryButton.tintColor.CGColor;
    
    CGRect retryButtonFrame = CGRectMake(kFailedTransferDetailPadding, titleFrame.size.height + descriptionFrame.size.height + (kFailedTransferDetailPadding * 3), subViewWidth, 40);
    [retryButton setFrame:retryButtonFrame];
    [retryButton addTarget:self action:@selector(retryButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:retryButton];
    
    CGRect containerFrame = containerView.frame;
    containerFrame.size.height = titleLabel.frame.size.height + descriptionLabel.frame.size.height + retryButton.frame.size.height + (kFailedTransferDetailPadding * 4);
    [containerView setFrame:containerFrame];
    [self setView:containerView];
}

#pragma mark - Button Action

- (void)retryButtonAction:(id)sender
{
    if (self.retryCompletionBlock != NULL)
    {
        self.retryCompletionBlock();
    }
}

@end
