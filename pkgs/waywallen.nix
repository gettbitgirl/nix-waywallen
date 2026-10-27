{
  lib,
  stdenv,
  callPackage,
  symlinkJoin,
  llvmPackages_22,
  lito,
  rustPlatform,
  cargo,
  rustc,
  pkg-config,
  cmake,
  ninja,
  protobuf,
  glslang,
  qt6,
  makeWrapper,
  vulkan-headers,
  vulkan-loader,
  libGL,
  wayland,
  libgbm,
  libxkbcommon,
  libpulseaudio,
  libva,
  ffmpeg,
  sqlite,
  src,
  gitDeps ? { },
  gitOverrides ? { },
}:
let
  mkLitoBundle = callPackage ./mk-lito-bundle.nix { };
  bundleInfo = mkLitoBundle {
    lockFile = "${src}/lito.lock";
    inherit (stdenv.hostPlatform) system;
    inherit gitDeps gitOverrides;
  };

  qt6Env = symlinkJoin {
    name = "qt6-unified-env";
    paths = [
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtwebsockets
      qt6.qtgrpc
      qt6.qttools
      qt6.qtsvg
      protobuf
    ];
  };
in
stdenv.mkDerivation {
  pname = "waywallen";
  version = "0.4.4";

  inherit src;

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "mlua-extra-0.1.0" = "sha256-Dp8E/4tQHB17CxL5Fpis+gRMkvzR2/Ose13kzLreguQ=";
    };
  };

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    cargo
    rustc
    lito
    llvmPackages_22.clang
    llvmPackages_22.bintools
    pkg-config
    cmake
    ninja
    protobuf
    glslang
    qt6.wrapQtAppsHook
    makeWrapper
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtgrpc
    qt6.qtwebsockets
    qt6.qtwayland
    qt6.qtsvg
    protobuf
    ffmpeg
    libva
    libpulseaudio
    libgbm
    vulkan-headers
    vulkan-loader
    libGL
    wayland
    libxkbcommon
    sqlite
  ];

  hardeningDisable = [ "fortify" ];

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
      -p waywallen-image-plugin \
      -p waywallen-video-plugin \
      --profile release \
      --offline \
      --source-bundle ${bundleInfo.sourceBundle} \
      --use-env-flags
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    lito install \
      -p waywallen-bridge \
      -p waywallen-image-plugin \
      -p waywallen-video-plugin \
      -p waywallen-wallhaven-plugin \
      -p waywallen-ui \
      --prefix $out \
      --profile release \
      --offline \
      --source-bundle ${bundleInfo.sourceBundle} \
      --use-env-flags

    # Wrap daemon with default UI and plugin paths + graphics and audio libraries
    if [ -f $out/bin/waywallen ]; then
      wrapProgram $out/bin/waywallen \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL vulkan-loader wayland libgbm libxkbcommon libpulseaudio ffmpeg ]}
    fi

    if [ -f $out/bin/waywallen_renderer ]; then
      wrapProgram $out/bin/waywallen_renderer \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL vulkan-loader wayland libgbm libxkbcommon libpulseaudio ffmpeg ]}
    fi

    if [ -f $out/bin/waywallen-video-renderer ]; then
      wrapProgram $out/bin/waywallen-video-renderer \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL vulkan-loader libva libpulseaudio ]}
    fi

    if [ -f $out/bin/waywallen-image-renderer ]; then
      wrapProgram $out/bin/waywallen-image-renderer \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL vulkan-loader libva ]}
    fi

    runHook postInstall
  '';

  qtWrapperArgs = [
    "--prefix NIXPKGS_QT6_QML_IMPORT_PATH : ${placeholder "out"}/lib/qt6/qml"
    "--prefix QML_IMPORT_PATH : ${placeholder "out"}/lib/qt6/qml"
    "--prefix QML2_IMPORT_PATH : ${placeholder "out"}/lib/qt6/qml"
  ];

  meta = with lib; {
    description = "Next-generation animated wallpaper manager for Wayland (daemon, UI, and core plugins)";
    homepage = "https://github.com/waywallen/waywallen";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "waywallen";
  };
}
