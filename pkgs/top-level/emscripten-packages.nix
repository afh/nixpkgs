{ pkgs }:

with pkgs;

# emscripten toolchain abstraction for nix
# https://github.com/NixOS/nixpkgs/pull/16208

rec {
  boost =
    (pkgs.boost.override {
      toolset = "emscripten";
      enableStatic = true;
      enableShared = false;
      enableSingleThreaded = true;
      enableMultiThreaded = false;
      useMpi = false;
      extraB2Args = [
        ''cxxflags="-fdeclspec -Os"''
        "address-model=32"
        "--without-graph_parallel"
        "--without-type_erasure"
        "--prefix=${placeholder "out"}"
        # The following boost libraries cause errors when building with emscripten
        "--without-process"
        "--without-contract"
        "--without-container"
        "--without-log"
        "--without-json"
        "--without-python"
      ];
    }).overrideAttrs
      (old: {
        pname = "emscripten-${lib.getName old}";
        outputs = [
          "out"
          "dev"
        ];
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          writableTmpDirAsHomeHook
          emscripten
        ];
        configureScript = "emconfigure ${old.configureScript}";
        doCheck = true;
        checkPhase = ''
          mkdir -p .emscriptencache
          export EM_CACHE=$PWD/.emscriptencache
          ${lib.getExe' emscripten "emcc"} -O2 -o example.js -I. libs/uuid/test/test_hash.cpp
          ${lib.getExe nodejs} ./example.js
          ${lib.getExe' emscripten "emcc"} -O2 -o example.js -I. libs/date_time/example/gregorian/localization.cpp
          ${lib.getExe nodejs} ./example.js
        '';
      });

  gmp =
    (pkgs.gmp.override {
      stdenv = emscriptenStdenv;
      cxx = true;
    }).overrideAttrs
      (old: {
        outputs = [ "out" ];
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          writableTmpDirAsHomeHook
          which
        ];
        configureFlags = lib.remove "ABI=64" (old.configureFlags or [ ]) ++ [
          "--disable-shared"
          "--enable-static"
          "--host=wasm32"
          "--prefix=${placeholder "out"}"
        ];
        configurePhase = ''
          mkdir -p $PWD/.emscriptencache
          export EM_CACHE=$PWD/.emscriptencache
          emconfigure ./configure $configureFlags
        '';
        buildPhase = ''
          emmake make
        '';
        checkPhase = ''
          emcc -O2 -o example.js demos/isprime.c -I. -L.libs -lgmp
          ${lib.getExe nodejs} ./example.js 23 42 | grep -E '^(23 is a prime|42 is composite)$'
        '';
        installPhase = ''
          mkdir -p $out
          emmake make install
        '';
      });

  json_c =
    (pkgs.json_c.override {
      stdenv = pkgs.emscriptenStdenv;
    }).overrideAttrs
      (old: {
        nativeBuildInputs = [
          pkg-config
          cmake
        ];
        propagatedBuildInputs = [ zlib ];
        configurePhase = ''
          HOME=$TMPDIR
          mkdir -p .emscriptencache
          export EM_CACHE=$(pwd)/.emscriptencache
          emcmake cmake . $cmakeFlags -DCMAKE_INSTALL_PREFIX=$out -DCMAKE_INSTALL_INCLUDEDIR=$dev/include
        '';
        checkPhase = ''
          echo "================= testing json_c using node ================="

          echo "Compiling a custom test"
          set -x
          emcc -O2 -s EMULATE_FUNCTION_POINTER_CASTS=1 tests/test1.c \
            `pkg-config zlib --cflags` \
            `pkg-config zlib --libs` \
            -I . \
            libjson-c.a \
            -o ./test1.js

          echo "Using node to execute the test which basically outputs an error on stderr which we grep for"
          ${pkgs.nodejs}/bin/node ./test1.js

          set +x
          if [ $? -ne 0 ]; then
            echo "test1.js execution failed -> unit test failed, please fix"
            exit 1;
          else
            echo "test1.js execution seems to work! very good."
          fi
          echo "================= /testing json_c using node ================="
        '';
      });

  ledger =
    (pkgs.ledger.override {
      stdenv = emscriptenStdenv;
      boost = boost;
      gmp = gmp;
      mpfr = mpfr;
      usePython = false;
    }).overrideAttrs
      (old: {
        src = fetchFromGitHub {
          owner = "gudzpoz";
          repo = "ledger";
          #rev = "v${version}";
          rev = "emscripten-build";
          hash = "sha256-3fCYFxKclIZFfJVAILHq0jWuC9hK0yk61+iq3jDIZ+I=";
        };
        patches = [];
        patchPhase = ''
          substituteInPlace src/CMakeLists.txt \
            --replace-fail \
              "target_compile_options(libledger PRIVATE -fwasm-exceptions)" \
              "target_compile_options(libledger PRIVATE -fwasm-exceptions)
              target_compile_definitions(libledger PRIVATE BOOST_DATE_TIME_USE_CLASSIC_LOCALE)" \
            --replace-fail \
              "target_compile_options(ledger PRIVATE -fwasm-exceptions)" \
              'target_compile_options(ledger PRIVATE -fwasm-exceptions)
              target_compile_definitions(ledger PRIVATE BOOST_DATE_TIME_USE_CLASSIC_LOCALE)'
        '';
        buildInputs = (old.buildInputs or [ ]) ++ [
          boost gmp mpfr
        ];
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          writableTmpDirAsHomeHook
          which
        ];
        propagatedBuildInputs = [ boost gmp mpfr ];
        configurePhase = ''
          emcmake cmake -S . -B build \
            -DBUILD_LIBRARY=OFF \
            -DCMAKE_CXX_FLAGS="-flto -DBOOST_DATE_TIME_NO_LOCALE" \
            -DCMAKE_EXE_LINKER_FLAGS="-Wl,--gc-sections -lnodefs.js -lnoderawfs.js -sSTACK_SIZE=1048576"
        '';
        buildPhase = ''
          #export LDFLAGS="-lnodefs.js -lnoderawfs.js -sSTACK_SIZE=1048576"
          emmake make -C build -j8

          # Fix Emscripten TTY issue, for details see
          # https://github.com/emscripten-core/emscripten/issues/22264
          sed -i.bak \
              -e '1i #!${lib.getExe nodejs}' \
              -e 's/if\s*(!stream.tty)/if(!stream.tty||!stream.tty.ops)/g' \
              -e 's/,\s*tty:\s*true,/,tty:false,/g' \
              build/ledger.js
        '';
        checkPhase = ''
          ${lib.getExe nodejs} build/ledger.js --version | grep -o 'Ledger ${old.version}'
        '';
        installPhase = ''
          mkdir -p $out
          install -Dm555 build/ledger.js $out
          install -Dm444 build/ledger.wasm $out
        '';
        # Fails to build on darwin due to:
        # wasm-ld: error: greg_month.o: section too large
        meta = old.meta // { platforms = lib.platforms.linux; };
      });

  libxml2 =
    (pkgs.libxml2.override {
      stdenv = emscriptenStdenv;
      pythonSupport = false;
    }).overrideAttrs
      (old: {
        propagatedBuildInputs = [ zlib ];
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkg-config ];

        # just override it with nothing so it does not fail
        autoreconfPhase = "echo autoreconfPhase not used...";
        configurePhase = ''
          HOME=$TMPDIR
          mkdir -p .emscriptencache
          export EM_CACHE=$(pwd)/.emscriptencache
          emconfigure ./configure --prefix=$out --without-python
        '';
        checkPhase = ''
          echo "================= testing libxml2 using node ================="

          echo "Compiling a custom test"
          set -x
          emcc -O2 -s EMULATE_FUNCTION_POINTER_CASTS=1 xmllint.o \
          ./.libs/${
            if pkgs.stdenv.hostPlatform.isDarwin then "libxml2.dylib" else "libxml2.a"
          } `pkg-config zlib --cflags` `pkg-config zlib --libs` -o ./xmllint.test.js \
          --embed-file ./test/xmlid/id_err1.xml

          echo "Using node to execute the test which basically outputs an error on stderr which we grep for"
          ${pkgs.nodejs}/bin/node ./xmllint.test.js --noout test/xmlid/id_err1.xml 2>&1 | grep 0bar

          set +x
          if [ $? -ne 0 ]; then
            echo "xmllint unit test failed, please fix this package"
            exit 1;
          else
            echo "since there is no stupid text containing 'foo xml:id' it seems to work! very good."
          fi
          echo "================= /testing libxml2 using node ================="
        '';
      });

  mpfr =
    (pkgs.mpfr.override {
      stdenv = emscriptenStdenv;
      gmp = gmp;
    }).overrideAttrs
      (old: {
        outputs = [ "out" ];
        propagatedBuildInputs = [ gmp ];
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          writableTmpDirAsHomeHook
        ];
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--disable-shared"
          "--enable-static"
          "--with-gmp=${gmp}"
          "--prefix=${placeholder "out"}"
        ];
        configurePhase = ''
          emconfigure ./configure $configureFlags
        '';
        buildPhase = ''
          emmake make
        '';
        checkPhase = ''
          emcc -O2 -o example.js examples/sample.c -I${lib.getDev gmp}/include -Isrc -L${lib.getDev gmp}/lib -Lsrc/.libs -lgmp -lmpfr
          ${lib.getExe nodejs} ./example.js | grep -E '^Sum is 2.7182818284590452353602874713526624977572470936999595749669131e0$'
        '';
        installPhase = ''
          mkdir $out
          emmake make install
        '';
      });

  xmlmirror = pkgs.buildEmscriptenPackage rec {
    pname = "xmlmirror";
    version = "unstable-2016-06-05";

    buildInputs = [
      libtool
      gnumake
      libxml2
      nodejs
      openjdk
      json_c
    ];
    nativeBuildInputs = [
      pkg-config
      zlib
      autoconf
      automake
    ];

    src = pkgs.fetchgit {
      url = "https://gitlab.com/odfplugfest/xmlmirror.git";
      rev = "4fd7e86f7c9526b8f4c1733e5c8b45175860a8fd";
      sha256 = "1jasdqnbdnb83wbcnyrp32f36w3xwhwp0wq8lwwmhqagxrij1r4b";
    };

    configurePhase = ''
      rm -f fastXmlLint.js*
      # a fix for ERROR:root:For asm.js, TOTAL_MEMORY must be a multiple of 16MB, was 234217728
      # https://gitlab.com/odfplugfest/xmlmirror/issues/8
      sed -e "s/TOTAL_MEMORY=234217728/TOTAL_MEMORY=268435456/g" -i Makefile.emEnv
      # https://github.com/kripken/emscripten/issues/6344
      # https://gitlab.com/odfplugfest/xmlmirror/issues/9
      sed -e "s/\$(JSONC_LDFLAGS) \$(ZLIB_LDFLAGS) \$(LIBXML20_LDFLAGS)/\$(JSONC_LDFLAGS) \$(LIBXML20_LDFLAGS) \$(ZLIB_LDFLAGS) /g" -i Makefile.emEnv
      # https://gitlab.com/odfplugfest/xmlmirror/issues/11
      sed -e "s/-o fastXmlLint.js/-s EXTRA_EXPORTED_RUNTIME_METHODS='[\"ccall\", \"cwrap\"]' -o fastXmlLint.js/g" -i Makefile.emEnv
      mkdir -p .emscriptencache
      export EM_CACHE=$(pwd)/.emscriptencache
    '';

    buildPhase = ''
      HOME=$TMPDIR
      make -f Makefile.emEnv
    '';

    outputs = [
      "out"
      "doc"
    ];

    installPhase = ''
      mkdir -p $out/share
      mkdir -p $doc/share/${pname}

      cp Demo* $out/share
      cp -R codemirror-5.12 $out/share
      cp fastXmlLint.js* $out/share
      cp *.xsd $out/share
      cp *.js $out/share
      cp *.xhtml $out/share
      cp *.html $out/share
      cp *.json $out/share
      cp *.rng $out/share
      cp README.md $doc/share/${pname}
    '';
    checkPhase = '''';
  };

  zlib =
    (pkgs.zlib.override {
      stdenv = pkgs.emscriptenStdenv;
    }).overrideAttrs
      (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkg-config ];
        # we need to reset this setting!
        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE = "";
        };
        dontStrip = true;
        outputs = [ "out" ];
        buildPhase = ''
          emmake make
        '';
        installPhase = ''
          emmake make install
        '';
        checkPhase = ''
          echo "================= testing zlib using node ================="

          echo "Compiling a custom test"
          set -x
          emcc -O2 -s EMULATE_FUNCTION_POINTER_CASTS=1 test/example.c -DZ_SOLO \
          -L. libz.a -I . -o example.js

          echo "Using node to execute the test"
          ${pkgs.nodejs}/bin/node ./example.js

          set +x
          if [ $? -ne 0 ]; then
            echo "test failed for some reason"
            exit 1;
          else
            echo "it seems to work! very good."
          fi
          echo "================= /testing zlib using node ================="
        '';

        postPatch = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          substituteInPlace configure \
            --replace '/usr/bin/libtool' 'ar' \
            --replace 'AR="libtool"' 'AR="ar"' \
            --replace 'ARFLAGS="-o"' 'ARFLAGS="-r"'
        '';
      });

}
