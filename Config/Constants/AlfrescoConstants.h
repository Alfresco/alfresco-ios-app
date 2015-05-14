#import "AlfrescoConfigInfo.h"
#import "AlfrescoCreationConfig.h"
#import "AlfrescoFeatureConfig.h"
#import "AlfrescoFormConfig.h"
#import "AlfrescoProfileConfig.h"
#import "AlfrescoRepositoryConfig.h"
#import "AlfrescoViewConfig.h"
#import "AlfrescoViewGroupConfig.h"


typedef void (^AlfrescoConfigInfoCompletionBlock)(AlfrescoConfigInfo *configInfo, NSError *error);
typedef void (^AlfrescoCreationConfigCompletionBlock)(AlfrescoCreationConfig *config, NSError *error);
typedef void (^AlfrescoFeatureConfigCompletionBlock)(AlfrescoFeatureConfig *config, NSError *error);
typedef void (^AlfrescoFormConfigCompletionBlock)(AlfrescoFormConfig *config, NSError *error);
typedef void (^AlfrescoProfileConfigCompletionBlock)(AlfrescoProfileConfig *config, NSError *error);
typedef void (^AlfrescoRepositoryConfigCompletionBlock)(AlfrescoRepositoryConfig *config, NSError *error);
typedef void (^AlfrescoViewConfigCompletionBlock)(AlfrescoViewConfig *config, NSError *error);
typedef void (^AlfrescoViewGroupConfigCompletionBlock)(AlfrescoViewGroupConfig *config, NSError *error);

/**---------------------------------------------------------------------------------------
 * @name Configuration Constants
 --------------------------------------------------------------------------------------- */
extern NSString * const kAlfrescoConfigServiceParameterApplicationId;
extern NSString * const kAlfrescoConfigServiceParameterProfileId;
extern NSString * const kAlfrescoConfigServiceParameterFolder;

extern NSString * const kAlfrescoConfigScopeContextNode;
extern NSString * const kAlfrescoConfigScopeContextFormMode;


