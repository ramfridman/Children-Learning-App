# Speech recognition for the Languages category (research, 2026-11-03)

**Status:** research for the owner's decision 1 (CHANGED) in `decisions-2026-11-03.md`: an on-device recogniser for English and Russian, per-word feedback, a confident or an unsure result, never "wrong", nothing sent or stored. This file also covers a reading check for the Hebrew course. No code was changed. Nothing here is approved: a model, a package or a host needs the owner's OK (CLAUDE.md rule 9).

**How to read the numbers.** "Verified" means I read it on the cited page on 2026-11-03. "Estimate" is my reasoning, marked as such. "Unknown" is something I could not find. Figures from papers are quoted as printed; none is invented. Sizes in MB are decimal (bytes / 1,000,000).

## 0. What the app has today

- `app/lib/speech/sherpa_engine.dart` runs one model, the ivrit.ai streaming Hebrew Zipformer (`zipformer2-66m-streaming-he`, CC-BY-4.0), with `sherpa_onnx` 2.0.0 and `record` 7.1.2, both already approved and pinned. It decodes the audio **openly** (greedy search, no hotwords), then `answer_matcher.dart` compares the text with the accepted words of the activity (Hebrew text tools, a Hebrew phonetic key).
- **No confidence value reaches the app.** `OnlineRecognizerResult` in the Dart package carries only `text`, `tokens` and `timestamps` (checked in the package source, `online_recognizer_config.dart`). So the engine gives every reading the fixed confidence 0.85 and the decision rests on how well the words match (`docs/milestones/M5.md` §11, "Differences from the plan"). The native library does write more: its JSON result contains `ys_probs`, `lm_probs` and `context_scores` (read in `sherpa-onnx/csrc/online-recognizer.cc` on GitHub master); the Dart wrapper throws them away.
- The model is four files whose size and SHA-256 are written in `app/lib/speech/model_spec.dart`; `tools/make-m5-model.ps1` fetches them at a pinned Hugging Face revision and pushes them to the phone with `adb`. **The app has no downloader yet** and `app/network_hosts.json` lists only the Supabase gateway and three Firebase hosts. PLAN.md says the model will be "mirrored on R2 with a pinned hash" and "hosting packs on R2 comes with M9".
- `tools/run-asr-eval.ps1` and `app/tool/asr_eval.dart` run the model and the matcher over WAV files on the PC (x64 sherpa-onnx v2.0.0 libraries checked against a pinned SHA-256) and print the share of accepted answers that were right, how many were asked to confirm or repeat, and the decision time. Hebrew only. On adults, the Hebrew model plus matcher decided in a median of 87 ms (M5 report). The children's accuracy was never measured (M5 Q6, owner-todo P6).
- Spoken answers already follow the rule this research must keep: only a clear right answer reaches the lesson; everything else is confirmed, asked again, or handed to a tap; "unclear speech is never wrong" (PLAN › When the child speaks).

## 1. Candidate models

### 1.1 What the runtime can do (no new package)

`sherpa_onnx` 2.0.0, already in the app, exposes in Dart (read in the package source in the pub cache):

| Capability | Dart API | Notes |
| --- | --- | --- |
| Streaming transducer | `OnlineRecognizer` + `OnlineTransducerModelConfig` | What the Hebrew engine uses. |
| Streaming CTC | `OnlineZipformer2CtcModelConfig`, `OnlineNemoCtcModelConfig`, `OnlineToneCtcModelConfig` (T-one, Russian) | |
| Non-streaming | `OfflineRecognizer` with transducer, NeMo CTC and transducer, Whisper, Moonshine, Omnilingual, and more | The app decides when the child has finished anyway, so non-streaming is workable: record up to about 5 s, then decode. |
| **Hotwords (contextual biasing)** | `OnlineRecognizerConfig.hotwordsFile/hotwordsScore`, `OnlineModelConfig.modelingUnit/bpeVocab`, and **`createStream(hotwords: ...)` per stream** | Transducer models only, and only with `decodingMethod: modified_beam_search`. The words are tokenised and compiled into an Aho-Corasick automaton; a partial match is boosted and the boost is cancelled if the path fails. A score can follow a colon on each line (`word :3.5`). Source: sherpa-onnx hotwords docs. |
| **Open-vocabulary keyword spotting** | `KeywordSpotter`, `KeywordSpotterConfig(keywordsScore, keywordsThreshold)`, keywords per stream | The decoder is "a tiny ASR system restricted to your keywords, so output is either a given keyword or empty". Per keyword: a boost (`:1.5`) and a trigger threshold from 0 to 1 (`#0.35`), a lower value triggers more easily. The result is the keyword only, with no probability. Source: sherpa-onnx KWS docs. |
| CTC graph decoding | `OnlineCtcFstDecoderConfig(graph, maxActive)` | In the API; the docs do not describe how to build a graph and none of the pages I read uses one. Treat as a research item (see 2.2). |

