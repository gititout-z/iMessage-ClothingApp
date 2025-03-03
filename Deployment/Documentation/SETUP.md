// SETUP.md
# Clothing App for iMessage Setup Guide

## Prerequisites
- Xcode 14.0 or later
- iOS 16.0 or later
- Apple Developer account
- iCloud CloudKit enabled

## Setup Steps

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/iMessage-ClothingApp.git
cd iMessage-ClothingApp
```

### 2. Configure the Project

#### Bundle Identifier
1. Open the project in Xcode
2. Select the project in the Project Navigator
3. Select the MessagesExtension target
4. Under the "General" tab, update the Bundle Identifier to your own
5. Do the same for any other targets in the project

#### Signing & Capabilities
1. Under the "Signing & Capabilities" tab, select your Team
2. Ensure the following capabilities are enabled:
   - App Groups
   - CloudKit
   - Sign in with Apple

#### CloudKit Configuration
1. Go to the [Apple Developer Portal](https://developer.apple.com)
2. Navigate to Certificates, Identifiers & Profiles
3. Select your App ID
4. Enable iCloud services with CloudKit
5. Create an iCloud Container with the same identifier as in the project
6. Configure the CloudKit Dashboard with the schema provided in `CloudKitSchema.json`

### 3. Configure Info.plist
1. Update the `CFBundleDisplayName` if you want to change the app name
2. Review and update the privacy description strings for camera and photo library access

### 4. Build and Run
1. Select an iOS simulator or device
2. Build and run the project
3. The app should appear in the Messages app drawer

## Troubleshooting

### App Not Appearing in Messages
1. Ensure the Messages app is running
2. Pull down the app drawer to refresh
3. Check that the app is enabled in Messages settings

### CloudKit Errors
1. Verify your Apple Developer account has iCloud enabled
2. Check that the CloudKit container is properly configured
3. Ensure the schema matches the one in `CloudKitSchema.json`

### Sign in with Apple Issues
1. Verify the capability is enabled in Xcode
2. Check the entitlements file
3. Ensure your Apple Developer account has Sign in with Apple enabled

## Support
For additional support, please contact the development team at support@example.com