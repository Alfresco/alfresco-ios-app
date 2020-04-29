/*
 ******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile SDK.
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
 *****************************************************************************
 */

NSString * const kAlfrescoJSONEvaluator = @"evaluator";
NSString * const kAlfrescoJSONEvaluators = @"evaluators";
NSString * const kAlfrescoJSONMatchAny = @"match-any";
NSString * const kAlfrescoJSONMatchAll = @"match-all";
NSString * const kAlfrescoJSONInfo = @"info";
NSString * const kAlfrescoJSONSchemaVersion = @"schema-version";
NSString * const kAlfrescoJSONConfigVersion = @"config-version";
NSString * const kAlfrescoJSONRepository = @"repository";
NSString * const kAlfrescoJSONShareURL = @"share-url";
NSString * const kAlfrescoJSONCMISURL = @"cmis-url";
NSString * const kAlfrescoJSONProfiles = @"profiles";
NSString * const kAlfrescoJSONDefault = @"default";
NSString * const kAlfrescoJSONLabelId = @"label-id";
NSString * const kAlfrescoJSONDescriptionId = @"description-id";
NSString * const kAlfrescoJSONIconId = @"icon-id";
NSString * const kAlfrescoJSONFormId = @"form-id";
NSString * const kAlfrescoJSONRootViewId = @"root-view-id";
NSString * const kAlfrescoJSONFeatures = @"features";
NSString * const kAlfrescoJSONItemType = @"item-type";
NSString * const kAlfrescoJSONViewGroups = @"view-groups";
NSString * const kAlfrescoJSONViewGroupId = @"view-group-id";
NSString * const kAlfrescoJSONViewGroup = @"view-group";
NSString * const kAlfrescoJSONViewId = @"view-id";
NSString * const kAlfrescoJSONViews = @"views";
NSString * const kAlfrescoJSONView = @"view";
NSString * const kAlfrescoJSONType = @"type";
NSString * const kAlfrescoJSONParams = @"params";
NSString * const kAlfrescoJSONCreation = @"creation";
NSString * const kAlfrescoJSONMimeTypes = @"mime-types";
NSString * const kAlfrescoJSONDocumentTypes = @"document-types";
NSString * const kAlfrescoJSONFolderTypes = @"folder-types";
NSString * const kAlfrescoJSONForms = @"forms";
NSString * const kAlfrescoJSONLayout = @"layout";
NSString * const kAlfrescoJSONFieldGroupId = @"field-group-id";
NSString * const kAlfrescoJSONFieldGroups = @"field-groups";
NSString * const kAlfrescoJSONFieldGroup = @"field-group";
NSString * const kAlfrescoJSONFieldId = @"field-id";
NSString * const kAlfrescoJSONField = @"field";
NSString * const kAlfrescoJSONFields = @"fields";
NSString * const kAlfrescoJSONModelId = @"model-id";

NSString * const kAlfrescoConfigApplicationDirectoryCMISSearchQuery = @"SELECT * FROM cmis:folder WHERE CONTAINS ('QNAME:\"app:company_home/app:dictionary\"')";
NSString * const kAlfrescoConfigFolderPathToConfigFileRelativeToApplicationDirectory = @"Mobile";

NSString * const kAlfrescoConfigServiceDefaultFileName = @"configuration.json";
NSString * const kAlfrescoConfigServiceTemporaryFileName = @"configuration-temp.json";
NSString * const kAlfrescoConfigProfileDefaultIdentifier = @"default";
NSString * const kAlfrescoConfigProfileDefaultLabel = @"Default";
NSString * const kAlfrescoConfigFormTypePrefix = @"type:";
NSString * const kAlfrescoConfigFormAspectPrefix = @"aspect:";
NSString * const kAlfrescoConfigFormTypeProperties = @"${type-properties}";
NSString * const kAlfrescoConfigFormAspectProperties = @"${aspects}";
NSString * const kAlfrescoConfigEvaluatorRepositoryCapability = @"org.alfresco.client.evaluator.hasRepositoryCapability";
NSString * const kAlfrescoConfigEvaluatorNodeType = @"org.alfresco.client.evaluator.nodeType";
NSString * const kAlfrescoConfigEvaluatorAspect = @"org.alfresco.client.evaluator.hasAspect";
NSString * const kAlfrescoConfigEvaluatorProfile = @"org.alfresco.client.evaluator.hasProfile";
NSString * const kAlfrescoConfigEvaluatorFormMode = @"org.alfresco.client.evaluator.formMode";
NSString * const kAlfrescoConfigEvaluatorIsUser = @"org.alfresco.client.evaluator.isUser";
NSString * const kAlfrescoConfigEvaluatorParameterProfile = @"profile";
NSString * const kAlfrescoConfigEvaluatorParameterTypeName = @"typeName";
NSString * const kAlfrescoConfigEvaluatorParameterAspectName = @"aspectName";
NSString * const kAlfrescoConfigEvaluatorParameterOperator = @"operator";
NSString * const kAlfrescoConfigEvaluatorParameterSession = @"session";
NSString * const kAlfrescoConfigEvaluatorParameterEdition = @"edition";
NSString * const kAlfrescoConfigEvaluatorParameterMajorVersion = @"majorVersion";
NSString * const kAlfrescoConfigEvaluatorParameterMinorVersion = @"minorVersion";
NSString * const kAlfrescoConfigEvaluatorParameterMaintenanceVersion = @"maintenanceVersion";
NSString * const kAlfrescoConfigEvaluatorParameterMode = @"mode";
NSString * const kAlfrescoConfigEvaluatorParameterUsers = @"users";
NSString * const kAlfrescoConfigEvaluatorParameterEvaluatorIds = @"evaluatorIds";
NSString * const kAlfrescoConfigEvaluatorParameterMatchAll = @"matchAll";

NSString * const kAlfrescoConfigSessionTypeCloud = @"cloud";
NSString * const kAlfrescoConfigSessionTypeOnPremise = @"onpremise";
