{
  description = "A basic gomod2nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    gomod2nix,
  }: (
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      haskellPackages = pkgs.haskellPackages.extend (
        pkgs.haskell.lib.compose.packageSourceOverrides {
          haskelicious = ./haskelicious;
        }
      );

      # The current default sdk for macOS fails to compile go projects, so we use a newer one for now.
      # This has no effect on other platforms.
      callPackage = pkgs.darwin.apple_sdk_11_0.callPackage or pkgs.callPackage;

      haskelicious = pkgs.haskellPackages.developPackage {
        root = ./haskelicious;
      };
    in {
      packages = {
        bubbletea-capi = callPackage ./bubbletea-capi {
          inherit (gomod2nix.legacyPackages.${system}) buildGoApplication;
        };
        inherit haskelicious;
      };
      devShells.default = let
        bubbletea-capi-goEnv = gomod2nix.legacyPackages.${system}.mkGoEnv {
          pwd = ./bubbletea-capi;
        };
        haskellShell = haskellPackages.shellFor {
          packages = p: [ p.haskelicious ];
          withHoogle = true;
        };
      in
        pkgs.mkShell {
          inputsFrom = [ haskellShell ];
          packages = [
            bubbletea-capi-goEnv
            pkgs.gopls
            gomod2nix.legacyPackages.${system}.gomod2nix
          ];
        };
    })
  );
}
