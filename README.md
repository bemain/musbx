# Musician's Toolbox

<p align="left">
    <a href='https://play.google.com/store/apps/details?id=se.agardh.musbx&pcampaignid=musbx-readme-badge' style="border-radius: 13px; height: 84px;"><img alt='Get it on Google Play' src='https://bemain.github.io/musbx/assets/badges/google-play.png' style="height: 84px;"/></a>
    <a href="https://apps.apple.com/us/app/musicians-toolbox/id1670009655?itsct=musbx-readme-badge&amp;itscg=30200" style="display: inline-block; border-radius: 13px; height: 84px;"><img src="https://bemain.github.io/musbx/assets/badges/app-store.png" alt="Download on the App Store" style="border-radius: 13px; height: 84px;"></a>
</p>

Transcribe — Practice — Perform

Musician's Toolbox offers all the essential tools in a single app, built to provide a sleek and easy-to-use experience that puts state-of-the-art AI technology at your fingertips. Whether you are a professional musician or just want to tune your guitar, Musician's Toolbox has the right tool for the job. 

## Current features
- Metronome
- Tuner
- Music player featuring:
    - Automatic chord identification
    - Changing the pitch and speed
    - Muting or isolating specific instruments
    - Equalizer
- Drone

## Git naming

### Commits
This project follows (since Sep 25 2023) the [Conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) specification for naming commits. Here follows a short summary of that specification.

A commit message should be structured as follows:

```
<type>[(scope)]: <description>

[body]

[footer(s)]
```

A commit that has a footer `BREAKING CHANGE`:, or appends a ! after the type/scope, introduces a breaking API change. 
The footer `Fixes <issue number>` can be used to reference a GitHub issue.

[Commitizen](https://commitizen-tools.github.io/commitizen/) is a command line tool that can be used to assist in creating commits that follows the Conventional commits specification. 

### Branches
A branch should be named as follows:

```
feat/[area]/[issue reference]/<description>
```

Example `area`s: `demixer`, `tuner`, `songs`.

The `description` should use kebab-case.

Here's a complete example: 
```
feat/songs/issue72/configure-audio-session
```

## Tools

### Custom icons
To generate custom icons for use in the app, add them to [`assets/icons`](assets/icons). Then make sure `npx` is installed and run
```bash
dart run tool/generate_icons.dart
```

## Privacy policy
Privacy policy can be found [here](https://bemain.github.io/musbx/privacy/)

## Contact information
If you have any questions, feedback or issues with the app, please reach out:

Benjamin Agardh \
bemain.dev@gmail.com
