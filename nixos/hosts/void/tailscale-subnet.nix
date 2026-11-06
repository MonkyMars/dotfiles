# ~/dotfiles/nixos/tailscale-subnet.nix
{ config, pkgs, lib, ... }:

{
  services.tailscale = {
    enable = true;
    # Enables IP forwarding and the firewall settings a subnet router needs
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-routes=192.168.178.0/24" ];
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
