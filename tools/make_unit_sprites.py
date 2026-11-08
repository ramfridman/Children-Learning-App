"""Superseded on 2026-11-06: the Counting Hills sprites this file used to draw as flat placeholders (ladybug, star, apple,
fish, bird, duck, cat, dog, tick, cross, basket_target, their _lit twins, and the empty nest, bowl and basket scenes) are
drawn in the house style by tools/make_logic_sprites.py, under the same ids.

This file only runs that generator, so an old command can never bring the placeholders back.
"""
import os
import runpy

runpy.run_path(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'make_logic_sprites.py'), run_name='__main__')
