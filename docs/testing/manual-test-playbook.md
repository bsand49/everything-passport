# Manual test playbook

How to run a hands-on pass on real devices/emulators, plus the tooling that
makes it fast. Pair with `manual-test-checklist.md` (the checklist template).
Completed run notes are kept locally as `manual-test-run*.md` files (see
`docs/.gitignore`) and are not committed — record outcomes in the relevant
PR description instead.

## Launching the app

```bash
cd mobile
flutter run --dart-define=ENV=dev \
  --dart-define=SERVER_CLIENT_ID=<web-client-id>
```

`SERVER_CLIENT_ID` must be the `client_type: 3` web OAuth client from
`android/app/google-services.json` — a dummy value breaks Google Sign-In at
runtime.

## Tooling

- **adb**: `~/Library/Android/sdk/platform-tools/adb` (not always on `PATH`).
- **Maestro**: `~/.maestro/bin/maestro` (Homebrew install). Use
  `--device <id-or-udid>` when more than one device is connected;
  `maestro --device ... hierarchy` dumps the UI tree as JSON, and
  `maestro test flow.yaml` runs tap/swipe/input flows on both platforms.
- **Screenshots**: `adb -s <device> exec-out screencap -p > /tmp/x.png`;
  `xcrun simctl io <udid> screenshot /tmp/x.png`. The read tool may not render
  images to the agent — sample pixel colours instead (e.g. decode the PNG via
  `sips -s format bmp` and read pixels with a small Python script).
- **iOS appearance**: `xcrun simctl ui <udid> appearance dark|light`, then
  `xcrun simctl terminate` + `launch` for a cold start (catches splash).
- **Firebase Storage check**: `gsutil ls -l
  gs://<project>.firebasestorage.app/profile_pictures/` confirms uploads
  actually landed (bucket is `<project>.firebasestorage.app`, not
  `<project>.appspot.com`).

## Gotchas learned

- `adb shell input text` does **not** URL-decode escapes — type `+` literally,
  not `%2B`. Special chars like spaces need `%s`.
- The soft keyboard covers lower form fields; dismiss with a single
  `KEYCODE_BACK` between fields (two backs navigates away).
- Clearing a focused `EditText`: tap it, `KEYCODE_MOVE_END`, then repeated
  `KEYCODE_DEL` events.
- `image_cropper` requires `com.yalantis.ucrop.UCropActivity` declared in the
  app `AndroidManifest.xml` — without it the plugin crashes the app
  (`ActivityNotFoundException` then a fatal double MethodChannel reply). See
  the comment in `mobile/android/app/src/main/AndroidManifest.xml`.
- The Android photo picker is the system picker; push test images to
  `/sdcard/Pictures/` and media-scan them
  (`am broadcast -a android.intent.action.MEDIA_SCAN_FILE ...`) so they
  appear. Note `mobile/test_image.jpg` is a 3-byte placeholder, not a real
  image.
- Verification emails: Firebase sends from
  `noreply@<project>.firebaseapp.com`; plus-addressed inboxes
  (`user+tag@domain`) work for extra test accounts. The verification link is
  an `oobCode` URL — open it in the device browser, then use the app's
  "Refresh" button rather than restarting.

## Checklist coverage notes

Items that automated tests already cover or could cover cheaply
(unit/widget/integration tests): banner visibility per auth state, resend
cooldown countdown, clear-cache dialog + snackbar, navigation flows.

Items that genuinely need a manual/device pass: real email delivery, the
oobCode link → Refresh flow, Google Sign-In (needs a real Google account on
the device), profile photo pick/crop/upload end-to-end (native pickers and
cropper UIs, plus confirming the Storage object), splash in light/dark on
both platforms, and status/nav-bar contrast in dark mode.

## Test accounts

Dev project accounts used for manual passes (credentials shared out-of-band):

- `brad.sanderson_94@live.co.uk` / `bradsand94test` — verified email/password
- `brad.sanderson_94+two@live.co.uk` / `bradsand94two` — unverified
- `brad.sanderson_94+three@live.co.uk` / `bradsand94three` — unverified
- `bsand49.development@gmail.com` — Google account on the Android emulator
