//
//  AlfrescoFormFieldCellTableViewCell.h
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 14/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlfrescoFormField.h"

extern NSString * const kAlfrescoFormFieldChangedNotification;

@interface AlfrescoFormCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *label;

@property (nonatomic, assign, getter = isSelectable) BOOL selectable;
@property (nonatomic, strong) AlfrescoFormField *field;

- (void)configureCell;

- (void)didSelectCellWithNavigationController:(UINavigationController *)navigationController;

@end
