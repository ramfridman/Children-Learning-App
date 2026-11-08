"""Recipes of the print items of Hebrew Band A, for tools/lang_recipes.py (class `Print`, which `Recipes` takes): the own-name items (HEB-A-11:
`name` and `name-letter`) and the print-direction items (HEB-A-12: `page-zones` and `follow`). Standard library only.

An own-name item has no name in it. The unit file holds the rules and the closed list of names (`ownName`: `names`, `pairs`); the item says
what each option is made of at run time (`options`: `own`, `first`, `length` in a choice of names; `first`, `lookalike`, `last` in a row of
letters) and the app makes the options on the device from the child's first name, so that no name is ever in a file, a log or a message
(docs/languages/hebrew/band-a-content.md, A-11; decision 25).
"""
import re

from lang_recipes_base import ALT, PAGE_ALT

# The tag a distractor carries, by what it is made of (an item may name its own in `wrong`); the look-alike carries the tag of its pair at run
# time, and this one (the first pair's) in the pack.
NAME_TAGS = {'first': 'name_first', 'length': 'name_length', 'last': 'order'}
# What a screen reader says of a zone of a page (adult text, needs-editor like every generated text).
ZONE_LABELS = {'start': 'תְּחִלַּת הַשּׁוּרָה', 'end': 'סוֹף הַשּׁוּרָה', 'picture': 'הַתְּמוּנָה', 'word': 'הַמִּלָּה', 'other': 'מִלָּה אַחֶרֶת'}
NAME_ALT = {'name': 'שְׁמוֹת לִבְחֹר מֵהֶן', 'letter': 'אוֹתִיּוֹת שֶׁל הַשֵּׁם'}


