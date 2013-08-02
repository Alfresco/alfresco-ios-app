//
//  VersionHistoryCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VersionHistoryCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) IBOutlet UILabel *lastModifiedLabel;
@property (nonatomic, strong) IBOutlet UILabel *lastModifiedByLabel;
@property (nonatomic, strong) IBOutlet UILabel *commentLabel;
@property (nonatomic, strong) IBOutlet UILabel *currentVersionLabel;

@end