Not available: a grammar or word-list decoder with a score for "the target word", and a Dart-level confidence. Section 2 works around both.

### 1.2 English

| Model | Size on disk | Licence | Streaming | Constrained decoding | Accuracy known | Children |
| --- | --- | --- | --- | --- | --- | --- |
| **sherpa-onnx-streaming-zipformer-en-20M-2023-02-17** (int8) | 43.6 MB (encoder 42.8, decoder 0.54, joiner 0.26, tokens) + `bpe.model` 0.24 MB for hotwords. The archive is 122 MB because it carries fp32 too | Apache-2.0 (HF card) | Yes | Hotwords: yes in principle (transducer); the sherpa repo ships no `bpe.model`, it is in the icefall source repo `desh2608/icefall-asr-librispeech-pruned-transducer-stateless7-streaming-small` (`data/lang_bpe_500/bpe.model`, 244,865 bytes) | LibriSpeech test-clean 3.94 and test-other 9.79 WER, greedy search; 3.88 and 9.53 with modified beam search (source model card). Trained on LibriSpeech only (sherpa docs) | Unknown |
| sherpa-onnx-streaming-zipformer-en-2023-06-26 (int8, chunk-16-left-128) | about 73 MB (encoder 71.1, decoder 1.3, joiner 0.26, tokens, `bpe.model`) | Apache-2.0 (HF tag) | Yes | Same as above, `bpe.model` is in the repo | WER not stated on the sherpa page; LibriSpeech-trained | Unknown |
| **sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01** (keyword spotter) | about 6 to 7 MB for the int8 encoder (4.6) plus the decoder (1.1) and joiner (0.6) the docs list; the archive is 16.8 MB (14.9 MB "mobile") | **Not stated** on the sherpa page | Yes | **Yes, built for it**: any keyword list, a threshold per keyword | About 3.3M parameters. Trained on GigaSpeech XL (10,000 h). The icefall recipe tested on adult commands against about 40 h of GigaSpeech negatives: original model missed 43 of 307 (86% recall) with 1 false alarm (0.025 per hour); a version fine-tuned on the commands missed 4 of 307 (98.7%) but had 24 false alarms (0.6 per hour). Same pattern on 3,994 commands. This tells how the threshold trades misses for false alarms, not how it does on children | Unknown |
| NeMo streaming FastConformer CTC en, 480 ms (int8) | 125.9 MB file (archive 97.9 MB) | Not checked | Yes | No hotwords (CTC) | Not checked | Unknown |
| Moonshine tiny en, v2 quantized (2026-02-27) | archive 28.5 MB (v1 tiny int8 archive 102.6 MB) | MIT by default for the models, per the upstream README; an exception for legacy non-English models | The sherpa page offers a streaming path for v2; I could not confirm details | No | No figures found | Not mentioned |
| Whisper tiny / base (multilingual) | archives 110.8 / 197.9 MB | MIT (OpenAI) | No (30 s window) | Prompt only; sherpa does not expose it | See 1.5 | See 1.5 |
| Parakeet TDT 0.6B v3 (int8) | archive 464.6 MB | CC-BY-4.0 | No | Not verified for NeMo transducers in sherpa | FLEURS WER: English 4.85, Russian 5.51; leaderboard mean 6.34; noise rises it to 7.12 (SNR 10 dB), 11.66 (0 dB), 19.88 (-5 dB). 600 M parameters. English and Russian are two of its 25 languages; **no Hebrew** | Not addressed on the card. The family of larger NeMo models did best in the children's benchmark below |

### 1.3 Russian

