import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether lessons are played in their room (M11: the room's look, the host's greeting and cheer, the landmark that reacts). On in the app;
/// the tests of the frame and the templates that predate the rooms switch it off, and the room tests switch it on.
final Provider<bool> roomsEnabledProvider = Provider<bool>((Ref ref) => true);
