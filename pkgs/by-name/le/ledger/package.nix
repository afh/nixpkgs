{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  boost188,
  gmp,
  mpfr,
  libedit,
  python3,
  gpgme2,
  gpgmepp,
  installShellFiles,
  texinfo,
  gnused,
  usePython ? false,
  gpgmeSupport ? false,
}:

let
  boost = boost188;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ledger";
  version = "3.3.2-unstable-2025-08-17";

  src = fetchFromGitHub {
    owner = "ledger";
    repo = "ledger";
    rev = "bbfe4808aaefa6e898aa96127d340bab30f54008";
    hash = "sha256-jnuPoF2sQFXjZrsgGs/kgxLq5t1y1JKzufc6Z/FcZAg=";
  };

  postPatch = ''
    # Replace deprecated asString with asStdString
    # see https://github.com/gpg/gpgmepp/blob/cd13d4b00cd19d723574acf843abee95111070fb/src/error.h#L50
    substituteInPlace src/gpgme.cc \
      --replace-fail 'asString' 'asStdString'
  '';

  outputs = [
    "out"
    "dev"
  ]
  ++ lib.optionals usePython [ "py" ];

  buildInputs = [
    gmp
    mpfr
    libedit
    gnused
  ]
  ++ lib.optionals gpgmeSupport [
    gpgme2
    gpgmepp
  ]
  ++ (
    if usePython then
      [
        python3
        (boost.override {
          enablePython = true;
          python = python3;
        })
      ]
    else
      [ boost ]
  );

  nativeBuildInputs = [
    cmake
    texinfo
    installShellFiles
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DBUILD_DOCS:BOOL=ON"
    "-DUSE_PYTHON:BOOL=${if usePython then "ON" else "OFF"}"
    "-DUSE_GPGME:BOOL=${if gpgmeSupport then "ON" else "OFF"}"
  ];

  # by default, it will query the python interpreter for it's sitepackages location
  # however, that would write to a different nixstore path, pass our own sitePackages location
  prePatch = lib.optionalString usePython ''
    substituteInPlace src/CMakeLists.txt \
      --replace 'DESTINATION ''${Python_SITEARCH}' 'DESTINATION "${placeholder "py"}/${python3.sitePackages}"'
  '';

  installTargets = [
    "doc"
    "install"
  ];

  postInstall = ''
    installShellCompletion --cmd ledger --bash $src/contrib/ledger-completion.bash
  '';

  meta = {
    description = "Double-entry accounting system with a command-line reporting interface";
    mainProgram = "ledger";
    homepage = "https://www.ledger-cli.org/";
    changelog = "https://github.com/ledger/ledger/raw/v${finalAttrs.version}/NEWS.md";
    license = lib.licenses.bsd3;
    longDescription = ''
      Ledger is a powerful, double-entry accounting system that is accessed
      from the UNIX command-line. This may put off some users, as there is
      no flashy UI, but for those who want unparalleled reporting access to
      their data, there really is no alternative.
    '';
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ jwiegley ];
  };
})