| Model | Size on disk | Licence | Streaming | Constrained decoding | Accuracy known | Children |
| --- | --- | --- | --- | --- | --- | --- |
| **sherpa-onnx-streaming-zipformer-small-ru-vosk-int8-2025-08-16** (from `alphacep/vosk-model-small-streaming-ru`) | **28.8 MB** (encoder.int8 26.2, decoder 2.1, joiner.int8 0.26, `bpe.model` 0.25, tokens) | Apache-2.0 on the upstream card; the sherpa repo's card states none | Yes | Hotwords: yes in principle, `bpe.model` is shipped | Common Voice ru test 11.3 WER (self-reported, upstream card). In the T-one table: call-centre 15.53, named entities 17.65, Common Voice 19 11.3 | Unknown |
| sherpa-onnx-zipformer-ru-int8-2025-04-20 (from `alphacep/vosk-model-ru`, v0.54) | 73.5 MB (encoder.int8 70.9) | Apache-2.0 upstream | **No** (offline) | Hotwords: offline transducers support them | Common Voice ru 6.1 WER (self-reported); 6.22 in the T-one table (65M parameters); call-centre 11.28 | Unknown |
| GigaAM v2 / v3 CTC or transducer (`sherpa-onnx-nemo-ctc-giga-am-v3-russian-2025-12-16`, and others) | archives 155.7 to 164.4 MB | MIT | No (the repo does not mention streaming) | CTC: no hotwords. The transducer variants: not verified | v2 transducer: Common Voice 2.68 WER, v2 CTC 3.14 (T-one table). Parameters about 242 M (v2). v3 is "about 30% better" on new internal domains and equal on public benchmarks (GigaAM README) | The README mentions "speech with atypical characteristics" in v3 training and nothing on children |
| T-one (`sherpa-onnx-streaming-t-one-russian-2025-09-08`) | 144 MB model file (precision not stated), archive 122 MB | Apache-2.0 | Yes (300 ms chunks) | No (CTC) | Common Voice 19 5.32; call-centre 8.63. 71.7 M parameters; trained on 80,000 h, mostly telephony, "primarily intended for use with telephone-channel audio" | Not mentioned |
| Parakeet TDT 0.6B v3 | see 1.2 | CC-BY-4.0 | No | | Russian 5.51 on FLEURS | |
| Omnilingual ASR 300M CTC (int8) | archive 279 MB | Apache-2.0 (upstream) | No | No (CTC) | The README says the 7B LLM system has CER below 10 for 78% of 1,600+ languages; I could not read a per-language number for Russian, Hebrew or English | Unknown |

### 1.4 Hebrew reading check

| Model | Size | Licence | Streaming | Constrained decoding | Accuracy known | Children |
| --- | --- | --- | --- | --- | --- | --- |
| **ivrit.ai zipformer2-66m-streaming-he** (in the app) | 72.3 MB (four files, pinned) | CC-BY-4.0 (base model Apache-2.0; the training audio has its own licence) | Yes, 1.28 s chunks | The repo has `bpe.model` (262,382 bytes at the pinned revision) so hotwords are possible after exporting a `bpe.vocab`; the card does not mention hotwords | WER 5.1 (eval-d1) and 8.9 (eval-whatsapp); the int8 export 5.3 and 8.8; fine-tuned from icefall's English streaming Zipformer on about 20,000 h pseudo-labelled Hebrew | Not mentioned on the card. `docs/tech.md` §8.3: no public Hebrew child audio exists (CHILDES Hebrew BSF audio is "no longer available") |
| Whisper tiny/base multilingual | 110.8 / 197.9 MB archives | MIT | No | No | Not quantified here | See 1.5 |

There is no smaller or better-suited Hebrew model in the sherpa-onnx release list (I searched the `asr-models` release for Hebrew; only Whisper, Omnilingual and ivrit.ai cover it). Parakeet v3 does not cover Hebrew.

### 1.5 What is known about children's speech

All of it is about English, or about no language in particular. For Russian and Hebrew children I found nothing usable.

