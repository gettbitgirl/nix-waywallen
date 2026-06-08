{
  description = "waywallen - Rust daemon + Qt/QML UI + renderer plugins";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Upstream sources — tracked at latest default-branch commit.
    # Pin is recorded in flake.lock; run `nix flake update` to advance.
    waywallen-src = {
      url = "github:waywallen/waywallen";
      flake = false;
    };
    waywallen-display-src = {
      url = "github:waywallen/waywallen-display";
      flake = false;
    };
    open-wallpaper-engine-src = {
      url = "github:waywallen/open-wallpaper-engine";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    waywallen-src,
    waywallen-display-src,
    open-wallpaper-engine-src,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});

    # Parse deps.json from waywallen-src
    depsJson = builtins.fromJSON (builtins.readFile "${waywallen-src}/deps.json");

    # Helper to resolve sub-dependencies dynamically from deps.json
    fetchDepFor = pkgs: name: let
      match = builtins.filter (d: d.x-cmake.name or "" == name) depsJson;
    in
      if builtins.length match > 0
      then let
        dep = builtins.head match;
      in
        if name == "qml_material"
        then
          # qml_material ships LFS assets (icon font woff2); must use
          # pkgs.fetchgit with fetchLFS = true. Hash must match the commit
          # in deps.json — update it when deps.json bumps qml_material.
          pkgs.fetchgit {
            url = dep.url;
            rev = dep.commit;
            hash = "sha256-iygNy9PvQpK0/PoHCNOjMYNNn19YMSWFSaVakFK3XQI=";
            fetchLFS = true;
          }
        else
          builtins.fetchGit {
            url = dep.url;
            rev = dep.commit;
            allRefs = true;
          }
      else throw "Dependency ${name} not found in deps.json";
  in {
    packages = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
        fetchDep = fetchDepFor pkgs;
        waywallen-daemon = pkgs.callPackage ./pkgs/waywallen-daemon.nix {src = waywallen-src;};
        waywallen-ui = pkgs.callPackage ./pkgs/waywallen-ui.nix {
          src = waywallen-src;
          rstd-src = fetchDep "rstd";
          ncrequest-src = fetchDep "ncrequest";
          wavsen-src = fetchDep "wavsen";
          qml_material-src = fetchDep "qml_material";
          QExtra-src = fetchDep "QExtra";
          asio-src = fetchDep "asio";
          pegtl-src = fetchDep "pegtl";
        };
        waywallen-plugins = pkgs.callPackage ./pkgs/waywallen-plugins.nix {
          src = waywallen-src;
          rstd-src = fetchDep "rstd";
          wavsen-src = fetchDep "wavsen";
        };
        waywallen-layer-shell = pkgs.callPackage ./pkgs/waywallen-layer-shell.nix {src = waywallen-display-src;};
        waywallen-kde = pkgs.callPackage ./pkgs/waywallen-kde.nix {src = waywallen-display-src;};
        waywallen-gnome = pkgs.callPackage ./pkgs/waywallen-gnome.nix {src = waywallen-display-src;};
      in rec {
        inherit waywallen-daemon waywallen-ui waywallen-plugins waywallen-layer-shell waywallen-kde waywallen-gnome;

        waywallen-open-wallpaper-engine = pkgs.callPackage ./pkgs/waywallen-open-wallpaper-engine.nix {
          inherit waywallen-plugins;
          src = open-wallpaper-engine-src;
        };

        # Combined package: daemon + renderer plugins + ui + owe
        # in a single store path, suitable for `nix profile install`.
        waywallen = pkgs.symlinkJoin {
          name = "waywallen-${waywallen-daemon.version}";
          paths = [waywallen-daemon waywallen-plugins waywallen-open-wallpaper-engine waywallen-ui];
          nativeBuildInputs = [pkgs.makeWrapper];
          postBuild = ''
            wrapProgram $out/bin/waywallen \
              --add-flags "--ui $out/bin/waywallen-ui --plugin $out/bin"
          '';
          meta =
            waywallen-daemon.meta
            // {
              description = "waywallen - daemon, renderer plugins, open-wallpaper-engine and UI";
            };
        };

        default = self.packages.${system}.waywallen;
      }
    );

    overlays.default = final: prev: let
      fetchDep = fetchDepFor final;
    in {
      waywallen-daemon = final.callPackage ./pkgs/waywallen-daemon.nix {src = waywallen-src;};
      waywallen-ui = final.callPackage ./pkgs/waywallen-ui.nix {
        src = waywallen-src;
        rstd-src = fetchDep "rstd";
        ncrequest-src = fetchDep "ncrequest";
        wavsen-src = fetchDep "wavsen";
        qml_material-src = fetchDep "qml_material";
        QExtra-src = fetchDep "QExtra";
        asio-src = fetchDep "asio";
        pegtl-src = fetchDep "pegtl";
      };
      waywallen-plugins = final.callPackage ./pkgs/waywallen-plugins.nix {
        src = waywallen-src;
        rstd-src = fetchDep "rstd";
        wavsen-src = fetchDep "wavsen";
      };
      waywallen-layer-shell = final.callPackage ./pkgs/waywallen-layer-shell.nix {src = waywallen-display-src;};
      waywallen-kde = final.callPackage ./pkgs/waywallen-kde.nix {src = waywallen-display-src;};
      waywallen-gnome = final.callPackage ./pkgs/waywallen-gnome.nix {src = waywallen-display-src;};
      waywallen-open-wallpaper-engine = final.callPackage ./pkgs/waywallen-open-wallpaper-engine.nix {
        waywallen-plugins = final.waywallen-plugins;
        src = open-wallpaper-engine-src;
      };
      waywallen = final.symlinkJoin {
        name = "waywallen-${final.waywallen-daemon.version}";
        paths = [final.waywallen-daemon final.waywallen-plugins final.waywallen-open-wallpaper-engine final.waywallen-ui];
        nativeBuildInputs = [final.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/waywallen \
            --add-flags "--ui $out/bin/waywallen-ui --plugin $out/bin"
        '';
        meta =
          final.waywallen-daemon.meta
          // {
            description = "waywallen - daemon, renderer plugins, open-wallpaper-engine and UI";
          };
      };
    };
  };
}
