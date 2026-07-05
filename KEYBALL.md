# Keyball Setup

How to setup Keyball61

See also: https://github.com/Yowkees/keyball/blob/main/qmk_firmware/keyboards/keyball/readme.md

## Customize Keymap

1. Clone Repository
    - `git clone https://github.com/kyoh86/keyball --branch kyoh86-ow keyball`
1. Edit Keymap
    - `qmk_firmware/keyboards/keyball/keyball61/keymaps/kyoh86/config.h`
    - `qmk_firmware/keyboards/keyball/keyball61/keymaps/kyoh86/keymap.c`
1. Build Firmware (See below)

## View Keymap

https://remap-keys.app/

## Build Farmware In GitHub Actions

https://github.com/kyoh86/keyball/actions/workflows/build-user.yml

```console
$ gh --repo kyoh86/keyball workflow run build-user.yml --ref kyoh86-ow --field keyboard=keyball61 --field keymap=kyoh86
```

To Download Artifact:
```console
$ gh --repo kyoh86/keyball run watch
$ gh --repo kyoh86/keyball run download "$(gh --repo kyoh86/keyball run list --branch kyoh86-ow --json "name,updatedAt,databaseId,status" --limit 1 --status success --jq ".[]|select(.updatedAt > \"$(date -u -d "-30 minutes" +'%Y-%m-%dT%H:%M:%SZ')\")|.databaseId")" --name keyball61-kyoh86-firmware

## Build Farmware By Manual

NOTE: DEPRECATED
I don't want to maintenance an environment to build qmk firmwares.

## Flush the built firmware

You can use `qmk_tookbox` or [Pro Micro Web Updater](https://sekigon-gonnoc.github.io/promicro-web-updater/index.html).
Pushing twice quickly a "Reset" button of keyball, they recognise a keyboard.

See more: https://docs.qmk.fm/newbs_flashing#flashing-your-keyboard-with-qmk-toolbox
