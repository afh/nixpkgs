{
  lib,
  stdenv,
  fetchFromGitHub,
  which,
  curl,
  makeWrapper,
  jdk,
  writeScript,
  common-updater-scripts,
  cacert,
  git,
  nix,
  jq,
  coreutils,
  gnused,
}:

stdenv.mkDerivation rec {
  pname = "sbt-extras";
  rev = "b317f2ef85a28d8e1ee1566a1ad7937b2c3888ec";
  version = "2025-06-15";

  src = fetchFromGitHub {
    owner = "paulp";
    repo = "sbt-extras";
    inherit rev;
    sha256 = "xfd/jgGsbkuHrWAujglKlGFtMa3iigzhHZaI5I1XZN4=";
  };

  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    substituteInPlace bin/sbt --replace 'declare java_cmd="java"' 'declare java_cmd="${jdk}/bin/java"'

    install bin/sbt $out/bin

    wrapProgram $out/bin/sbt --prefix PATH : ${
      lib.makeBinPath [
        which
        curl
      ]
    }

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/sbt -h >/dev/null
  '';

  passthru.updateScript = writeScript "update.sh" ''
     #!${stdenv.shell}
     set -xo errexit
     PATH=${
       lib.makeBinPath [
         common-updater-scripts
         curl
         cacert
         git
         nix
         jq
         coreutils
         gnused
       ]
     }
    oldVersion="$(nix-instantiate --eval -E "with import ./. {}; lib.getVersion ${pname}" | tr -d '"')"
     latestSha="$(curl -L -s https://api.github.com/repos/paulp/sbt-extras/commits\?sha\=master\&since\=$oldVersion | jq -r '.[0].sha')"
    if [ ! "null" = "$latestSha" ]; then
       latestDate="$(curl -L -s https://api.github.com/repos/paulp/sbt-extras/commits/$latestSha | jq '.commit.committer.date' | sed 's|"\(.*\)T.*|\1|g')"
       update-source-version ${pname} "$latestSha" --version-key=rev
       update-source-version ${pname} "$latestDate" --ignore-same-hash
     else
       echo "${pname} is already up-to-date"
     fi
  '';

  meta = {
    description = "More featureful runner for sbt, the simple/scala/standard build tool";
    homepage = "https://github.com/paulp/sbt-extras";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [
      nequissimus
      puffnfresh
    ];
    mainProgram = "sbt";
    platforms = lib.platforms.unix;
  };
}