- **Learning Agency review** ("Closing the child speech recognition gap"; it cites Shivakumar et al. 2020 and Kathania et al. 2022 for the age figures): word error rates of about 5% for adults, 11 to 18% for children overall, 15 to 21% for ages 6 to 10, and up to 35% for kindergarteners (4 to 6). These are open dictation, not a choice among a few words.
- **Fan, Balaji Shankar and Alwan, "Benchmarking Children's ASR with Supervised and Self-supervised Speech Foundation Models"** (arXiv 2406.10507, Interspeech 2024). Zero-shot WER, MyST (school grades 3 to 5, conversation) and OGI (kindergarten to grade 10, read speech), test sets: Whisper-small (242M) 13.4 and 25.4; Whisper-medium 13.1 and 20.8; Whisper-large-v3 12.6 and 19.9; Canary (1.0B) 9.5 and 18.2; Parakeet-rnnt (1.1B) 11.1 and 16.7. So the large NeMo models beat Whisper on children, and every model is about twice as bad (or worse) on the OGI set, which includes the youngest children, than on MyST. The paper gives grades, not ages, and no model small enough for a phone.
- **Sundar, Lehman and Singh, "Keyword Spotting in Multi-Player Voice Driven Games for Children"** (Interspeech 2015): standard keyword spotters that work for adults "fail to perform well even in a basic two-word vocabulary" with children, who interrupt, shout, stretch and repeat words. A warning for section 2.1, not a number.
- **Whisper hallucinations** (Koenecke et al., "Careless Whisper", arXiv 2402.08021): about 1% of transcriptions contain whole phrases that are not in the audio. A hallucinated "praise" for silence is the exact failure this feature must not have. This is why no Whisper model is recommended below.
- Public sets that could help an evaluation (section 2.3): MyST (CC BY-NC-SA 4.0 for non-commercial use, per the search result; also through LDC and Boulder Learning); speechocean762 (OpenSLR 101, CC BY 4.0; half the speakers are children, all non-native speakers of English with a Mandarin mother tongue; the ages are not on the page); for Russian, the Lyakso lab's EmoChildRu (ages 3 to 7, 100 children, about 30 h) and CHILDRU (ages 4 to 7, 150 children), whose access terms I could not find; the Nexdata 163 h Russian children's set is commercial.

## 2. The approach for per-word checks

### 2.1 Constrained recognition and "confident" or "unsure"

The question is never "what did the child say". It is "did the child say the target word W (or one of its accepted forms) rather than one of the other words on screen". The activity knows W, the options and the accepted variants, so the recogniser should only have to tell a few things apart.

Three ways to get there with the runtime already in the app; the evaluation chooses between them, per language.

1. **Open decode, then match** (what Hebrew does now). No extra machinery, works with every model above, but there is no confidence and the language model may turn an unusual word into a frequent one.
2. **Biased decode, then match.** Create the stream with `createStream(hotwords: ...)` listing W and its accepted forms, and the distractors too (all with the same boost, so the bias does not favour the answer). Needs `modified_beam_search` and the BPE vocabulary of the model. Biasing raises the chance that W is output when it was said unclearly, and also the chance that W is output when it was not said: the second is the harmful error here (a false "confident"), so the decision must be **relative**: W's match must beat the best distractor by a margin, never "W appeared".
3. **Keyword spotting (English only).** `KeywordSpotter` with W and the distractors as keywords; threshold per keyword. The result is binary, so for "confident" and "unsure" run two thresholds on the same audio (for example a strict one for "confident", a loose one for "heard something like it"); the 3.3M model is small enough for two streams. There is no Russian or Hebrew spotter in the release list.

**Where "confident" comes from.** The Dart result has no probability, so the rule is built from what is there:
- the match score of the text against W's accept list (phonetic key, as the Hebrew matcher does) and its margin over the best distractor;
- agreement between two readings (open decode and biased decode give the same word);
- for the spotter, which threshold fired;
- **a real token probability**, if obtained. The native `ys_probs` and `context_scores` exist in the JSON the library produces. To read them the app needs a change in the Dart wrapper, in one of three ways: a patch upstream (the project is active), a call to the binding in `package:sherpa_onnx/src/...` (an implementation import, brittle), or a fork. Whether the shipped 2.0.0 native library fills `ys_probs` under `modified_beam_search` is **unverified**; it is a half-day spike. A fork or a patched package needs the owner's OK under rule 9.

Rule (proposal, thresholds from the evaluation, not guessed): **confident** only if the target form is matched with a score at or above a threshold and ahead of every distractor by a margin, and (when available) its token probabilities are above a floor. **Unsure** otherwise. **Silence** when the voice detector never saw speech (the existing energy gate, or the Silero VAD that sherpa ships).

