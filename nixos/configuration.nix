{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enable flakes
  nix.settings = {
    extra-substituters = [
      "https://attic.xuyh0120.win/lantian"
    ];

    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];

    experimental-features = [ "nix-command" "flakes" ];
  };

  # Store maintenance
  nix.optimise.automatic = true;

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
    # Point this at your config repo to rebuild with just `nh os switch`:
    # flake = "/home/monky/nixos-config";
  };

  # Bootloader: Limine
  boot.loader.limine = {
    enable = true;
    efiSupport = true;
    maxGenerations = 10;

    extraEntries = ''
      /Windows
          protocol: efi
          path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
    '';
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Faster gpu init on boot
  hardware.amdgpu.initrd.enable = true;

  networking.hostName = "void";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Amsterdam";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.espanso.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users."monky" = {
    isNormalUser = true;
    description = "monky";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
      wl-clipboard
      xwayland-satellite
      fzf
      fd
    ];
  };

  services.keyd = {
    enable = true;

    keyboards.default = {
      ids = [ "*" ];

      settings.main.capslock = "~";
    };
  };

  services.flatpak.enable = true;
  services.tailscale.enable = true;
  programs.zoxide.enable = true;
  programs.zsh.enable = true;
  programs.niri.enable = true;

  programs.neovim.enable = true;

  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

  users.defaultUserShell = pkgs.zsh;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  programs.gamemode.enable = true;

  # Network NAS
  fileSystems."/mnt/nas" = {
    device = "//192.168.178.42/storage";
    fsType = "cifs";
    options = [
      "credentials=/etc/samba/credentials-monky"
      "uid=1000"
      "gid=1000"
      "file_mode=0644"
      "dir_mode=0755"
      "vers=3.1.1"
      "_netdev"
      "nofail"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.mount-timeout=10"
      "x-gvfs-show"
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    jq
    cifs-utils
    clang
  ];

  # Do not change this after the initial install
  system.stateVersion = "26.05";
}
