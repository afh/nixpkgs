{ lib
, stdenv
, fetchFromGitHub
, cmake
, ragel
, util-linux
, python3
, boost
, enableShared ? !stdenv.hostPlatform.isStatic
}:

stdenv.mkDerivation rec {
  pname = "vectorscan";
  version = "5.4.10.1";

  src = fetchFromGitHub {
    owner = "VectorCamp";
    repo = "vectorscan";
    rev = "vectorscan/${version}";
    hash = "sha256-x6FefOrUvpN/A4GXTd+3SGZEAQL6pXt83ufxRIY3Q9k=";
  };

  nativeBuildInputs = [
    cmake
    ragel
    python3
  ] ++ lib.optional stdenv.isLinux util-linux;

  buildInputs = [
    boost
  ];

  cmakeFlags = lib.cmakeBools ({
    FAT_RUNTIME =  stdenv.hostPlatform.isLinux;
  } // lib.attrsets.prefixAttrsNameWith "BUILD_" {
    STATIC_AND_SHARED = enableShared;
    AVX2 = stdenv.hostPlatform.avx2Support;
    AVX512N = stdenv.hostPlatform.avx512Support;
  });

  meta = with lib; {
    description = "A portable fork of the high-performance regular expression matching library";
    longDescription = ''
      A fork of Intel's Hyperscan, modified to run on more platforms. Currently
      ARM NEON/ASIMD is 100% functional, and Power VSX are in development.
      ARM SVE2 will be implemented when hardware becomes accessible to the
      developers. More platforms will follow in the future, on demand/request.

      Vectorscan will follow Intel's API and internal algorithms where possible,
      but will not hesitate to make code changes where it is thought of giving
      better performance or better portability. In addition, the code will be
      gradually simplified and made more uniform and all architecture specific
      code will be abstracted away.
    '';
    homepage = "https://www.vectorcamp.gr/vectorscan/";
    changelog = "https://github.com/VectorCamp/vectorscan/blob/${src.rev}/CHANGELOG-vectorscan.md";
    platforms = platforms.unix;
    license = with licenses; [ bsd3 /* and */ bsd2 /* and */ licenses.boost ];
    maintainers = with maintainers; [ tnias vlaci ];
  };
}
