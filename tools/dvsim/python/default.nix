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
          # Wheel-first (see sourcePreference above): only first-party
          # source-only deps need an override. compile-to-core has no wheel, so
          # it builds from sdist and must declare its PEP 517 backend.
          #
          # The patches/ list also carries local-only fixes against upstream
          # behaviour; drop each entry once the corresponding change lands at
          # github.com/lowRISC/compile-to-core.
          (final: prev: {
            compile-to-core = prev.compile-to-core.overrideAttrs (old: {
              nativeBuildInputs = old.nativeBuildInputs ++ (final.resolveBuildSystem {hatchling = [];});
              patches = (old.patches or []) ++ [
                ./patches/compile-to-core-passthrough-vlnv.patch
              ];
            });
          })
        ]
      );

    env = pythonSet.mkVirtualEnv "caliptra-dvsim" workspace.deps.default;
  in
    env;
in
  mkEnv python313
