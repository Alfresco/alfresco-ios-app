/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
  
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
