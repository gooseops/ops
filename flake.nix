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
        jq
        nixfmt-rfc-style
        python3
        shellcheck
        terraform
        tflint
        wireguard-tools
      ];
      pkgs-unst = import nixpkgs-unst {
        inherit system;
        config = { allowUnfree = true; };
      };
      tools-unst = with pkgs-unst; [ just ];
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = tools ++ tools-unst;

        shellHook = ''
          echo "gooseops ops dev shell"

          # Absolute path captured at shell entry — keeps reload-env
          # correct even if the operator cd's elsewhere before invoking it.
          _ops_env_file="$PWD/.envs/.env"

          # Bookkeeping for clean env switching: every time we source
          # _ops_env_file we record the list of variable names it set into
          # _ops_env_keys. The next reload-env first unsets those names,
          # then sources the file fresh, so switching environments doesn't
          # leak stale variables from the previous one.
          _ops_env_keys=""

          # Extract bare variable names from the active env file. Matches
          # lines of the form NAME=value (the format f_setupEnv writes).
          _ops_env_capture_keys() {
            [ -f "$_ops_env_file" ] || return 0
            grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$_ops_env_file" \
              | cut -d= -f1 \
              | tr '\n' ' '
          }

          if [ -f "$_ops_env_file" ]; then
            set -a
            # shellcheck disable=SC1091
            source "$_ops_env_file"
            set +a
            _ops_env_keys=$(_ops_env_capture_keys)
            echo "Active environment: $DOPPLER_CONFIG"
          else
            echo "No active environment — run 'just use <env>' then 'reload-env'."
          fi

          # `just use <env>` updates .envs/.env, but a just recipe runs in
          # a subshell and cannot mutate the parent's env. reload-env
          # unsets the previously-loaded variables and re-sources the file
          # so the new DOPPLER_TOKEN/etc. take effect without exiting and
          # re-entering the shell.
          reload-env() {
            if [ ! -f "$_ops_env_file" ]; then
              echo "No active environment to reload." >&2
              return 1
            fi
            local _v
            for _v in $_ops_env_keys; do
              unset "$_v"
            done
            set -a
            # shellcheck disable=SC1091
            source "$_ops_env_file"
            set +a
            _ops_env_keys=$(_ops_env_capture_keys)
            echo "Reloaded environment: $DOPPLER_CONFIG"
          }

          echo "Run 'just' to see available recipes"
          echo "Run 'reload-env' after switching environments"
        '';
      };
    }
  );
}
