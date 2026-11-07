"""What a kind of item becomes: the recipes of the language templates, for tools/lang_pack.py (class `Recipes`, taken by `Course`).

A recipe turns one item of a unit file into one activity document (or, for `say` with a tap, two). The teacher writes what only a
teacher can decide (the picture, the clip, the right answer, the tag each wrong answer shows, the frame line, the ladder); the recipe
holds what is the same for every item of its kind (the file shape, the scoring, the tutor switched off, the voice ids, the layout of a
scene). Kinds: tap, listen_do, puppet, say, chant, drum, story (lang_recipes_talk.py), count, pairs, sort, sequence, trace
(lang_recipes_more.py). The format of each is in docs/languages/band-a-build.md section 2.2. Standard library only.
"""
import re

from lang_recipes_base import (ALT, CHECK_TYPES, DOMAIN, HINT_ACTIONS, PICTURE_LABEL, PLACE_LABELS, PURPOSES, RAIL, RAIL_SIDE, derived_svg,
                               REPRESENTATIONS, SOUND_LABEL, overlap, rect, slug)
from lang_recipes_more import More
from lang_recipes_print import Print
from lang_recipes_talk import Talk


class Recipes(Talk, More, Print):
    """The recipes. `self` is a Course: it reads lines, clips, pictures, tags, ladders and feedback through it."""

    # ------------------------------------------------------------ what every recipe shares
    def _choose(self, item, key, default, allowed, where):
        value = item.get(key, default)
        if value not in allowed:
            self.problem(where, '%s "%s" is not one of %s' % (key, value, ', '.join(allowed)))
        return value

    def head(self, sk, sid, aid, item, where, template, *, version=None, alt=None, goal='listen and choose', attempts=3,
             rep='pictorial', purpose=None, check=None, variant=None, choices=None):
        """The fields every activity has, in the order the pack writes them (prompt, feedback, hints, scene and answer follow)."""
        purpose = purpose or self._choose(item, 'purpose', 'learn', PURPOSES, where)
        check = check or self._choose(item, 'check', 'transfer' if purpose == 'check' else 'practice', CHECK_TYPES, where)
        rep = self._choose(item, 'rep', self.defaults.get('rep', rep) if 'rep' not in item and rep == 'pictorial' else rep,
                           REPRESENTATIONS, where)
        # The word of an item is the clip it plays; one that plays none (a reverse item, which shows the picture) is of the word it names.
        variant = item.get('variant') or variant or slug(item.get('target') or item.get('hintWord') or '%s-%s' % (sk['slug'], item['id']))
        doc = {
            'schema': 'activity/v1',
            'id': aid,
            'review': 'needs-editor',
            'revision': item.get('revision', 1),
            'template': template,
            'templateVersion': version or self.template_versions[template],
            'course': self.id,
            'domain': DOMAIN,
            'band': sk['band'],
            'skills': [{'id': sid, 'weight': 1}],
            'purpose': purpose,
            'checkType': check,
            'representation': rep,
            'variantGroup': variant,
            'difficulty': {'authored': item.get('difficulty', 0.2)},
            # A two-choice item allows one retry only (frame section 2.3).
            'scoring': {'maxAttempts': 2 if choices == 2 else attempts, 'creditByHintLevel': [1, 0.75, 0.5, 0.25]},
            # The AI tutor is off for every language item (frame section 1.6): RuleTutor plays these hints.
            'tutor': {'llmAllowed': False, 'goal': goal, 'mustNotRevealBeforeHint': 2},
            'a11y': {'altText': item.get('alt') or alt or ALT.get(template, 'תְּמוּנָה')},
        }
        if item.get('contradicts'):
            doc['contradicts'] = self.tag(item['contradicts'], sid, where)
        if item.get('font'):
            # The display face (Secular One) for one item, a Hebrew course only: a check of the same letters in another face.
            if item['font'] != 'display' or self.id != 'heb':
                self.problem(where, 'font "%s": only "display" (Secular One), and only in the Hebrew course' % item['font'])
            else:
                doc['font'] = 'display'
        return doc

    def lines_of(self, doc, item, where, tag_ids=(), *, frame=None, target=None, target2=None, show=None, hints=True):
        """Adds the prompt, the feedback and the hints to [doc]; False when a line is missing (the problem is said)."""
        # `target=False` says the prompt has no clip after the frame line (the drum, the count, a sort).
        prompt = self.spoken({'line': frame or item.get('frame') or self.defaults.get('frame'),
                              'target': item.get('target') if target is None else (target or None),
                              'target2': item.get('target2') if target2 is None else (target2 or None),
                              'show': item.get('show', False) if show is None else show}, where + ' prompt', item)
        feedback = self.feedback_of(item, tag_ids, where)
        hint_list = self.hints_of(item, where) if hints else []
        if prompt is None or feedback is None:
            return False
        doc['prompt'] = dict(prompt, replayButton=True)
        doc['feedback'] = feedback
        doc['hints'] = hint_list
        return True

    def feedback_of(self, item, tag_ids, where):
        fb = self.spec.get('feedback', {})
        own = item.get('feedback') or {}
        right = fb.get('right') or []
        if not right or not fb.get('wrong') or not fb.get('unsure'):
            self.problem('course.json', 'feedback needs "right" (a list of lines), "wrong" and "unsure"')
            return None
        # The praise is chosen by the item's place in the course (the same item always says the same line).
        step = own.get('right') or right[(len(self.items) - self.teach_count) % len(right)]
        step = dict({'line': step} if isinstance(step, str) else step)
        after = item.get('after')
        if after:
            after = [after] if isinstance(after, str) else list(after)
            step['target'] = after[0]
            if len(after) > 1:
                step['target2'] = after[1]
        correct = self.spoken(step, where + ' feedback.correct', item)
        by_tag = dict(fb.get('byTag', {}))
        by_tag.update(own.get('byTag', {}))
        rules = []
        for tag_id in tag_ids:
            slug_ = next((k for k, v in self.tags.items() if v.get('id') == tag_id), None)
            line_step = by_tag.get(slug_)
            if line_step and not any(r['when'] == 'misconception:' + tag_id for r in rules):
                line = self.spoken(line_step, '%s feedback.%s' % (where, slug_), item)
                if line:
                    rules.append(dict([('when', 'misconception:' + tag_id)] + list(line.items())))
        default = self.spoken(own.get('wrong') or fb['wrong'], where + ' feedback.wrong', item)
        if default:
            rules.append(dict([('when', 'default')] + list(default.items())))
        unsure = self.spoken(own.get('unsure') or fb['unsure'], where + ' feedback.unsure', item)
        if correct is None or default is None or unsure is None:
            return None
        return {'correct': correct, 'incorrect': rules, 'unsure': unsure}

    def hints_of(self, item, where):
        name = item.get('ladder', self.defaults.get('ladder'))
        ladder = name if isinstance(name, list) else self.ladders.get(name)
        if not ladder:
            self.problem(where, 'the ladder "%s" is not in course.json "ladders"' % name)
            return []
        hints = []
        for level, step in enumerate(ladder, start=1):
            line = self.spoken(step, '%s hint %d' % (where, level), item)
            action = step.get('action') if isinstance(step, dict) else None
            if action not in HINT_ACTIONS:
                self.problem(where, 'the ladder step %d has action "%s" (one of %s)' % (level, action, ', '.join(HINT_ACTIONS)))
            if line:
                hints.append(dict([('level', level), ('action', action)] + list(line.items())))
        if len(ladder) != 3:
            self.problem(where, 'a ladder has exactly 3 steps')
        return hints

    def tag(self, slug_, sid, where):
        """The tag id of a slug of course.json "tags", noted as used by the skill."""
        tag = self.tags.get(slug_)
        if tag is None:
            self.problem(where, 'the tag "%s" is not in course.json "tags"' % slug_)
            return 'x.x.x'
        self._tags_used.setdefault(slug_, [])
        if sid not in self._tags_used[slug_]:
            self._tags_used[slug_].append(sid)
        return tag.get('id', 'x.x.x')

    def clip(self, clip, where):
        """The `vo:` id of a clip of the pronunciation table, noted as used."""
        self.clip_row(clip, where)
        self.used_clips.add(clip)
        return self.vo(clip)

    def asset(self, picture, where):
        return 'asset:' + self._picture(picture, where)

    # ------------------------------------------------------------ choices (the options of a tap, a bubble, a button, a rhyme)
    def parse_options(self, raw, where):
        """[(aliases, face dict)]: one entry per option. A face has `pic`, `text`, `numeral` or only `clip`, and may carry `clip`,
        `label`, `reveal`. The aliases are the names the item's `right` and `wrong` may use for it."""
        out = []
        for opt in raw:
            face = {'pic': opt} if isinstance(opt, str) else dict(opt)
            if 'pic' in face and isinstance(face['pic'], str) and face['pic'].startswith('text:'):
                face['text'] = face.pop('pic')[5:]
            if 'pic' in face and isinstance(face['pic'], str) and re.match(r'^n:\d+$', face['pic']):
                face['numeral'] = int(face.pop('pic')[2:])
            aliases = []
            if 'pic' in face:
                aliases.append(face['pic'])
            if 'text' in face:
                aliases += ['text:' + face['text'], face['text']]
            if 'numeral' in face:
                aliases += ['n:%d' % face['numeral'], str(face['numeral'])]
            if 'clip' in face:
                aliases += [face['clip'], 'clip:' + face['clip']]
            out.append((aliases, face))
        return out

    def entry_of(self, oid, face, where, *, sid=None, tag=None, default_label=None):
        """The option document of one face."""
        entry = {'id': oid}
        if 'pic' in face:
            entry['sprite'] = self.asset(face['pic'], where)
            label = face.get('label') or default_label or self.defaults.get('pictureLabel') or PICTURE_LABEL
        elif 'text' in face:
            entry['text'] = face['text']
            label = face.get('label') or face['text']
        elif 'numeral' in face:
            entry['numeral'] = face['numeral']
            label = face.get('label') or str(face['numeral'])
        else:
            label = face.get('label') or self.defaults.get('soundLabel') or SOUND_LABEL
        entry['label'] = label
        if 'clip' in face:
            entry['clip'] = self.clip(face['clip'], where)
        if face.get('reveal'):
            entry['reveal'] = face['reveal']
        if tag:
            entry['misconception'] = tag
        return entry

    def choice(self, item, sid, where, *, raw=None, lo=2, hi=3, wrong_key='wrong'):
        """Resolves a choice: ([option documents], correct id or ids, [faces], names), or None (the problem is said).

        Every distractor must carry a tag in `wrong`, keyed by any alias of the option."""
        raw = item.get('options', []) if raw is None else raw
        if not lo <= len(raw) <= hi:
            span = '%d or %d' % (lo, hi) if hi == lo + 1 else '%d to %d' % (lo, hi)
            self.problem(where, 'a Band A item has %s options (it has %d)' % (span, len(raw)))
            return None
        parsed = self.parse_options(raw, where)
        wrong = item.get(wrong_key) or {}
        rights = item.get('letters') or [item.get('right', parsed[0][0][0])]
        if not isinstance(rights, list):
            rights = [rights]
        options, correct, names, used = [], [], [], set()
        for n, (aliases, face) in enumerate(parsed, start=1):
            oid = 'o%d' % n
            names.append(aliases[0])
            is_right = any(r in aliases for r in rights)
            tag = None
            if not is_right:
                hit = next((a for a in aliases if a in wrong), None)
                if hit is None:
                    self.problem(where, 'the distractor "%s" has no tag in "wrong" (every distractor carries the error it reveals)'
                                 % aliases[0])
                else:
                    used.add(hit)
                    tag = self.tag(wrong[hit], sid, where)
            else:
                correct.append(oid)
            options.append(self.entry_of(oid, face, where, tag=tag))
        for r in rights:
            if not any(r in aliases for aliases, _ in parsed):
                self.problem(where, 'the right answer "%s" is not among the options' % r)
        if len({a[0] for a, _ in parsed}) != len(parsed):
            self.problem(where, 'an option is listed twice')
        for key in wrong:
            if key not in used:
                self.problem(where, '"%s" names "%s", which is not a distractor of this item' % (wrong_key, key))
        if not correct:
            return None
        return options, (correct if len(correct) > 1 or item.get('letters') else correct[0]), [f for _, f in parsed], names

    def tag_ids(self, options):
        out = []
        for o in options:
            t = o.get('misconception')
            if t and t not in out:
                out.append(t)
        return out

    def pair_with(self, item, sk):
        ref = item.get('pairWith')
        if not ref:
            return None
        return ref if ref.count('.') >= 2 else '%s.%s.%s' % (self.id, sk['slug'], ref)

    # ------------------------------------------------------------ LS01 tap
    def recipe_tap(self, sk, sid, aid, item, where):
        """LS01 tap (`tap_answer`): the clip is heard, the child touches the picture (or letter, or sound) it names."""
        got = self.choice(item, sid, where, hi=5 if item.get('letters') else 3)
        if got is None:
            return None
        options, correct, faces, names = got
        text_face = any('text' in f for f in faces)
        scene = {}
        stage = item.get('stage')
        if isinstance(stage, dict):  # {"box": "bin-box", "front": "elephant"}: a picture with a thing in front of it
            scene['background'] = self.asset(stage['box'], where)
            scene['group'] = {'sprite': self.asset(stage['front'], where), 'count': 1}
        elif stage:
            scene['group'] = {'sprite': self.asset(stage, where), 'count': 1}
        answer = {'type': 'choice', 'options': options, 'correct': correct, 'shuffle': True, 'unsureAllowed': True}
        if item.get('letters'):
            answer['all'] = True
        if item.get('face') or text_face:
            answer['face'] = item.get('face', 'letter')
        if item.get('pole'):
            answer['pole'] = item['pole']
        pair = self.pair_with(item, sk)
        if pair:
            answer['pairWith'] = pair
        if item.get('letters'):
            count_word = 'כׇּל הָאוֹתִיּוֹת'
            alt_text = count_word
        else:
            alt_text = ALT['tap_answer'][len(options)] if len(options) in ALT['tap_answer'] else ALT['tap_answer'][3]
            if text_face:
                alt_text = {2: 'שְׁתֵּי אֶפְשָׁרֻיּוֹת', 3: 'שָׁלוֹשׁ אֶפְשָׁרֻיּוֹת'}.get(len(options), alt_text)
        doc = self.head(sk, sid, aid, item, where, 'tap_answer', version='1.4' if item.get('letters') else None, alt=alt_text,
                        choices=len(options))
        if not self.lines_of(doc, item, where, self.tag_ids(options)):
            return None
        doc['scene'] = scene
        doc['answer'] = answer
        if doc['checkType'] == 'reverse':
            self.check_reverse(doc, faces, where)
        return doc

    def check_reverse(self, doc, faces, where):
        """A reverse check (band-a-build.md 7.3) shows the picture and the child finds its word among 2 or 3 sound buttons. No line before
        the third hint may play the right word: not the prompt, not the first two hints, not the first-error lines (the ladder `HL-REV` and
        the item's `feedback` see to it). A clip that is not the answer, such as the question "who is this?", may be played."""
        if doc['purpose'] != 'check':
            self.problem(where, 'a reverse item is a check (`"purpose": "check"`)')
        if not doc['scene'].get('group'):
            self.problem(where, 'a reverse item shows the picture of the word it asks for (`stage`)')
        if not all(set(f) <= {'clip', 'label'} and 'clip' in f for f in faces):
            self.problem(where, 'the options of a reverse item are sound buttons only: {"clip": ...}')
        right = {o['clip'] for o in doc['answer']['options'] if o['id'] == doc['answer']['correct'] and 'clip' in o}

        def says_right(line):
            return bool(right & {line.get('target'), line.get('target2')})

        if says_right(doc['prompt']):
            self.problem(where, 'the prompt of a reverse item plays the right word: that is the answer')
        for hint in doc['hints']:
            if hint['level'] < 3 and says_right(hint):
                self.problem(where, 'hint %d of a reverse item plays the right word: only the third hint may say it (ladder HL-REV)' % hint['level'])
        for rule in doc['feedback']['incorrect']:
            if says_right(rule):
                self.problem(where, 'the first-error line of a reverse item plays the right word: it names no option (`feedback.wrong`, `byTag`)')

    # ------------------------------------------------------------ LS11 listen and do
    def recipe_listen_do(self, sk, sid, aid, item, where):
        mode = item.get('mode', 'buttons')
        if mode not in ('buttons', 'hotspots', 'cards', 'drag', 'place', 'embodied'):
            self.problem(where, 'mode "%s" is not buttons, hotspots, cards, drag, place or embodied' % mode)
            return None
        picture = item.get('picture')
        if not picture:
            self.problem(where, 'a listen_do item names the scene `picture`')
            return None
        scene = {'picture': self.asset(picture, where)}
        embodied = mode == 'embodied'
        if embodied:
            doc = self.head(sk, sid, aid, item, where, 'listen_do', rep='embodied', purpose='practice',
                            check='practice', goal='do it yourself')
            clips = (item.get('clips') or [])[:2]
            ok = self.lines_of(doc, item, where, (), target=clips[0] if clips else False,
                               target2=clips[1] if len(clips) > 1 else False, hints=False)
            if not ok:
                return None
            doc.update({'scene': scene, 'answer': {'type': 'none', 'mode': 'embodied'}})
            return doc
        areas = self.areas_of(picture)
        wrong = item.get('wrong') or {}
        right = item.get('right')
        raw = item.get('options') or []
        if mode == 'hotspots' or mode == 'cards':
            item = dict(item, _keys=['%s %s' % (sid, item['id']), '%s.%s.%s' % (self.id, sk['slug'], item['id'])])
            got = self.hot_options(item, sid, where, picture, mode, raw, right, wrong)
            if got:
                mode = got[2]
                got = got[:2]
        elif mode == 'buttons':
            got = self.choice(item, sid, where)
            got = (got[0], got[1]) if got else None
        elif mode == 'drag':
            got = self.drag_options(item, sid, where, raw, right, wrong, scene, picture)
        else:
            got = self.place_options(item, sid, where, picture, raw, right, wrong, scene)
        if got is None:
            return None
        options, correct = got
        doc = self.head(sk, sid, aid, item, where, 'listen_do', rep='embodied', goal='do what is said', choices=len(options))
        if not self.lines_of(doc, item, where, self.tag_ids(options)):
            return None
        doc['scene'] = scene
        doc['answer'] = {'type': 'choice', 'mode': mode, 'options': options, 'correct': correct, 'shuffle': True,
                         'unsureAllowed': True}
        return doc

    def areas_of(self, picture):
        return self.area_table.get(picture, {})

    def areas_for(self, picture, key, where):
        """The rectangles ([x, y, w, h] lists) of a named place of a picture, from the part map or the areas table."""
        table = self.areas_of(picture)
        area = table.get(key) or table.get(key.split('-', 1)[-1])
        if area is None:
            self.problem(where, 'the picture "%s" has no touch area "%s" (content/languages/pictures/scenes.areas.json, '
                                'or its .hotspots.json: the design-director draws it)' % (picture, key))
            return [(0.0, 0.0, 1.0, 1.0)]
        return [tuple(a) for a in (area if isinstance(area[0], list) else [area])]

    def at_of(self, rects):
        return rect(rects[0]) if len(rects) == 1 else [rect(r) for r in rects]

    def hot_options(self, item, sid, where, picture, mode, raw, right, wrong):
        """Hotspots (or cards of the parts) of a picture: options named by their part; a part's place is read from the picture's map."""
        if not 2 <= len(raw) <= 3:
            self.problem(where, 'a Band A command has 2 or 3 options (it has %d)' % len(raw))
            return None
        right = right or raw[0]
        options, correct = [], None
        shown = self.hot_show(item, picture, raw)
        mode_cards = shown == 'cards'
        for n, key in enumerate(raw, start=1):
            oid = 'o%d' % n
            rects = self.areas_for(picture, key, where)
            tag = None
            if key == right:
                correct = oid
            elif key not in wrong:
                self.problem(where, 'the distractor "%s" has no tag in "wrong" (every distractor carries the error it reveals)' % key)
            else:
                tag = self.tag(wrong[key], sid, where)
            entry = {'id': oid}
            if mode_cards:
                card = self.area_table.get(picture, {}).get('@cards', {}).get(key)
                if not card:
                    self.problem(where, 'the part "%s" of %s has no close-up card' % (key, picture))
                    card = key
                entry['sprite'] = self.asset(card, where)
            entry['label'] = self.part_label(picture, key)
            entry['at'] = self.at_of(rects)
            if tag:
                entry['misconception'] = tag
            options.append(entry)
        for key in wrong:
            if key not in raw or key == right:
                self.problem(where, '"wrong" names "%s", which is not a distractor of this item' % key)
        if correct is None:
            self.problem(where, 'the right answer "%s" is not among the options' % right)
            return None
        return options, correct, 'cards' if mode_cards else 'hotspots'

    def hot_show(self, item, picture, raw):
        """`cards` when the picture's map says the item shows its parts as close-up cards (parts too close to touch on the body)."""
        if item.get('mode') == 'cards':
            return 'cards'
        for key in item.get('_keys', []):
            listed = self.area_table.get(picture, {}).get('@items', {}).get(key)
            if listed:
                return listed.get('show', 'body')
        rects = [self.areas_of(picture).get(k) for k in raw]
        flat = [tuple(r) for rs in rects if rs for r in (rs if isinstance(rs[0], list) else [rs])]
        for i, a in enumerate(flat):
            for b in flat[i + 1:]:
                if overlap(a, b):
                    return 'cards'
        return 'body'

    def part_label(self, picture, key):
        return PLACE_LABELS.get(key) or key

    def drag_options(self, item, sid, where, raw, right, wrong, scene, picture):
        if not 2 <= len(raw) <= 3:
            self.problem(where, 'a Band A command has 2 or 3 options (it has %d)' % len(raw))
            return None
        right = right or (raw[0] if isinstance(raw[0], str) else raw[0].get('pic'))
        areas = self.areas_of(picture)
        target = areas.get('@target')
        if target is None:
            self.problem(where, 'the picture "%s" has no `@target` area in scenes.areas.json (the place things are taken to)' % picture)
            target = [0.58, 0.3, 0.38, 0.38]
        scene['target'] = {'at': rect(target)}
        if item.get('target_sprite'):
            scene['target']['sprite'] = self.asset(item['target_sprite'], where)
        options, correct = [], None
        taken = [tuple(target)]
        for n, key in enumerate(raw, start=1):
            oid = 'o%d' % n
            face = {'pic': key} if isinstance(key, str) else dict(key)
            x, y = RAIL[n - 1]
            at = (x, y, RAIL_SIDE, RAIL_SIDE)
            tag = None
            if face['pic'] == right:
                correct = oid
            elif face['pic'] not in wrong:
                self.problem(where, 'the distractor "%s" has no tag in "wrong" (every distractor carries the error it reveals)' % face['pic'])
            else:
                tag = self.tag(wrong[face['pic']], sid, where)
            entry = self.entry_of(oid, face, where, tag=tag)
            entry['at'] = rect(at)
            options.append(entry)
        if correct is None:
            self.problem(where, 'the right answer "%s" is not among the options' % right)
            return None
        return options, correct

    def place_options(self, item, sid, where, picture, raw, right, wrong, scene):
        """Place mode: one thing is moved to one of 2 or 3 places of the picture (on, under, by, in)."""
        if not 2 <= len(raw) <= 3:
            self.problem(where, 'a Band A command has 2 or 3 places (it has %d)' % len(raw))
            return None
        thing = item.get('thing')
        areas = self.areas_of(picture)
        at = areas.get('@thing') or [0.70, 0.02, 0.28, 0.28]
        scene['thing'] = {'sprite': self.asset(thing, where), 'at': rect(at)}
        right = right or raw[0]
        options, correct = [], None
        for n, key in enumerate(raw, start=1):
            oid = 'o%d' % n
            rects = self.areas_for(picture, key, where)
            tag = None
            if key == right:
                correct = oid
            elif key not in wrong:
                self.problem(where, 'the place "%s" has no tag in "wrong" (every wrong place carries the error it shows)' % key)
            else:
                tag = self.tag(wrong[key], sid, where)
            entry = {'id': oid, 'label': self.part_label(picture, key), 'at': self.at_of(rects)}
            if tag:
                entry['misconception'] = tag
            options.append(entry)
        if correct is None:
            self.problem(where, 'the right place "%s" is not among the places' % right)
            return None
        return options, correct
