{ config, pkgs, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  unsupported = builtins.abort "Unsupported platform";
in
{
  imports = [
    ## Modularize your home.nix by moving statements into other files
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username =
    if isLinux then "kyoh86" else
    if isDarwin then "yamada" else unsupported;
  home.homeDirectory =
    if isLinux then "/home/kyoh86" else
    if isDarwin then "/Users/yamada" else unsupported;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; ([
    # Common packages

    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    (pkgs.writeShellScriptBin "my-hello" ''
      echo "Hello, ${config.home.username}!"
    '')

    # Utilities
    diffutils
    dnsutils
    findutils
    cmake
    gettext

    # Shell environment
    direnv
    delta
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting

    # Languages
    go
    sqlite
    deno
    luajit
    luajitPackages.luarocks
    luajitPackages.luv

    # Tools
    actionlint
    awscli2
    docker-compose
    gh
    httpie
    jq
    mise
    postgresql_17
    ripgrep
    ssm-session-manager-plugin
    tig
    unzip

    # Language servers
    angular-language-server
    ansible-language-server
    astro-language-server
    bash-language-server
    dockerfile-language-server-nodejs
    efm-langserver
    eslint
    gopls
    vscode-langservers-extracted # HTML, CSS, JSON, ESLint
    jq-lsp
    lua-language-server
    sqls
    stylelint-lsp
    stylua
    svelte-language-server
    taplo
    terraform-ls
    vim-language-server
    vtsls
    yaml-language-server

  ] ++ lib.optionals isLinux [
    # GNU/Linux packages
    inotify-tools
    wslu
    coreutils
    binutils
    gnumake
  ] ++ lib.optionals isDarwin [
    # macOS packages
    wezterm
    raycast
    plemoljp
  ]);

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/kyoh86/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
}
