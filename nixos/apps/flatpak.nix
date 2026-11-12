{ ... }:

{
  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    packages = [
      "ai.lmstudio.lm-studio"
      "com.spotify.Client"
      "org.jeffvli.feishin"
      "org.triliumnotes.Trilium"
      "org.openrgb.OpenRGB"
    ];

    # Remove Flatpak apps that aren't declared above.
    # Set to false if you want to install things manually too.
    uninstallUnmanaged = true;

    update.onActivation = true;
  };
}
