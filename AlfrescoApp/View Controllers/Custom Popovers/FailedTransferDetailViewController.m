//
//  FailedTransferDetailViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 08/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

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
    [titleLabel setFont:[UIFont boldSystemFontOfSize:19.]];
    [titleLabel setText:self.titleText];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    CGRect titleFrame = titleLabel.frame;
    titleFrame.size.height = [titleLabel sizeThatFits:CGSizeMake(subViewWidth, kFailedTransferDetailHeight)].height;
    [titleLabel setFrame:titleFrame];
    [containerView addSubview:titleLabel];
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFailedTransferDetailPadding, titleFrame.size.height + (kFailedTransferDetailPadding * 2), subViewWidth, 0)];
    [descriptionLabel setFont:[UIFont systemFontOfSize:17.]];
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel setText:self.messageText];
    [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
    [descriptionLabel setBackgroundColor:[UIColor clearColor]];
    CGRect descriptionFrame = descriptionLabel.frame;
    descriptionFrame.size.height = [descriptionLabel sizeThatFits:CGSizeMake(subViewWidth, kFailedTransferDetailHeight)].height;
    [descriptionLabel setFrame:descriptionFrame];
    [containerView addSubview:descriptionLabel];
    
    UIButton *retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [retryButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17.]];
    [retryButton setTitle:NSLocalizedString(@"Retry", @"Retry") forState:UIControlStateNormal];
    [retryButton setTitleColor:[UIColor textDefaultColor] forState:UIControlStateNormal];
    UIImage *buttonTemplate = [UIImage imageNamed:@"failed-transfer-detail-button"];
    UIImage *stretchedButtonImage = [buttonTemplate resizableImageWithCapInsets:UIEdgeInsetsMake(7., 5., 37., 5.)];
    [retryButton setBackgroundImage:stretchedButtonImage forState:UIControlStateNormal];
    
    CGRect retryButtonFrame = CGRectMake(kFailedTransferDetailPadding, titleFrame.size.height + descriptionFrame.size.height + (kFailedTransferDetailPadding * 3), subViewWidth, 40);
    [retryButton setFrame:retryButtonFrame];
    [retryButton addTarget:self action:@selector(retryButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:retryButton];
    
    CGRect containerFrame = containerView.frame;
    containerFrame.size.height = titleLabel.frame.size.height + descriptionLabel.frame.size.height + retryButton.frame.size.height + (kFailedTransferDetailPadding * 4);
    [containerView setFrame:containerFrame];
    [self setView:containerView];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Button Action

- (void)retryButtonAction:(id)sender
{
    if (self.retryCompletionBlock != NULL)
    {
        self.retryCompletionBlock(YES);
    }
}

@end
