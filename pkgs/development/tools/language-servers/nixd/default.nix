{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  boost,
  gtest,
  llvmPackages,
  meson,
  ninja,
  nixVersions,
  nix-update-script,
  nixd,
  nixf,
  nixt,
  nlohmann_json,
  pkg-config,
  testers,
  python3,
}:

let
  nix = nixVersions.nix_2_28;
  common = rec {
    version = "2.6.4";

    src = fetchFromGitHub {
      owner = "nix-community";
      repo = "nixd";
      tag = version;
      hash = "sha256-K7S626SPzlNCmRhntSKhGP1iyHJXBZEeHliX4iEwbKk=";
    };

    nativeBuildInputs = [
      meson
      ninja
      python3
      pkg-config
    ];

    mesonBuildType = "release";

    strictDeps = true;

    doCheck = true;

    meta = {
      homepage = "https://github.com/nix-community/nixd";
      changelog = "https://github.com/nix-community/nixd/releases/tag/${version}";
      license = lib.licenses.lgpl3Plus;
      maintainers = with lib.maintainers; [
        inclyc
        Ruixi-rebirth
        aleksana
        redyf
      ];
      platforms = lib.platforms.unix;
    };
  };
in
{
  nixf = stdenv.mkDerivation (
    common
    // {
      pname = "nixf";

      sourceRoot = "${common.src.name}/libnixf";

      outputs = [
        "out"
        "dev"
      ];

      buildInputs = [
        gtest
        boost
        nlohmann_json
      ];

      passthru.tests.pkg-config = testers.hasPkgConfigModules {
        package = nixf;
        moduleNames = [ "nixf" ];
      };

      meta = common.meta // {
        description = "Nix language frontend, parser & semantic analysis";
        mainProgram = "nixf-tidy";
      };
    }
  );

  nixt = stdenv.mkDerivation (
    common
    // {
      pname = "nixt";

      sourceRoot = "${common.src.name}/libnixt";

      outputs = [
        "out"
        "dev"
      ];

      buildInputs = [
        nix
        gtest
        boost
      ];

      passthru.tests.pkg-config = testers.hasPkgConfigModules {
        package = nixt;
        moduleNames = [ "nixt" ];
      };

      meta = common.meta // {
        description = "Supporting library that wraps C++ nix";
      };
    }
  );

  nixd = stdenv.mkDerivation (
    common
    // {
      pname = "nixd";

      sourceRoot = "${common.src.name}/nixd";

      buildInputs = [
        nix
        nixf
        nixt
        llvmPackages.llvm
        gtest
        boost
      ];

      nativeBuildInputs = common.nativeBuildInputs ++ [ cmake ];

      # See https://github.com/nix-community/nixd/issues/519
      doCheck = false;

      passthru = {
        updateScript = nix-update-script { };
        tests.version = testers.testVersion { package = nixd; };
      };

      meta = common.meta // {
        description = "Feature-rich Nix language server interoperating with C++ nix";
        mainProgram = "nixd";
      };
    }
  );
}
