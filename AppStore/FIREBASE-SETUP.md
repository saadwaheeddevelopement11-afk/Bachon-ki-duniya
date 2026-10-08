# Firebase setup — Kido (`com.cmpak.kidoApp`)

Project ID: `kido-1c8be`  
Bundle ID must match: `com.cmpak.kidoApp`

## Already done in the Xcode project

- Pods: `FirebaseAnalytics`, `FirebaseCrashlytics`, `FirebaseMessaging`
- `FirebaseApp.configure()` in `AppDelegate`
- Push permission + FCM token handling (`PushNotificationManager`)
- Analytics helper (`AppAnalytics`) + sample events (login, logout, play_video, open_game, app_open)
- Crashlytics user ID = MSISDN when logged in
- Entitlements: Push (`aps-environment`)
- `Info.plist`: `UIBackgroundModes` → `remote-notification`
- Crashlytics upload-symbols Run Script build phase
- `GoogleService-Info.plist` in app folder (auto-synced by Xcode)

Run after pulling:

```bash
cd "/Users/macbookpro/Documents/Bachon Ki Duniya/Bachon ki duniya"
pod install
open "Bachon ki duniya.xcworkspace"
```

---

## What you must do in Firebase Console

### 1. Confirm the iOS app

1. Open [Firebase Console](https://console.firebase.google.com/) → project **kido-1c8be**
2. Project settings → Your apps → iOS app
3. Bundle ID = **`com.cmpak.kidoApp`** (must match Xcode)
4. Keep `GoogleService-Info.plist` in the app target (already in `Bachon ki duniya/`)

### 2. Enable Analytics

1. Analytics → Dashboard (enable if prompted)
2. Analytics → Events — after a few minutes you should see `app_open`, `login`, etc. (DebugView is faster; see below)
### 2b. Custom definitions (`msisdn`, `query`, `device`)

In Firebase Console → **Analytics → Custom definitions**:

| Name | Scope | Event parameter / User property | Notes |
|------|--------|----------------------------------|--------|
| `msisdn` | **User property** | User property: `msisdn` | Also sent on events |
| `device` | **User property** | User property: `device` | e.g. `iPhone\|iOS 18.x` |
| `query` | **Event** (Custom dimension) | Event parameter: `query` | Logged on `search` events |

Steps:
1. Custom definitions → **Create custom dimensions**
2. For `query`: Scope = Event, Event parameter = `query`, optionally Event = `search`
3. Custom definitions → **Create custom user properties** (or User properties tab)
4. Add `msisdn` and `device`
5. Wait up to 24h for reporting; use **DebugView** to verify immediately

App code already sets:
- User properties: `msisdn`, `device` at launch / login
- Event params: `query` on search; `msisdn` + `device` attached to most events

**DebugView (recommended while testing):**

```bash
# On a physical device connected via USB:
/usr/bin/xcrun simctl spawn booted log config --mode "level:debug" --subsystem com.google.firebase.analytics
# Or for device:
# Xcode → Product → Scheme → Edit Scheme → Run → Arguments →
# -FIRDebugEnabled
```

In Xcode scheme **Run → Arguments Passed On Launch**, add:

```
-FIRDebugEnabled
```

Then open Firebase → Analytics → DebugView.

### 3. Enable Crashlytics

1. Build & Crashlytics → Crashlytics → Enable if not already
2. Build a **Release** (or Archive) once so dSYMs upload via the Run Script
3. To verify: temporarily call `fatalError("Crashlytics test")` on a button, run on device, relaunch — crash should appear within a few minutes

### 4. Enable Cloud Messaging (Push)

1. Engage → Messaging (or Build → Cloud Messaging)
2. Apple app configuration:
   - Upload **APNs Authentication Key** (`.p8`) from [Apple Developer → Keys](https://developer.apple.com/account/resources/authkeys/list)
   - Or upload APNs certificates (legacy)
3. Key must be created under **CMPAK LIMITED** team (same as the app)
4. In the Firebase iOS app settings, paste:
   - Key ID
   - Team ID (`JVHLZ8B94A` for CMPAK)
   - Upload the `.p8` file

**Apple Developer (CMPAK) steps for push:**

1. Certificates, Identifiers & Profiles → Identifiers → `com.cmpak.kidoApp`
2. Enable **Push Notifications** capability → Save
3. Keys → create key with **Apple Push Notifications service (APNs)** → download `.p8` once
4. Xcode: Signing & Capabilities → ensure **Push Notifications** capability is present (entitlements file is already wired)

### 5. Send a test push

1. Run the app on a **real device** (simulator push is limited)
2. Allow notifications when prompted
3. Copy FCM token from Xcode console (`[FCM] token: …`)
4. Firebase → Messaging → New campaign → Firebase Notification messages → Send test message → paste FCM token

### 6. Privacy / App Store

- Update Privacy Policy to mention Analytics, Crashlytics, Push tokens
- App Store Connect → App Privacy: disclose analytics / crash data / identifiers as applicable

---

## How to log more events in code

```swift
AppAnalytics.logScreen("Home")
AppAnalytics.logSearch(term: query)
AppAnalytics.logSelectContent(type: "category", id: "49", name: "Games")
AppAnalytics.log("custom_event", parameters: ["key": "value"])
```

---

## Checklist

- [ ] `pod install` and open `.xcworkspace`
- [ ] Push Notifications enabled on App ID `com.cmpak.kidoApp`
- [ ] APNs Auth Key uploaded to Firebase
- [ ] Xcode capability Push Notifications visible
- [ ] Crashlytics enabled in console
- [ ] Analytics DebugView shows events
- [ ] Test push received on device
