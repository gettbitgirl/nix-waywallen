{ config, lib, pkgs, self ? null, ... }:

let
  cfg = config.programs.waywallen;
  flakePkgs =
    if self != null then
      (self.packages.${pkgs.stdenv.hostPlatform.system} or self.packages.${pkgs.system})
    else
      pkgs;
  finalPackage =
    if cfg.plugins == [ ] then
      cfg.package
    else
      pkgs.symlinkJoin {
        name = "${cfg.package.name or "waywallen"}-with-plugins";
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/waywallen \
            ${lib.concatMapStringsSep " " (p: "--add-flags \"--plugin ${p}/share/waywallen\"") cfg.plugins}
        '';
      };
in
{
  options.programs.waywallen = {
    enable = lib.mkEnableOption "Waywallen wallpaper manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = flakePkgs.waywallen;
      defaultText = lib.literalExpression "flakePkgs.waywallen";
      description = "The Waywallen unified package (daemon, UI, and core plugins).";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      defaultText = lib.literalExpression "[ ]";
      description = "List of additional plugin packages (e.g. open-wallpaper-engine). Core plugins are already included in package.";
    };

    displayBackend = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "layer-shell" "kde" "gnome" ]);
      default = "layer-shell";
      description = ''
        Display backend to integrate with the desktop environment / window manager:
        - "layer-shell": Adds waywallen-layer-shell to home.packages (for wlroots/Niri/Hyprland/Sway).
        - "kde": Adds the KDE Plasma wallpaper plugin to home.packages.
        - "gnome": Adds the GNOME Shell extension to home.packages.
        - null: Manual or no display backend managed by this module.
      '';
    };

    layerShellPackage = lib.mkOption {
      type = lib.types.package;
      default = flakePkgs.waywallen-layer-shell;
      defaultText = lib.literalExpression "flakePkgs.waywallen-layer-shell";
      description = "The Waywallen layer-shell display backend package.";
    };

    kdePackage = lib.mkOption {
      type = lib.types.package;
      default = flakePkgs.waywallen-kde;
      defaultText = lib.literalExpression "flakePkgs.waywallen-kde";
      description = "The Waywallen KDE Plasma wallpaper plugin package.";
    };

    gnomePackage = lib.mkOption {
      type = lib.types.package;
      default = flakePkgs.waywallen-gnome;
      defaultText = lib.literalExpression "flakePkgs.waywallen-gnome";
      description = "The Waywallen GNOME extension package.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      finalPackage
    ]
    ++ cfg.plugins
    ++ lib.optional (cfg.displayBackend == "layer-shell") cfg.layerShellPackage
    ++ lib.optional (cfg.displayBackend == "kde") cfg.kdePackage
    ++ lib.optional (cfg.displayBackend == "gnome") cfg.gnomePackage;
  };
}
