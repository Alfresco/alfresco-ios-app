//
//  SaveBackMetadata.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SaveBackMetadata : NSObject

@property (nonatomic, strong, readonly) NSString *accountID;
@property (nonatomic, strong, readonly) NSString *nodeRef;
@property (nonatomic, strong, readonly) NSString *originalFileLocation;
@property (nonatomic, assign, readonly) InAppDocumentLocation documentLocation;

- (instancetype)initWithAccountID:(NSString *)accountID nodeRef:(NSString *)nodeRef originalFileLocation:(NSString *)urlString documentLocation:(InAppDocumentLocation)location;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
