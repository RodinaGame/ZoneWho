# Changelog — ZoneWho

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.2] — 2026-10-07

### Fixed
- **Who window no longer flashes open / instantly closes** when the addon performs a background query.
  Previously the addon suppressed `ShowUIPanel` and then forced `FriendsFrame:Hide()`, which raced with the player pressing Social/Who (key `O` on many servers). The window could open for a frame and then be closed, or refuse to stay open.
- Removed fragile hooks on `ShowUIPanel` and `FriendsFrame.Show`.

### Changed
- Background `/who` now temporarily **unregisters** `WHO_LIST_UPDATE` from `FriendsFrame` while the addon is waiting for its own results, then re-registers it. This is the classic reliable 1.12 pattern and leaves the Social window completely alone for the player.
- Added a safety timeout (4 s) so FriendsFrame event handling is always restored even if the server never answers.
- Guard against overlapping who requests (ignore a new request while one is already pending).

### Added
- Version string shown in the frame title and on load (`ZoneWho v1.2 loaded`).
- Slash command `/zonewho version` (alias `ver`).
- This CHANGELOG.

## [1.1] — previous

- Initial public version with periodic zone who, class-coloured list, movable frame, and basic FriendsFrame suppression via ShowUIPanel hooks.
