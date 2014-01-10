//
//  UIView+AutoLayout.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "UICollectionView+AutoLayout.h"

@implementation UICollectionView (AutoLayout)

- (instancetype)initAutoLayoutWithCollectionViewLayout:(UICollectionViewFlowLayout *)layout
{
    self = [self initWithFrame:CGRectZero collectionViewLayout:layout];
    if (self)
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

@end
