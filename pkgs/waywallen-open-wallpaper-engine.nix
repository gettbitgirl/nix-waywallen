{ lib
, stdenv
, llvmPackages_latest
, fetchFromGitHub
, fetchFromGitLab
, fetchzip
, cmake
, pkg-config
, ninja
, freetype
, lz4
, fontconfig
, ffmpeg
, vulkan-loader
, vulkan-headers
, libpulseaudio   # wavsen audio backend
, libva           # wavsen VA-API dep
, expat
, libgbm          # wavsen GBM dep (gbm.pc)
, libGL
, autoPatchelfHook
# CEF runtime deps — autoPatchelfHook resolves libcef.so's NEEDED entries against these
, alsa-lib
, atk
, cairo
, cups
, dbus
, glib
, gtk3
, libdrm
, libxkbcommon
, mesa
, nspr
, nss
, pango
, wayland
, libx11
, libxcomposite
, libxdamage
, libxext
, libxfixes
, libxrandr
, libxcb
, glslang         # provides glslangValidator for wavsen GLSL→SPIR-V compilation
, waywallen-plugins  # provides waywallen::bridge headers/cmake config
, patchelf
, src
}:

let
  # upstream uses CMake FetchContent for all these deps; we vendor them via
  # FETCHDEPS_LOCAL_* so the build stays reproducible and network-free.
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

    eigen = fetchFromGitLab {
      domain = "gitlab.com";
      owner = "libeigen";
      repo = "eigen";
      rev = "3147391d946bb4b6c68edd901f2add6ac1f31f8c";
      sha256 = "0k1c4qnymwwvm68rv6s0cyk08xbw65ixvwqccsh36c2axcqk3znp";
    };
    nlohmann_json = fetchFromGitHub {
      owner = "nlohmann";
      repo = "json";
      rev = "v3.12.0";
      sha256 = "09nqq56ighr3lghhn3fs399lkllghz717j0xyp87x0giw86ayh3h";
    };
    spirv_reflect = fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "SPIRV-Reflect";
      rev = "vulkan-sdk-1.4.321.0";
      sha256 = "0c62j4hpaw5grxf4winpgs8ri68fxa59ah63aa7phra3fn82zs64";
    };
    glslang_src = fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "glslang";
      rev = "275822a6261ee689aadb1da5f09a0ec2f058685c";
      sha256 = "0qdnazfv1sk5w60k74zbcv2ig3yqwwcb75bia395ba2z8ckmrjf1";
    };
    argparse = fetchFromGitHub {
      owner = "p-ranav";
      repo = "argparse";
      rev = "d924b84eba1f0f0adf38b20b7b4829f6f65b6570";
      sha256 = "0wicwx34hgx1566pv8xv746v5mn74nggxlqbpaxxghdi7giff4l1";
    };
    quickjs = fetchFromGitHub {
      owner = "quickjs-ng";
      repo = "quickjs";
      rev = "3c051980ab7e783dfbfb1c70c014ce5e05ecf24c";
      sha256 = "05k8niswh0ly5sx0129jdhiinqs84s86b7sv29ff68v3546dl04i";
    };

    # CEF (Chromium Embedded Framework) prebuilt minimal distribution.
    # autoPatchelfHook rewrites ELF interpreter paths and resolves NEEDED entries
    # against the buildInputs so libcef.so can find its system dependencies.
    # The minimal build includes ANGLE (libEGL.so, libGLESv2.so) — see postFixup.
    cef = stdenv.mkDerivation {
      pname = "cef-minimal";
      version = "147.0.10";
      src = fetchzip {
        url = "https://cef-builds.spotifycdn.com/cef_binary_147.0.10%2Bgd58e84d%2Bchromium-147.0.7727.118_linux64_minimal.tar.bz2";
        sha256 = "sha256-Da6weC6xDs6F2QUmARLiF8YIbWG7p+tGt1FRFpEZf1Q=";
      };
      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [
        alsa-lib atk cairo cups dbus expat fontconfig glib gtk3 libdrm
        libxkbcommon mesa nspr nss pango wayland
        libx11 libxcomposite libxdamage libxext
        libxfixes libxrandr libxcb
      ];
      installPhase = ''
        mkdir -p $out
        cp -a * $out/
      '';
    };
  };
