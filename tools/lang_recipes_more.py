"""Recipes of the counting, matching, sorting, ordering and tracing templates of Band A, for tools/lang_recipes.py (class `More`, which
`Recipes` takes): count and tap, pairs (match_pairs), sort (sort_drag), a story line (build_pattern) and the pre-writing trace.
Standard library only."""
import re

from lang_recipes_base import ALT


class More:
    """The recipes. `self` is a Course (tools/lang_pack.py)."""

    # ------------------------------------------------------------ count and tap
    def recipe_count(self, sk, sid, aid, item, where):
        """`count_tap` in a course: the counting taps are practice (one number word for each); the scored step is "how many?" on
        sound buttons that each say a number word."""
        clips = item.get('clips') or []
        got = self.choice(item, sid, where)
        if got is None:
            return None
        options, correct, faces, names = got
        for o, f in zip(options, faces):
            o.pop('label', None)
            if 'value' in f:
                o['value'] = f['value']
            else:
                self.problem(where, 'the option "%s" needs its `value` (the number its word says)' % f.get('clip'))
        right = faces[[o['id'] for o in options].index(correct)].get('clip')
        item = dict(item, target=right)  # the hints' gloss is the number word
        doc = self.head(sk, sid, aid, item, where, 'count_tap', rep='concrete', goal='count, then say how many')
        asked = self.spoken({'line': item.get('answerPrompt') or self.defaults.get('answerPrompt'),
                             'target': item.get('answerTarget')}, where + ' answerPrompt', item)
        if asked is None or not self.lines_of(doc, item, where, self.tag_ids(options), target=False):
            return None
        doc['scene'] = {'objects': {'sprite': self.asset(item['objects'], where), 'litSprite': self.lit_sprite(item['objects'], where),
                                    'count': item['count'], 'arrangement': 'line', 'onTap': 'glow', 'seed': item.get('seed', 3),
                                    'clips': [self.clip(c, where) for c in clips]},
                        'target': {'sprite': self.blank_sprite()}}
        doc['answer'] = {'type': 'choice', 'options': options, 'correct': correct, 'shuffle': True, 'unsureAllowed': True}
        doc['answerPrompt'] = asked
        doc['traceClassifiers'] = []
        return doc

    def lit_sprite(self, picture, where):
        """The picture of a counted thing that has been touched: the same drawing on a soft gold glow, made here from the picture
        (the design-director may replace it with a drawn one: a file `<picture>-lit.svg` in the shared pictures is used instead)."""
        if self.picture_exists(picture + '-lit'):
            return self.asset(picture + '-lit', where)
        self._picture(picture, where)
        asset = (picture + '-lit').replace('-', '_')
        self.derived[asset] = ('lit', picture)
        return 'asset:' + asset

    def blank_sprite(self):
        """The thing at the middle of a count that the counted things fly to: nothing, because a course's counting only lights them."""
        self.derived['blank'] = ('blank', None)
        return 'asset:blank'

    # ------------------------------------------------------------ pairs
    def recipe_pairs(self, sk, sid, aid, item, where):
        """`match_pairs`: two rows of faces, the child joins each face of the top row to its partner in the bottom row. Cards say their
        word on a touch. A wrong partner carries the tag of what joined it (`wrong`: "a+b": tag)."""
        pairs = item.get('pairs') or []
        if not 2 <= len(pairs) <= 3:
            self.problem(where, 'a Band A pairs item has 2 or 3 pairs (it has %d)' % len(pairs))
            return None
        cards = {}
        for c in item.get('cards') or []:
            cards[c['pic']] = c
        left, right, links = [], [], []
        wrong = dict(item.get('wrong') or {})
        for n, p in enumerate(pairs, start=1):
            a, b = p[0], p[1]
            clip_a = (cards.get(a) or {}).get('clip') or (p[2] if len(p) > 2 else None)
            clip_b = (cards.get(b) or {}).get('clip') or (p[2] if len(p) > 2 else None)
            left.append(self.face_of('l%d' % n, a, clip_a, where))
            right.append(self.face_of('r%d' % n, b, clip_b, where))
            links.append({'left': 'l%d' % n, 'right': 'r%d' % n})
        # A wrong partner is the face of the bottom row that the wrong pair names; faces no wrong pair names take the next tag.
        tags = []
        for pair, slug_ in wrong.items():
            for part in pair.split('+'):
                for face, pr in zip(right, pairs):
                    if part == pr[1] and face.get('misconception') is None:
                        face['misconception'] = self.tag(slug_, sid, where)
            tags.append(slug_)
        if not tags:
            self.problem(where, 'a pairs item names what joins a wrong pair (`wrong`)')
            return None
        spare = [self.tag(t, sid, where) for t in tags]
        for face in right:
            if face.get('misconception') is None:
                face['misconception'] = spare[0]
        # The bottom row stands one place along from the top row, so the partners are never straight below.
        shift = right[-1:] + right[:-1]
        item = dict(item, hintWord=item.get('hintWord') or (cards.get(pairs[0][0]) or {}).get('clip') or (pairs[0][2:] or [None])[0])
        doc = self.head(sk, sid, aid, item, where, 'match_pairs', rep='pictorial', goal='join the partners')
        if not self.lines_of(doc, item, where, [f['misconception'] for f in shift], target=False):
            return None
        doc['scene'] = {'left': left, 'right': shift}
        doc['answer'] = {'type': 'match', 'pairs': links, 'misconception': spare[0]}
        return doc

    def face_of(self, fid, pic, clip, where):
        face = {'id': fid, 'sprite': self.asset(pic, where), 'label': self.defaults.get('pictureLabel') or 'תְּמוּנָה'}
        if clip:
            face['clip'] = self.clip(clip, where)
        return face

    # ------------------------------------------------------------ sort
    def recipe_sort(self, sk, sid, aid, item, where):
        """`sort_drag`: cards go into two or three bins by touch or drag. A card is a picture (that says its word), a sound or a text; a
        card put in a wrong bin carries the tag of that mistake (`traps`, or `wrong` for the cards by name)."""
        bins_in = item.get('bins') or []
        if not 2 <= len(bins_in) <= 3:
            self.problem(where, 'a sort has 2 or 3 bins (it has %d)' % len(bins_in))
            return None
        ids = {}
        bins = []
        for n, b in enumerate(bins_in, start=1):
            bid = 'b%d' % n
            ids[b['id']] = bid
            entry = {'id': bid}
            row = self.clip_row(b['label'], where) if self.pronunciation.get(b['label']) or True else {}
            text = (row or {}).get('shown') or ''
            if b.get('picture'):
                entry['sprite'] = self.asset(b['picture'], where)
            else:
                entry['text'] = text
            entry['clip'] = self.clip(b['label'], where)
            entry['label'] = text or b['id']
            bins.append(entry)
        traps = item.get('traps') or {}
        wrong = item.get('wrong') or {}
        cards, first_tag = [], None
        for n, c in enumerate(item.get('cards') or [], start=1):
            card = {'id': 'i%d' % n}
            key = c.get('pic') or c.get('text') or c.get('clip')
            if isinstance(c, str):
                key, c = c, {'text': c}
            if c.get('pic'):
                card['sprite'] = self.asset(c['pic'], where)
            elif c.get('text'):
                card['text'] = c['text']
            if c.get('clip'):
                card['clip'] = self.clip(c['clip'], where)
            if c.get('bin') is None:
                c = dict(c, bin=item['of'][key])
            card['bin'] = ids[c['bin']]
            tag = (traps.get(key) or {}).get('tag') or wrong.get(key)
            if tag:
                card['misconception'] = self.tag(tag, sid, where)
                first_tag = first_tag or card['misconception']
            cards.append(card)
        if first_tag is None and isinstance(wrong, dict) and wrong:
            first_tag = self.tag(next(iter(wrong.values())), sid, where)
        if first_tag is None:
            self.problem(where, 'a sort names the tag a card put in a wrong bin shows (`traps` or `wrong`)')
            return None
        doc = self.head(sk, sid, aid, item, where, 'sort_drag', rep='concrete', goal='put each card in its place', attempts=3)
        if not self.lines_of(doc, item, where, [first_tag] + [c['misconception'] for c in cards if c.get('misconception')], target=False):
            return None
        doc['scene'] = {'bins': bins, 'items': cards}
        doc['answer'] = {'type': 'sort', 'mode': 'sort', 'misconception': first_tag}
        return doc

    # ------------------------------------------------------------ a story line
    def recipe_sequence(self, sk, sid, aid, item, where):
        """`build_pattern` as a story line: 2 or 3 picture tiles into places in the order of the story. The tiles start in a shuffled
        row (the row turned one place); `reversed` and `swap` are two mistakes, but the document holds one tag."""
        tiles = item.get('tiles') or []
        n = len(tiles)
        if not 2 <= n <= 3:
            self.problem(where, 'a Band A story line has 2 or 3 pictures (it has %d)' % n)
            return None
        palette = tiles[-1:] + tiles[:-1]
        order = [palette.index(t) for t in tiles]
        wrong = item.get('wrong') or {}
        tag = wrong.get('swap') or next(iter(wrong.values()), None)
        if tag is None:
            self.problem(where, 'a story line names the tag a wrong order shows (`wrong`)')
            return None
        tag_id = self.tag(tag, sid, where)
        doc = self.head(sk, sid, aid, item, where, 'build_pattern', rep='pictorial', goal='put the pictures in the order of the story')
        if not self.lines_of(doc, item, where, [tag_id], target=False):
            return None
        scene = {'slots': n, 'palette': [self.asset(t, where) for t in palette]}
        clips = item.get('clips') or []
        if clips:
            scene['clips'] = [self.clip(c, where) for c in clips]
        doc['scene'] = scene
        doc['answer'] = {'type': 'build', 'order': order, 'misconception': tag_id}
        return doc

    # ------------------------------------------------------------ pre-writing
    def recipe_trace(self, sk, sid, aid, item, where):
        """`trace` (T04, the pre-writing paths of Hebrew A-14): the finger follows a path on a picture. Practice only (rule E-1):
        a start at the far end is the tag of the stroke, never evidence."""
        scene_pic = item.get('scene')
        source = self.stroke_scenes.get(scene_pic)
        if source is None:
            self.problem(where, 'the picture "%s" has no path in content/languages/strokes/prewriting-%s-a14.json' % (scene_pic, self.id))
            return None
        strokes = [[list(p) for p in s['points']] for s in source['strokes']]
        doc = self.head(sk, sid, aid, item, where, 'trace', rep='embodied', purpose='practice', check='practice',
                        goal='follow the path with a finger', attempts=3)
        tag = self.tag(item.get('tag', 'stroke'), sid, where)
        if not self.lines_of(doc, item, where, [tag], target=False):
            return None
        doc['scene'] = {'background': self.asset(scene_pic, where), 'strokes': strokes,
                        'guide': 'start' if 'start' in item.get('guide', 'full') else 'full', 'tolerance': item.get('tolerance', 14)}
        doc['answer'] = {'type': 'trace', 'directionMisconception': tag}
        return doc
