{description = "Dev environment for core tech";

inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  nixpkgs-unst.url = "github:nixos/nixpkgs/nixos-unstable";
  flake-utils.url = "github:numtide/flake-utils";
};

outputs = { self, nixpkgs, nixpkgs-unst, flake-utils }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      tools = with pkgs; [
        ansible
        ansible-lint
        awscli2
        bash
        doppler
        google-cloud-sdk
        nixfmt-rfc-style
        python3
        terraform
        tflint
      ];
      pkgs-unst = import nixpkgs-unst {
        inherit system;
        config = { allowUnfree = true; };
      };
      tools-unst = with pkgs-unst; [ just ];
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = tools ++ tools-unst;
      };
    }
  );
}
