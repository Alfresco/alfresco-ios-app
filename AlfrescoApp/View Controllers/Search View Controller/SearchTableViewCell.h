//
//  SearchTableViewCell.h
//  AlfrescoApp
//
//  Created by Silviu Odobescu on 20/08/15.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *searchItemImage;
@property (weak, nonatomic) IBOutlet UILabel *searchItemText;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchItemImageWidthConstraint;

@end
