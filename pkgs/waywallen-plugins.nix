{
  lib,
  stdenv,
  llvmPackages_22,
  lito,
  callPackage,
  pkg-config,
  glslang,
  ffmpeg,
  libva,
  libpulseaudio,
  libgbm,
  libglvnd,
  vulkan-headers,
  waywallen-src,
}:
let
  mkLitoBundle = callPackage ./mk-lito-bundle.nix { };
  bundleInfo = mkLitoBundle {
    lockFile = "${waywallen-src}/lito.lock";
    inherit (stdenv.hostPlatform) system;
  };
in
stdenv.mkDerivation {
  pname = "waywallen-plugins";
  version = "0.4.4";

  src = waywallen-src;

  nativeBuildInputs = [
    lito
    llvmPackages_22.clang
    llvmPackages_22.bintools
    pkg-config
    glslang
  ];

  buildInputs = [
    ffmpeg
    libva
    libpulseaudio
    libgbm
    libglvnd
    vulkan-headers
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
EOF
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    lito build \
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
      --prefix $out \
      --profile release \
      --offline \
      --source-bundle ${bundleInfo.sourceBundle} \
      --use-env-flags
    runHook postInstall
  '';

  meta = with lib; {
    description = "Official plugins for Waywallen wallpaper manager";
    homepage = "https://github.com/waywallen/waywallen";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