Per-language details the matcher needs (`answer_matcher.dart` and `hebrew_text.dart` are Hebrew-specific today):
- **English:** Hebrew-accented English is the expected input (th/s, w/v, r, short/long vowels). The English teacher supplies, per target word, the accepted spellings the model may output and the minimal-pair distractors that are allowed. Pseudo-words ("zat") and single phonemes are out of scope: models are not trained on them and decision 1 says per word, not per sound. The 20M model's tokens are upper-case BPE pieces (LibriSpeech), so hotwords go in upper case.
- **Russian:** normalise ё to е, drop stress marks, lower-case; the model writes spelling, not sound, so reduced vowels (молоко) cost nothing; the teacher lists inflected forms. Heritage-speaker accents are an open risk.
- **Hebrew:** the model outputs unpointed text. Words that differ only by niqqud (homographs such as סֵפֶר and סִפֵּר) cannot be told apart, so the curriculum must not use them as target and distractor. A syllable alone (בָּ) is not a word: syllables stay unscored (decision 22), as does the child's own name (decision 10: never put it in a hotword list; only detect that the child spoke).

### 2.2 Making a false "wrong" impossible

By construction, in four layers:

1. **No such value.** The result type for a language word check has three members, `confident`, `unsure`, `silence`. There is no `wrong` to return, and a source-rule test (like `source_rules_m4_test.dart`) fails if one is added or if the language speech code references the wrong/correct vocabulary of the tap path.
2. **No negative evidence.** An `unsure` or `silence` result writes no score, lowers no mastery, adds no misconception tag and counts as no attempt for the "struggling" detectors. `confident` may add positive evidence ("said it"), never more than a tap does. Speaking skills show to the parent as "practised" (as the English and Russian syllabi already say), with confident counts only as an extra, worded by the hebrew-text-editor so it never reads as a failure rate.
3. **The same kind reply for every unsure cause.** A clear distractor, a mumble, noise, an accent the model missed all get "let's say it together" and a model of the word; the child is never told what the recogniser heard. After two unsure results the item continues by tap (the existing repair rule, PLAN › When the child speaks 5). The mic is never taken away from the child (owner, 2026-10-27).
4. **Tests that prove it.** Extend the 20,000 random nonsense strings and 300 random listening sequences of M5 to the new matcher: nothing is `confident` except the target forms; a distractor said clearly is never `confident` for the target; silence and noise never `confident`; the tutor's own audio fed back into the engine is never `confident`.

The opposite error, a false "confident" (praise for a word not said, or an unsure child praised for a distractor), is the one that can mislead a child about a language. It is held down by the relative decision and measured in section 2.3. Praise lines for `confident` should say "I heard you" in kind words and never "perfect" or "you said it right".

### 2.3 Evaluating on child-like speech before shipping

Reuse `tools/run-asr-eval.ps1` and `app/tool/asr_eval.dart`. They already: verify the model hashes, read 16-bit PCM WAV of any rate, feed the audio in 100 ms pieces and add silence as the engine does, run the matcher, and print per-speaker results and timing. Changes needed (for the developer, later):

- a language flag and a model spec per language (today `SpeechModel` is the Hebrew model; the script `make-m5-model.ps1` has its hashes written in);
- a language normaliser and phonetic key in the matcher (2.1);
- `--mode open|hotwords|kws`, and a threshold sweep that writes the table of false-confident rate against confident rate, so a threshold is chosen from data;
- a `speakers.csv` (speaker, age) so results are reported per age band (A 3 to 4, B 5 to 6, C 7 to 8);
- a negatives set in the same `labels.csv`: the child saying a distractor, another word, mumbling, silence, room noise, a sibling talking, and the tutor's voice played back through the phone speaker.

**Data.** The model-and-matcher machinery can be measured on adults and public sets; the claim for children needs children.

1. The owner's two children, with a parent present and the separate recording consent that `docs/curriculum.md` already requires: 30 to 60 words per language (the words of the first lessons and their distractors), each said several times. The recordings stay in a folder on the PC outside the repository, are never uploaded, and are never sent to a cloud service for labelling (the tool has no network code). This is an evaluation set, not product data.
2. Adults reading the same lists (baseline, and a check of the machinery).
3. Public data, to see how far the model is from its best on children: for English MyST (conversation, grades 3 to 5, WER only), speechocean762 (children, non-native; a proxy for accented children); for Russian the Lyakso corpora if the lab grants access. For Hebrew there is nothing public.
4. Adult recordings pitch-shifted upward are a cheap smoke test of the pipeline; they are **not** evidence about children.
5. A ceiling run on the PC with a large model (Parakeet v3 for English and Russian) over the same files tells how much accuracy a small model leaves on the table; it is not shipped.

