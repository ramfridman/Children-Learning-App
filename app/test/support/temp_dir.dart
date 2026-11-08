import 'dart:io';

/// Deletes a temporary folder a test made, and never fails the test for it.
///
/// On Windows a recursive delete can fail with "directory is not empty" when the indexer or a virus scanner still holds a file the test
/// just wrote. The delete is tried again a few times, a moment apart; if the folder still cannot go it is left for the system's temp
/// clean-up: a leftover temporary folder is harmless, a red test for it is not.
void removeTempDir(Directory dir, {int tries = 5, Duration wait = const Duration(milliseconds: 100)}) {
  for (int attempt = 1; attempt <= tries; attempt++) {
    try {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      return;
    } on FileSystemException {
      if (attempt == tries) return;
      sleep(wait * attempt);
    }
  }
}
