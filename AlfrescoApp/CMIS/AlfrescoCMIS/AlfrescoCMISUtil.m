/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */

//
// AlfrescoCMISUtil 
//
#import "AlfrescoCMISUtil.h"
#import "CMISObject.h"
#import "CMISAtomPubConstants.h"
#import "CMISAtomParserUtil.h"
#import "CMISErrors.h"
#import "AlfrescoErrors.h"

#define ALFRESCO_EXTENSION_ASPECTS @"aspects"
#define ALFRESCO_EXTENSION_APPLIED_ASPECTS @"appliedAspects"
#define ALFRESCO_EXTENSION_PROPERTIES @"properties"
#define ALFRESCO_EXTENSION_PROPERTY_VALUE @"value"


@implementation AlfrescoCMISUtil

+ (NSMutableArray *)processExtensionElementsForObject:(CMISObject *)cmisObject
{
    NSArray *alfrescoExtensions = [cmisObject extensionsForExtensionLevel:CMISExtensionLevelProperties];
    NSMutableArray *aspectTypeIds = [[NSMutableArray alloc] init];

    // We'll gather all the properties, and expose them as conveniently on the document
    NSMutableArray *propertyExtensionRootElements = [[NSMutableArray alloc] init];

    // Find all Alfresco aspects in the extensions
    if (alfrescoExtensions != nil && alfrescoExtensions.count > 0)
    {
        for (CMISExtensionElement *extensionElement in alfrescoExtensions)
        {
            if ([extensionElement.name isEqualToString:ALFRESCO_EXTENSION_ASPECTS])
            {
                for (CMISExtensionElement *childExtensionElement in extensionElement.children)
                {
                    if ([childExtensionElement.name isEqualToString:ALFRESCO_EXTENSION_APPLIED_ASPECTS])
                    {
                        [aspectTypeIds addObject:childExtensionElement.value];
                    }
                    else if ([childExtensionElement.name isEqualToString:ALFRESCO_EXTENSION_PROPERTIES])
                    {
                        [propertyExtensionRootElements addObject:childExtensionElement];
                    }
                }
            }
        }
    }

    // Convert all extended properties to 'real' properties
    for (CMISExtensionElement *propertyRootExtensionElement in propertyExtensionRootElements)
    {
        for (CMISExtensionElement *propertyExtension in propertyRootExtensionElement.children)
        {
            CMISPropertyData *propertyData = [[CMISPropertyData alloc] init];
            propertyData.identifier = [propertyExtension.attributes objectForKey:kCMISAtomEntryPropertyDefId];
            propertyData.displayName = [propertyExtension.attributes objectForKey:kCMISAtomEntryDisplayName];
            propertyData.queryName = [propertyExtension.attributes objectForKey:kCMISAtomEntryQueryName];
            propertyData.type = [CMISAtomParserUtil atomPubTypeToInternalType:propertyExtension.name];

            CMISExtensionElement *valueExtensionElement = [propertyExtension.children objectAtIndex:0];
            if (valueExtensionElement.value)
            {
                NSMutableArray *propertyValue = [NSMutableArray array];
                [CMISAtomParserUtil parsePropertyValue:valueExtensionElement.value propertyType:propertyExtension.name addToArray:propertyValue];
                propertyData.values = (NSArray *)propertyValue;
            }

            [cmisObject.properties addProperty:propertyData];
        }
    }

    return aspectTypeIds;
}

+ (NSError *)alfrescoErrorWithCMISError:(NSError *)cmisError
{
    int cmisErrorCode = [cmisError code];
    NSError *alfrescoError = nil;
    switch (cmisErrorCode) {
        case kCMISErrorCodeNoReturn:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeHTTPResponse];
            break;
        case kCMISErrorCodeConnection:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeSession];
            break;
        case kCMISErrorCodeProxyAuthentication:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeUnauthorisedAccess];
            break;
        case kCMISErrorCodeUnauthorized:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeUnauthorisedAccess];
            break;
        case kCMISErrorCodeNoRootFolderFound:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeRequestedNodeNotFound];
            break;
        case kCMISErrorCodeNoRepositoryFound:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeNoRepositoryFound];
            break;
        case kCMISErrorCodeCancelled:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeNetworkRequestCancelled];
            break;
        case kCMISErrorCodeInvalidArgument:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeHTTPResponse];
            break;
        case kCMISErrorCodeObjectNotFound:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeRequestedNodeNotFound];
            break;
        case kCMISErrorCodeNotSupported:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeHTTPResponse];
            break;
        case kCMISErrorCodePermissionDenied:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderPermissions];
            break;
        case kCMISErrorCodeRuntime:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeUnknown];
            break;
        case kCMISErrorCodeConstraint:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolder];
            break;
        case kCMISErrorCodeContentAlreadyExists:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolderNodeAlreadyExists];
            break;
        case kCMISErrorCodeFilterNotValid:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolder];
            break;
        case kCMISErrorCodeNameConstraintViolation:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolder];
            break;
        case kCMISErrorCodeStorage:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolder];
            break;
        case kCMISErrorCodeStreamNotSupported:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolder];
            break;
        case kCMISErrorCodeUpdateConflict:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeDocumentFolder];
            break;
        case kCMISErrorCodeVersioning:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:cmisError andAlfrescoErrorCode:kAlfrescoErrorCodeHTTPResponse];
            break;
            
        default:
            alfrescoError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeUnknown];
            break;
    }
    return alfrescoError;
}


@end