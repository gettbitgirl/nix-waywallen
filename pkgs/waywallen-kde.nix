{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, qt6
, vulkan-headers
, libGL
, libgbm
, vulkan-loader
}:

stdenv.mkDerivation rec {
  pname = "waywallen-display-kde";
  version = "unstable-2026-05-30";

  src = fetchFromGitHub {
    owner = "waywallen";
    repo = "waywallen-display";
    rev = "6767dcf5a76c804c7dfd576310b1ed49fa769212";
    hash = "sha256-jb0lqror2kO1oF6HdFYjMeVzkGSuUj/MCYgP+Jbqkkg=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    vulkan-headers
    libGL
    libgbm
    vulkan-loader
  ];

  cmakeFlags = [
    "-DWAYWALLEN_DISPLAY_PLUGIN_QML=ON"
    "-DWAYWALLEN_DISPLAY_BUILD_TESTS=OFF"
    "-DWAYWALLEN_DISPLAY_BUILD_EXAMPLES=OFF"
  ];

  meta = with lib; {
    description = "waywallen-display KDE (QML) plugin";
    homepage = "https://github.com/waywallen/waywallen-display";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
