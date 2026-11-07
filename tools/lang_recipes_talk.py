"""Recipes of the talking and telling templates of Band A: puppet talk (LS10), say it with me (LS09), sing along (LS12), the drum (LS03)
and the story (LS08), for tools/lang_recipes.py (class `Talk`, which `Recipes` takes). Standard library only."""
import re

from lang_recipes_base import PAGE_ALT, PICTURE_LABEL, rect, slug

PERSONAL_TOPICS = ('name', 'age', 'likes', 'family')


class Talk:
    """The recipes. `self` is a Course (tools/lang_pack.py)."""

    # ------------------------------------------------------------ LS10 puppet talk
    def recipe_puppet(self, sk, sid, aid, item, where):
        """One turn of a puppet. `bubble`: the child picks the answer bubble that fits the scene. `personal` (frame 5.2): a scripted turn
        about the name, age, likes or family; the puppet answers first, nothing is scored or kept."""
        mode = item.get('mode', 'bubble')
        prompt = list(item.get('prompt') or [])
        if len(prompt) > 2:
            self.problem(where, "the puppet's turn is at most two clips (`prompt`)")
            return None
        picture = item.get('shows') or item.get('picture')
        scene = {'picture': self.asset(picture, where)}
        if item.get('key'):
            scene['key'] = {'at': rect(self.areas_for(picture, item['key'], where)[0])}
        frame = {'target': prompt[0] if prompt else False, 'target2': prompt[1] if len(prompt) > 1 else False}
        if mode == 'bubble':
            got = self.choice(item, sid, where)
            if got is None:
                return None
            options, correct, faces, names = got
            right_face = faces[[o['id'] for o in options].index(correct)]
            doc = self.head(sk, sid, aid, item, where, 'puppet_talk', rep='story', goal='answer the puppet', choices=len(options))
            item = dict(item)
            item.setdefault('after', right_face.get('clip'))
            item.setdefault('hintWord', right_face.get('clip'))
            if not self.lines_of(doc, item, where, self.tag_ids(options), **frame):
                return None
            doc['scene'] = scene
            doc['answer'] = {'type': 'choice', 'mode': 'bubble', 'options': options, 'correct': correct, 'shuffle': True,
                             'unsureAllowed': True}
            return doc
        topic = item.get('topic')
        if topic not in PERSONAL_TOPICS:
            self.problem(where, 'a personal turn asks the name, age, likes or family (topic "%s")' % topic)
            return None
        cards = []
        clips = item.get('cardClips') or []
        for n, c in enumerate(item.get('cards') or [], start=1):
            face = {'pic': c} if isinstance(c, str) else dict(c)
            if 'pic' in face and re.match(r'^n:\d+$', face['pic']):
                face = {'numeral': int(face['pic'][2:])}
                if len(clips) >= n:
                    face['clip'] = clips[n - 1]
            cards.append(self.entry_of('o%d' % n, face, where))
        doc = self.head(sk, sid, aid, item, where, 'puppet_talk', rep='story', purpose='practice', check='practice',
                        goal='the puppet asks, the child may answer or pass')
        reply = item.get('reply')
        reply = [r for r in (reply if isinstance(reply, list) else [reply]) if r and r != '@card']
        item = dict(item, after=reply or None)
        if not self.lines_of(doc, item, where, (), hints=False, **frame):
            return None
        pass_line = self.spoken({'line': self.defaults.get('pass', 'pass'), 'target': item.get('pass')}, where + ' pass', item)
        if pass_line is None:
            return None
        answer = {'type': 'none', 'mode': 'personal', 'topic': topic}
        if cards:
            answer['options'] = cards
        answer['pass'] = pass_line
        doc['scene'] = scene
        doc['answer'] = answer
        return doc

    # ------------------------------------------------------------ LS09 say it
    def recipe_say(self, sk, sid, aid, item, where):
        """`say_it`: the voice says the word with its picture, the child may say it (never wrong), then touches the picture."""
        word = item.get('clip')
        row = self.clip_row(word, where) if word else None
        forms = item.get('forms') or ([row['shown']] if row and row.get('shown') else []) + list(item.get('variants') or [])
        foils = item.get('foils') or []
        if not forms or not foils:
            self.problem(where, 'a say item lists the `forms` it accepts and the `foils` it must not take for them')
            return None
        doc = self.head(sk, sid, aid, item, where, 'say_it', rep='embodied', goal='say the word with the voice', attempts=1)
        # No word is shown in a chip: Band A has no reading (the curriculum-expert's decision of 2026-11-07, band-a-build.md 7.2). A step may
        # still say `show: true`, and `spoken` refuses it in a Band A skill (the letters of Hebrew A-10 to A-12 aside).
        item = dict(item, target=word, show=item.get('show', False))
        # A say step of a course with routes (docs/languages/band-a-build.md 2.6.1 R4): the prompt is the echo one ("let's say it together",
        # then the word), and `say.order` and `say.pictureFirst` let the player ask for the word before it is heard. A teach or hearing
        # screen is always echo.
        order = None if item.get('_screen') else self.say_order(sk)
        picture_first = self.picture_first(item, where) if order else None
        if order and picture_first is None:
            return None
        frame = (item.get('together') or self.defaults.get('together')) if order else None
        if not self.lines_of(doc, item, where, (), frame=frame, hints=False):
            return None
        heard = self.spoken({'line': item.get('heard') or self.defaults.get('heard'), 'target': word}, where + ' heard', item)
        together = self.spoken({'line': item.get('together') or self.defaults.get('together'), 'target': word},
                               where + ' together', item)
        if heard is None or together is None:
            return None
        say = {'forms': forms, 'foils': foils}
        if item.get('keyWords'):
            say['keyWords'] = item['keyWords']
        say.update({'clip': self.vo(word), 'heard': heard, 'together': together})
        if order:
            say.update({'order': order, 'pictureFirst': picture_first})
        doc['scene'] = {'picture': {'sprite': self.asset(item['picture'], where)}}
        doc['say'] = say
        doc['answer'] = {'type': 'say_it', 'scored': bool(item.get('scored', False))}
        return doc

    # ------------------------------------------------------------ LS12 chant
    def recipe_chant(self, sk, sid, aid, item, where):
        """`sing_along` chant: spoken lines on a beat; the pictures light on their key words; joining in is practice."""
        pictures = []
        for p in item.get('pictures') or []:
            face = {'pic': p} if isinstance(p, str) else p
            row = self.clip_row(face['clip'], where) if face.get('clip') else {}
            entry = {'picture': self.asset(face['pic'], where),
                     'label': face.get('label') or (row or {}).get('shown') or self.defaults.get('pictureLabel') or PICTURE_LABEL}
            if face.get('clip'):
                entry['clip'] = self.clip(face['clip'], where)
            pictures.append((entry, (row or {}).get('shown', '')))
        body = []
        for clip in item.get('lines') or []:
            row = self.clip_row(clip, where) or {}
            text = ' %s ' % re.sub(r'[^\w ]', '', (row.get('say') or row.get('shown') or '').lower())
            lights = [i for i, (_, shown) in enumerate(pictures)
                      if shown and ' %s ' % re.sub(r'[^\w ]', '', shown.lower()) in text]
            body.append({'clips': [self.clip(clip, where)], 'lights': lights[:3]})
        doc = self.head(sk, sid, aid, item, where, 'sing_along', rep='story', purpose='practice', check='practice',
                        goal='say the chant together')
        if not self.lines_of(doc, item, where, (), hints=False):
            return None
        doc['hints'] = []
        doc['scene'] = {'pictures': [p for p, _ in pictures], 'lines': body}
        doc['answer'] = {'type': 'none', 'mode': 'chant'}
        return doc

    # ------------------------------------------------------------ LS03 drum
    def recipe_drum(self, sk, sid, aid, item, where):
        """`sound_boxes` in drum mode: the child taps a drum once for each part of the word. A free response; one more and one fewer
        taps map to a tag, any other count is a retry."""
        word = item.get('word')
        word = word if isinstance(word, list) else [word]
        slow = item.get('slow') or []
        slow = slow if isinstance(slow, list) else [slow]
        item = dict(item, target=word[0])  # the hints' gloss and slow clip are the word's
        classifiers = list(item.get('classifiers') or [])
        for when, key in (('one_more', 'oneMore'), ('one_fewer', 'oneFewer')):
            if item.get(key):
                classifiers.append({'when': when, 'misconception': item[key]})
        doc = self.head(sk, sid, aid, item, where, 'sound_boxes', rep='concrete', goal='tap once for each part of the word',
                        variant=slug(word[0]))
        tags = [self.tag(c['misconception'], sid, where) for c in classifiers]
        if not self.lines_of(doc, item, where, tags, target=False):
            return None
        scene = {'picture': self.asset(item['picture'], where), 'word': [self.clip(w, where) for w in word]}
        if slow:
            scene['slow'] = [self.clip(w, where) for w in slow]
        if self.defaults.get('drum'):
            scene['drum'] = self.clip(self.defaults['drum'], where)
        doc['scene'] = scene
        doc['answer'] = {'type': 'drum', 'mode': 'drum', 'beats': item['beats'],
                         'classifiers': [{'when': c['when'], 'misconception': t} for c, t in zip(classifiers, tags)]}
        return doc

    # ------------------------------------------------------------ LS08 story
    def recipe_story(self, sk, sid, aid, item, where):
        """`story`: a picture book, heard page by page; a touch on a thing in a picture says its word. `listen` is never scored;
        `dialogic` stops after a page and asks a question with 2 or 3 pictures (scored); the recast is the right answer's feedback."""
        mode = item.get('mode', 'listen')
        pages = []
        words = item.get('words') or {}
        alts = item.get('alts') or []
        for n, p in enumerate(item.get('pages') or [], start=1):
            picture, clips = (p['picture'], p['clips']) if isinstance(p, dict) else (p[0], list(p[1:]))
            page = {'picture': self.asset(picture, where), 'clips': [self.clip(c, where) for c in clips],
                    'alt': (alts[n - 1] if len(alts) >= n else None) or self.defaults.get('pageAlt') or PAGE_ALT}
            # A picture with no touch-area map (no `<picture>.hotspots.json` of the design-director) has no things to touch yet.
            hot = [{'at': rect(self.areas_for(picture, clip, where)[0]), 'clip': self.clip(clip, where)}
                   for clip in words.get(picture, []) if picture in self.area_table]
            if hot:
                page['words'] = hot
            pages.append(page)
        if not 2 <= len(pages) <= 10:
            self.problem(where, 'a story has 2 to 10 pages (it has %d)' % len(pages))
            return None
        if mode == 'listen':
            doc = self.head(sk, sid, aid, item, where, 'story', rep='story', purpose='practice', check='practice',
                            goal='listen to the story')
            if not self.lines_of(doc, item, where, (), hints=False):
                return None
            doc['hints'] = []
            doc['scene'] = {'pages': pages}
            doc['answer'] = {'type': 'none', 'mode': 'listen'}
            return doc
        got = self.choice(item, sid, where)
        if got is None:
            return None
        options, correct, faces, names = got
        doc = self.head(sk, sid, aid, item, where, 'story', rep='story', goal='answer the question the story asks',
                        choices=len(options))
        if item.get('recast'):
            item = dict(item, after=item['recast'])
        if not self.lines_of(doc, item, where, self.tag_ids(options)):
            return None
        question = self.spoken({'line': item.get('question')}, where + ' question', item)
        if question is None:
            return None
        doc['scene'] = {'pages': pages}
        doc['answer'] = {'type': 'choice', 'mode': 'dialogic', 'pauseAfter': item.get('pauseAfter', len(pages) - 1),
                         'question': question, 'options': options, 'correct': correct, 'shuffle': True, 'unsureAllowed': True}
        return doc
