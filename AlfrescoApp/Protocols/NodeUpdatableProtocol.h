//
//  NodeUpdatableProtocol.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 14/05/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

@protocol NodeUpdatableProtocol <NSObject>

/*
 * Both are optional, however, one should be implemented. If the controller deals with a document
 * it is recommened that the AlfrescoDocument specific method be implemented.
 *
 * If -updateToAlfrescoDocument:permissions:contentFilePath:documentLocation:session: is implemented,
 * it is called instead of -updateToAlfrescoNode:permissions:session:
 */
@optional
- (void)updateToAlfrescoNode:(AlfrescoNode *)node
                 permissions:(AlfrescoPermissions *)permissions
                     session:(id<AlfrescoSession>)session;

- (void)updateToAlfrescoDocument:(AlfrescoDocument *)node
                     permissions:(AlfrescoPermissions *)permissions
                 contentFilePath:(NSString *)contentFilePath
                documentLocation:(InAppDocumentLocation)documentLocation
                         session:(id<AlfrescoSession>)session;

@end
