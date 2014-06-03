To replace all source code headers in .h and .m files:

    $ cd AlfrescoApp
    $ find . \( -name "*.h" -or -name "*.m" \) -exec ../tools/header/replace_header.sh {} \;


** IMPORTANT **

This will recursively replace headers in source files not owned by Alfresco, including:

    "Third Party Libraries/*"
    "NSData+Base64.*"
    The legacy FreshDocs source code files "AccountInfo.*" and "AccountStatus.*"

...these files MUST be reverted back to their own original header and not be replaced with the template here.
