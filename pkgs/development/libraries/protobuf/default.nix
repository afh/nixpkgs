{ lib
, stdenv
, abseil-cpp
, abseil-cpp_202103
, autoreconfHook
, buildPackages
, cmake
, fetchFromGitHub
, fetchpatch
, gtest
, zlib

  # downstream dependencies
, python3
, grpc
}:


let
  meta = {
    description = "Google's data interchange format";
    longDescription = ''
      Protocol Buffers are a way of encoding structured data in an efficient
      yet extensible format. Google uses Protocol Buffers for almost all of
      its internal RPC protocols and file formats.
    '';
    license = lib.licenses.bsd3;
    homepage = "https://protobuf.dev/";
    mainProgram = "protoc";
    maintainers = with lib.maintainers; [ jonringer ];
    platforms = lib.platforms.all;
  };
  make-protobuf = (import ./make-protobuf.nix) {
    inherit lib stdenv buildPackages cmake fetchFromGitHub fetchpatch gtest zlib python3 grpc meta;
  };
  make-protobuf-v3 = (import ./make-protobuf-v3.nix) {
    inherit lib stdenv buildPackages fetchFromGitHub autoreconfHook gtest zlib meta;
  };
in
{
  protobuf_25 = make-protobuf {
    version = "25.3";
    hash = "sha256-N/mO9a6NyC0GwxY3/u1fbFbkfH7NTkyuIti6L3bc+7k=";
    inherit abseil-cpp;
  };
  protobuf_24 = make-protobuf {
    version = "24.4";
    hash = "sha256-I+Xtq4GOs++f/RlVff9MZuolXrMLmrZ2z6mkBayqQ2s=";
    inherit abseil-cpp;
  };
  protobuf_23 = make-protobuf {
    version = "23.4";
    hash = "sha256-eI+mrsZAOLEsdyTC3B+K+GjD3r16CmPx1KJ2KhCwFdg=";
    inherit abseil-cpp;
  };
  protobuf_21 = make-protobuf {
    version = "21.12";
    hash = "sha256-VZQEFHq17UsTH5CZZOcJBKiScGV2xPJ/e6gkkVliRCU=";
    abseil-cpp = abseil-cpp_202103;
  };
  protobuf3_20 = make-protobuf-v3 {
    version = "3.20.3";
    hash = "sha256-u/1Yb8+mnDzc3OwirpGESuhjkuKPgqDAvlgo3uuzbbk=";
    abseil-cpp = abseil-cpp_202103;
  };
}
