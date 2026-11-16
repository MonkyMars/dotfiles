{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    serein = {
      url = "github:ViceVerse-cz/Serein";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zapfast = {
      url = "github:crmne/zapfast";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia.url = "github:noctalia-dev/noctalia";

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent.url = "github:NousResearch/hermes-agent";

    # CachyOS kernel
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Declarative Flatpaks
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };

  outputs = inputs@{
    nixpkgs,
    home-manager,
    sops-nix,
    nix-index-database,
    helium,
    noctalia,
    noctalia-greeter,
    hermes-agent,
    nix-cachyos-kernel,
    nix-flatpak,
    zapfast,
    ...
  }:

  let
    mkHost = name: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./configuration.nix
        ./hosts/${name}

        sops-nix.nixosModules.sops
        nix-index-database.nixosModules.nix-index

        noctalia-greeter.nixosModules.default

        nix-flatpak.nixosModules.nix-flatpak
        ./apps/flatpak.nix

        # CachyOS kernel
        ({ pkgs, ... }: {
          nixpkgs.overlays = [
            nix-cachyos-kernel.overlays.pinned
          ];

          boot.kernelPackages =
            pkgs.cachyosKernels.linuxPackages-cachyos-latest-zen4;
        })

        # micro:bit v2 udev rules
        ({ pkgs, ... }: {
          services.udev.packages = [
            pkgs.openocd
            (pkgs.writeTextFile {
              name = "microbit-udev-rules";
              destination = "/etc/udev/rules.d/60-microbit.rules";
              text = ''
                SUBSYSTEM=="usb", ATTRS{idVendor}=="0d28", ATTRS{idProduct}=="0204", MODE="0660", TAG+="uaccess"
                SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0d28", ATTRS{idProduct}=="0204", MODE="0660", TAG+="uaccess"
              '';
            })
          ];
        })

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";

          # Pass all flake inputs to Home Manager
          home-manager.extraSpecialArgs = {
            inherit inputs;
          };

          home-manager.users.monky = {
            imports = [
              ./home.nix
              helium.homeModules.default
              noctalia.homeModules.default
              hermes-agent.homeManagerModules.default
              zapfast.homeManagerModules.default
            ];
          };
        }
      ];
    };
  in
  {
    nixosConfigurations = {
      void = mkHost "void";
      monkylaptop = mkHost "monkylaptop";
    };
  };
}
