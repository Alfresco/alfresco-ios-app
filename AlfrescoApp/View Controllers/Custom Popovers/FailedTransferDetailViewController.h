//
//  FailedTransferDetailViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 08/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

typedef void (^FailedTransferRetryCompletionBlock)(BOOL retry);

@interface FailedTransferDetailViewController : UIViewController

@property (nonatomic, strong) FailedTransferRetryCompletionBlock retryCompletionBlock;

- (id)initWithTitle:(NSString *)title message:(NSString *)message retryCompletionBlock:(FailedTransferRetryCompletionBlock)retryCompletionBlock;

@end
