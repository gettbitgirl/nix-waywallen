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
      url = "github:litocpp/rstd/0c755371a02ccee658fa6d63728b6078cb2f9070";
      flake = false;
    };
    lito-dep-zstd = {
      url = "github:facebook/zstd/f8745da6ff1ad1e7bab384bd1f9d742439278e99";
      flake = false;
    };
    lito-src = {
      url = "github:litocpp/lito/v0.8.6";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    open-wallpaper-engine-src = {
      url = "github:waywallen/open-wallpaper-engine/v0.3.0";
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
    owe-dep-spirv-reflect = {
      url = "git+https://github.com/hypengw/SPIRV-Reflect.git?rev=355785128c1b6ba808e3a7d0e344814fe6cff502";
      flake = false;
    };
    owe-dep-vrento = {
      url = "git+https://github.com/vecren/vrento.git?rev=a781859c940325a909c77613b5b2795cc3d65e48";
      flake = false;
    };
    owe-dep-wavsen = {
      url = "git+https://github.com/hypengw/wavsen.git?rev=73be92f4f9db0179e93e3f28d62077a2aed77a8e";
      flake = false;
    };
    waywallen-dep-luato = {
      url = "git+https://github.com/litocpp/luato.git?rev=df0c6f2d1cce2051b4711d36067619eda7933683";
      flake = false;
    };
    waywallen-dep-ncrequest = {
      url = "git+https://github.com/hypengw/ncrequest.git?rev=40d40224842a080039d2a76710fbedb20ee002ac";
      flake = false;
    };
    waywallen-dep-qextra = {
      url = "git+https://github.com/hypengw/QExtra.git?rev=650cb670c15c2f34a9cf0dedd52447df7b56e761";
      flake = false;
    };
    waywallen-dep-qml-material = {
      url = "git+https://github.com/hypengw/QmlMaterial.git?rev=98b8acd3e0bd57ca0710f2712e4dfa3fcef13113&lfs=1";
      flake = false;
    };
    waywallen-dep-wavsen = {
      url = "git+https://github.com/hypengw/wavsen.git?rev=bd8a72e0f68fabc42f3d123623787398ed28dbe4";
      flake = false;
    };
    waywallen-display-src = {
      url = "github:waywallen/waywallen-display/v0.4.2";
      flake = false;
    };
    waywallen-src = {
      url = "github:waywallen/waywallen/v0.4.4";
      flake = false;
    };
  };
}
