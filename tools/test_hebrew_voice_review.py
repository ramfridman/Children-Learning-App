"""The course rules of tools/hebrew_voice_review.py (hebrew-notes.md section 15): the words that keep their nikud in a course line and the voice
text of a gloss.

    python tools/test_hebrew_voice_review.py

Standard library only. The module is imported, never run: it reads its tables only in main().
"""
import os
import sys
import unittest

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
ARGV = sys.argv[:]
import hebrew_voice_review as hvr  # noqa: E402

sys.argv = ARGV  # the tool replaces argv when it is imported (line 25); unittest must read its own


class CourseKeepTest(unittest.TestCase):
    def test_the_three_words_of_section_15_keep_their_nikud(self):
        for word in ('מַחֲאוּ', 'סַפְּרוּ', 'קְחוּ'):
            self.assertIn(hvr.canon(word), hvr.COURSE_KEEP, word)
            self.assertEqual(hvr.partial_nikud(word), word, 'a kept word is not turned into its plain spelling')

    def test_a_course_line_keeps_them_in_the_middle_of_a_sentence(self):
        text, _ = hvr.course_voice_text('מַחֲאוּ כַּפַּיִם, סַפְּרוּ לַחָבֵר.')
        self.assertIn('מַחֲאוּ', text)
        self.assertIn('סַפְּרוּ', text)

    def test_the_older_words_are_still_kept(self):
        for word in ('וְאִמְרוּ', 'לֶחָבֵר', 'נְשַׂחֵק', 'הָאֹכֶל', 'אִי'):
            self.assertIn(hvr.canon(word), hvr.COURSE_KEEP, word)


class GlossVoiceTextTest(unittest.TestCase):
    def test_a_word_alone_is_fully_pointed_with_no_full_stop(self):
        for gloss in ('אִמָּא', 'פֶּה', 'חָלָב', 'סֵפֶר', 'גֶּרֶב', 'שִׂמְלָה', 'מַחֲאוּ כַּפַּיִם'):
            text, notes = hvr.gloss_voice_text(gloss)
            self.assertEqual(text, gloss, 'nothing is dropped, nothing added')
            self.assertTrue(any(n.startswith('gloss:') for n in notes))

    def test_a_gloss_that_ends_in_a_mark_goes_through_the_course_rules(self):
        for gloss in ('זוֹ אִמָּא.', 'מִי זֶה?', 'הִנֵּה הַכַּדּוּר!'):
            text, _ = hvr.gloss_voice_text(gloss)
            self.assertEqual(text, hvr.course_voice_text(gloss)[0], gloss)
            self.assertTrue(text.endswith(('.', '?')), 'a sentence closes: %r' % text)

    def test_a_carrier_that_ends_in_a_colon_keeps_it(self):
        text, _ = hvr.gloss_voice_text('בְּעִבְרִית:')
        self.assertTrue(text.endswith(':') and not text.endswith(':.'), text)

    def test_quotes_and_the_maqaf_are_dropped_as_in_a_course_line(self):
        text, _ = hvr.gloss_voice_text('תִּיק־תַּק')
        self.assertEqual(text, 'תִּיק תַּק')


if __name__ == '__main__':
    unittest.main()
