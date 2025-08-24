# flake.nix
{
  description = "Dev environment for core tech";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        tools = [
          pkgs.ansible
          pkgs.awscli2
          pkgs.google-cloud-sdk
        ];
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = tools;
        };
        packages.default = pkgs.buildEnv {
          name = "core-tech-env";
          paths = tools;
        };
      }
    );
}
