# Nix Waywallen

This repository contains a Nix Flake that packages [Waywallen](https://github.com/waywallen/waywallen) and its associated components, plugins, and display extensions.

## Packages Available

This flake exports the following packages:

- **`waywallen-daemon`**: The core Rust daemon for Waywallen.
- **`waywallen-ui`**: The Qt/QML graphical user interface.
- **`waywallen-plugins`**: Renderer plugins (image, video) for Waywallen.
- **`waywallen-wlroots`**: The Wayland layer-shell display backend.
- **`waywallen-open-wallpaper-engine`**: An open wallpaper engine plugin.
- **`waywallen-kde`**: KDE Plasma plugin for the Waywallen display.
- **`waywallen-gnome`**: GNOME Shell extension for the Waywallen display.
- **`waywallen`**: A combined package that symlink-joins the daemon, renderer plugins, the open wallpaper engine plugin, and the UI into a single, easy-to-install package.

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
