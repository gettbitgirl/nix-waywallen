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
}:

let
  version = "0.8.6";
  llvmPkgs = llvmPackages_22;
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
    zstd
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
    "-DCMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES=${llvmPkgs.libcxx.dev}/include/c++/v1;${llvmPkgs.libcxx.dev}/include;${glibc.dev}/include"
    "-DFETCHCONTENT_SOURCE_DIR_RSTD=${rstdSrc}"
    "-DFETCHCONTENT_SOURCE_DIR_LUATO=${luatoSrc}"
    "-DFETCHCONTENT_SOURCE_DIR_LICRYPTO=${licryptoSrc}"
    "-DFETCHCONTENT_SOURCE_DIR_LUA=${luaSrc}"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
  ] ++ lib.optionals (zstdSrc != null) [
    "-DFETCHCONTENT_SOURCE_DIR_ZSTD=${zstdSrc}"
  ] ++ lib.optionals (zstdSrc == null) [
    "-DLITO_USE_SYSTEM_ZSTD=ON"
  ];

  NIX_CFLAGS_COMPILE = "-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0";

  meta = with lib; {
    description = "Module-first C++ builder";
    homepage = "https://github.com/litocpp/lito";
    license = with licenses; [ mit asl20 ];
    mainProgram = "lito";
    platforms = platforms.unix;
  };
}
