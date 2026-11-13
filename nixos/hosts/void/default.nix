{ pkgs,... }:

{
  imports = [
    ./hardware-configuration.nix
    ./sunshine-headless.nix
  ];

  environment.systemPackages = [ pkgs.sbctl ];

  networking.hostName = "void";

  boot.loader.limine.secureBoot.enable = true;
  boot.loader.limine.extraEntries = ''
    /Windows
        protocol: efi
        path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
  '';


  fileSystems."/mnt/data" =
    { device = "/dev/disk/by-uuid/c69bd35b-6fac-41c1-ae48-a35fb11f8ded";
      fsType = "ext4";
      options = [ "nofail" "defaults" ];
    };

  fileSystems."/mnt/nas" =
    { device = "192.168.178.42:/";
      fsType = "nfs";
      options = [ "nofail" "x-systemd.automount" "x-systemd.requires=network-online.target" "hard" "timeo=60" "retrans=3" ];
    };
}
