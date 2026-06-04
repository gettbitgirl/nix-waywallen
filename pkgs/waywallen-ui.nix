{ lib
, llvmPackages_latest
, fetchFromGitHub
, cmake
, pkg-config
, qt6
, protobuf
, curl
, ffmpeg
, asio
, libva
, libpulseaudio
, glslang
, vulkan-loader
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
    ncrequest = fetchFromGitHub {
      owner = "hypengw";
      repo = "ncrequest";
      rev = "404868aa2aa4481e262f25d8f7d053f42b61b7b8";
      sha256 = "sha256-qY1JraJAnA1wW9Xgd4ZpgblDh3Se4mnwss5VcgU+ot8=";
    };
    wavsen = fetchFromGitHub {
      owner = "hypengw";
      repo = "wavsen";
      rev = "d70d19e14437c2e1283e87e8bff43afe7c7e565d";
      sha256 = "sha256-vrMoY/UhP8zs/CpmUCp7N99Rf1ytcn7ehRaTY5MNoQs=";
    };
    qml_material = fetchFromGitHub {
      owner = "hypengw";
      repo = "QmlMaterial";
      rev = "e6d500030ef57cea5c3af9d6b96afa62c76439d4";
      sha256 = "sha256-SGMRx5EA3DWCQLsaE8rK1OFsFVGsmlMFeYPb2xpa0i4=";
    };
    QExtra = fetchFromGitHub {
      owner = "hypengw";
      repo = "QExtra";
      rev = "2b947f16cfba8ba21c16f2a5dd953c152db78c4a";
      sha256 = "sha256-y9duictNak3lMxDFVKfq+nNddpuFwNEY5IsOl0lwFAQ=";
    };
    asio = fetchFromGitHub {
      owner = "chriskohlhoff";
      repo = "asio";
      rev = "12e0ce9e0500bf0f247dbd1ae894272656456079";
      sha256 = "sha256-g+ZPKBUhBGlgvce8uTkuR983unD2kbQKgoddko7x+fk=";
    };
    pegtl = fetchFromGitHub {
      owner = "taocpp";
      repo = "PEGTL";
      rev = "be527327653e94b02e711f7eff59285ad13e1db0";
      sha256 = "sha256-nPWSO2wPl/qenUQgvQDQu7Oy1dKa/PnNFSclmkaoM8A=";
    };
  };
in
llvmPackages_latest.stdenv.mkDerivation rec {
  pname = "waywallen-ui";
  version = "0.1.8";

  src = fetchFromGitHub {
    owner = "waywallen";
    repo = "waywallen";
    rev = "v${version}";
    sha256 = "0368i58ynv3r61yi16vm78r4qmr93jwc779hzrd72csj6pv9kibl";
  };

  sourceRoot = "source/ui";

  hardeningDisable = [ "fortify" ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "\''${CMAKE_SOURCE_DIR}/cmake/FetchDeps.cmake" "\''${CMAKE_CURRENT_SOURCE_DIR}/../cmake/FetchDeps.cmake" \
      --replace "fetchdeps(\''${CMAKE_SOURCE_DIR}/deps.json)" "fetchdeps(\''${CMAKE_CURRENT_SOURCE_DIR}/../deps.json NAMES pegtl rstd ncrequest wavsen qml_material QExtra)" \
      --replace "set(QT_QML_GENERATE_QMLLS_INI ON)" "set(QT_QML_GENERATE_QMLLS_INI OFF)"

    substituteInPlace qml/Window.qml \
      --replace "id: win" "id: win; Binding { target: MD.Token.color; property: \"accentColor\"; value: win.palette.highlight }"
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
    qt6.qtgrpc
    protobuf
    glslang
    ninja
    llvmPackages_latest.clang-tools
    llvmPackages_latest.lld
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtgrpc
    protobuf
    (curl.override { websocketSupport = true; })
    ffmpeg
    asio
    libva
    libpulseaudio
    qt6.qtwayland
    vulkan-loader
  ];

  cmakeFlags = [
    "-DFETCHDEPS_LOCAL_rstd=${deps.rstd}"
    "-DFETCHDEPS_LOCAL_ncrequest=${deps.ncrequest}"
    "-DFETCHDEPS_LOCAL_wavsen=${deps.wavsen}"
    "-DFETCHDEPS_LOCAL_qml_material=${deps.qml_material}"
    "-DFETCHDEPS_LOCAL_QExtra=${deps.QExtra}"
    "-DFETCHDEPS_LOCAL_asio=${deps.asio}"
    "-DFETCHDEPS_LOCAL_pegtl=${deps.pegtl}"
    "-DCMAKE_MODULE_PATH=${qt6.qtgrpc}/lib/cmake/Qt6"
    "-DCMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=${llvmPackages_latest.clang-tools}/bin/clang-scan-deps"
  ];

  qtWrapperArgs = [
    "--prefix NIXPKGS_QT6_QML_IMPORT_PATH : ${placeholder "out"}/lib/qt6/qml"
    "--prefix QML_IMPORT_PATH : ${placeholder "out"}/lib/qt6/qml"
    "--prefix QML2_IMPORT_PATH : ${placeholder "out"}/lib/qt6/qml"
  ];

  meta = with lib; {
    description = "Qt/QML UI component of waywallen";
    homepage = "https://github.com/waywallen/waywallen";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
