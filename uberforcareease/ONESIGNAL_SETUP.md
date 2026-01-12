# OneSignal Notification Setup Guide

This guide explains how to configure OneSignal notifications for the CareEase application.

## Overview

OneSignal has been integrated across all parts of the application:
- **Backend**: Notification service to send push notifications
- **User Mobile App**: Receive notifications for order updates
- **Vendor Mobile App**: Receive notifications for new orders and order status changes
- **Delivery Mobile App**: Receive notifications for order assignments and status updates

## Backend Setup

### 1. Install Dependencies

The OneSignal package has been added to `backend/package.json`. Install it:

```bash
cd backend
npm install
```

### 2. Environment Variables

Add the following environment variables to your `.env` file:

```env
ONESIGNAL_APP_ID=your_onesignal_app_id
ONESIGNAL_REST_API_KEY=your_onesignal_rest_api_key
ONESIGNAL_ANDROID_CHANNEL_ID=default
```

**To get your OneSignal credentials:**
1. Go to https://onesignal.com and create an account
2. Create a new app
3. Go to Settings > Keys & IDs
4. Copy the **App ID** and **REST API Key**

## Mobile Apps Setup

### 1. Install Dependencies

OneSignal SDK has been added to all three Flutter apps. Install dependencies:

```bash
# User App
cd usermobileapp
flutter pub get

# Vendor App
cd vendormobileapp
flutter pub get

# Delivery App
cd deliverymobileapp
flutter pub get
```

### 2. Configure OneSignal App ID

Update the OneSignal App ID in each app's service file:

**usermobileapp/lib/services/onesignal_service.dart:**
```dart
static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
```

**vendormobileapp/lib/services/onesignal_service.dart:**
```dart
static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
```

**deliverymobileapp/lib/services/onesignal_service.dart:**
```dart
static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
```

Replace `YOUR_ONESIGNAL_APP_ID` with your actual OneSignal App ID (same as used in backend).

### 3. Android Configuration

For Android, add the following to `android/app/build.gradle` in each app:

```gradle
android {
    defaultConfig {
        manifestPlaceholders = [
            onesignal_app_id: 'YOUR_ONESIGNAL_APP_ID',
            onesignal_google_project_number: 'YOUR_GOOGLE_PROJECT_NUMBER'
        ]
    }
}
```

Get your Google Project Number from OneSignal dashboard under Settings > Platforms > Google (FCM).

### 4. iOS Configuration

For iOS, add the following to `ios/Runner/Info.plist` in each app:

```xml
<key>OneSignal_AppID</key>
<string>YOUR_ONESIGNAL_APP_ID</string>
```

## Notification Events

The following events trigger notifications:

### User App Notifications:
- **New Order Created**: When user places an order
- **Items Picked Up**: When delivery guy picks up items
- **Items at Vendor**: When items arrive at vendor
- **Order Processing**: When vendor confirms items and starts processing
- **Out for Delivery**: When items are out for delivery
- **Order Delivered**: When order is completed

### Vendor App Notifications:
- **New Order Received**: When a new order is placed
- **Items Incoming**: When items are picked up and on the way
- **Order Ready for Pickup**: When order is marked ready (notifies delivery guy too)

### Delivery App Notifications:
- **Order Ready for Pickup**: When vendor marks order as ready
- **Order Status Updates**: Various status change notifications

## API Endpoints

### Update Player ID
**PUT** `/api/auth/onesignal-player-id`

Updates the OneSignal player ID for the authenticated user.

**Request Body:**
```json
{
  "playerId": "onesignal-player-id-here"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OneSignal player ID updated successfully"
}
```

## Testing

1. **Test Backend Notifications:**
   - Create an order as a user
   - Check vendor app receives "New Order Received" notification
   - Update order status as delivery guy
   - Check user app receives status update notifications

2. **Test Player ID Registration:**
   - Login to any app
   - Check backend logs for player ID update
   - Verify player ID is saved in database

## Troubleshooting

### Notifications not received:
1. Check OneSignal App ID is correct in all apps
2. Verify environment variables are set in backend
3. Check device has internet connection
4. Verify user has granted notification permissions
5. Check OneSignal dashboard for delivery status

### Player ID not updating:
1. Check authentication token is valid
2. Verify API endpoint is accessible
3. Check backend logs for errors
4. Ensure user is logged in when OneSignal initializes

## Additional Resources

- [OneSignal Flutter SDK Documentation](https://documentation.onesignal.com/docs/flutter-sdk-setup)
- [OneSignal REST API Documentation](https://documentation.onesignal.com/reference)
- [OneSignal Dashboard](https://app.onesignal.com)

