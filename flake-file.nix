{
  config,
  lib,
  ...
}@args:
let
  inputs = args.inputs or { };
  litoDeps = import ./pkgs/lito-deps.nix { inherit lib; };

  waywallenSrc =
    inputs.waywallen-src or (builtins.fetchTree {
      type = "github";
      owner = "waywallen";
      repo = "waywallen";
      ref = "v0.4.4";
    });

  oweSrc =
    inputs.open-wallpaper-engine-src or (builtins.fetchTree {
      type = "github";
      owner = "waywallen";
      repo = "open-wallpaper-engine";
      ref = "v0.3.0";
    });

  litoSrc =
    inputs.lito-src or (builtins.fetchTree {
      type = "github";
      owner = "litocpp";
      repo = "lito";
      ref = "v0.8.6";
    });

  waywallenInputs = litoDeps.extractLockInputs {
    lockFile = "${waywallenSrc}/lito.lock";
    prefix = "waywallen-dep";
  };

  oweInputs = litoDeps.extractLockInputs {
    lockFile = "${oweSrc}/lito.lock";
    prefix = "owe-dep";
  };

  litoInputs = litoDeps.extractCompilerInputs {
    inherit litoSrc;
    prefix = "lito-dep";
  };
in
{
  flake-file.description = "waywallen - Rust daemon + display backends + renderer plugins";
  flake-file.outputs = "flake-module";

  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      flake-file.url = "github:denful/flake-file";

      lito-src = {
        url = "github:litocpp/lito/v0.8.6";
        flake = false;
      };

      waywallen-src = {
        url = "github:waywallen/waywallen/v0.4.4";
        flake = false;
      };
      waywallen-display-src = {
        url = "github:waywallen/waywallen-display/v0.4.2";
        flake = false;
      };
      open-wallpaper-engine-src = {
        url = "github:waywallen/open-wallpaper-engine/v0.3.0";
        flake = false;
      };
    }
    // litoInputs
    // waywallenInputs
    // oweInputs;

  outputs =
    flakeInputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = flakeInputs.nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import flakeInputs.nixpkgs { inherit system; });
    in
    {
      homeManagerModules = {
        default =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          import ./modules/home-manager.nix {
            inherit
              config
              lib
              pkgs
              ;
            self = flakeInputs.self;
          };
        waywallen = flakeInputs.self.homeManagerModules.default;
      };

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          write-flake = {
            type = "app";
            program = "${config.flake-file.apps.write-flake pkgs}/bin/write-flake";
            meta.description = "Generate flake.nix and lock inputs from flake-file.nix";
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};

          litoPkg = pkgs.callPackage ./pkgs/lito.nix {
            src = flakeInputs.lito-src;
            rstdSrc = flakeInputs.lito-dep-rstd;
            luatoSrc = flakeInputs.lito-dep-luato;
            licryptoSrc = flakeInputs.lito-dep-licrypto;
            zstdSrc = flakeInputs.lito-dep-zstd;
            luaSrc = flakeInputs.lito-dep-lua;
          };

          waywallenGitDeps = litoDeps.resolveGitDeps {
            lockFile = "${flakeInputs.waywallen-src}/lito.lock";
            prefix = "waywallen-dep";
            inputs = flakeInputs;
          };

          oweGitDeps = litoDeps.resolveGitDeps {
            lockFile = "${flakeInputs.open-wallpaper-engine-src}/lito.lock";
            prefix = "owe-dep";
            inputs = flakeInputs;
          };

          waywallen = pkgs.callPackage ./pkgs/waywallen.nix {
            lito = litoPkg;
            src = flakeInputs.waywallen-src;
            gitDeps = waywallenGitDeps;
          };

          waywallen-open-wallpaper-engine = pkgs.callPackage ./pkgs/waywallen-open-wallpaper-engine.nix {
            lito = litoPkg;
            waywallen-plugins = waywallen;
            src = flakeInputs.open-wallpaper-engine-src;
            gitDeps = oweGitDeps;
          };

          waywallen-layer-shell = pkgs.callPackage ./pkgs/waywallen-layer-shell.nix {
            src = flakeInputs.waywallen-display-src;
          };

          waywallen-kde = pkgs.callPackage ./pkgs/waywallen-kde.nix {
            src = flakeInputs.waywallen-display-src;
          };

          waywallen-gnome = pkgs.callPackage ./pkgs/waywallen-gnome.nix {
            src = flakeInputs.waywallen-display-src;
          };
        in
        {
          inherit
            waywallen
            waywallen-open-wallpaper-engine
            waywallen-layer-shell
            waywallen-kde
            waywallen-gnome
            ;

          lito = litoPkg;

          # Aliases for backwards compatibility
          waywallen-daemon = waywallen;
          waywallen-ui = waywallen;
          waywallen-plugins = waywallen;

          default = waywallen;
        }
      );
    };
}
