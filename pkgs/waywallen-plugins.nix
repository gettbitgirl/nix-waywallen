{ lib
, llvmPackages_latest
, fetchFromGitHub
, cmake
, pkg-config
, ffmpeg
, libGL          # EGL headers (via libGL/mesa)
, libgbm         # gbm.pc (mesa-libgbm)
, vulkan-loader
, vulkan-headers
, libva
, libpulseaudio
, glslang        # provides glslangValidator, required by wavsen::video
, ninja
}:

let
  deps = {
    rstd = fetchFromGitHub {
      owner = "hypengw";
      repo = "rstd";
      rev = "629bda81eb98856ca023f0f87f57dde8d22b4823";
      sha256 = "sha256-yN5S3g0QUIyMrCy6KdJVMxyDxs5kYpv+pfv5efsy8BU=";
    };
    wavsen = fetchFromGitHub {
      owner = "hypengw";
      repo = "wavsen";
      rev = "d70d19e14437c2e1283e87e8bff43afe7c7e565d";
      sha256 = "sha256-vrMoY/UhP8zs/CpmUCp7N99Rf1ytcn7ehRaTY5MNoQs=";
    };
  };
in
llvmPackages_latest.stdenv.mkDerivation rec {
  pname = "waywallen-plugins";
  version = "0.1.8";

  src = fetchFromGitHub {
    owner = "waywallen";
    repo = "waywallen";
    rev = "v${version}";
    sha256 = "0368i58ynv3r61yi16vm78r4qmr93jwc779hzrd72csj6pv9kibl";
  };

  # Build from the repo root so CMAKE_SOURCE_DIR resolves cmake/ and deps.json
  sourceRoot = "source";

  hardeningDisable = [ "fortify" ];

  postPatch = ''
    # Patch top-level CMakeLists.txt:
    #   - Remove the CPackConfig include (unneeded, may pull in cpack)
    substituteInPlace CMakeLists.txt \
      --replace "include(CPackConfig)" "# include(CPackConfig)"

    # Patch bridge.c to send all plane fds for multi-planar modifiers:
    substituteInPlace bridge/src/bridge.c \
      --replace-fail "                  m, fds, m->count);" "                  m, fds, m->count * m->planes_per_buffer);"

    # Filter out AMD DCC modifiers (vendor ID 0x02, DCC bit 13) from Vulkan format caps:
    substituteInPlace bridge/src/pool_vulkan.c \
      --replace-fail '            if ((ff & want_features) != want_features) continue;' '            if ((ff & want_features) != want_features) continue;
            if (((probed[i].drmFormatModifier >> 56) == 2) && ((probed[i].drmFormatModifier >> 13) & 1)) continue;'
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    ninja
    glslang        # glslangValidator for wavsen shader compilation
    llvmPackages_latest.clang-tools
    llvmPackages_latest.lld
  ];

  buildInputs = [
    ffmpeg
    libGL          # EGL headers
    libgbm         # GBM (gbm.pc + libgbm)
    vulkan-loader
    vulkan-headers
    libva          # wavsen dependency
    libpulseaudio  # wavsen dependency
  ];

  cmakeFlags = [
    # Only build the plugins component
    "-DWAYWALLEN_BUILD_DAEMON=OFF"
    "-DWAYWALLEN_BUILD_UI=OFF"
    "-DWAYWALLEN_BUILD_PLUGINS=ON"
    # MPV plugin requires libmpv — skip for now
    "-DWAYWALLEN_BUILD_MPV_PLUGIN=OFF"
    # Point FetchDeps at the pre-fetched Nix store paths
    "-DFETCHDEPS_LOCAL_rstd=${deps.rstd}"
    "-DFETCHDEPS_LOCAL_wavsen=${deps.wavsen}"
    # C++20 module scanning
    "-DCMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=${llvmPackages_latest.clang-tools}/bin/clang-scan-deps"
  ];

  meta = with lib; {
    description = "Renderer plugin binaries (image + video) for waywallen";
    homepage = "https://github.com/waywallen/waywallen";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
