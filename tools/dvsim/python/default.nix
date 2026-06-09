# Copyright lowRISC Contributors.
# Licensed under the MIT License, see LICENSE for details.
# SPDX-License-Identifier: MIT
{
  inputs,
  pkgs,
  python313,
  lib,
  ...
}: let
  mkEnv = python: let
    workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
      workspaceRoot = ./.;
    };
    overlay = workspace.mkPyprojectOverlay {
      sourcePreference = "sdist";
    };

    pythonSet =
      (pkgs.callPackage inputs.pyproject-nix.build.packages {
        inherit python;
      })
          .overrideScope
      (
        lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.default
          overlay
          (import ./pyprojectOverrides.nix {inherit pkgs;})
          # (inputs.uv2nix_hammer_overrides.overrides pkgs)
        ]
      );

    env = pythonSet.mkVirtualEnv "caliptra-dvsim" workspace.deps.default;
  in
    env;
in
  mkEnv python313
