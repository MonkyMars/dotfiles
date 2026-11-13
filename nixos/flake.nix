{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
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

    hermes-agent.url = "github:NousResearch/hermes-agent";

    # CachyOS kernel
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Declarative Flatpaks
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };

  outputs = {
    nixpkgs,
    home-manager,
    sops-nix,
    nix-index-database,
    helium,
    noctalia,
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

        # Declarative Flatpaks
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

        # udev rules for the micro:bit v2 (DAPLink, 0d28:0204) so OpenOCD can
        # open it as a normal user. Shipped as its own 60-* rules file because
        # uaccess tags must be set before 73-seat-late.rules (extraRules lands
        # in 99-local.rules, which is too late).
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
