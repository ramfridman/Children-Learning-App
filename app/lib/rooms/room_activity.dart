import '../content/models.dart';

/// [a] as it is played in a room: the meadow of its scene is left out (the room draws its own backdrop behind the stage), and any other
/// background (the empty basket, the stroke pictures) is kept. The activity is otherwise the same one.
Activity inRoom(Activity a) {
  if (a.background != _meadow) return a;
  final Object? scene = a.json['scene'];
  if (scene is! Map<String, Object?>) return a;
  return Activity.fromJson(<String, Object?>{
    ...a.json,
    'scene': <String, Object?>{...scene}..remove('background'),
  }, a.assets);
}

const String _meadow = 'asset:meadow';
