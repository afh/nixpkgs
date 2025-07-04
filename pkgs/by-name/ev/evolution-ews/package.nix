{
  stdenv,
  lib,
  fetchurl,
  gnome,
  cmake,
  gettext,
  intltool,
  pkg-config,
  evolution-data-server,
  evolution,
  gtk3,
  libsoup_3,
  libical,
  json-glib,
  libmspack,
  webkitgtk_4_1,
  replaceVars,
  _experimental-update-script-combinators,
  glib,
  makeHardcodeGsettingsPatch,
}:

stdenv.mkDerivation rec {
  pname = "evolution-ews";
  version = "3.56.2";

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    hash = "sha256-Hrfsz5TGuGGNa0XDICNQIJ21Z8SJEIrcICM8TRn48o8=";
  };

  patches = [
    # evolution-ews contains .so files loaded by evolution-data-server referring
    # schemas from evolution. evolution-data-server is not wrapped with
    # evolution's schemas because it would be a circular dependency with
    # evolution.
    (replaceVars ./hardcode-gsettings.patch {
      evo = glib.makeSchemaPath evolution evolution.name;
    })
  ];

  nativeBuildInputs = [
    cmake
    gettext
    intltool
    pkg-config
  ];

  buildInputs = [
    evolution-data-server
    evolution
    gtk3
    libsoup_3
    libical
    json-glib
    libmspack
    # For evolution-shell-3.0
    webkitgtk_4_1
  ];

  cmakeFlags = [
    # don't try to install into ${evolution}
    "-DFORCE_INSTALL_PREFIX=ON"
  ];

  passthru = {
    hardcodeGsettingsPatch = makeHardcodeGsettingsPatch {
      inherit src;
      schemaIdToVariableMapping = {
        "org.gnome.evolution.mail" = "evo";
        "org.gnome.evolution.calendar" = "evo";
      };
      schemaExistsFunction = "e_ews_common_utils_gsettings_schema_exists";
    };

    updateScript =
      let
        updateSource = gnome.updateScript {
          packageName = "evolution-ews";
          versionPolicy = "odd-unstable";
        };
        updatePatch = _experimental-update-script-combinators.copyAttrOutputToFile "evolution-ews.hardcodeGsettingsPatch" ./hardcode-gsettings.patch;
      in
      _experimental-update-script-combinators.sequence [
        updateSource
        updatePatch
      ];
  };

  meta = with lib; {
    description = "Evolution connector for Microsoft Exchange Server protocols";
    homepage = "https://gitlab.gnome.org/GNOME/evolution-ews";
    license = licenses.lgpl21Plus; # https://gitlab.gnome.org/GNOME/evolution-ews/issues/111
    maintainers = [ maintainers.dasj19 ];
    platforms = platforms.linux;
  };
}
