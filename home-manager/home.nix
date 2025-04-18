{ config, pkgs, lib, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
    # Common packages

    # Utilities
    diffutils
    dnsutils
    findutils
    cmake

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
    git

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
  ];

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
