# NAU Themes for OpenEdx

This repository contains the NAU themes.

## How to update translations

To extract the strings to be translated, add them to .po files and to compile the translation .mo
files, run the Makefile target `update_translations`.

```bash
make update_translations
```

### Devstack

To update translations on devstack it's require to run:

For LMS:
```bash
make publish_lms_devstack
```

For STUDIO:
```bash
make publish_studio_devstack
```
