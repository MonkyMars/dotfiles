# ~/dotfiles/nixos/hosts/void/sunshine-headless.nix
{ ... }:

let
  # Unused HDMI port on the 9070 XT (card1)
  virtualConnector = "HDMI-A-2";
in
{
  # Fake 2048x1280 monitor matching the laptop panel.
  hardware.display = {
    edid = {
      enable = true;
      # CVT reduced blanking, 2048x1280 @ ~119.99 Hz
      # (name must be 12 characters or less)
      modelines."V_2048_120" =
        "359.00 2048 2096 2128 2208 1280 1283 1289 1355 +hsync -vsync";
    };
    outputs.${virtualConnector} = {
      edid = "V_2048_120.bin";
      mode = "e"; # force-enable even with nothing plugged in
    };
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;   # harmless to keep; only KMS capture needs it
    openFirewall = false; # only reachable through Tailscale
    # Declared settings make the web UI's config read-only;
    # delete this block if you'd rather manage it in the UI.
    settings = {
      capture = "wlr";               # niri screencopy: no capabilities, no portal dialog
      origin_web_ui_allowed = "wan"; # accept the web UI from Tailscale's 100.x addresses
      # Must match the browser's address bar exactly (scheme + host + port)
      csrf_allowed_origins = "https://void:47990";
    };
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
