{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, zlib
, gtest
, buildPackages

, meta
}:

{ version, hash, abseil-cpp }:

let
mkProtobufDerivation = buildProtobuf: stdenv: stdenv.mkDerivation {
  pname = "protobuf";
  inherit version;

  # make sure you test also -A pythonPackages.protobuf
  src = fetchFromGitHub {
    owner = "protocolbuffers";
    repo = "protobuf";
    rev = "v${version}";
    inherit hash;
  };

  postPatch = ''
    rm -rf gmock
    cp -r ${gtest.src}/googlemock gmock
    cp -r ${gtest.src}/googletest googletest
    chmod -R a+w gmock
    chmod -R a+w googletest
    ln -s ../googletest gmock/gtest
  '' + lib.optionalString stdenv.isDarwin ''
    substituteInPlace src/google/protobuf/testing/googletest.cc \
      --replace 'tmpnam(b)' '"'$TMPDIR'/foo"'
  '';

  nativeBuildInputs = [ autoreconfHook buildPackages.which buildPackages.stdenv.cc buildProtobuf ];

  buildInputs = [ zlib ];
  configureFlags = lib.optional (buildProtobuf != null) "--with-protoc=${buildProtobuf}/bin/protoc";

  enableParallelBuilding = true;

  doCheck = true;

  dontDisableStatic = true;

  meta = meta // {
    maintainers = [];
    platforms = lib.platforms.unix;
  };
};
in mkProtobufDerivation(if (stdenv.buildPlatform != stdenv.hostPlatform)
                        then (mkProtobufDerivation null buildPackages.stdenv)
                        else null) stdenv
