{ config, lib, pkgs, ... }:

{
  nix.settings = {
    auto-optimise-store = true;
    max-jobs = 8;
    cores = 0;
    extra-substituters = [
      "https://cache.lantian.pub/lantian"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
    ];
    extra-trusted-public-keys = [
      "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
      "nix-community.cachix.org-1:mBshFgYSC15i7X2EnRAiTZ0dhQVEpVTgT7NUqpkP91M="
      "cache.nixos.org-1:6NCHd0YV2ODXoN9Zt02NzUVnSUkcWQ9yDRa+0WP0lrs="
    ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  programs.fish.enable = true;

  # Secrets (sops-nix): encrypted in the repo, decrypted at activation
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets."nas-credentials" = {
      mode = "0400";
    };

    # Readable by wheel so `nix flake update` as your user can use it
    secrets."nix-access-tokens" = {
      group = "wheel";
      mode = "0440";
    };
  };

  # GitHub token for flake input downloads (avoids HTTP 429 rate limits)
  nix.extraOptions = "!include ${config.sops.secrets."nix-access-tokens".path}";

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd niri-session";
      user = "greeter";
    };
  };

  # Stops boot messages from scribbling over the greeter
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # Laptop shit
  hardware.bluetooth = {
     enable = true;
     powerOnBoot = false;
   };
  hardware.enableRedistributableFirmware = true;
  hardware.uinput.enable = true;

  # Store maintenance
  nix.optimise.automatic = true;

  # Command-not-found replacement + comma (run any package with `, name`)
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
  programs.command-not-found.enable = false;

  zramSwap.enable = true;

  # Bootloader: Limine
  boot.loader.limine = {
    enable = true;
    efiSupport = true;
    maxGenerations = 10;
  };

  boot.loader.efi.canTouchEfiVariables = true;

  # Faster gpu init on boot
  hardware.amdgpu.initrd.enable = true;

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
  services.espanso = {
    enable = true;
    package = pkgs.espanso-wayland;
  };

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
    extraGroups = [ "networkmanager" "wheel" "docker" "render" "video" "uinput" ];
    packages = with pkgs; [
      kdePackages.kate
      wl-clipboard
      xwayland-satellite
      fzf
      fd
      nil
      nixd
      docker
      docker-compose
    ];
};

  services.keyd = {
    enable = true;

    keyboards.default = {
      ids = [ "*" ];

      settings.main.capslock = "~";
    };
  };

  virtualisation.docker.enable = true;
  services.flatpak.enable = true;
  services.tailscale.enable = true;
  programs.niri.enable = true;

  programs.neovim.enable = true;

  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

  users.defaultUserShell = pkgs.fish;

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
  fileSystems."/mnt/nas" = lib.mkForce {
    device = "//100.81.106.40/storage";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.secrets."nas-credentials".path}"
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
    sops
    age
    stdenv.cc.cc.lib
  ];

  # Do not change this after the initial install
  system.stateVersion = "26.05";
}
