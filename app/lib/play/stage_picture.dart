import 'package:flutter/painting.dart';

import '../design/tokens.g.dart';

/// The smallest picture a cell of a row on a stage of [stage] may have: the token `stagePictureMin` on a phone, and 1.4 times that
/// on a tablet (the stage there is wider than any phone's), as the hint's pictures are scaled (`hintScale`). A row whose cells would
/// be smaller stands in two lines.
double minPictureOf(Size stage) => TokenComponent.stagePictureMin * (stage.width > 500 ? 1.4 : 1);
