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
      sourcePreference = "wheel";
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
        ]
      );

    env = pythonSet.mkVirtualEnv "caliptra-reg-gen" workspace.deps.default;
  in
    env;
in
  mkEnv python313
