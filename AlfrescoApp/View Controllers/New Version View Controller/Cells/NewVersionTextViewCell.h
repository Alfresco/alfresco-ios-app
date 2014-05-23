//
//  NewVersionTextViewCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 23/05/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "TextView.h"

@interface NewVersionTextViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet TextView *valueTextView;

@end