in
llvmPackages_latest.stdenv.mkDerivation {
  pname = "waywallen-open-wallpaper-engine";
  version = "0.1.4";

  inherit src;

  # wavsen and rstd are compiled as static libs without glibc FORTIFY_SOURCE
  # pass_object_size annotations. With FORTIFY enabled, glibc replaces read/pread/open
  # with annotated variants whose signatures don't match, causing link failures.
  hardeningDisable = [ "fortify" ];

  postPatch = ''
    # upstream's third_party/CMakeLists.txt unconditionally calls add_library(eigen ...)
    # and add_library(Eigen3::Eigen ALIAS eigen). When eigen is supplied via
    # FETCHDEPS_LOCAL_eigen, CMake has already defined those targets, so the
    # unconditional declarations produce a "target already exists" error. Guard them.
    substituteInPlace third_party/CMakeLists.txt \
      --replace-fail "add_library(eigen INTERFACE)" "if(NOT TARGET eigen)
  add_library(eigen INTERFACE)
endif()" \
      --replace-fail "add_library(Eigen3::Eigen ALIAS eigen)" "if(NOT TARGET Eigen3::Eigen)
  add_library(Eigen3::Eigen ALIAS eigen)
endif()"

    # cmake/CEF.cmake calls add_subdirectory() on the CEF wrapper unconditionally.
    # When CEF is supplied via FETCHDEPS_LOCAL_cef the wrapper target already exists,
    # so a second add_subdirectory produces a duplicate-target error. Guard it.
    substituteInPlace cmake/CEF.cmake \
      --replace-fail "add_subdirectory(" "if(NOT TARGET libcef_dll_wrapper)
  add_subdirectory(" \
      --replace-fail "EXCLUDE_FROM_ALL)" "EXCLUDE_FROM_ALL)
endif()"

    # NixOS environments often have a system locale set (e.g. de_DE, fr_FR) which
    # causes strtod/sscanf to use ',' as the decimal separator. Upstream parses
    # floating-point values from wallpaper JSON/asset files using the default locale,
    # which silently misparses numbers on non-C locales. Force the C locale at
    # startup in both the scene renderer and the weweb renderer entry points.
    substituteInPlace waywallen/scene_main.cpp \
      --replace-fail '#include <rstd/macro.hpp>' '#include <clocale>
#include <locale>
#include <rstd/macro.hpp>' \
      --replace-fail 'int main(int argc, char** argv) {' 'int main(int argc, char** argv) { std::setlocale(LC_ALL, "C"); std::locale::global(std::locale("C"));'

    substituteInPlace waywallen/web_main.cpp \
      --replace-fail '#include "BrowserHost.hpp"' '#include <clocale>
