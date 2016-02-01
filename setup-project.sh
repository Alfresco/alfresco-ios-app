#author @bhagyas
echo "Installing cocoapods..."
pod install
echo "Installing Alfresco SDK and other submodules..."
git submodule update --init --recursive --remote
echo "Project setup completed. Open 'AlfrescoApp.xcworkspace' to work on the project."
echo "You can also issue the following command 'open AlfrescoApp.xcworkspace' on your terminal."
