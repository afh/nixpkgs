{
  stdenv,
  gccStdenv,
  binutils,
  glibc,
  lib,
  bash,
  fetchurl,
  # fetchzip,
  writeText,
  ed,
  writableTmpDirAsHomeHook,
  flex,
  bison,
  sysctl,
  curl,
  unzip,
}:

let
  stdenv' = if stdenv.isLinux then gccStdenv else stdenv;

  #pkgtools = fetchzip {
  #  url = "https://downloads.kergis.com/kertex/pkg/src/pkgtools.zip";
  #  hash = "sha256-ct4seLpNwxOU5o01UdhJZtPNIDEP4F4Nk25TGazdtB4=";
  #  stripRoot = false;
  #};

  prote_doc = fetchurl {
    url = "https://downloads.kergis.com/kertex/prote_man.pdf";
    hash = "sha256-0xL2m/f90TmvDS1xirw+AsS1X24Wj2jG+nLf09Ekaks=";
  };

  knuth-source =
    let
      version = "2021.02.10";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/knuth_${version}.tar.gz";
      hash = "sha256-biyNPLUjqhqck/CCDTlGu80YFiL49aLUNOQ0b4xjsdU=";
    };

  etex-source =
    let
      version = "2.1.0.1";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/etex_${version}.tar.gz";
      hash = "sha256-qzbNfWO2lw0NYmQvOqZyuG1nWJhqecnZVy3IhiY7bng=";
    };

  bibtex-source =
    let
      version = "0.99d";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/bibtex_${version}.tar.gz";
      hash = "sha256-+ak9EQOnLJbxrSBwuzJ6hfvOBF/dA898vFWzvzcmzGQ=";
    };

  ams-source =
    let
      version = "3.04";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/ams_${version}.tar.gz";
      hash = "sha256-wThCDW070iwIznT88bm+deBkhFIaHyfrf7DGGPoW7ck=";
    };

  adobe-source =
    let
      version = "2011.12.31";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/adobe_${version}.tar.gz";
      hash = "sha256-UC1AnaeeX62tbcOo9pqAOO5H2hyqB0IHyqnwFxjmBAQ=";
    };

  kertex_M-source =
    let
      version = "1.1.0.2";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/kertex_M_${version}.tar.gz";
      hash = "sha256-UmKUbIqiBNk3OhzxPC7mKMwlOEVH5EZowU0OZHxya7k=";
    };

  kertex_T-source =
    let
      version = "0.99.25.02";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/kertex_T_${version}.tar.gz";
      hash = "sha256-RewgysK7EtnR552WrC78RP2BPNRRiSiW51SQ0oH7bNA=";
    };

  risk_comp-source =
    let
      version = "1.20.99.6";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/risk_comp_${version}.tar.gz";
      hash = "sha256-2RV6w8S6ScJz7NWuZppaq/TqliWSme/XTFa8qRYakYw=";
    };

  my_conf = writeText "my_conf" ''
    USER0=_nixbld1
    GROUP0=nixbld
    TARGETOPTDIR=${placeholder "out"}
    TARGETSHELL=${lib.getExe bash}
    OBJDIRPREFIX=$PWD/../obj
    OBJDIR=objdir
    TARGET_SUBTYPE=$TARGET_SUBTYPE
    # TODO: Make configurable
    WITH_2D_MF=YES
    HUGETEX=NO
    #MAKE_STATIC=YES
  '';
in

