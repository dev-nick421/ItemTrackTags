# Item Track Tags

A lightweight World of Warcraft addon that marks each equipped item on the Character panel (**C**):

- **Upgrade-track items** show a tiny colored letter.
- **Crafted items** show their crafting quality icon (Tier 1–5).

| Letter | Track | Default color |
|:------:|-------|---------------|
| E | Explorer | gray |
| A | Adventurer | green |
| V | Veteran | teal |
| C | Champion | blue |
| H | Hero | orange |
| M | Myth | pink |

It just sits in the corner of each gear slot and updates when you open the panel or swap gear.

## Install

Drop the `ItemTrackTags` folder into:

```
World of Warcraft\_retail_\Interface\AddOns\
```

Then enable it on the character-select addon list.

## Settings — `/itt`

Type `/itt` in chat to open the settings panel:

- **Font size** — adjust the marker size.
- **Track colors** — click a swatch to recolor any track.
- **Show crafted quality icons** — toggle off if another addon already shows these, to avoid clashes.

Settings are saved per account.

## Localization

Track detection ignores any modifier prefix (e.g. `Sporefused:`, `Galactic Void-Charged:`), reading only the track word before the rank — so new item modifiers keep working automatically.

Works on **English** and **German** clients out of the box. For any other locale, run `/itt debug` with gear equipped to print the parsed lines, then add the localized track word to the `TRACK_KEY` table in `ItemTrackTags.lua`.

## Requirements

World of Warcraft: Midnight (interface 12.0+).