{
  description = "void - NixOS configuration";

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

    noctalia.url = "github:noctalia-dev/noctalia";

    hermes-agent.url = "github:NousResearch/hermes-agent";

    # CachyOS kernel
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    nix-index-database,
    helium,
    noctalia,
    hermes-agent,
    nix-cachyos-kernel,
    ...
  }: {
    nixosConfigurations.void = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./configuration.nix

        sops-nix.nixosModules.sops
        nix-index-database.nixosModules.nix-index

        # CachyOS kernel
        ({ pkgs, ... }: {
          nixpkgs.overlays = [
            nix-cachyos-kernel.overlays.pinned
          ];

          boot.kernelPackages =
            pkgs.cachyosKernels.linuxPackages-cachyos-latest-zen4;
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
            ];
          };
        }
      ];
    };
  };
}
