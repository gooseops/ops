{
  description = "Dev environment for core tech";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        tools = with pkgs; [
          ansible
          awscli2
          google-cloud-sdk
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
