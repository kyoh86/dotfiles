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
gh --repo kyoh86/keyball workflow run build-user.yml --ref kyoh86-ow --field keyboard=keyball61 --field keymap=kyoh86
```

## Build Farmware By Manual

### 0. Install qmk tool

```shell
pip install --user qmk
qmk setup
```

### 1. Prepare working directory

Prepare temporary directory and change working directory to there.

```shell
pushd "$(mktemp -d)"
```

### 2. Prepare Keyball keymap

Prepare my own Keyball keymap and rebase it on-to Yowkees/keyball.

```shell
git clone https://github.com/kyoh86/keyball --branch kyoh86-ow keyball

pushd keyball
git remote add upstream https://github.com/Yowkees/keyball
git fetch upstream
git rebase upstream/main
popd
```

### 3. Prepare QMK firmware

Prepare QMK firmware (`0.22.14`)

```shell
git clone https://github.com/qmk/qmk_firmware --depth 1 --recurse-submodules --shallow-submodules --branch 0.22.14 qmk
```

### 4. Merge them and build

```shell
pushd qmk
pushd keyboards
ln -s ../../keyball/qmk_firmware/keyboards/keyball keyball
popd
make SKIP_GIT=yes keyball/keyball61:kyoh86

ls keyball_*.hex
```

## Flush the built firmware

You can use `qmk_tookbox` or [Pro Micro Web Updater](https://sekigon-gonnoc.github.io/promicro-web-updater/index.html).
Pushing twice quickly a "Reset" button of keyball, they recognise a keyboard.

See more: https://docs.qmk.fm/newbs_flashing#flashing-your-keyboard-with-qmk-toolbox
