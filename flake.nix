# Copyright lowRISC Contributors.
# Licensed under the MIT License, see LICENSE for details.
# SPDX-License-Identifier: MIT
{
  description = "caliptra-rtl Nix Packages and Environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";

    ##########
    # PYTHON #
    ##########

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };
  };

  outputs = inputs: let
    all_system_outputs = inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
      };
      python_dvsim = pkgs.callPackage ./tools/dvsim/python {inherit inputs;};
      python_reg_gen = pkgs.callPackage ./tools/scripts/python {inherit inputs;};

      # Environment variables derivable from the repo layout.
      # Variables that cannot be auto-set here:
      #   CALIPTRA_WORKSPACE — user-specific parent dir for verilator scratch output
      #   RV_ROOT            — external VeeR-EL2 checkout (not a submodule)
      commonShellHook = ''
        export CALIPTRA_ROOT="$(git rev-parse --show-toplevel)"
        export ADAMSBRIDGE_ROOT="$CALIPTRA_ROOT/submodules/adams-bridge"
      '';
      dvsimShellHook = commonShellHook + ''
        # xmsc/xrun invoke Cadence's bundled gcc, which ignores NIX_CFLAGS_COMPILE / CPATH.
        # Export concrete nix-store paths so dvsim hjson can thread them to xrun as -I/-L.
        export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
        export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
      '';
    in {
      devShells = rec {
        default = caliptra-dvsim;
        caliptra-dvsim = pkgs.mkShell {
          name = "caliptra-dvsim";
          packages = ([
            python_dvsim
          ]) ++ (with pkgs; [
            uv
            # Needed by the AES DPI model's crypto.c (openssl/conf.h etc.); xrun also links -lcrypto.
            openssl
            openssl.dev
          ]);
          shellHook = dvsimShellHook;
        };
        caliptra-reg-gen = pkgs.mkShell {
          name = "caliptra-reg-gen";
          packages = [
            python_reg_gen
          ];
          shellHook = commonShellHook;
        };
      };
    });
  in
    all_system_outputs;
}
