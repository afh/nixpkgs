{ lib
, stdenv
, fetchFromGitHub
, cmake
, gtest
, static ? stdenv.hostPlatform.isStatic
, cxxStandard ? null
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "abseil-cpp";
  version = "20240116.0";

  src = fetchFromGitHub {
    owner = "abseil";
    repo = "abseil-cpp";
    rev = "refs/tags/${finalAttrs.version}";
    hash = "sha256-HtJh2oYGx87bNT6Ll3WLeYPPxH1f9JwVqCXGErykGnE=";
  };

  cmakeFlags = lib.cmakeBools {
    ABSL_BUILD_TEST_HELPERS = true;
    ABSL_USE_EXTERNAL_GOOGLETEST = true;
    BUILD_SHARED_LIBS = !static;
    CMAKE_CXX_STANDARD = cxxStandard != null;
  };

  strictDeps = true;

  nativeBuildInputs = [ cmake ];

  buildInputs = [ gtest ];

  meta = with lib; {
    description = "An open-source collection of C++ code designed to augment the C++ standard library";
    homepage = "https://abseil.io/";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = [ maintainers.GaetanLepage ];
  };
})
