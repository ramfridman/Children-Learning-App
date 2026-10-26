// A small schema language for the JSON files of a content pack, and the validator that runs it.
//
// The same definitions are used in three places, so they can never disagree: the pack builder
// (before it signs anything), the app's installer (before it installs anything), and the generator
// that writes standard JSON Schema files for authors' editors (`toJsonSchema`).
//
// Rules that hold for every schema: an object may have only the fields it lists (an unknown field is
// a problem, so nothing can be smuggled into a file), every string has a length limit, and a number
// has a range. Problems are reported with their path, for example `answer.options[1].misconception`.

/// One thing wrong with a document.
class Problem {
  const Problem(this.path, this.message);

  /// Where, like `answer.options[1].id`; empty for the document itself.
  final String path;
  final String message;

  @override
  String toString() => path.isEmpty ? message : '$path: $message';

  @override
  bool operator ==(Object other) => other is Problem && other.path == path && other.message == message;

  @override
  int get hashCode => Object.hash(path, message);
}

sealed class Schema {
  const Schema({this.doc});

  /// A short sentence for authors; it becomes the `description` in the JSON Schema file.
  final String? doc;
}

class SString extends Schema {
  const SString({this.minLength = 0, this.maxLength = 400, this.pattern, super.doc});

  final int minLength;
  final int maxLength;

  /// A regular expression the whole string must match (anchors are added by the validator).
  final String? pattern;
}

class SInt extends Schema {
  const SInt({required this.min, required this.max, super.doc});

  final int min;
  final int max;
}

class SNum extends Schema {
  const SNum({required this.min, required this.max, super.doc});

  final double min;
  final double max;
}

class SBool extends Schema {
  const SBool({super.doc});
}

class SEnum extends Schema {
  const SEnum(this.values, {super.doc});

  final List<String> values;
}

class SConst extends Schema {
  const SConst(this.value, {super.doc});

  final String value;
}

class SArray extends Schema {
  const SArray(this.items, {this.minItems = 0, this.maxItems = 100, this.uniqueKey, super.doc});

  final Schema items;
  final int minItems;
  final int maxItems;

  /// For an array of objects: a field whose value must differ in every element (usually `id`).
  final String? uniqueKey;
}

/// A field of an object. Fields are required unless [required] is false.
class SField {
  const SField(this.schema, {this.required = true});

  final Schema schema;
  final bool required;
}

class SObject extends Schema {
  const SObject(this.fields, {super.doc});

  final Map<String, SField> fields;
}

// ---- validation ----

List<Problem> validate(Schema schema, Object? value) {
  final List<Problem> out = <Problem>[];
  _check(schema, value, '', out);
  return out;
}

String _join(String path, String key) => path.isEmpty ? key : '$path.$key';

String _describe(Object? v) => switch (v) {
  null => 'null',
  bool() => 'a boolean',
  int() => 'an integer',
  double() => 'a number',
  String() => 'a string',
  List<Object?>() => 'a list',
  Map<Object?, Object?>() => 'an object',
  _ => 'something else',
};

void _check(Schema s, Object? v, String path, List<Problem> out) {
  switch (s) {
    case SString():
      if (v is! String) {
        out.add(Problem(path, 'expected a string, found ${_describe(v)}'));
        return;
      }
      if (v.length < s.minLength || v.length > s.maxLength) {
        out.add(Problem(path, 'length ${v.length} is outside ${s.minLength} to ${s.maxLength}'));
      }
      if (v.codeUnits.any((int c) => c < 0x20 || c == 0x7f)) {
        out.add(Problem(path, 'contains a control character'));
      }
      final String? p = s.pattern;
      if (p != null && !RegExp('^(?:$p)\$').hasMatch(v)) {
        out.add(Problem(path, 'does not match the pattern $p'));
      }
    case SInt():
      if (v is! int) {
        out.add(Problem(path, 'expected an integer, found ${_describe(v)}'));
      } else if (v < s.min || v > s.max) {
        out.add(Problem(path, '$v is outside ${s.min} to ${s.max}'));
      }
    case SNum():
      if (v is! num) {
        out.add(Problem(path, 'expected a number, found ${_describe(v)}'));
      } else if (v.isNaN || v < s.min || v > s.max) {
        out.add(Problem(path, '$v is outside ${s.min} to ${s.max}'));
      }
    case SBool():
      if (v is! bool) out.add(Problem(path, 'expected true or false, found ${_describe(v)}'));
    case SEnum():
      if (v is! String || !s.values.contains(v)) {
        out.add(Problem(path, 'must be one of ${s.values.join(', ')}'));
      }
    case SConst():
      if (v != s.value) out.add(Problem(path, 'must be "${s.value}"'));
    case SArray():
      if (v is! List<Object?>) {
        out.add(Problem(path, 'expected a list, found ${_describe(v)}'));
        return;
      }
      if (v.length < s.minItems || v.length > s.maxItems) {
        out.add(Problem(path, '${v.length} items is outside ${s.minItems} to ${s.maxItems}'));
      }
      final Set<Object?> seen = <Object?>{};
      for (int i = 0; i < v.length; i++) {
        _check(s.items, v[i], '$path[$i]', out);
        final String? key = s.uniqueKey;
        final Object? item = v[i];
        if (key != null && item is Map<Object?, Object?> && !seen.add(item[key])) {
          out.add(Problem('$path[$i].$key', 'is used twice'));
        }
      }
    case SObject():
      if (v is! Map<Object?, Object?>) {
        out.add(Problem(path, 'expected an object, found ${_describe(v)}'));
        return;
      }
      for (final Object? k in v.keys) {
        if (k is! String || !s.fields.containsKey(k)) out.add(Problem(path, 'unknown field "$k"'));
      }
      s.fields.forEach((String name, SField f) {
        if (!v.containsKey(name)) {
          if (f.required) out.add(Problem(path, 'missing "$name"'));
        } else {
          _check(f.schema, v[name], _join(path, name), out);
        }
      });
  }
}

// ---- JSON Schema export (draft 2020-12), for authors' editors ----

Map<String, Object?> toJsonSchema(Schema s, {String? id, String? title}) {
  final Map<String, Object?> body = _export(s);
  return <String, Object?>{
    r'$schema': 'https://json-schema.org/draft/2020-12/schema',
    r'$id': ?id,
    'title': ?title,
    ...body,
  };
}

Map<String, Object?> _export(Schema s) {
  final Map<String, Object?> out = switch (s) {
    SString() => <String, Object?>{
      'type': 'string',
      'minLength': s.minLength,
      'maxLength': s.maxLength,
      'pattern': ?(s.pattern == null ? null : '^(?:${s.pattern})\$'),
    },
    SInt() => <String, Object?>{'type': 'integer', 'minimum': s.min, 'maximum': s.max},
    SNum() => <String, Object?>{'type': 'number', 'minimum': s.min, 'maximum': s.max},
    SBool() => <String, Object?>{'type': 'boolean'},
    SEnum() => <String, Object?>{'type': 'string', 'enum': s.values},
    SConst() => <String, Object?>{'const': s.value},
    SArray() => <String, Object?>{
      'type': 'array',
      'items': _export(s.items),
      'minItems': s.minItems,
      'maxItems': s.maxItems,
    },
    SObject() => <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        for (final MapEntry<String, SField> e in s.fields.entries) e.key: _export(e.value.schema),
      },
      'required': <String>[
        for (final MapEntry<String, SField> e in s.fields.entries)
          if (e.value.required) e.key,
      ],
      'additionalProperties': false,
    },
  };
  if (s.doc != null) out['description'] = s.doc;
  return out;
}
