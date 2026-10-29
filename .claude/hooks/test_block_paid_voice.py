"""Tests for block_paid_voice.py. Run: python .claude/hooks/test_block_paid_voice.py"""
import json
import os
import subprocess
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import block_paid_voice as h  # noqa: E402

BLOCKED = [
    "dart run tool/voice_gen.dart generate nitzi --confirm-chars 5",
    "dart run tool/voice_gen.dart generate",
    "dart run tool/voice_gen.dart audition nitzi \"שלום.\"",
    "dart run tool/voice_gen.dart audition-batch run ../docs/audio/audition/round1.json",
    "dart run tool/voice_gen.dart audition-batch ../docs/audio/audition/round1.json",
    "dart run tool/voice_gen.dart --repo x generate",
    "cd app && dart run tool/voice_gen.dart generate nitzi",
    "cd app; dart run tool/voice_gen.dart audition-batch run a.json",
    ".\\voice_gen.exe generate nitzi",
    "& .\\voice_gen.exe audition x",
    "git status && dart run tool/voice_gen.dart generate",
    "echo hi | dart run tool/voice_gen.dart generate",
    "cmd /c dart run tool/voice_gen.dart generate",
    "dart run tool/tutor_prewarm.dart --all",
    "dart run tool/tutor_prewarm.dart",
    "supabase functions invoke tutor-prewarm --project-ref ungkvkabqxssggttajfs",
    "curl -X POST https://api.elevenlabs.io/v1/text-to-speech/abc -H xi-api-key:1",
    "Invoke-RestMethod -Uri https://api.elevenlabs.io/v1/voices",
    "curl https://ungkvkabqxssggttajfs.supabase.co/functions/v1/tutor-turn",
    "echo $env:ELEVENLABS_API_KEY",
    "$env:ELEVENLABS_API_KEY = 'x'; dart run tool/voice_gen.dart plan",
    "printenv ELEVENLABS_API_KEY",
    "Write-Output $env:ELEVENLABS_API_KEY",
    "python -c \"import requests; requests.post('https://api.elevenlabs.io/v1/x')\"",
]

ALLOWED = [
    "dart run tool/voice_gen.dart plan",
    "dart run tool/voice_gen.dart plan --characters nitzi --list",
    "dart run tool/voice_gen.dart --repo C:\\x plan",
    "dart run tool/voice_gen.dart audition-batch plan ../docs/audio/audition/round1.json",
    "dart run tool/voice_gen.dart mock nitzi --out C:\\tmp\\mock",
    "dart run tool/voice_gen.dart list",
    "dart compile exe tool/voice_gen.dart -o build/voice_gen.exe",
    "dart analyze tool/voice_gen.dart",
    "dart format tool/voice_gen.dart",
    "git add app/tool/voice_gen.dart && git commit -m \"voice_gen generate needs the owner\"",
    "git diff -- app/tool/voice_gen_lib.dart",
    "grep -rn \"ELEVENLABS_API_KEY\" app/tool",
    "rg elevenlabs_api_key app",
    "cat app/tool/voice_gen.dart",
    "flutter test test/voice_gen_test.dart",
    "flutter analyze",
    "ls docs/audio",
    "gh pr view 2",
    "supabase functions deploy tutor-turn --project-ref ungkvkabqxssggttajfs",
]


class BlockPaidVoice(unittest.TestCase):
    def test_blocked(self):
        for c in BLOCKED:
            self.assertIsNotNone(h.check(c), c)

    def test_allowed(self):
        for c in ALLOWED:
            self.assertIsNone(h.check(c), c)

    def run_hook(self, payload):
        p = subprocess.run([sys.executable, os.path.join(os.path.dirname(__file__), "block_paid_voice.py")],
                           input=payload, capture_output=True, text=True)
        return p

    def test_process_denies_with_exit_2_and_json(self):
        p = self.run_hook(json.dumps({"tool_name": "Bash", "tool_input": {"command": "dart run tool/voice_gen.dart generate"}}))
        self.assertEqual(p.returncode, 2)
        out = json.loads(p.stdout)
        self.assertEqual(out["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_process_allows_free_and_other_tools(self):
        p = self.run_hook(json.dumps({"tool_name": "PowerShell", "tool_input": {"command": "dart run tool/voice_gen.dart plan"}}))
        self.assertEqual(p.returncode, 0)
        self.assertEqual(p.stdout.strip(), "")
        p = self.run_hook(json.dumps({"tool_name": "Read", "tool_input": {"file_path": "x"}}))
        self.assertEqual(p.returncode, 0)

    def test_unreadable_payload_fails_closed(self):
        p = self.run_hook("not json")
        out = json.loads(p.stdout)
        self.assertEqual(out["hookSpecificOutput"]["permissionDecision"], "deny")


if __name__ == "__main__":
    unittest.main()