stdenv'.mkDerivation {
  pname = "kertex";
  version = "0.99.25.02";

  unpackPhase = ''
    for tgz in \
      ${risk_comp-source} \
      ${knuth-source} \
      ${etex-source} \
      ${bibtex-source} \
      ${ams-source} \
      ${adobe-source} \
      ${kertex_M-source} \
      ${kertex_T-source} \
      ; do
      tar zxf $tgz
    done
  '';

  postPatch = ''
    sed -i -e 's@test -f "''${M_CROSS_PATH_PREFIX}$p/$rsolib"@test true@' \
      risk_comp/sys/posix/sh1/lib/librkcompsh

    substituteInPlace kertex_T/pkg/sys/sh1/lib/unix.data \
      --replace-fail '@@SYS_HTTPC@@' 'curl'

    substituteInPlace risk_comp/sys/posix/lib/C_{clang,posix} \
      --replace-fail 'CC=$(rk_which_cmd_of c' "CC=${lib.getExe stdenv'.cc.cc} #c"

    substituteInPlace risk_comp/sys/posix/lib/C_gcc \
      --replace-fail 'CC=$(rk_which_cmd_of g' "CC=${lib.getExe stdenv'.cc.cc} #g"

    #substituteInPlace \
    #  kertex_T/pkg/rcp/{,core,tools}/pkg.sh \
    #  kertex_T/pkg/proto/latex.rct \
    #  kertex_T/pkg/sys/sh1/lib/ctrl/template.sh \
    #  kertex_T/mpware/sh1/{mp2ps,troffmpx,texmpx}/sh.data
    #  kertex_T/pkg/sh1/{bulk_get,sketch}/sh \
    #  kertex_T/dviware/bin1/dvips/makefont.c \
    #  kertex_T/share/kertex/pkg/proto/latex.rct \
    #  --replace-fail '. which_kertex' ". $out/bin/which_kertex"

    #substituteInPlace risk_comp/sys/posix/lib/T_darwin \
    #  --replace-fail 'LIB_TYPES="static ' 'LIB_TYPES="'
  ''
  + lib.optionalString stdenv'.hostPlatform.isDarwin ''
    sed -i -e '/= static/s/.*/if [ $lib = "libSystem.B" ]; then continue; fi\n&/' \
      risk_comp/sys/posix/sh1/rkbuild

    # libc and libm are both part of libSystem
    substituteInPlace risk_comp/sys/posix/lib/T_darwin \
      --replace-fail "libc__" "libSystem.B"

    substituteInPlace risk_comp/sys/posix/sh1/rkinstall \
      --replace-fail 'third parties files"' 'third parties files"; pwd; sed -i -e "/.*libSystem.*/d" installed.list'

    substituteInPlace risk_comp/sys/posix/lib/darwin.cmds \
      --replace-fail 'su $USER0 -c "$1"' '$1'

    substituteInPlace risk_comp/sys/posix/lib/{M_darwin,darwin.cmds} \
      --replace-fail 'FSLINK="ln -sfh"' 'FSLINK="ln -sfn"'

    substituteInPlace risk_comp/sys/posix/lib/M_darwin \
      --replace-fail "availcpu" "ncpu" # fails with "sysctl: unknown oid 'n.availacpu'" otherwise
  '';

  # Is ed truly a buildInput or just nativeBuildInput?
  buildInputs = [
    flex
    bison
    ed
  ]
  ++ lib.optional stdenv'.isLinux [ binutils glibc.static glibc stdenv'.cc.cc ];


  nativeBuildInputs = [
    writableTmpDirAsHomeHook
    sysctl # Darwin only?
    curl
    unzip
  ];

  configurePhase = ''
    runHook preConfigure

    install -Dm644 ${my_conf} $PWD/${my_conf.name}

    runHook preConfigure
  '';

  enableParallelBuilding = false;

  buildPhase = ''
    runHook preBuild

    . risk_comp/sys/posix/lib/T_${stdenv'.targetPlatform.parsed.kernel.name}

    (
    cd kertex_M
    objdir="$(../risk_comp/sys/posix/sh1/rkconfig ../${my_conf.name})"
    cd $objdir
    make SAVE_SPACE=NO all
    )

    cd kertex_T
    objdir="$(../risk_comp/sys/posix/sh1/rkconfig ../${my_conf.name})"
    cd $objdir
    make SAVE_SPACE=NO all

    make SAVE_SPACE=NO pkg

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    make SAVE_SPACE=NO local_install

    install -Dm444 ${prote_doc} $out/share/kergte/doc

    #export PATH=$out/bin:$PATH # Add path to which_kertex
    #bash $out/share/kertex/pkg/rcp/tools@pkg.sh install
    #bash $out/share/kertex/pkg/rcp/core@pkg.sh install
    #bash $out/share/kertex/pkg/rcp/rcp@pkg.sh install

    runHook postInstall
  '';
}
