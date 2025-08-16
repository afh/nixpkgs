{
  fetchurl,
  installShellFiles,
  lib,
  makeWrapper,
  stdenv,
  writableTmpDirAsHomeHook,

  bash,
  bison,
  cacert,
  coreutils,
  curl,
  ed,
  findutils,
  flex,
  ghostscript_headless,
  glibc,
  gnused,
  inetutils,
  sysctl,
  unzip,
}:

# Build with  --option sandbox relaxed on NixOS until FODs are added
# https://downloads.kergis.com/kertex/README
# https://github.com/tlaronde/kertex_pkg

let
  sources = import ./sources.nix { inherit fetchurl; };
in
stdenv.mkDerivation {
  inherit (sources) version;

  pname = "kertex";
  __noChroot = true;

  unpackPhase = ''
    for tgz in \
      ${sources.adobe-source} \
      ${sources.ams-source} \
      ${sources.bibtex-source} \
      ${sources.etex-source} \
      ${sources.kertex_M-source} \
      ${sources.kertex_T-source} \
      ${sources.knuth-source} \
      ${sources.risk_comp-source} \
      ; do
      tar zxf $tgz
    done
  '';

  postPatch = ''

    substituteInPlace kertex_T/pkg/sys/sh1/lib/unix.data \
      --replace-fail '@@SYS_HTTPC@@' 'curl' \
      --replace-fail '@@SYS_FTPC@@' 'ftp'

    substituteInPlace kertex_T/mpware/bin1/dmp/Makefile.ker \
      --replace-fail 'MAKE_STATIC=YES' 'MAKE_STATIC=NO'

    # ''${placeholder "out"} instead of $out?
    substituteInPlace \
      kertex_T/pkg/rcp/{,core,tools}/pkg.sh \
      kertex_T/pkg/proto/latex.rct \
      kertex_T/pkg/sys/sh1/lib/ctrl/template.sh \
      kertex_T/mpware/sh1/{mp2ps,troffmpx,texmpx}/sh.data \
      kertex_T/dviware/bin1/dvips/makefont.c \
      --replace-fail '. which_kertex' ". $out/bin/which_kertex"
      #kertex_T/pkg/sh1/{bulk_get,rcp_sketch}/sh{,.data} \
      #kertex_T/share/kertex/pkg/proto/latex.rct \

    #substituteInPlace risk_comp/sys/posix/lib/T_darwin \
    #  --replace-fail 'LIB_TYPES="static ' 'LIB_TYPES="'
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    sed -i -e 's@test -f "''${M_CROSS_PATH_PREFIX}$p/$rsolib"@test true@' \
      risk_comp/sys/posix/sh1/lib/librkcompsh

    sed -i \
      -e '/= static/s/.*/if [ $lib = "libSystem.B" ]; then continue; fi\n&/' \
      -e 's/OBJPROGDIR=$OBJPROGDIR/&\nvpath %.c $SRCDIR/' \
      risk_comp/sys/posix/sh1/rkbuild

    substituteInPlace risk_comp/sys/posix/lib/C_{clang,posix} \
      --replace-fail 'CC=$(rk_which_cmd_of c' "CC=${lib.getExe stdenv.cc.cc} #c"

    substituteInPlace risk_comp/sys/posix/lib/C_gcc \
      --replace-fail 'CC=$(rk_which_cmd_of g' "CC=${lib.getExe stdenv.cc.cc} #g"

    # libc and libm are both part of libSystem
    substituteInPlace risk_comp/sys/posix/lib/T_darwin \
      --replace-fail 'libc__' 'libSystem.B' \
      --replace-fail 'TARGET_ARCH=' '#TARGET_ARCH='

    substituteInPlace risk_comp/sys/posix/sh1/rkinstall \
      --replace-fail 'third parties files"' 'third parties files"; sed -i -e "/.*libSystem.*/d" installed.list'

    substituteInPlace risk_comp/sys/posix/lib/darwin.cmds \
      --replace-fail 'su $USER0 -c "$1"' '$1'

    substituteInPlace risk_comp/sys/posix/lib/{M_darwin,darwin.cmds} \
      --replace-fail 'FSLINK="ln -sfh"' 'FSLINK="ln -sfn"'

    substituteInPlace risk_comp/sys/posix/lib/M_darwin \
      --replace-fail 'availcpu' 'ncpu' # fails with "sysctl: unknown oid 'n.availacpu'" otherwise
  '';

  buildInputs = [
    cacert
    coreutils
    curl
    ed
    findutils
    ghostscript_headless
    gnused
    inetutils
    unzip
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    glibc
  ];

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
    writableTmpDirAsHomeHook

    bison
    flex
    sysctl # Darwin only?

    ed
    gnused
    ghostscript_headless
    findutils
    coreutils
  ];

  configurePhase = ''
    runHook preConfigure

    cat >my_conf <<EOF
    USER0=$(id -un)
    GROUP0=$(id -gn)
    TARGETOPTDIR=${placeholder "out"}
    TARGETSHELL=${lib.getExe bash}
    OBJDIRPREFIX=$PWD/obj
    OBJDIR=objdir
    #TARGET_SUBTYPE=$TARGET_SUBTYPE
    # TODO: Make configurable
    WITH_2D_MF=YES
    HUGETEX=YES
    MAKE_STATIC=NO
    MAKE_STATIC_LIB=NO
    EOF

    runHook preConfigure
  '';

  enableParallelBuilding = false;

  env = {
    SYS_LIB_PATH = lib.optionalString stdenv.hostPlatform.isLinux "${glibc}/lib";
  };

  buildPhase = ''
    runHook preBuild

    . risk_comp/sys/posix/lib/T_${stdenv.targetPlatform.parsed.kernel.name}

    (
    cd kertex_M
    objdir="$(../risk_comp/sys/posix/sh1/rkconfig ../my_conf)"
    cd $objdir
    make SAVE_SPACE=NO all
    )

    cd kertex_T
    objdir="$(../risk_comp/sys/posix/sh1/rkconfig ../my_conf)"
    cd $objdir
    make SAVE_SPACE=NO all

    make SAVE_SPACE=NO pkg

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    make SAVE_SPACE=NO local_install

    # TODO: Convert to fixed output derivation?
    bash $out/share/kertex/pkg/rcp/tools@pkg.sh install
    bash $out/share/kertex/pkg/rcp/core@pkg.sh install
    bash $out/share/kertex/pkg/rcp/rcp@pkg.sh install

    install -Dm444 ${sources.prote_doc} $out/share/kertex/doc/prote_man.pdf
    installManPage $out/share/kertex/man/man{1,8}/*

    runHook postInstall
  '';

  postInstall = ''
    rm -rf $out/share/kertex/man $out/share/kertex/prote/sellette/*.log

    # symlink KERTEX_BINDIR
    for f in "$out/bin/kertex"/*; do
      [ -f "$f" ] && [ -x "$f" ] && ln -s "$f" "$out/bin/$(basename "$f")"
    done
  '';

  postFixup = ''
    wrapProgram $out/bin/kertex/kpstopdf \
      --prefix PATH : ${lib.makeBinPath [
        coreutils
        ghostscript_headless
        gnused
      ]}
    wrapProgram $out/bin/kertex/mp2ps \
      --prefix PATH : ${lib.makeBinPath [
        coreutils
        ghostscript_headless
        gnused
      ]}
    wrapProgram $out/bin/kertex/mpgrid \
      --prefix PATH : ${lib.makeBinPath [
        coreutils
        gnused
      ]}
  '';

  installCheckPhase = ''
    runHook preInstallCheck

    for check in etex mf mpost prote tex; do
      $out/bin/kertex/adm/ck_''${check}
    done

    runHook postInstallCheck
  '';

  meta = {
    description = "TeX kernel system";
    homepage = "https://kertex.kergis.com/";
    #license = lib.licenses.bsd3; KerTEX PUBLIC LICENCE
    mainProgram = "etex"; # "iniprote";
    platforms = lib.platforms.all;
  };
}
