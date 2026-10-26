// Text of the developer harness. These screens exist only in the `dev` flavour, for the owner to
// test the device chain on a phone. They are never shown to a child and never ship in `prod`,
// so they are in plain English and are not part of the Hebrew string catalogue.
abstract final class DevStrings {
  static const String title = 'Nitznutz dev harness';
  static const String signIn = '1. Parent sign-in (email code)';
  static const String email = 'Email';
  static const String sendCode = 'Send code';
  static const String code = '6-digit email code';
  static const String verify = 'Verify';
  static const String enrol = '2. Enrol this phone as parent';
  static const String devSecret = 'Dev secret (emulator only, optional)';
  static const String enrolButton = 'Enrol as parent';
  static const String replaceButton = 'Replace this device';
  static const String pair = '3. Pair this phone as a child';
  static const String pairCode = 'Pairing code from a parent phone';
  static const String pairButton = 'Pair as child';
  static const String calls = '4. Signed calls';
  static const String ping = 'Signed ping';
  static const String appConfig = 'App config';
  static const String makeCode = 'Create pairing code (parent)';
  static const String listDevices = 'List devices (parent)';
  static const String revokeId = 'Device id to revoke';
  static const String revoke = 'Revoke device (parent)';
  static const String forget = 'Forget this phone (local only)';
  static const String packs = '5. Content packs';
  static const String installIncoming = 'Install .nnpack files from the incoming folder';
  static const String listPacks = 'List installed packs';
  static const String engine = '6. Learning engine';
  static const String engineState = 'Show what the engine knows about each child';
  static const String output = 'Output';
  static const String prodPlaceholder = 'Nitznutz';
  static const String configProblem = 'Build settings are missing or wrong';

  static const String tutorHeading = 'AI helper (M6)';
  static const String aiHelper = 'AI helper in lessons';
  static const String aiHelperNote =
      'Off by default. Needs the server keys and the server switch; a failure always falls back to the authored line.';
}
