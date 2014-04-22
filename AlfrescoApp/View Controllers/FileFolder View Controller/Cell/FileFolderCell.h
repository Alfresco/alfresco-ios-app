//
//  FileFolderCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailImageView.h"

@interface FileFolderCell : UITableViewCell

@property (nonatomic, weak) IBOutlet ThumbnailImageView *nodeImageView;
@property (nonatomic, weak) IBOutlet UILabel *nodeNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *nodeDetailLabel;

@end
