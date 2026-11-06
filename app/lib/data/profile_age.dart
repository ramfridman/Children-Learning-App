import '../engine/age.dart';
import 'app_database.dart';

/// What a stored profile says about the child's school stage (B-29).
extension ProfileAge on Profile {
  /// The school stage a parent confirmed, or null when none was (a child made before B-29 until a parent confirms one).
  SchoolStage? get confirmedStage => SchoolStage.fromWire(schoolStage);

  /// The confirmed stage, else the middle stage of the child's band. This is what the warm-up and the Today's Adventure rows read.
  SchoolStage get stage => confirmedStage ?? SchoolStage.middleOfBand(ageBand);
}
