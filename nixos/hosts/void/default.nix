{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    #./sunshine-headless.nix
  ];

  networking.hostName = "void";

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
}