class Print:
    """The recipes. `self` is a Course (tools/lang_pack.py)."""

    # ------------------------------------------------------------ HEB-A-11 the child's own name
    def recipe_name(self, sk, sid, aid, item, where):
        return self._own_name(sk, sid, aid, item, where, 'name')

    def recipe_name_letter(self, sk, sid, aid, item, where):
        return self._own_name(sk, sid, aid, item, where, 'letter')

    def _own_name(self, sk, sid, aid, item, where, unit):
        """`tap_answer` 1.5 with `answer.type` `name`: 2 or 3 options, each made on the device from the child's first name."""
        rules = sk.get('ownName') or {}
        names = rules.get('names') or []
        pairs = rules.get('pairs') or []
        right_source = 'own' if unit == 'name' else 'first'
        allowed = ('own', 'first', 'length') if unit == 'name' else ('first', 'lookalike', 'last')
        sources = item.get('options') or []
        if not 2 <= len(sources) <= 3 or any(s not in allowed for s in sources) or len(set(sources)) != len(sources):
            self.problem(where, 'the options of a %s item are 2 or 3 of %s, each once' % (unit, ', '.join(allowed)))
            return None
        if right_source not in sources:
            self.problem(where, 'a %s item has the option "%s" (the right one)' % (unit, right_source))
            return None
        if unit == 'name' and not names:
            self.problem(where, 'the unit has no `ownName.names` (the closed list the distractor names come from)')
            return None
        if not pairs and (unit == 'letter' or 'lookalike' in sources):
            self.problem(where, 'the unit has no `ownName.pairs` (the look-alike pairs of letters)')
            return None
        pair_tags = [self.tag(p['tag'], sid, where) for p in pairs]
        wrong = dict(NAME_TAGS, lookalike=pairs[0]['tag'] if pairs else None)
        wrong.update(item.get('wrong') or {})
        options, correct = [], None
        for n, source in enumerate(sources, start=1):
            entry = {'id': 'o%d' % n, 'label': 'שֵׁם' if unit == 'name' else 'אוֹת', 'source': source}
            if source == right_source:
                correct = entry['id']
            else:
                entry['misconception'] = self.tag(wrong[source], sid, where)
            options.append(entry)
        doc = self.head(sk, sid, aid, item, where, 'tap_answer', version='1.5', alt=NAME_ALT[unit],
                        goal='choose the name or the letter that is the child\'s own', choices=len(options))
        if not self.lines_of(doc, item, where, self.tag_ids(options) + [t for t in pair_tags if t not in self.tag_ids(options)]):
            return None
        doc['scene'] = {}
        answer = {'type': 'name', 'unit': unit, 'options': options, 'correct': correct, 'shuffle': True, 'unsureAllowed': True}
        if unit == 'name':
            answer['names'] = list(names)
        answer['pairs'] = [{'a': p['a'], 'b': p['b'], 'misconception': t} for p, t in zip(pairs, pair_tags)]
        doc['answer'] = answer
        return doc

    # ------------------------------------------------------------ HEB-A-12 print direction
    def recipe_page_zones(self, sk, sid, aid, item, where):
        """`story` mode `zones`: a page that shows its text; the child touches where reading starts (the right end of the first line)."""
        zones = item.get('zones') or []
        if not 2 <= len(zones) <= 3 or 'line1-start' not in zones:
            self.problem(where, '`zones` are 2 or 3 places of the page, with "line1-start" (where reading starts)')
            return None
        return self._read_page(sk, sid, aid, item, where, 'zones', zones, 'line1-start')

    def recipe_follow(self, sk, sid, aid, item, where):
        """`story` mode `follow`: the voice reads a word and waits for the child's touch on it, word by word. The clip of each word is cut
        from the clip of the page by its timing, so it costs no voicing of its own."""
        return self._read_page(sk, sid, aid, item, where, 'follow', ['word', 'other', 'picture'], 'word')

    def _read_page(self, sk, sid, aid, item, where, mode, zones, right):
        page, clip = item.get('page'), item.get('clip')
        row = self.clip_row(clip, where) if clip else None
        if not page or not row or not row.get('shown'):
            self.problem(where, 'a %s item names the `page` (a picture) and the `clip` of its text (a row of the clip table with its text)' % mode)
            return None
        lines = [l for l in re.split(r'(?<=[.!?])\s+', row['shown'].strip()) if l]
        if not 1 <= len(lines) <= 3:
            self.problem(where, 'the text of the page has %d lines (1 to 3: one sentence to a line)' % len(lines))
            return None
        shown = []
        for n, line in enumerate(lines, start=1):
            words = []
            for k, word in enumerate(line.split(), start=1):
                entry = {'text': word}
                if mode == 'follow':
                    cut = '%s-w%d' % (clip, len(words) + sum(len(l) for l in shown) + 1)
                    entry['clip'] = self.cut_clip(cut, clip, word, where)
                words.append(entry)
            shown.append(words)
        wrong = item.get('wrong') or {}
        options = []
        for n, zone in enumerate(zones, start=1):
            entry = {'id': 'o%d' % n, 'label': ZONE_LABELS[zone.split('-')[-1] if zone.startswith('line') else zone], 'zone': zone}
            if zone != right:
                key = next((k for k in (zone, zone.split('-')[-1]) if k in wrong), None)
                if key is None:
                    self.problem(where, 'the zone "%s" has no tag in "wrong" (every wrong place carries the error it shows)' % zone)
                    return None
                entry['misconception'] = self.tag(wrong[key], sid, where)
            options.append(entry)
        doc = self.head(sk, sid, aid, dict(item, hintWord=clip), where, 'story', version='1.1', rep='symbolic',
                        goal='touch where reading starts' if mode == 'zones' else 'touch each word as it is read',
                        choices=len(options), alt=item.get('alt') or self.defaults.get('pageAlt') or PAGE_ALT)
        if not self.lines_of(doc, dict(item, hintWord=clip), where, self.tag_ids(options), target=False):
            return None
        alt = item.get('alt') or self.defaults.get('pageAlt') or PAGE_ALT
        doc['scene'] = {'pages': [{'picture': self.asset(page, where), 'clips': [self.clip(clip, where)], 'alt': alt, 'lines': shown}]}
        doc['answer'] = {'type': 'choice', 'mode': mode, 'options': options, 'correct': next(o['id'] for o in options if o['zone'] == right),
                         'shuffle': False, 'unsureAllowed': True}
        return doc

    def cut_clip(self, cut, page_clip, word, where):
        """The `vo:` id of the clip of one word, cut from the page's clip by its timing: it is listed apart from the clips to voice."""
        self.cut_clips[cut] = {'id': cut, 'from': page_clip, 'text': word}
        return self.vo(cut)
