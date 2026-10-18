{ lib
, rustPlatform
, pkg-config
, wayland
, libGL
, vulkan-loader
, glslang
, makeWrapper
, src
}:

rustPlatform.buildRustPackage {
  pname = "waywallen-layer-shell";
  version = "0.4.2";

  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [
    pkg-config
    glslang
    makeWrapper
  ];

  buildInputs = [
    wayland
    libGL       # provides egl.pc for build.rs
    vulkan-loader  # provides vulkan.pc for build.rs
  ];

  cargoBuildFlags = [ "--bin" "waywallen-layer-shell" ];
  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/waywallen-layer-shell \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ wayland vulkan-loader libGL ]}
  '';

  meta = with lib; {
    description = "Wayland layer-shell display backend for waywallen";
    homepage = "https://github.com/waywallen/waywallen-display";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "waywallen-layer-shell";
  };
}

