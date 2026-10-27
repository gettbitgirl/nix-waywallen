{
  lib,
  llvmPackages_22,
  cmake,
  ninja,
  pkg-config,
  zstd,
  openssl,
  glibc,
  src,
  rstdSrc,
  luatoSrc,
  licryptoSrc,
  zstdSrc ? null,
  luaSrc,
  useNixpkgsDeps ? false,
}:

let
  version = (builtins.fromTOML (builtins.readFile "${src}/lito.toml")).workspace.package.version;
  llvmPkgs = llvmPackages_22;
  effectiveZstdSrc = if useNixpkgsDeps then null else zstdSrc;
  zstdLib = lib.getLib zstd;
  zstdDev = lib.getDev zstd;
in
llvmPkgs.libcxxStdenv.mkDerivation {
  pname = "lito";
  inherit version src;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    llvmPkgs.lld
  ];

  buildInputs = [
    zstdLib
    zstdDev
    openssl
  ];

  cmakeFlags = [
    "-DCMAKE_C_COMPILER=clang"
    "-DCMAKE_CXX_COMPILER=clang++"
    "-DCMAKE_AR=${llvmPkgs.llvm}/bin/llvm-ar"
    "-DCMAKE_RANLIB=${llvmPkgs.llvm}/bin/llvm-ranlib"
    "-DCMAKE_CXX_COMPILER_AR=${llvmPkgs.llvm}/bin/llvm-ar"
    "-DCMAKE_C_COMPILER_AR=${llvmPkgs.llvm}/bin/llvm-ar"
    "-DCMAKE_CXX_COMPILER_RANLIB=${llvmPkgs.llvm}/bin/llvm-ranlib"
    "-DCMAKE_C_COMPILER_RANLIB=${llvmPkgs.llvm}/bin/llvm-ranlib"
    "-DCMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES=${llvmPkgs.libcxx.dev}/include/c++/v1;${llvmPkgs.libcxx.dev}/include;${glibc.dev}/include;${zstdDev}/include;${openssl.dev}/include"
    "-DFETCHCONTENT_SOURCE_DIR_RSTD=${rstdSrc}"
    "-DFETCHCONTENT_SOURCE_DIR_LUATO=${luatoSrc}"
    "-DFETCHCONTENT_SOURCE_DIR_LICRYPTO=${licryptoSrc}"
    "-DFETCHCONTENT_SOURCE_DIR_LUA=${luaSrc}"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DCMAKE_BUILD_RPATH=${zstdLib}/lib"
    "-DCMAKE_INSTALL_RPATH=${zstdLib}/lib"
    "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"
    "-DCMAKE_EXE_LINKER_FLAGS=-Wl,-rpath,${zstdLib}/lib"
    "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-rpath,${zstdLib}/lib"
  ] ++ lib.optionals (effectiveZstdSrc != null) [
    "-DFETCHCONTENT_SOURCE_DIR_ZSTD=${effectiveZstdSrc}"
  ] ++ lib.optionals (effectiveZstdSrc == null) [
    "-DLITO_USE_SYSTEM_ZSTD=ON"
  ];

  preBuild = ''
    export LD_LIBRARY_PATH="${zstdLib}/lib:$LD_LIBRARY_PATH"
  '';

  NIX_CFLAGS_COMPILE = "-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0";
  NIX_LDFLAGS = "-rpath ${zstdLib}/lib";

  meta = with lib; {
    description = "Module-first C++ builder";
    homepage = "https://github.com/litocpp/lito";
    license = with licenses; [ mit asl20 ];
    mainProgram = "lito";
    platforms = platforms.unix;
  };
}
