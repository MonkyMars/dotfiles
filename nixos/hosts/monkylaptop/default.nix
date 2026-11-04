{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "monkylaptop";

  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
       governor = "powersave";
       turbo = "never";
    };
    charger = {
       governor = "performance";
       turbo = "auto";
    };
  };

  services.fwupd.enable = true;
  services.fstrim.enable = true;

  networking.networkmanager.wifi.powersave = true;
}
