//
//  MultiSelectActionItem.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@interface MultiSelectActionItem : UIBarButtonItem

@property (nonatomic, strong) NSString *actionId;

- (void)setButtonTitleWithCounterValue:(NSUInteger)counter;
- (id)initWithTitle:(NSString *)titleLocalizationKey style:(UIBarButtonItemStyle)style actionId:(NSString *)actionId isDestructive:(BOOL)isDestructive target:(id)target action:(SEL)action;

@end
