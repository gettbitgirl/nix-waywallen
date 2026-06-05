{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, glib
, gobject-introspection
, gtk4
, vulkan-headers
, libGL
, libgbm
, vulkan-loader
, gjs
}:

stdenv.mkDerivation rec {
  pname = "waywallen-display-gnome";
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
    gobject-introspection
    glib # for glib-compile-schemas
  ];

  buildInputs = [
    glib
    gtk4
    vulkan-headers
    libGL
    libgbm
    vulkan-loader
    gjs
  ];

  cmakeFlags = [
    "-DWAYWALLEN_DISPLAY_PLUGIN_GOBJECT=ON"
    "-DWAYWALLEN_DISPLAY_PLUGIN_GNOME=ON"
    "-DWAYWALLEN_DISPLAY_BUILD_TESTS=OFF"
    "-DWAYWALLEN_DISPLAY_BUILD_EXAMPLES=OFF"
  ];

  postPatch = ''
    substituteInPlace extensions/gnome/renderer/renderer.js \
      --replace-fail "keepMinimized: true" "keepMinimized: false"
  '';

  postInstall = ''
    glib-compile-schemas $out/share/gnome-shell/extensions/org.waywallen.gnome@waywallen.io/schemas
    ln -s $out/lib $out/share/gnome-shell/extensions/org.waywallen.gnome@waywallen.io/lib
  '';

  passthru = {
    extensionUuid = "org.waywallen.gnome@waywallen.io";
    extensionPortalSlug = "waywallen";
  };

  meta = with lib; {
    description = "waywallen-display GNOME shell extension";
    homepage = "https://github.com/waywallen/waywallen-display";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
