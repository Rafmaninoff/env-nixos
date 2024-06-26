{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    #pinned to a specific commit to fix amdgpu issue, should be reverted after it is fixed

    nixpkgs-floorp-unfuck.url = "github:nixos/nixpkgs/3f316d2a50699a78afe5e77ca486ad553169061e";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    #home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # TODO: Add any other flake you might need
    nixos-hardware.url = "github:nixos/nixos-hardware";
    rust-overlay.url = "github:oxalica/rust-overlay";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";


    arrpc = {
      url = "github:notashelf/arrpc-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs =
    { self, nixpkgs, chaotic, home-manager, nixos-hardware, rust-overlay, ... }@inputs:
    let inherit (self) outputs;
      overlays = [
        rust-overlay.overlays.default
      ];
      pkgs-unfuck = inputs.nixpkgs-floorp-unfuck.legacyPackages."x86_64-linux";
    in
    {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        "nixos-raf" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          # > Our main nixos configuration file <
          modules = [
            ./nixos/configuration.nix
            chaotic.nixosModules.default
            ({ pkgs, ... }: {
              nixpkgs.overlays = overlays;
            })
          ];
          specialArgs = {
            inherit pkgs-unfuck;
          };
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        "raf@nixos-raf" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          # > Our main home-manager configuration file <
          modules = [
            ./home-manager/home.nix
            ({ pkgs, ... }: {
              nixpkgs.overlays = overlays;
            })
          ];
        };
      };
    };
}
