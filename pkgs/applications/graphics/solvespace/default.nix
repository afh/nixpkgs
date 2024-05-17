{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, wrapGAppsHook3
, at-spi2-core
, cairo
, dbus
, eigen
, freetype
, fontconfig
, glew
, gtkmm3
, json_c
, libdatrie
, libepoxy
, libGLU
, libpng
, libselinux
, libsepol
, libspnav
, libthai
, libxkbcommon
, openmp
, pangomm
, pcre
, util-linuxMinimal # provides libmount
, xorg
, zlib
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "solvespace";
  version = "3.1";

  src = fetchFromGitHub {
    owner = "solvespace";
    repo = "solvespace";
    rev = "v${finalAttrs.version}";
    hash = "sha256-sSDht8pBrOG1YpsWfC/CLTTWh2cI5pn2PXGH900Z0yA=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    at-spi2-core
    cairo
    dbus
    eigen
    freetype
    fontconfig
    glew
    gtkmm3
    json_c
    libdatrie
    libepoxy
    libGLU
    libpng
    libspnav
    libthai
    libxkbcommon
    pangomm
    pcre
    xorg.libpthreadstubs
    xorg.libXdmcp
    xorg.libXtst
    zlib
  ] ++ lib.optionals stdenv.isDarwin [
    openmp
  ] ++ lib.optionals stdenv.isLinux [
    libselinux
    libsepol
    util-linuxMinimal
  ];

  postPatch = ''
    patch CMakeLists.txt <<EOF
    @@ -20,9 +20,9 @@
     # NOTE TO PACKAGERS: The embedded git commit hash is critical for rapid bug triage when the builds
     # can come from a variety of sources. If you are mirroring the sources or otherwise build when
     # the .git directory is not present, please comment the following line:
    -include(GetGitCommitHash)
    +# include(GetGitCommitHash)
     # and instead uncomment the following, adding the complete git hash of the checkout you are using:
    -# set(GIT_COMMIT_HASH 0000000000000000000000000000000000000000)
    +set(GIT_COMMIT_HASH ${finalAttrs.src.rev})
    EOF
  '' + lib.optionalString stdenv.isDarwin ''
    substituteInPlace src/CMakeLists.txt \
      --replace-fail "\''${OpenMP_CXX_INCLUDE_DIRS}/../lib/libomp.dylib" \
                     "${lib.getLib openmp}/lib/libomp.dylib"
    # This is a workaround to avoid depending on Xcode. Unfortunately
    substituteInPlace res/CMakeLists.txt \
      --replace-fail "iconutil" "\''${ICONUTIL}" \
      --replace-fail "ibtool" "\''${IBTOOL}"
  '';

  postInstall = lib.optionalString stdenv.isDarwin ''
    mkdir -p $out/Applications
    cp -r bin/SolveSpace.app $out/Applications/SolveSpace.app

    install_name_tool -add_rpath $out/lib $out/Applications/SolveSpace.app/Contents/MacOS/SolveSpace

    for wrapper in SolveSpace solvespace-cli; do
      makeWrapper $out/Applications/SolveSpace.app/Contents/MacOS/$wrapper $out/bin/$wrapper
    done
  '';

  CXXFLAGS = lib.optionals stdenv.isDarwin
    [ "-Wno-unused-but-set-variable" ];

  cmakeFlags = [
    "-DENABLE_OPENMP=ON"
  ] ++ lib.optionals stdenv.isDarwin [
    "-DICONUTIL=/usr/bin/iconutil"
    "-DIBTOOL=/usr/bin/ibtool"
  ];

  meta = {
    description = "Parametric 3d CAD program";
    license = lib.licenses.gpl3Plus;
    maintainers = [ lib.maintainers.edef ];
    platforms = with lib.platforms; linux ++ darwin;
    homepage = "https://solvespace.com";
    changelog = "https://github.com/solvespace/solvespace/raw/v${finalAttrs.version}/CHANGELOG.md";
  };
})
