{
  lib,
  stdenv,
  cmake,
  pkg-config,
  glib,
  gobject-introspection,
  gtk4,
  vulkan-headers,
  libGL,
  libgbm,
  vulkan-loader,
  gjs,
  src,
}:
stdenv.mkDerivation {
  pname = "waywallen-display-gnome";
  version = "0.4.2";

  inherit src;

  nativeBuildInputs = [
    cmake
    pkg-config
    gobject-introspection  # generates GObject introspection data consumed by GJS
    glib                   # for glib-compile-schemas (run in postInstall)
  ];

  buildInputs = [
    glib
    gtk4
    vulkan-headers
    libGL
    libgbm
    vulkan-loader
    gjs    # GNOME JavaScript runtime; the extension runs inside gnome-shell's GJS
  ];

  cmakeFlags = [
    "-DWAYWALLEN_DISPLAY_PLUGIN_GOBJECT=ON"  # builds the GObject/GJS bridge library
    "-DWAYWALLEN_DISPLAY_PLUGIN_GNOME=ON"    # builds the GNOME shell extension
    "-DWAYWALLEN_DISPLAY_BUILD_TESTS=OFF"
    "-DWAYWALLEN_DISPLAY_BUILD_EXAMPLES=OFF"
  ];

  postInstall = ''
    # Compile GSettings schemas so the extension can read its configuration at runtime.
    # gnome-shell will not load an extension with uncompiled schemas.
    glib-compile-schemas $out/share/gnome-shell/extensions/org.waywallen.gnome@waywallen.io/schemas

    # The extension's JS imports the GObject bridge library via GJS's native module
    # loader, which looks for .so files relative to the extension directory. Symlink
    # the installed lib/ into the extension tree so the relative import resolves.
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
