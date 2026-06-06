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
, libpulseaudio   # wavsen::audio backend
, libva           # wavsen dep
, expat
, libgbm          # wavsen dep (gbm.pc)
, libGL
, autoPatchelfHook
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
, glslang         # provides glslangValidator for wavsen shader compilation
, waywallen-plugins  # provides waywallen::bridge via CMake find_package
, patchelf
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

  src = fetchFromGitHub {
    owner = "waywallen";
    repo = "open-wallpaper-engine";
    rev = "f2bb8d800208603c6febc464779b7853ff6c0f52";
    sha256 = "18ya8xlj6w54hjwafva5jsqm5bjr0a84fiyjicz3s4br67fdgacf";
  };

  hardeningDisable = [ "fortify" ];

  postPatch = ''
    substituteInPlace third_party/CMakeLists.txt \
      --replace-fail "add_library(eigen INTERFACE)" "if(NOT TARGET eigen)
  add_library(eigen INTERFACE)
endif()" \
      --replace-fail "add_library(Eigen3::Eigen ALIAS eigen)" "if(NOT TARGET Eigen3::Eigen)
  add_library(Eigen3::Eigen ALIAS eigen)
endif()"

    substituteInPlace cmake/CEF.cmake \
      --replace-fail "add_subdirectory(" "if(NOT TARGET libcef_dll_wrapper)
  add_subdirectory(" \
      --replace-fail "EXCLUDE_FROM_ALL)" "EXCLUDE_FROM_ALL)
endif()"

    # Inject classic locale to fix float parsing on localized systems
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

    substituteInPlace src/Web/AppHandler.cpp \
      --replace-fail 'cmd->AppendSwitch("enable-accelerated-video-decode");' '// cmd->AppendSwitch("enable-accelerated-video-decode");' \
      --replace-fail 'cmd->AppendSwitch("enable-native-gpu-memory-buffers");' '// cmd->AppendSwitch("enable-native-gpu-memory-buffers");' \
      --replace-fail 'cmd->AppendSwitch("enable-zero-copy");' '// cmd->AppendSwitch("enable-zero-copy");'
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    ninja
    glslang
    llvmPackages_latest.clang-tools
    llvmPackages_latest.lld
    patchelf
  ];

  buildInputs = [
    freetype
    lz4
    fontconfig
    ffmpeg
    vulkan-loader
    vulkan-headers
    libpulseaudio
    libva
    libgbm
    libGL
    expat
    waywallen-plugins
  ];

  cmakeFlags = [
    "-DBUILD_WEWEB=ON"
    "-DBUILD_WESCENE=ON"
    "-DBUILD_VIEWER=OFF"
    "-DBUILD_TESTS=OFF"
    "-DBUILD_WAYWALLEN=ON"
    "-DCMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=${llvmPackages_latest.clang-tools}/bin/clang-scan-deps"
    "-Dwaywallen-bridge_DIR=${waywallen-plugins}/lib/cmake/waywallen-bridge"
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
    # Remove CEF's unpatched Vulkan and SwiftShader stubs; keep ANGLE EGL/GLES.
    # Do NOT remove libEGL.so or libGLESv2.so — those are CEF's bundled ANGLE
    # implementation. Replacing them with system libglvnd causes EGL_BAD_ATTRIBUTE
    # crashes on NVIDIA because NVIDIA's libEGL_nvidia.so doesn't support the
    # ANGLE-specific context-virtualization attributes Chromium passes internally.
    rm -f $out/bin/weweb/libvulkan.so.1
    rm -f $out/bin/weweb/libvk_swiftshader.so
    rm -f $out/bin/weweb/vk_swiftshader_icd.json

    # Symlink system Vulkan loader (needed by libcef.so for Vulkan device probing)
    ln -s ${vulkan-loader}/lib/libvulkan.so.1 $out/bin/weweb/libvulkan.so.1

    # Add RPATHs to libcef.so so it can locate Mesa, Vulkan loader, and Wayland
    patchelf --add-rpath "${lib.makeLibraryPath [ mesa vulkan-loader wayland libGL ]}" $out/bin/weweb/libcef.so
  '';

  meta = with lib; {
    description = "Wallpaper Engine renderer plugin for waywallen (open-wallpaper-engine)";
    homepage = "https://github.com/waywallen/open-wallpaper-engine";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
