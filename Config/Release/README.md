# Config/Release

Place `GoogleService-Info.plist` for the **production** Firebase project here before making a Release build.

`GoogleService-Info.plist` is gitignored — obtain it by running:

```bash
firebase apps:sdkconfig IOS <IOS_APP_ID> --project vitrumlabs-flixr-prod
```

Or download from Firebase Console → Project Settings → Your apps → iOS app → GoogleService-Info.plist.

The build will fail with a clear error if this file is missing when building Release.
