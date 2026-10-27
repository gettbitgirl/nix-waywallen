{
  lib,
  stdenv,
  callPackage,
  llvmPackages_22,
  lito,
  pkg-config,
  cmake,
  ninja,
  glslang,
  waywallen-plugins,
  freetype,
  lz4,
  fontconfig,
  glfw3,
  vulkan-loader,
  vulkan-headers,
  ffmpeg,
  libpulseaudio,
  libva,
  libgbm,
  libGL,
  expat,
  wayland,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  autoPatchelfHook,
  patchelf,
  makeWrapper,
  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  glib,
  libxkbcommon,
  nspr,
  nss,
  pango,
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
in
stdenv.mkDerivation {
  pname = "waywallen-open-wallpaper-engine";
  version = "0.3.0";

  inherit src;

  nativeBuildInputs = [
    lito
    llvmPackages_22.clang
    llvmPackages_22.bintools
    pkg-config
    cmake
    ninja
    glslang
    autoPatchelfHook
    patchelf
    makeWrapper
  ];

  buildInputs = [
    waywallen-plugins
    freetype
    lz4
    fontconfig
    glfw3
    vulkan-loader
    vulkan-headers
    ffmpeg
    libpulseaudio
    libva
    libgbm
    libGL
    expat
    wayland
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    glib
    libxkbcommon
    nspr
    nss
    pango
  ];

  hardeningDisable = [ "fortify" ];
  NIX_CFLAGS_COMPILE = "-Qunused-arguments -Wno-error=unused-command-line-argument";

  postPatch = ''
    substituteInPlace lito.toml \
      --replace-fail 'config-directory = "lib/cmake/quickjs"' 'config-directory = "lib64/cmake/quickjs"'

    substituteInPlace src/Web/cmake/CEF.cmake \
      --replace-fail 'if(OS_MAC)
    # The macOS CEF distribution is a dynamically loaded framework.' 'set_property(TARGET libcef_dll_wrapper PROPERTY CXX_SCAN_FOR_MODULES OFF)
    target_compile_options(libcef_dll_wrapper PRIVATE -Qunused-arguments -Wno-error)

if(OS_MAC)
    # The macOS CEF distribution is a dynamically loaded framework.'
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
EOF
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    lito build \
      -p owe-waywallen-scene-renderer \
      -p owe-waywallen-web-renderer \
      --profile release \
      --offline \
      --source-bundle ${bundleInfo.sourceBundle} \
      --use-env-flags
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    lito install \
      -p owe-waywallen-scene-renderer \
      -p owe-waywallen-web-renderer \
      -p owe-waywallen-plugin \
      --prefix $out \
      --profile release \
      --offline \
      --source-bundle ${bundleInfo.sourceBundle} \
      --use-env-flags
    runHook postInstall
  '';

  postFixup = ''
    # Replace prebuilt libvulkan.so.1 with the system loader
    if [ -f $out/lib/weweb/libvulkan.so.1 ]; then
      rm -f $out/lib/weweb/libvulkan.so.1
      ln -s ${vulkan-loader}/lib/libvulkan.so.1 $out/lib/weweb/libvulkan.so.1
    fi
    if [ -f $out/bin/weweb/libvulkan.so.1 ]; then
      rm -f $out/bin/weweb/libvulkan.so.1
      ln -s ${vulkan-loader}/lib/libvulkan.so.1 $out/bin/weweb/libvulkan.so.1
    fi

    # Wrap waywallen-wescene-renderer with PulseAudio (for wallpaper audio playback)
    if [ -f $out/bin/waywallen-wescene-renderer ]; then
      wrapProgram $out/bin/waywallen-wescene-renderer \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libpulseaudio ]}
    fi

    # Wrap waywallen-weweb-renderer with graphics and audio libraries
    if [ -f $out/lib/weweb/waywallen-weweb-renderer ]; then
      wrapProgram $out/lib/weweb/waywallen-weweb-renderer \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL vulkan-loader wayland libpulseaudio alsa-lib ]}
    fi
  '';

  meta = with lib; {
    description = "Wallpaper Engine renderer plugin for waywallen (open-wallpaper-engine)";
    homepage = "https://github.com/waywallen/open-wallpaper-engine";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
