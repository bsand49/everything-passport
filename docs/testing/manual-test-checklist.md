# Manual Test Checklist

Template for manual testing passes. Copy this file (or its sections) into the
PR description, release PR, or a pinned issue when a change needs hands-on
verification that unit/widget/integration tests cannot cover — e.g. real
Firebase email delivery, platform-specific UI behavior, or CI workflow
behavior.

Record results by checking boxes and noting the environment (OS, device,
Flutter version, Firebase project). For release sign-off, paste the completed
checklist into the release PR description.

## Environment

- Date:
- Tester:
- App build / commit:
- Platform(s) tested:
- Firebase project / `ENV`:

## Authentication & email verification

- [ ] Email/password sign-up succeeds and shows the expected SnackBar
- [ ] Verification email is delivered (do not click the link yet — verifying
      ends the unverified-state checks below; use a second account if needed)
- [ ] Unverified password account can sign in (login is not blocked)
- [ ] Verification banner appears on home, profile onboarding, settings, and
      edit-profile screens for unverified password accounts
- [ ] Banner is absent for verified accounts and Google sign-in accounts
- [ ] "Resend" sends another email and shows success feedback; repeat sends
      surface rate-limit/error feedback gracefully
- [ ] Resend cooldown: countdown disables the button for ~60s and is shared
      across screens; it resets on app restart and does not leak between
      accounts
- [ ] Clicking the verification link verifies the account, and "Refresh" then
      clears the banner without restarting the app
- [ ] Regression: profile onboarding, username flows, logout, and settings
      navigation still work

## UI / platform spot-checks

- [ ] Theme, colors, and core widgets render correctly (no broken layouts),
      including dark mode (splash retains brand colours; status/nav-bar
      contrast stays readable)
- [ ] Locale-sensitive formatting is correct (e.g. en-GB vs en-US dates)
- [ ] Google Sign-In completes end-to-end
- [ ] Profile photo upload/pick/crop works, and the uploaded object is
      visible in Firebase Storage (`profile_pictures/{userId}`)

## CI / workflow verification (when applicable)

- [ ] `workflow_dispatch` manual runs behave as expected
- [ ] Path filters trigger (or correctly skip) the relevant workflows
- [ ] Required status checks report on PRs that touch their paths
- [ ] Smoke jobs pass on the target runners (Android emulator, iOS simulator)

## Results / notes

<!-- Record failures, surprises, and follow-up items here. -->
