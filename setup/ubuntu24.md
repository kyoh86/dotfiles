# Setup Ubuntu 24.04

## 1. Prepare Ubuntu 24.04 in WSL:

$ wsl --install --distribution Ubuntu-24.04 --no-launch

## 2. Move the virtual machine storage too another location.

If I need to move the virtual machine to another location, I can use the following command:

```console
$ wsl
$ mkdir -p E:\wsl\images
$ wsl --export Ubuntu-24.04 E:\wsl\images\Ubuntu-24.04.tar
$ wsl --unregister Ubuntu-24.04
$ wsl --import Ubuntu-24.04 E:\wsl\ubuntu24 E:\wsl\images\Ubuntu-24.04.tar
```

And then, you can start the virtual machine with the following command:

```console
$ wsl --distribution Ubuntu-24.04 --user kyoh86
```

## 3. Setup 

In Ubuntu:
$ git clone https://github.com/kyoh86/dotfiles $HOME/Projects/github.com/kyoh86/dotfiles
$ cd $HOME/Projects/github.com/kyoh86/dotfiles
$ ./setup/ubuntu24

## 4. Link to hosts

In Ubuntu:
```console
$ ln -s /mnt/c/Users/xxxxx /home/kyoh86/Host
```
