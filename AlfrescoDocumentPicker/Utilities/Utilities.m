//
//  Utilities.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 26/02/2015.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import "Utilities.h"

static NSString * const kWorkspaceNodePrefix = @"workspace://SpacesStore/";

@implementation Utilities

#pragma mark - Public Methods

+ (NSString *)filenameWithVersionFromFilename:(NSString *)filename nodeIdentifier:(NSString *)nodeIdentifier
{
    NSRange versionStartRange = [nodeIdentifier rangeOfString:@";"];
    
    if (nodeIdentifier.length > versionStartRange.location)
    {
        NSString *versionNumber = [nodeIdentifier substringFromIndex:(versionStartRange.location + 1)];
    
        NSString *pathExtension = filename.pathExtension;
        filename = [filename stringByDeletingPathExtension];
        filename = [filename stringByAppendingString:[NSString stringWithFormat:@" v%@", versionNumber]]; // append the version number
        filename = [filename stringByAppendingPathExtension:pathExtension];
    }
    
    return filename;
}

+ (NSString *)nodeGUIDFromNodeIdentifierWithVersion:(NSString *)nodeIdentifier
{
    NSString *nodeGUID = [nodeIdentifier stringByReplacingOccurrencesOfString:kWorkspaceNodePrefix withString:@""];
    nodeGUID = [nodeGUID stringByReplacingOccurrencesOfString:@";" withString:@""];
    nodeGUID = [nodeGUID stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    return nodeGUID;
}

@end
