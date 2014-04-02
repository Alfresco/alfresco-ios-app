//
//  NodePickerListCell.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 31/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailImageView.h"

@interface NodePickerListCell : UITableViewCell

@property (nonatomic, weak) IBOutlet ThumbnailImageView *thumbnail;
@property (nonatomic, weak) IBOutlet UILabel *label;

@end
