"""Regenerates every unit spec and the whole starter pack from the generators, in the one order that reproduces the
committed files:

    python tools/regen_content.py

1. tools/band_b.py writes the Band B specs (content/units/band-b-*.json; it runs band_b2.py and band_b3.py too);
2. tools/author.py turns each unit spec into content/starter, Band A first (Band B reads lines and assets the Band A
   files already wrote).

A handful of the oldest starter files (the M2 butterflies lesson and its skills and misconceptions) have no spec and
are edited by hand. Nothing is published or voiced here.
"""
import os
import subprocess
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(TOOLS, '..')
UNITS = ['counting-hills', 'math', 'colours', 'shapes', 'logic', 'robots',
         'band-b-numbers', 'band-b-math', 'band-b-colours', 'band-b-shapes', 'band-b-logic', 'band-b-robots',
         'band-b-extra-numbers', 'band-b-extra-math', 'band-b-extra-shapes']


def run(root=ROOT, quiet=False):
    """Runs the generators that live in <root>/tools over <root>/content."""
    env = dict(os.environ, PYTHONIOENCODING='utf-8')
    out = subprocess.DEVNULL if quiet else None
    tools = os.path.join(root, 'tools')
    subprocess.run([sys.executable, '-s', os.path.join(tools, 'band_b.py')], cwd=root, env=env, check=True, stdout=out)
    for u in UNITS:
        spec = os.path.join(root, 'content', 'units', u + '.json')
        subprocess.run([sys.executable, '-s', os.path.join(tools, 'author.py'), spec], cwd=root, env=env, check=True,
                       stdout=out)


if __name__ == '__main__':
    run()
