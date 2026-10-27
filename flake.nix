# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "waywallen - Rust daemon + display backends + renderer plugins";

  outputs =
    inputs:
    (inputs.nixpkgs.lib.evalModules {
      specialArgs = {
        inherit inputs;
        inherit (inputs) self;
      };
      modules = [
        inputs.flake-file.flakeModules.flake
        ./flake-file.nix
      ];
    }).config.outputs
      inputs;

  inputs = {
    flake-file.url = "github:denful/flake-file";
    lito-dep-licrypto = {
      url = "github:litocpp/licrypto/40da005cbd7faf1328fd29a01cb0c534d6998612";
      flake = false;
    };
    lito-dep-lua = {
      url = "tarball+https://www.lua.org/ftp/lua-5.5.1.tar.gz";
      flake = false;
    };
    lito-dep-luato = {
      url = "github:litocpp/luato/df0c6f2d1cce2051b4711d36067619eda7933683";
      flake = false;
    };
    lito-dep-rstd = {
      url = "github:litocpp/rstd/9cf950ecccb50b480ddeb51b7bcdf3b2141c9d89";
      flake = false;
    };
    lito-dep-zstd = {
      url = "github:facebook/zstd/f8745da6ff1ad1e7bab384bd1f9d742439278e99";
      flake = false;
    };
    lito-src = {
      url = "github:litocpp/lito/v0.8.7";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    open-wallpaper-engine-src = {
      url = "github:waywallen/open-wallpaper-engine/v0.3.1";
      flake = false;
    };
    owe-dep-eigen = {
      url = "git+https://gitlab.com/libeigen/eigen.git?rev=bc3b39870ecb690a623a3f49149a358b95c5781d";
      flake = false;
    };
    owe-dep-glslang = {
      url = "git+https://github.com/KhronosGroup/glslang.git?rev=275822a6261ee689aadb1da5f09a0ec2f058685c";
      flake = false;
    };
    owe-dep-quickjs = {
      url = "git+https://github.com/quickjs-ng/quickjs.git?rev=3c051980ab7e783dfbfb1c70c014ce5e05ecf24c";
      flake = false;
    };
    owe-dep-vectext = {
      url = "git+https://github.com/vecren/vectext.git?rev=d918972da5c08b5afc73b812062e855fce2d847d";
      flake = false;
    };
    owe-dep-vrento = {
      url = "git+https://github.com/vecren/vrento.git?rev=11f19089b51acd71c5e4e9a4248bfc39927c47e4";
      flake = false;
    };
    owe-dep-wavsen = {
      url = "git+https://github.com/hypengw/wavsen.git?rev=756437443d84905a027f115c75ec6ae6b19692e7";
      flake = false;
    };
    waywallen-cargo-mlua-extra = {
      url = "git+https://github.com/hypengw/mlua-extra?rev=e0238375dc8576c2c9f4c679e3fd3cbfd4175a53";
      flake = false;
    };
    waywallen-dep-luato = {
      url = "git+https://github.com/litocpp/luato.git?rev=df0c6f2d1cce2051b4711d36067619eda7933683";
      flake = false;
    };
    waywallen-dep-ncrequest = {
      url = "git+https://github.com/hypengw/ncrequest.git?rev=2ba60ef6321f5e7f5bccc5fe086d2682bcaccf40";
      flake = false;
    };
    waywallen-dep-qextra = {
      url = "git+https://github.com/hypengw/QExtra.git?rev=b3fd790bb4a5c5cf7c0cc0384cc140e78e627609";
      flake = false;
    };
    waywallen-dep-qml-material = {
      url = "git+https://github.com/hypengw/QmlMaterial.git?rev=f1464c52d42732acb1363122b9b1a2360fd505b3&lfs=1";
      flake = false;
    };
    waywallen-dep-wavsen = {
      url = "git+https://github.com/hypengw/wavsen.git?rev=756437443d84905a027f115c75ec6ae6b19692e7";
      flake = false;
    };
    waywallen-display-src = {
      url = "github:waywallen/waywallen-display/v0.4.3";
      flake = false;
    };
    waywallen-src = {
      url = "github:waywallen/waywallen/v0.5.0";
      flake = false;
    };
  };
}
