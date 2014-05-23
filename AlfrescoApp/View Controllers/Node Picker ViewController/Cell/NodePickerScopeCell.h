//
//  NodePickerScopeCell.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 17/03/2014.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ThumbnailImageView.h"

@interface NodePickerScopeCell : UITableViewCell

@property (nonatomic, weak) IBOutlet ThumbnailImageView *thumbnail;
@property (nonatomic, weak) IBOutlet UILabel *label;

@end
