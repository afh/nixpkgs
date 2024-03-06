{ lib
, stdenv
, fetchFromGitHub
, cmake
, testers

, static ? stdenv.hostPlatform.isStatic

, lz4
, zlib-ng
, zstd
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "c-blosc2";
  version = "2.13.2";

  src = fetchFromGitHub {
    owner = "Blosc";
    repo = "c-blosc2";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-RNIvg6p/+brW7oboTDH0bbRfIQDaZwtZbbWFbftfWTk=";
  };

  # https://github.com/NixOS/nixpkgs/issues/144170
  postPatch = ''
    sed -i -E \
      -e '/^libdir[=]/clibdir=@CMAKE_INSTALL_FULL_LIBDIR@' \
      -e '/^includedir[=]/cincludedir=@CMAKE_INSTALL_FULL_INCLUDEDIR@' \
      blosc2.pc.in
  '';

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    lz4
    zlib-ng
    zstd
  ];

  cmakeFlags = lib.cmakeBools
  (lib.attrsets.prefixAttrsNameWith "BUILD_" {
    STATIC = static;
    SHARED = !static;
    TESTS = finalAttrs.finalPackage.doCheck;
    EXAMPLES = false;
    BENCHMARKS = false;
  }
  // lib.attrsets.prefixAttrsNameWith "PREFER_EXTERNAL_" {
    LZ4 = true;
    ZLIB = true;
    ZSTD = true;
  });

  doCheck = !static;
  # possibly https://github.com/Blosc/c-blosc2/issues/432
  enableParallelChecking = false;

  passthru.tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;

  meta = with lib; {
    description = "A fast, compressed, persistent binary data store library for C";
    homepage = "https://www.blosc.org";
    changelog = "https://github.com/Blosc/c-blosc2/releases/tag/v${version}";
    pkgConfigModules = [
      "blosc2"
    ];
    license = licenses.bsd3;
    platforms = platforms.all;
    maintainers = with maintainers; [ ris ];
  };
})
