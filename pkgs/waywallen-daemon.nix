{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, protobuf
, sqlite
, libGL
, vulkan-loader
, wayland
, libgbm
, libxkbcommon
, makeWrapper
}:

rustPlatform.buildRustPackage rec {
  pname = "waywallen-daemon";
  version = "0.1.8";

  src = fetchFromGitHub {
    owner = "waywallen";
    repo = "waywallen";
    rev = "v${version}";
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

  cargoBuildFlags = [ "-p" "waywallen" ];
  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/waywallen \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL vulkan-loader wayland libgbm libxkbcommon ]}
    wrapProgram $out/bin/waywallen_renderer \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL vulkan-loader wayland libgbm libxkbcommon ]}
  '';

  meta = with lib; {
    description = "Rust daemon component of waywallen";
    homepage = "https://github.com/waywallen/waywallen";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
