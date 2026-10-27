{ lib
, rustPlatform
, pkg-config
, protobuf
, sqlite
, libGL
, vulkan-loader
, wayland
, libgbm
, libxkbcommon
, libpulseaudio
, ffmpeg
, makeWrapper
, src
, cargoOutputHashes ? { }
}:

rustPlatform.buildRustPackage {
  pname = "waywallen-daemon";
  version = (builtins.fromTOML (builtins.readFile "${src}/lito.toml")).workspace.package.version;

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = cargoOutputHashes;
  };

  nativeBuildInputs = [
    pkg-config
    protobuf
    makeWrapper
  ];

  buildInputs = [
    sqlite
    libGL
    vulkan-loader
    wayland
    libgbm
    libxkbcommon
    libpulseaudio
    ffmpeg
  ];

  cargoBuildFlags = [ "-p" "waywallen" ];
  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/waywallen \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL vulkan-loader wayland libgbm libxkbcommon libpulseaudio ffmpeg ]}
    wrapProgram $out/bin/waywallen_renderer \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL vulkan-loader wayland libgbm libxkbcommon libpulseaudio ffmpeg ]}
  '';

  meta = with lib; {
    description = "Rust daemon component of waywallen";
    homepage = "https://github.com/waywallen/waywallen";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "waywallen";
  };
}

