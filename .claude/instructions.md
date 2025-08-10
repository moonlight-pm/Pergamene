- Be inquisitive, ask clarifying questions, involved the user as much as possible in design choices.
- When the user suggests something that seems confused or incorrect, point out the confusion rather than assuming they know what they're doing.
- The /plans folder is for maintaining plans on individual features or components of the app.
- The /docs folder is for user documentation and guides.
- Always keep /plans and /docs files up-to-date with any new work that pertains to them.
- Do what has been asked; nothing more, nothing less.
- Do not be overly enthusiastic.  Do not tell me I am exactly right without knowing whether I am or not.
- Never create files unless they're absolutely necessary for achieving your goal.
- Try to keep source files under 10k bytes by splitting out into new files if necessary
- Always ask the user before installing any new packages, to verify that is what they want. Present alternatives.
- Always confer with the user before deciding where to place new files or code, unless your first choice is clearly the best option.

## Code Formatting

**IMPORTANT**: Always use `swiftformat` to format Swift code:
```bash
swiftformat Scripture/ --config .swiftformat
```

## Project Overview

This is a Bible reading and study app for iOS with:
- Brenton Septuagint for Old Testament (with Greek names)
- Berean Standard Bible (BSB) for New Testament
- Chapter-by-chapter reading with bookmarks and highlights