#include <locale>
#include "BrowserHost.hpp"' \
      --replace-fail 'int main(int argc, char** argv) {' 'int main(int argc, char** argv) { std::setlocale(LC_ALL, "C"); std::locale::global(std::locale("C"));'

    # Upstream enables three Chromium flags intended for ChromeOS that are broken
    # on desktop Linux:
    #
    #   enable-accelerated-video-decode — requires a VA-API/V4L2 decode pipeline
    #     that is not reliably available outside ChromeOS; causes GPU process crashes.
    #
    #   enable-native-gpu-memory-buffers — enables Linux GBM-backed GpuMemoryBuffers.
    #     Chromium's GMB Linux support is ChromeOS-only; on desktop it causes the GPU
    #     process to SIGSEGV during GmbVideoFramePoolContext::InitializeOnGpu.
    #
    #   enable-zero-copy — zero-copy texture upload via GpuMemoryBuffer. Depends on
    #     native-gpu-memory-buffers being functional; must be disabled together.
    substituteInPlace src/Web/AppHandler.cpp \
      --replace-fail 'cmd->AppendSwitch("enable-accelerated-video-decode");' '// cmd->AppendSwitch("enable-accelerated-video-decode");' \
      --replace-fail 'cmd->AppendSwitch("enable-native-gpu-memory-buffers");' '// cmd->AppendSwitch("enable-native-gpu-memory-buffers");' \
      --replace-fail 'cmd->AppendSwitch("enable-zero-copy");' '// cmd->AppendSwitch("enable-zero-copy");'
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    ninja
    glslang                            # glslangValidator for wavsen shader compilation
    llvmPackages_latest.clang-tools    # clang-scan-deps for C++20 module scanning
    llvmPackages_latest.lld            # faster linker; required by upstream CMake config
    patchelf                           # used in postFixup to patch libcef.so RPATH
  ];

  buildInputs = [
    freetype
    lz4
    fontconfig
    ffmpeg
    vulkan-loader
    vulkan-headers
    libpulseaudio   # wavsen audio backend
    libva           # wavsen VA-API dep
    libgbm          # wavsen GBM dep
    libGL           # also used in postFixup RPATH for libcef.so
    expat
    waywallen-plugins
  ];

  cmakeFlags = [
    "-DBUILD_WEWEB=ON"       # CEF-based web wallpaper renderer
    "-DBUILD_WESCENE=ON"     # scene (particle/shader) wallpaper renderer
    "-DBUILD_VIEWER=OFF"     # standalone viewer binary; not needed for daemon use
    "-DBUILD_TESTS=OFF"
    "-DBUILD_WAYWALLEN=ON"
    # Point CMake's clang module scanner at the Nix-store clang-tools binary
    "-DCMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=${llvmPackages_latest.clang-tools}/bin/clang-scan-deps"
    # Provide the waywallen IPC bridge cmake config from the plugins package
    "-Dwaywallen-bridge_DIR=${waywallen-plugins}/lib/cmake/waywallen-bridge"
    # Redirect all FetchContent calls to pre-fetched Nix store paths
    "-DFETCHDEPS_LOCAL_rstd=${deps.rstd}"
    "-DFETCHDEPS_LOCAL_wavsen=${deps.wavsen}"
    "-DFETCHDEPS_LOCAL_eigen=${deps.eigen}"
    "-DFETCHDEPS_LOCAL_nlohmann_json=${deps.nlohmann_json}"
    "-DFETCHDEPS_LOCAL_spirv_reflect=${deps.spirv_reflect}"
    "-DFETCHDEPS_LOCAL_glslang=${deps.glslang_src}"
    "-DFETCHDEPS_LOCAL_argparse=${deps.argparse}"
    "-DFETCHDEPS_LOCAL_quickjs=${deps.quickjs}"
    "-DFETCHDEPS_LOCAL_cef=${deps.cef}"
  ];

  postFixup = ''
    # CEF's minimal tarball ships libvulkan.so.1 and a SwiftShader software Vulkan
    # implementation (libvk_swiftshader.so + vk_swiftshader_icd.json). These are
    # unpatched upstream binaries with hardcoded non-Nix paths that will fail to
    # load. Remove them and replace libvulkan.so.1 with the system loader.
    rm -f $out/bin/weweb/libvulkan.so.1
    rm -f $out/bin/weweb/libvk_swiftshader.so
    rm -f $out/bin/weweb/vk_swiftshader_icd.json

    # libcef.so probes for Vulkan at runtime. Point it at the system vulkan-loader
    # which knows how to find ICD manifests via XDG/system paths.
    ln -s ${vulkan-loader}/lib/libvulkan.so.1 $out/bin/weweb/libvulkan.so.1

    # libcef.so is a prebuilt binary with no RPATH for Mesa, Vulkan, or Wayland.
    # Without these paths it cannot dlopen its GL/EGL/Wayland dependencies at runtime.
    # NOTE: do NOT replace the CEF-bundled libEGL.so or libGLESv2.so. Those are
    # ANGLE's own EGL/GLES implementation. Swapping them for the system libglvnd
    # causes EGL_BAD_ATTRIBUTE crashes on NVIDIA: NVIDIA's libEGL_nvidia.so does not
    # implement the ANGLE-specific context-virtualization EGL attributes that Chromium
    # passes when creating shared GPU contexts.
    patchelf --add-rpath "${lib.makeLibraryPath [ mesa vulkan-loader wayland libGL ]}" $out/bin/weweb/libcef.so
  '';

  meta = with lib; {
    description = "Wallpaper Engine renderer plugin for waywallen (open-wallpaper-engine)";
    homepage = "https://github.com/waywallen/open-wallpaper-engine";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
