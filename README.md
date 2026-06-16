# Item Track Tags

A lightweight World of Warcraft addon that stamps each equipped item's upgrade track onto the Character panel (**C**) as a tiny colored letter, so you know where 
you still need an item.

| Letter | Track | Color |
|:------:|-------|-------|
| E | Explorer | gray |
| A | Adventurer | green |
| V | Veteran | teal |
| C | Champion | blue |
| H | Hero | orange |
| M | Myth | pink |

Just sits in the corner of each gear slot and updates when you open the panel or swap gear, no menu.

## Install

Drop the `ItemTrackTags` folder into:

```
World of Warcraft\_retail_\Interface\AddOns\
```

Then enable it on the character-select addon list.

## Customize

Letters and colors live in the `TRACKS` table at the top of `ItemTrackTags.lua`. 
Can be freely edited

## Localization

Currently works with **English** and **German** clients.

For any other locale, run `/itt debug` with (different track!) gear equipped to print the raw upgrade lines, then add the localized track word to the `TRACKS` table.

Help with localization is much appreciated -> **Create a PR!**
