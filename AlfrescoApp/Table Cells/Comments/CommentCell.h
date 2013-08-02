//
//  CommentCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *authorTextLabel;
@property (nonatomic, strong) IBOutlet UILabel *contentTextLabel;
@property (nonatomic, strong) IBOutlet UILabel *timeTextLabel;

@end
