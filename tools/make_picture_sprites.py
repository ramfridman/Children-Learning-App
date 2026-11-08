"""Superseded on 2026-11-06: every picture this file used to draw as a flat placeholder (balls, balloons, flowers,
shades, shapes, solids, positions, lines, towers, rule cards, days, clocks, times of day, the Logic, maths and Robot
Harbour things) is drawn in the house style by tools/make_logic_sprites.py, under the same ids (the list:
docs/design/logic-sweep/old-style-inventory.md).

This file only runs that generator, so an old command can never bring the placeholders back.
"""
import os
import runpy

runpy.run_path(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'make_logic_sprites.py'), run_name='__main__')
