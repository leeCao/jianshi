#!/usr/bin/env python3
"""Rebuild the fixed UI heading font (requires fonttools)."""
import argparse
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('source_font', type=Path, help='Path to the original ZhuqueFangsong-Regular.ttf (v0.212)')
args = parser.parse_args()

from fontTools import subset
from fontTools.ttLib import TTFont
font = TTFont(args.source_font)
# appTitle is reserved for the brand and these fixed page headings, never user text.
text = '笺事待办详情新建编辑管理分组'
options = subset.Options()
options.name_IDs = ['*']
options.name_legacy = True
options.name_languages = ['*']
subsetter = subset.Subsetter(options=options)
subsetter.populate(text=text)
subsetter.subset(font)
# A distinct internal name avoids colliding with an installed full font.
for record in font['name'].names:
    if record.nameID in (1, 4, 6, 16):
        record.string = 'JianshiTitle-Regular'.encode(record.getEncoding())
font.save(root / 'Sources/Menuminder/Assets/Fonts/JianshiTitle-Regular.ttf')
