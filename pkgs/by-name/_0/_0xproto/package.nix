{
  lib,
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "0xproto";
  version = "2.100";

  src =
    let
      underscoreVersion = builtins.replaceStrings [ "." ] [ "_" ] version;
    in
    fetchzip {
      url = "https://github.com/0xType/0xProto/releases/download/${version}/0xProto_${underscoreVersion}.zip";
      hash = "sha256-hUQGCsktnun9924+k6ECQuQ1Ddl/qGmtuLWERh/vDpc=";
    };

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/share/fonts/opentype/ *.otf
    install -Dm644 -t $out/share/fonts/truetype/ *.ttf
    runHook postInstall
  '';

  meta = {
    description = "Free and Open-source font for programming";
    homepage = "https://github.com/0xType/0xProto";
    license = lib.licenses.ofl;
    maintainers = with lib.maintainers; [ edswordsmith ];
    platforms = lib.platforms.all;
  };
}
