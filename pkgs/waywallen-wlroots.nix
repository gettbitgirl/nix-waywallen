{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  protobuf,
  sqlite,
  libGL,
  vulkan-loader,
  wayland,
  libgbm,
  libxkbcommon,
  makeWrapper,
}:
rustPlatform.buildRustPackage {
  pname = "waywallen-layer-shell";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "waywallen";
    repo = "waywallen";
    rev = "v0.1.8";
    sha256 = "0368i58ynv3r61yi16vm78r4qmr93jwc779hzrd72csj6pv9kibl";
  };

  cargoHash = "sha256-1GrQPRVQCheI7YOjMi8iDE4nTrq423+THUd16Eb6A1M=";

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
  ];

  # Build only this binary; the `waywallen` lib crate is a workspace path dep
  # so it is compiled as a dependency automatically without separate fetching.
  cargoBuildFlags = ["-p" "waywallen-display-layer-shell"];
  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/waywallen-display-layer-shell \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libGL vulkan-loader wayland libgbm libxkbcommon]}
  '';

  meta = with lib; {
    description = "Wayland layer-shell display backend for waywallen";
    homepage = "https://github.com/waywallen/waywallen";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
