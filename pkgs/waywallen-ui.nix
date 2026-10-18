{
  lib,
  stdenv,
  callPackage,
  symlinkJoin,
  llvmPackages_22,
  lito,
  pkg-config,
  cmake,
  ninja,
  protobuf,
  qt6,
  glslang,
  libpulseaudio,
  ffmpeg,
  libva,
  waywallen-src,
}:
let
  mkLitoBundle = callPackage ./mk-lito-bundle.nix { };
  bundleInfo = mkLitoBundle {
    lockFile = "${waywallen-src}/lito.lock";
    inherit (stdenv.hostPlatform) system;
  };

  qt6Env = symlinkJoin {
    name = "qt6-unified-env";
    paths = [
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtwebsockets
      qt6.qtgrpc
      qt6.qttools
      protobuf
    ];
  };
in
stdenv.mkDerivation {
  pname = "waywallen-ui";
  version = "0.4.4";

  src = waywallen-src;

  nativeBuildInputs = [
    lito
    llvmPackages_22.clang
    llvmPackages_22.bintools
    pkg-config
    cmake
    ninja
    protobuf
    glslang
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtgrpc
    qt6.qtwebsockets
    qt6.qtwayland
    protobuf
    ffmpeg
    libva
    libpulseaudio
  ];

  hardeningDisable = [ "fortify" ];

  postPatch = ''
    substituteInPlace lito.toml \
      --replace-fail '[workspace.external-sources.waywallen-rust]
path = "."

[workspace.external-dependencies.cargo.waywallen-daemon]
source = "waywallen-rust"
package = "waywallen"' ""

    substituteInPlace ui/lito.toml \
      --replace-fail '[external-dependencies.cargo.waywallen-daemon]
workspace = true
usage = "runtime"' ""

    substituteInPlace ui/install.lua \
      --replace-fail '  external_assets = {
    {
      dependency = "waywallen-daemon",
      set = "waywallen",
      destination = "bin",
    },
  },' ""
  '';

  configurePhase = ''
    runHook preConfigure
    rm -rf build
    export HOME=$(mktemp -d)
    export XDG_DATA_HOME=$(mktemp -d)
    export LITO_ALLOWED_ROOTS="/nix/store"

    mkdir -p .lito
    cat << 'EOF' > .lito/config.toml
${bundleInfo.configToml}

[tools.cmake]
search-path = ["${qt6Env}"]
EOF
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    lito build \
      -p waywallen-ui \
      --profile release \
      --offline \
      --source-bundle ${bundleInfo.sourceBundle} \
      --use-env-flags
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    lito install \
      -p waywallen-ui \
      --prefix $out \
      --profile release \
      --offline \
      --source-bundle ${bundleInfo.sourceBundle} \
      --use-env-flags
    runHook postInstall
  '';

  qtWrapperArgs = [
    "--prefix NIXPKGS_QT6_QML_IMPORT_PATH : ${placeholder "out"}/lib/qt6/qml"
    "--prefix QML_IMPORT_PATH : ${placeholder "out"}/lib/qt6/qml"
    "--prefix QML2_IMPORT_PATH : ${placeholder "out"}/lib/qt6/qml"
  ];

  meta = with lib; {
    description = "Qt/QML UI component of waywallen";
    homepage = "https://github.com/waywallen/waywallen";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "waywallen-ui";
  };
}
