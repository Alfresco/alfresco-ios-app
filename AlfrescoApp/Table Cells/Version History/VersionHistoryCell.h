//
//  VersionHistoryCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VersionHistoryCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, weak) IBOutlet UILabel *lastModifiedLabel;
@property (nonatomic, weak) IBOutlet UILabel *lastModifiedByLabel;
@property (nonatomic, weak) IBOutlet UILabel *commentLabel;
@property (nonatomic, weak) IBOutlet UILabel *currentVersionLabel;
@property (nonatomic, weak) IBOutlet UITableView *metadataTableview;
@property (nonatomic, weak) IBOutlet UIImageView *disclosureImageView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *metadataTableViewHeightConstraint;

@end
