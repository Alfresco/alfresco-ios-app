//
//  Utilities.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 26/02/2015.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

+ (NSString *)nodeGUIDFromNodeIdentifierWithVersion:(NSString *)nodeIdentifier
{
    NSString *nodeGUID = [nodeIdentifier stringByReplacingOccurrencesOfString:@"workspace://SpacesStore/" withString:@""];
    nodeGUID = [nodeGUID stringByReplacingOccurrencesOfString:@";" withString:@""];
    nodeGUID = [nodeGUID stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    return nodeGUID;
}

@end
