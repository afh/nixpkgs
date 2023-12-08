{ lib
, stdenv
, fetchurl
, buildGoModule
, glfw
, freetype
, pkg-config
, darwin
}:

let
  inherit (darwin.apple_sdk.frameworks) Cocoa;
in
buildGoModule rec {
  pname = "vertigo";
  version = "0.2.1";

  src = fetchurl {
    url = "https://humungus.tedunangst.com/r/vertigo/d/vertigo-${version}.tgz";
    hash = "sha512-c1VPHBT857HEFBwz9ltatVTXD35W2oOmCQ50Cw13iWf3aUvCPy++bkqJDRQKja/VLE+UrrvVJ3IEGXDZv/6Zug==";
  };

  vendorHash = null;

  postPatch = ''
    substituteInPlace vendor/humungus.tedunangst.com/r/glfw3/build.go \
      --replace "/opt/homebrew/opt/glfw" "${glfw}"
  '';

  preBuild = ''
    export HOME=$TMPDIR
  '';

  buildInputs = [
    glfw freetype
  ]
  ++ lib.optionals stdenv.isDarwin [
    Cocoa
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  meta = {
    description = "A terminal emulator";
    homepage = "https://humungus.tedunangst.com/r/vertigo";
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ afh ];
  };
}