**What to report** per language and age band: confident rate on the target (recall); false-confident rate on the negatives; unsure rate; median and 90th-percentile decision time on the Samsung. **Proposed gate** (for the owner to confirm): false-confident at most 3% on the negatives, the same 97% bar as M5; recall is reported, not gated, because "unsure" is safe and the mic stays for every child.

**What the evidence can and cannot show.** With zero false-confidents in n negatives the 95% upper bound is about 3/n (the "rule of three"), so showing "at most 3%" takes at least 100 negative utterances per age band. Two children cannot fill three age bands, and they are not "any child" (README, decision 2). The result will therefore say "measured on two children"; a later, larger, consented set (owner-todo P6) is the way to widen it.

## 3. What it costs the app

### 3.1 Download size and when models load

| Language | Recommended first choice | Download | If the first choice fails the gate |
| --- | --- | --- | --- |
| Hebrew | ivrit.ai model (already pinned) + `bpe.vocab` for hotwords | 72.3 MB (+ about 0.3 MB) | none planned |
| English | zipformer-en-20M int8 + `bpe.model` | 43.9 MB | 2023-06-26 model about 73 MB; the 3.3M spotter, about 6 to 7 MB, can be added beside it |
| Russian | Vosk small streaming ru int8 | 28.8 MB | Vosk ru 0.54 offline, 73.5 MB |
| All three on | | **about 145 MB** | about 220 MB with the second choices |

- The native libraries are already in the build (about 27 MB for arm64, M5 report). The runtime is the same for all three languages, so **no new package** is needed. Spotter and hotwords are inside `sherpa_onnx` 2.0.0.
- Models are **not bundled** in the app. A language's model is downloaded only after a parent has turned voice on for that language, on the same switch pattern as Hebrew voice, and deleted when the parent turns it off. A language that is off costs no disk, no memory and no network.
- Only the recogniser of the language being practised is loaded; it is freed when the child leaves that language or the mic has been idle for a short time. The load runs off the main isolate (M5 left this open: the Hebrew model still loads on the main isolate and blocks for "about a second or two", unmeasured).

### 3.2 Memory and speed

- **Not measured for any of these on a phone.** The M5 report says so for the 72 MB Hebrew model ("more in memory", no low-end phone to prove it).
- **Estimate:** the resident size of an int8 model in onnxruntime is about its file size plus working buffers, so roughly 1.5 to 2.5 times the file size while loaded (my reasoning, not a source). That is about 100 MB for the 44 MB English model and 65 MB for Russian small, with one model loaded at a time.
- To measure: `adb shell dumpsys meminfo app.nitznutz.nitznutz.dev` before, during and after a listen, on the Samsung, for each model; and the time to load and to decode a 2 s clip. The PC number for Hebrew is a median 87 ms after the end of the audio (M5 report); the others are unknown. The streaming Hebrew model decodes in 1.28 s chunks, and the engine pads 1.5 s of silence to read the last word; the other streaming models have their own chunk sizes, to be read from their configs.
- Biased decoding uses `modified_beam_search`, which costs more CPU per frame than greedy search (estimate: small for models of this size; measure it).

### 3.3 Network hosts (rule 9)

