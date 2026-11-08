{ config, pkgs, ... }:

{

  imports = [
    ./fish.nix
  ];

  home.username = "monky";
  home.homeDirectory = "/home/monky";

  home.packages = with pkgs; [
    vesktop
    zed-editor
    kitty
    ncspot
    alacritty
    eza
    fastfetch
    gtk3
    heroic
    prismlauncher
    mangohud
    gamescope
    protonup-qt
    btop
    mpv
    feh
    nautilus

    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer

    moonlight-qt

    python313
    go
    gopls
    bun
    umu-launcher
    file
    ncdu
    dysk

    onlyoffice-desktopeditors
    jetbrains.idea
  ];

  home.file."nas".source = config.lib.file.mkOutOfStoreSymlink "/mnt/nas";

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    package = pkgs.atuin;
  };

  programs.hermes-agent = {
    enable = true;
    desktop.enable = true;
  };


  programs.helium.enable = true;
  programs.noctalia.enable = true;

  programs.starship = {
    enable = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Levi Noppers";
      email = "levinoppers@proton.me";
    };
  };

  home.file = {
    ".config/atuin".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dotfiles/general/atuin";

    ".config/espanso".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dotfiles/general/espanso";

    ".config/fastfetch".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dotfiles/general/fastfetch";

    ".config/kitty".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dotfiles/general/kitty";

    ".config/niri".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dotfiles/general/niri";

    ".config/noctalia".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dotfiles/general/noctalia";

    ".config/starship.toml".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dotfiles/general/starship.toml";

    ".config/zed".source =
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/dotfiles/general/zed";
  };

  home.stateVersion = "26.05";
}
