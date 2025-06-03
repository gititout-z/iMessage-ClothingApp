// ARCHITECTURE.md
# iMessage Clothing App Architecture

## Overview
The Clothing App is designed to run entirely within the iMessage context, with no standalone app required. It follows a modular architecture with clear separation of concerns, making it maintainable and extensible.

## App Structure

### 1. Core Components

#### MessagesViewController
The central controller that manages the iMessage lifecycle and coordinates between different parts of the app. It handles:
- Authentication state
- View presentation
- Deep linking
- iMessage presentation style changes

#### Environment
Custom environment values to handle iMessage-specific constraints like safe areas and presentation styles.

### 2. Module Structure

#### Authentication
- **AuthenticationService**: Manages user authentication state
- **AuthenticationView**: Sign in interface
- **User**: Data model for user information
- **SignInWithAppleButton**: Custom button for Apple authentication

#### Camera
- **CameraView**: UI for capturing clothing items
- **ClothingCamera**: Camera and photo library access
- **ClothingUploadForm**: Form for adding metadata to captures
- **ImagePermissionsHandler**: Permission management

#### Profile
- **ProfileView**: User profile and clothing collection
- **EditProfileView**: Profile editing interface
- **ClothingGridView**: Grid display for clothing items
- **ProfileHeader**: User information header

#### Search
- **SearchView**: Text and visual search interface
- **VisualSearchView**: Image-based search
- **SearchResultsView**: Text search results
- **ImageSearchResultsView**: Visual search results
- **ClothingMatchRow**: UI for social matches
- **ClothingPurchaseRow**: UI for commercial matches
- **SearchBar**: Search input component
- **FilterOptions**: Search filtering interface

#### Social
- **SocialView**: Social network interface
- **SocialManager**: Social graph operations
- **UserRow**: User display component
- **FollowButton**: Follow/unfollow functionality

#### Common
- **MessageSafeArea**: iMessage-specific safe area handling
- **LoadingIndicator**: Loading state UI
- **ErrorView**: Error display with retry
- **ImagePicker**: Photo selection interface
- **MessageComposer**: iMessage content creation

### 3. Data Flow

#### Backend Services
- **Backend**: Central facade for backend services. The `Backend` service acts as a crucial facade for most network operations. It implements a centralized retry mechanism with exponential backoff and standardizes error handling by transforming raw network or CloudKit errors into user-friendly `NSError` objects. All major services (`AuthenticationService`, `ClothingService`, `SocialService`, `ImageUploader`, `SearchService`) have been refactored to utilize `Backend.swift` for their network-dependent operations, ensuring consistent error handling and resilience.
- **CloudKitManager**: CloudKit operations
- **NetworkMonitor**: Network connectivity tracking

#### Data Models
- **ClothingItem**: Clothing item data
- **ClothingMatch**: Search match data
- **ClothingMetadata**: Item metadata
- **CommercialMatch**: Commercial item match

#### Services
- **ClothingService**: Clothing operations
- **SocialService**: Social operations
- **SearchService**: Search operations
- **ImageProcessor**: Image analysis
- **ImageUploader**: Image upload functionality
- **ImageCache**: Image caching

### 4. Image Processing
- **CoreMLProcessing**: ML model operations
- **ImageAnalysis**: Image analysis and metadata extraction
- **ImageCompression**: Image optimization
- **UIImage Extensions**: Image manipulation utilities

## Key Design Decisions

### 1. Memory Management
The app is optimized for the memory constraints of iMessage, with:
- Efficient image handling
- Minimal view hierarchy
- Background processing for heavy tasks
- Proper cleanup of unused resources

### 2. Network Handling
Robust error handling and retry logic are centralized in `Backend.swift`, which is used by all services making network requests. This includes:
- Robust error handling
- Retry logic with exponential backoff
- Offline support with caching
- Network status monitoring

### 3. iMessage Integration
- Proper handling of presentation styles
- Safe area adaptation
- Deep linking support
- Message composition and sharing

### 4. CloudKit Usage
- Efficient record design
- Proper relationship modeling
- Caching for offline operation
- Background syncing

## Performance Considerations

### Image Processing
- Images are resized and compressed before upload
- On-device processing when possible
- Background threading for heavy operations

### Search Performance
- Efficient indexing in CloudKit
- Caching of common searches
- Progressive loading of results

### UI Responsiveness
- Background threads for data operations
- Loading states for all operations
- Error handling with retry options

## Security

### Authentication
- Sign in with Apple for secure authentication
- The Apple User Identifier (`userIdentifier`) obtained from Sign In with Apple is securely stored in the Keychain by `AuthenticationService.swift`. This identifier is used to re-authenticate and fetch user profile data from CloudKit. No other sensitive user tokens are stored.
- Session management

### Data Protection
- CloudKit security for data storage
- Proper access controls
- Privacy considerations for shared data

## Future Expansion

### Potential Features
- AR try-on functionality
- Advanced social features
- More sophisticated visual search
- Retail integration for purchases

### Integration Points
- The modular architecture allows for easy expansion
- Clear separation of concerns makes feature addition straightforward
- Service interfaces can be extended without breaking changes