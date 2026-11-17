{ config, pkgs,... }:

{
  imports = [
    ./hardware-configuration.nix
#    ./sunshine-headless.nix
  ];

  environment.systemPackages = [ pkgs.sbctl pkgs.ddcutil ];

  systemd.services.wol-enp10s0 = {
    description = "Enable Wake-on-LAN on enp10s0";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp10s0 wol g";
    };
  };

  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";   # loads i2c-piix4 for AMD boards (7800X3D)
  };

  systemd.services.rgb-off = {
    description = "Turn off all RGB";
    wantedBy = [ "multi-user.target" "post-resume.target" ];
    after = [ "openrgb.service" "post-resume.target" ];
    requires = [ "openrgb.service" ];
    serviceConfig = let
      openrgb = "${config.services.hardware.openrgb.package}/bin/openrgb";
    in {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
      ExecStart = [
        "${openrgb} --device 0 --mode static --color 000000"
        "${openrgb} --device 1 --zone 0 --size 30 --zone 1 --size 30 --mode direct --color 000000"
      ];
    };
  };

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
