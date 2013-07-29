//
//  AboutViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITextView *aboutTextView;
@property (weak, nonatomic) IBOutlet UILabel *librariesLabel;
@property (weak, nonatomic) IBOutlet UIView *librariesContainerView;
@property (weak, nonatomic) IBOutlet UIView *versionInfoView;
@property (weak, nonatomic) IBOutlet UILabel *versionNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildDateLabel;

@end
