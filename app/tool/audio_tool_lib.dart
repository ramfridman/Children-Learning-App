// The two things the language packs need that no voice should be paid for: a slow copy of a clip, and one word cut out
// of a clip. Both are made from a clip that was voiced already, with ffmpeg (free software) on the owner's PC. Nothing
// here calls a voice service or reads a key.
import 'dart:io';
import 'dart:typed_data';

import 'voice_text_lib.dart' show VoiceGenFailed;

/// Slow and cut, for MP3 clips.
abstract interface class AudioTool {
  /// Why the tool cannot be used on this PC (with what to do about it), or null when it can.
  Future<String?> unavailableReason();

  /// [mp3] played at [tempo] times the speed (0.5 to 1.0), the pitch unchanged.
  Future<Uint8List> slow(Uint8List mp3, double tempo);

  /// The part of [mp3] from [fromSeconds] to [toSeconds].
  Future<Uint8List> cut(Uint8List mp3, double fromSeconds, double toSeconds);
}

/// What the plan says when ffmpeg is missing.
const String ffmpegMissing =
    'ffmpeg is not installed, or is not on the PATH. It is free software and the slow clips and the cut words need it. '
    'The owner installs it once (PowerShell: winget install Gyan.FFmpeg), opens a new PowerShell window, or passes '
    '--ffmpeg <path to ffmpeg.exe>. Nothing is paid for this step.';

/// The output of every clip this tool makes: MP3, mono, 44.1 kHz, 64 kbps, like the voice's own clips.
const List<String> _mp3Output = <String>['-codec:a', 'libmp3lame', '-b:a', '64k', '-ar', '44100', '-ac', '1'];

/// The ffmpeg arguments that make [output] from [input] at [tempo] times the speed.
List<String> slowArguments(String input, String output, double tempo) {
  if (!(tempo >= 0.5 && tempo <= 1.0)) {
    throw VoiceGenFailed('a slow clip runs at 0.5 to 1.0 times the speed, not $tempo');
  }
  return <String>[
    '-y',
    '-loglevel',
    'error',
    '-i',
    input,
    '-filter:a',
    'atempo=$tempo',
    ..._mp3Output,
    output,
  ];
}

/// The ffmpeg arguments that make [output] from the part of [input] between the two times (output options, so the cut is
/// exact and not moved to the nearest frame).
List<String> cutArguments(String input, String output, double fromSeconds, double toSeconds) {
  if (!(fromSeconds >= 0 && toSeconds > fromSeconds)) {
    throw VoiceGenFailed('a cut runs from a time to a later one, not $fromSeconds to $toSeconds');
  }
  return <String>[
    '-y',
    '-loglevel',
    'error',
    '-i',
    input,
    '-ss',
    fromSeconds.toStringAsFixed(3),
    '-to',
    toSeconds.toStringAsFixed(3),
    ..._mp3Output,
    output,
  ];
}

/// ffmpeg, started with an argument list (never through a shell) on files in a temporary folder.
class FfmpegTool implements AudioTool {
  const FfmpegTool([this.executable = 'ffmpeg']);

  final String executable;

  @override
  Future<String?> unavailableReason() async {
    try {
      final ProcessResult r = await Process.run(executable, const <String>['-version']);
      return r.exitCode == 0 ? null : ffmpegMissing;
    } on ProcessException {
      return ffmpegMissing;
    }
  }

  @override
  Future<Uint8List> slow(Uint8List mp3, double tempo) =>
      _run(mp3, (String i, String o) => slowArguments(i, o, tempo));

  @override
  Future<Uint8List> cut(Uint8List mp3, double fromSeconds, double toSeconds) =>
      _run(mp3, (String i, String o) => cutArguments(i, o, fromSeconds, toSeconds));

  Future<Uint8List> _run(Uint8List mp3, List<String> Function(String input, String output) arguments) async {
    final Directory tmp = Directory.systemTemp.createTempSync('nn_ffmpeg_');
    try {
      final String input = '${tmp.path}${Platform.pathSeparator}in.mp3';
      final String output = '${tmp.path}${Platform.pathSeparator}out.mp3';
      File(input).writeAsBytesSync(mp3);
      final ProcessResult r = await Process.run(executable, arguments(input, output));
      final File made = File(output);
      if (r.exitCode != 0 || !made.existsSync() || made.lengthSync() == 0) {
        throw VoiceGenFailed('ffmpeg could not make the clip (exit code ${r.exitCode})');
      }
      return made.readAsBytesSync();
    } on ProcessException {
      throw const VoiceGenFailed(ffmpegMissing);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  }
}
