{ lib
, stdenv
, fetchFromGitHub
, cmake
, openssl
, enableStatic ? stdenv.hostPlatform.isStatic
}:

stdenv.mkDerivation rec {
  pname = "liboqs";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "open-quantum-safe";
    repo = pname;
    rev = version;
    sha256 = "sha256-h3mXoGRYgPg0wKQ1u6uFP7wlEUMQd5uIBt4Hr7vjNtA=";
  };

  patches = [ ./fix-openssl-detection.patch ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [ openssl ];

  cmakeFlags = lib.cmakeBools {
    BUILD_SHARED_LIBS = !enableStatic;
    OQS_DIST_BUILD = true;
    OQS_BUILD_ONLY_LIB = true;
  };

  dontFixCmake = true; # fix CMake file will give an error

  meta = with lib; {
    description = "C library for prototyping and experimenting with quantum-resistant cryptography";
    homepage = "https://openquantumsafe.org";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [];
  };
}
