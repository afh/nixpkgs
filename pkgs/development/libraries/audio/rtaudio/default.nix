{ stdenv
, lib
, config
, fetchFromGitHub
, cmake
, pkg-config
, alsaSupport ? stdenv.hostPlatform.isLinux
, alsa-lib
, pulseaudioSupport ? config.pulseaudio or stdenv.hostPlatform.isLinux
, libpulseaudio
, jackSupport ? true
, jack
, coreaudioSupport ? stdenv.hostPlatform.isDarwin
, CoreAudio
}:

stdenv.mkDerivation rec {
  pname = "rtaudio";
  version = "5.2.0";

  src = fetchFromGitHub {
    owner = "thestk";
    repo = "rtaudio";
    rev = version;
    sha256 = "0xvahlfj3ysgsjsp53q81hayzw7f99n1g214gh7dwdr52kv2l987";
  };

  nativeBuildInputs = [ cmake pkg-config ];

  buildInputs = lib.optional alsaSupport alsa-lib
    ++ lib.optional pulseaudioSupport libpulseaudio
    ++ lib.optional jackSupport jack
    ++ lib.optional coreaudioSupport CoreAudio;

  cmakeFlags = lib.cmakeBools
  (lib.attrsets.prefixAttrsNameWith "RTAUDIO_API_" {
    ALSA = alsaSupport;
    PULSE = pulseaudioSupport;
    JACK = jackSupport;
    CORE = coreaudioSupport;
  });

  meta = with lib; {
    description = "A set of C++ classes that provide a cross platform API for realtime audio input/output";
    homepage = "https://www.music.mcgill.ca/~gary/rtaudio/";
    license = licenses.mit;
    maintainers = with maintainers; [ magnetophon ];
    platforms = platforms.unix;
  };
}