- The app may only talk to hosts in `app/network_hosts.json`, and a test fails on any URL literal in `lib/`. Today none of them serves model files.
- **Do not download from Hugging Face or GitHub inside the app.** Those are mutable third-party hosts, an extra vendor that would see the child's device address, and they have been the source of the pinned scripts only. Follow PLAN: **mirror the files on the project's own R2 bucket** and add one host entry (for example `models-r2`, `https`, roles `parent` and `child`, because the child's device downloads for itself after a parent switched voice on). That entry, the bucket and its public domain are the infrastructure-engineer's work and the owner's decision, together with the M9 R2 hosting that PLAN already announces. Until then the existing route (a PowerShell script and `adb push`) works for the owner's phones, exactly as for Hebrew.
- The development scripts on the owner's PC fetch from Hugging Face and GitHub (as `make-m5-model.ps1` does); the test covers `lib/`, not `tools/`.

### 3.4 Security notes

1. **A model file is data parsed by native code.** A damaged or swapped ONNX file could crash the parser or worse. Every file of every model gets its size and SHA-256 written in the app (the `model_spec.dart` pattern), is hashed before load, and is deleted if it differs. Download to a temporary name and rename only after the check; follow no redirect to another host; HTTPS only.
2. **Provenance and pinning.** Pin the source revision of each file (as the ivrit.ai script pins `ee769a2a…`), mirror the exact bytes on R2, and keep the licence text and the credit lines with them. The credits screen gains the model credits: CC-BY-4.0 needs attribution (ivrit.ai, and Parakeet if used); Apache-2.0 and MIT need their notices. One card (the sherpa Russian conversion) states no licence; the upstream Vosk card says Apache-2.0, which should be quoted in the credits and confirmed by the security-engineer before release. The English spotter's licence is **not stated**; do not ship it before it is found.
3. **Untrusted text.** What the recogniser returns is data from a model: it is compared, never shown, logged, stored or sent. Only the fixed outcome word (`confident`, `unsure`, `silence`) and the kind of answer may be stored, like the existing `voice_listens` row. The log scrubber should reject recogniser text.
4. **Hotword strings come from signed content only** (target, accepted forms, distractors), never from a child, a name or a tutor reply. The hotword file format uses `:` for a score, `#` and `@` in the spotter, and newlines between entries, so the pack validator must refuse those characters in a `speech` word; otherwise a content mistake could change a boost.
5. **Mic rules unchanged:** opens only on a tap, only for a language whose voice a parent turned on, audio held in memory only while the child speaks and dropped, no file, no network in the speech code (`source_rules_m4_test.dart` keeps checking). No cloud recogniser is ever added as a fallback; no child audio goes anywhere, including for labelling the evaluation set.
6. **Personal questions in scripted lessons** (decision 10): the answer is handled on the device. The speech engine hears it only to know that the child spoke; its text is never matched, kept or used to profile.
7. **iOS:** the same pinned files, in a folder excluded from backups, as the Android `no_backup` folder; sherpa-onnx on iOS has not been tried in this repository (the engine code is shared and "checked on iOS at that gate", M5 §10).
8. **A new package or a fork needs the owner's OK** (rule 9). The recommendation below needs none, except that reading the real confidence (2.1) may need a fork or an upstream patch of `sherpa_onnx`.

## 4. Recommendation per language

**Common.** Build the same small engine for all three: a per-language model spec (files, hashes, source, licence), a per-language normaliser and phonetic key, the three-valued result, and the evaluation changes in 2.3. Start with a **half-day spike** on a PC with `run-asr-eval`: (a) does `ys_probs` come out under `modified_beam_search`, (b) open decode against biased decode on adult recordings, (c) the spotter's threshold curve. Then record the children.

### English
- **First choice:** `streaming-zipformer-en-20M` int8 (43.9 MB, Apache-2.0), biased decode with the target and distractors, relative decision; compare with the **3.3M keyword spotter** (about 6 to 7 MB) on the same recordings. If the spotter's licence turns out to be fine and it wins on false-confident, it may be all English needs.
- **If it fails the gate:** the 2023-06-26 zipformer (about 73 MB). Not Whisper (offline, 111 to 198 MB for the small sizes, hallucination risk). Parakeet v3 (465 MB) is a PC ceiling, not a phone model.
- **Risks:** both streaming models learned from LibriSpeech or GigaSpeech, adult native speakers reading; children, Hebrew-accented English and isolated words are all far from that. Child speech errors up to 35% at 4 to 6 (open dictation). Phonics items (letter sounds, pseudo-words) cannot be checked and must stay unscored. 3 to 4 year olds will probably get many "unsure"; the design makes that harmless, and the tutoring words matter more than the model.

### Russian
- **First choice:** the Vosk small streaming model (28.8 MB, Apache-2.0 upstream). It is the smallest, and the only streaming Russian transducer (so the only streaming one that can take hotwords) in the release list, but its Common Voice WER (11.3) is nearly twice the larger Vosk model's (6.1) and several times GigaAM's (2.68), so it is the one most likely to miss a child.
- **If it fails:** Vosk ru 0.54 offline (73.5 MB); GigaAM v3 (about 156 MB, MIT, the most accurate on adults, CTC so no hotwords) as the quality ceiling or a heavy option for a tablet. T-one is trained on telephone audio and is not recommended for children's voices (reasoning, no evidence either way).
- **Risks:** no Russian child data that I can reach (the Lyakso corpora need a request); heritage-speaker accents; spelling normalisation (ё, stress marks, inflected forms) must be right, which is the Russian teacher's list to write; the 2.3 evidence will be two children at most.

### Hebrew reading check
- **Keep the ivrit.ai model** (nothing new to download beyond a `bpe.vocab`, if hotwords help), at **word level only**. Syllables and letters stay unscored (decision 22), pseudo-words are out, homograph pairs must not be used as target and distractor. The optional parent check in the parent area stays as the human fallback.
- **Risks:** WER 5.1 and 8.9 are adult figures on adult sets; the children's accuracy of this model has never been measured (M5 Q6, P6) and Hebrew has no public child audio. Reading aloud adds slow, stumbling and sounded-out speech ("ke-lev"), which a model trained on fluent adults will treat as noise; that is likely the weakest of the three, so the reading check should be built last and gated on the owner's own recordings.

### Needs the owner (summary)
1. The model choice per language, once the spike has numbers (a model is approved in principle by decision 1; each file set is a new pinned artefact).
2. A host for the model files (R2 entry in `network_hosts.json`), or keep `adb push` for his phones until M9.
3. The recordings of his two children, with the consent steps, and where the files may live.
4. OK for a fork or patch of `sherpa_onnx` only if reading the real confidence proves worth it.

## Sources

Checked on 2026-11-03.
- sherpa-onnx pretrained models and the `asr-models` and `kws-models` releases: https://k2-fsa.github.io/sherpa/onnx/pretrained_models/index.html, https://github.com/k2-fsa/sherpa-onnx/releases/tag/asr-models, https://github.com/k2-fsa/sherpa-onnx/releases/tag/kws-models
- Hotwords: https://k2-fsa.github.io/sherpa/onnx/hotwords/index.html. Keyword spotting: https://k2-fsa.github.io/sherpa/onnx/kws/index.html and https://k2-fsa.github.io/sherpa/onnx/kws/pretrained_models/index.html. KWS results: https://raw.githubusercontent.com/k2-fsa/icefall/master/egs/gigaspeech/KWS/RESULTS.md
- Native result JSON: https://raw.githubusercontent.com/k2-fsa/sherpa-onnx/master/sherpa-onnx/csrc/online-recognizer.cc. Dart API: `sherpa_onnx` 2.0.0 source in the pub cache.
- Model cards: https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17, https://huggingface.co/desh2608/icefall-asr-librispeech-pruned-transducer-stateless7-streaming-small, https://huggingface.co/alphacep/vosk-model-small-streaming-ru, https://huggingface.co/alphacep/vosk-model-ru, https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-small-ru-vosk-int8-2025-08-16, https://huggingface.co/csukuangfj/sherpa-onnx-zipformer-ru-int8-2025-04-20, https://huggingface.co/ivrit-ai/zipformer2-66m-streaming-he, https://huggingface.co/t-tech/T-one, https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3
- Vosk model list: https://alphacephei.com/vosk/models. GigaAM: https://github.com/salute-developers/GigaAM. Omnilingual ASR: https://github.com/facebookresearch/omnilingual-asr. Moonshine: https://github.com/moonshine-ai/moonshine and https://k2-fsa.github.io/sherpa/onnx/moonshine/index.html
- Children: Fan, Balaji Shankar, Alwan (2024), https://arxiv.org/abs/2406.10507 (Table 2 read at https://arxiv.org/html/2406.10507v1); Learning Agency, https://the-learning-agency.com/guides-resources/closing-the-child-speech-recognition-gap-evidence-limitations-and-paths-forward/; Sundar, Lehman, Singh (2015), https://la.disneyresearch.com/publication/keyword-spotting-in-multi-player-voice-driven-games-for-children/; Koenecke et al. (2024), https://arxiv.org/abs/2402.08021
- Datasets: speechocean762, https://www.openslr.org/101/; MyST, https://arxiv.org/abs/2309.13347 (licence from a search result, to confirm at myst.cemantix.org); Russian child corpora (EmoChildRu, CHILDRU) from the search result https://pureportal.spbu.ru/en/publications/emochildru-emotional-child-russian-speech-corpus(067b6581-b62a-419e-bebf-f7ee05c42d25)

**Not found or not checked:** the licence of the English keyword-spotter model; per-language CER of Omnilingual ASR; Moonshine v2 sizes and WER; the licence and WER of the NeMo streaming English models; whether sherpa-onnx supports hotwords with the NeMo transducers; the access terms of the Russian child corpora and of OGI/CSLU Kids at LDC; the ages in speechocean762; any measurement of any of these models on a phone or on a child.
