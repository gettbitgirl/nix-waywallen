{
  config,
  lib,
  ...
}@args:
let
  inputs = args.inputs or { };
  litoDeps = import ./pkgs/lito-deps.nix { inherit lib; };

  # Global toggle: set to true to build default packages with native Nixpkgs dependencies (e.g. zstd, glslang, eigen),
  # or false to build with bundled Lito git/archive inputs.
  useNixpkgsDeps = false;

  releases =
    if builtins.pathExists ./releases.json then
      builtins.fromJSON (builtins.readFile ./releases.json)
    else
      {
        waywallen = "v0.5.0";
        waywallen-display = "v0.4.3";
        open-wallpaper-engine = "v0.3.1";
        lito = "v0.8.7";
      };

  waywallenSrc =
    inputs.waywallen-src or (builtins.fetchTree "github:waywallen/waywallen/${releases.waywallen}");

  oweSrc =
    inputs.open-wallpaper-engine-src or (builtins.fetchTree "github:waywallen/open-wallpaper-engine/${releases.open-wallpaper-engine}");

  litoSrc =
    inputs.lito-src or (builtins.fetchTree "github:litocpp/lito/${releases.lito}");

  waywallenInputs = litoDeps.extractLockInputs {
    lockFile = "${waywallenSrc}/lito.lock";
    prefix = "waywallen-dep";
  };

  waywallenCargoInputs = litoDeps.extractCargoLockInputs {
    lockFile = "${waywallenSrc}/Cargo.lock";
    prefix = "waywallen-cargo";
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
        url = "github:litocpp/lito/${releases.lito}";
        flake = false;
      };

      waywallen-src = {
        url = "github:waywallen/waywallen/${releases.waywallen}";
        flake = false;
      };
      waywallen-display-src = {
        url = "github:waywallen/waywallen-display/${releases.waywallen-display}";
        flake = false;
      };
      open-wallpaper-engine-src = {
        url = "github:waywallen/open-wallpaper-engine/${releases.open-wallpaper-engine}";
        flake = false;
      };
    }
    // litoInputs
    // waywallenInputs
    // waywallenCargoInputs
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
          updateScript = pkgs.writeShellApplication {
            name = "write-flake";
            runtimeInputs = [
              pkgs.curl
              pkgs.jq
              pkgs.nix
              pkgs.git
            ];
            text = ''
              echo "==> Fetching latest official release tags from GitHub API..."

              fetch_tag() {
                local repo="$1"
                curl -sSL "https://api.github.com/repos/''${repo}/releases/latest" | jq -er .tag_name
              }

              WAYWALLEN_TAG=$(fetch_tag "waywallen/waywallen" || echo "")
              DISPLAY_TAG=$(fetch_tag "waywallen/waywallen-display" || echo "")
              OWE_TAG=$(fetch_tag "waywallen/open-wallpaper-engine" || echo "")
              LITO_TAG=$(fetch_tag "litocpp/lito" || echo "")

              if [ -n "$WAYWALLEN_TAG" ] && [ -n "$DISPLAY_TAG" ] && [ -n "$OWE_TAG" ] && [ -n "$LITO_TAG" ]; then
                jq -n \
                  --arg waywallen "$WAYWALLEN_TAG" \
                  --arg waywallen_display "$DISPLAY_TAG" \
                  --arg owe "$OWE_TAG" \
                  --arg lito "$LITO_TAG" \
                  '{
                    "waywallen": $waywallen,
                    "waywallen-display": $waywallen_display,
                    "open-wallpaper-engine": $owe,
                    "lito": $lito
                  }' > releases.json
                echo "==> Latest releases saved to releases.json:"
                cat releases.json
              else
                echo "==> Warning: Could not reach GitHub API or parse latest releases. Using existing releases.json."
              fi

              echo "==> Generating flake.nix..."
              ${config.flake-file.apps.write-flake pkgs}/bin/write-flake

              echo "==> Updating flake lock..."
              nix flake lock
            '';
          };
        in
        {
          write-flake = {
            type = "app";
            program = "${updateScript}/bin/write-flake";
            meta.description = "Fetch latest official releases, generate flake.nix, and lock inputs";
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};

          buildSet =
            useNixpkgsDeps:
            let
              litoPkg = pkgs.callPackage ./pkgs/lito.nix {
                src = flakeInputs.lito-src;
                rstdSrc = flakeInputs.lito-dep-rstd;
                luatoSrc = flakeInputs.lito-dep-luato;
                licryptoSrc = flakeInputs.lito-dep-licrypto;
                zstdSrc = flakeInputs.lito-dep-zstd;
                luaSrc = flakeInputs.lito-dep-lua;
                inherit useNixpkgsDeps;
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
                overrides = lib.optionalAttrs useNixpkgsDeps {
                  glslang = pkgs.glslang;
                };
              };

              waywallenCargoOutputHashes = litoDeps.resolveCargoOutputHashes {
                lockFile = "${flakeInputs.waywallen-src}/Cargo.lock";
                prefix = "waywallen-cargo";
                inputs = flakeInputs;
              };

              waywallen = pkgs.callPackage ./pkgs/waywallen.nix {
                lito = litoPkg;
                src = flakeInputs.waywallen-src;
                gitDeps = waywallenGitDeps;
                cargoOutputHashes = waywallenCargoOutputHashes;
                inherit useNixpkgsDeps;
              };

              waywallen-open-wallpaper-engine = pkgs.callPackage ./pkgs/waywallen-open-wallpaper-engine.nix {
                lito = litoPkg;
                waywallen-plugins = waywallen;
                src = flakeInputs.open-wallpaper-engine-src;
                gitDeps = oweGitDeps;
                inherit useNixpkgsDeps;
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
            };

          selected = buildSet useNixpkgsDeps;
          nixpkgsVariant = buildSet true;
          bundledVariant = buildSet false;
        in
        selected
        // {
          # Explicit variants for convenience
          waywallen-nixpkgs = nixpkgsVariant.waywallen;
          waywallen-bundled = bundledVariant.waywallen;
          waywallen-open-wallpaper-engine-nixpkgs = nixpkgsVariant.waywallen-open-wallpaper-engine;
          waywallen-open-wallpaper-engine-bundled = bundledVariant.waywallen-open-wallpaper-engine;
          lito-nixpkgs = nixpkgsVariant.lito;
          lito-bundled = bundledVariant.lito;

          # Aliases for backwards compatibility
          waywallen-daemon = selected.waywallen;
          waywallen-ui = selected.waywallen;
          waywallen-plugins = selected.waywallen;

          default = selected.waywallen;
        }
      );
    };
}
