{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "monkylaptop";

  boot.loader.limine.maxGenerations = lib.mkForce 2;

  # Enable it :D
  services.power-profiles-daemon.enable = true;

  services.fwupd.enable = true;
  services.fstrim.enable = true;

  networking.networkmanager.wifi.powersave = true;

  fileSystems."/mnt/nas" =
    { device = "fedora:/";
      fsType = "nfs";
      options = [ "nofail" "x-systemd.automount" "x-systemd.requires=network-online.target" "hard" "timeo=60" "retrans=3" ];
    };

  boot.loader.limine.extraEntries = ''
    /Windows
        protocol: efi
        path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
  '';
}
