{ lib
, llvmPackages_22
, fetchFromGitHub
, fetchzip
, cmake
, ninja
, pkg-config
, zstd
, openssl
, glibc
}:

let
  version = "0.8.6";
  src = fetchFromGitHub {
    owner = "litocpp";
    repo = "lito";
    rev = "v${version}";
    hash = "sha256-5KOC3DQe5N3/KrHNObzF4q3kG/4yxu674NCbEDzD28A=";
  };

  deps = builtins.fromJSON (builtins.readFile "${src}/deps.json");
  fetchDependency = name:
    let dep = deps.${name}; in
    fetchFromGitHub {
      inherit (dep) owner repo rev;
      hash = dep.narHash;
    };

  rstdSrc = fetchDependency "rstd";
  luatoSrc = fetchDependency "luato";
  licryptoSrc = fetchDependency "licrypto";
  zstdSrc = fetchDependency "zstd";

  luaSrc = fetchzip {
    url = "https://www.lua.org/ftp/lua-5.5.1.tar.gz";
    hash = "sha256-vb3Nt5dMPL/G6L1MmJPGQnQT3F8p6iK6Gu2F/cG00ho=";
  };

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
    "-DFETCHCONTENT_SOURCE_DIR_ZSTD=${zstdSrc}"
    "-DFETCHCONTENT_SOURCE_DIR_LUA=${luaSrc}"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
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
