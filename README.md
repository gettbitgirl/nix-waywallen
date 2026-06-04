# Nix Waywallen

This repository contains a Nix Flake that packages [Waywallen](https://github.com/waywallen/waywallen) and its associated components, plugins, and display extensions.

## Packages Available

This flake exports the following packages:

- **`waywallen`**: The unified, combined package containing the Waywallen daemon, UI, renderer plugins (image, video), and the open wallpaper engine plugin. This is the primary package you should install.
- **`waywallen-layer-shell`**: The Wayland layer-shell display backend.
- **`waywallen-kde`**: KDE Plasma plugin for the Waywallen display.
- **`waywallen-gnome`**: GNOME Shell extension for the Waywallen display.

*(Individual components like `waywallen-daemon`, `waywallen-ui`, and `waywallen-plugins` are also exported for advanced configurations, but most users only need the unified `waywallen` package).*

## Installation

You can add this repository to your flake inputs and use the provided overlay in your NixOS or Home Manager configuration:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  nix-waywallen.url = "github:gettbitgirl/nix-waywallen";
};

outputs = { self, nixpkgs, nix-waywallen, ... }: {
  nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ({ pkgs, ... }: {
        nixpkgs.overlays = [ nix-waywallen.overlays.default ];
        
        environment.systemPackages = with pkgs; [
          waywallen
          waywallen-kde
        ];
      })
      ./configuration.nix
    ];
  };
};
```
