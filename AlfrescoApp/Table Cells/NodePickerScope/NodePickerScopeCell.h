//
//  NodePickerScopeCell.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 17/03/2014.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailImageView.h"

@interface NodePickerScopeCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *thumbnail;
@property (nonatomic, weak) IBOutlet UILabel *label;

@end
