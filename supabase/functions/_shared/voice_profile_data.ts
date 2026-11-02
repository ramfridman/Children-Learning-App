// Generated from content/voices.json by voice_profile_gen.ts. Do not edit by hand: change voices.json and run the
// generator (the command is at the top of voice_profile_gen.ts); voice_profile_test.ts fails when they differ.
// deno-fmt-ignore-file

export const VOICE_PROFILE = {
  "id": "mp3_44100_64.eleven_v4_turbo.530f135ea53a",
  "modelId": "eleven_v4_turbo",
  "outputFormat": "mp3_44100_64",
  "settings": {
    "stability": 0.5,
    "similarity_boost": 0.8,
    "use_speaker_boost": true
  },
  "styles": {
    "cheer": {
      "stability": 0.35
    },
    "ceremony": {
      "stability": 0.45
    },
    "thinking": {
      "stability": 0.55
    },
    "ask": {
      "stability": 0.6
    },
    "hint": {
      "stability": 0.65
    },
    "hint3": {
      "stability": 0.7
    }
  },
  "styleRules": {
    "cheer": [
      "vo:core.celebrate.",
      "vo:celebrate."
    ],
    "ceremony": [
      "vo:core.ceremony."
    ],
    "thinking": [
      "vo:core.thinking."
    ],
    "hint3": [
      "*.h3"
    ],
    "hint": [
      "*.h1",
      "*.h2",
      "vo:hint."
    ],
    "ask": [
      "*.prompt",
      "vo:fb.",
      "vo:core.listen.",
      "vo:core.stuck.",
      "vo:core.breathe.",
      "vo:core.encourage.almost",
      "vo:core.encourage.mistake",
      "vo:core.encourage.help",
      "vo:core.encourage.check",
      "vo:core.encourage.ways"
    ]
  },
  "pronunciation": {
    "שְׁתַּיִם": "שתַּיִם",
    "שתיים": "שתַּיִם"
  }
} as const;
