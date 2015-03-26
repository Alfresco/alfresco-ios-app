//
//  ConnectionDiagnosticViewController.h
//  AlfrescoApp
//
//  Created by Silviu Odobescu on 19/03/15.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConnectionDiagnosticEventCell : UITableViewCell

@end

@interface ConnectionDiagnosticViewController : UIViewController < UITableViewDataSource, UITableViewDelegate >

- (void) setupWithParrent:(UIViewController *)parent andSelector:(SEL)selector;

@end
