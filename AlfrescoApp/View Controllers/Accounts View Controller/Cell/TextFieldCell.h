//
//  AddAccountCell.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 01/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextFieldCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UITextField *valueTextField;

@property (nonatomic, assign) BOOL shouldBecomeFirstResponder;

@end
