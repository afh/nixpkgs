{ lib
, stdenv
, callPackage
, fetchFromGitHub
, fetchpatch
, testers

, enableE57 ? lib.meta.availableOn stdenv.hostPlatform libe57format

, cmake
, curl
, gdal
, hdf5-cpp
, LASzip
, libe57format
, libgeotiff
, libtiff
, libxml2
, openscenegraph
, pkg-config
, postgresql
, proj
, tiledb
, xercesc
, zlib
, zstd
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pdal";
  version = "2.6.3";

  src = fetchFromGitHub {
    owner = "PDAL";
    repo = "PDAL";
    rev = finalAttrs.version;
    sha256 = "sha256-wrgEbCYOGW1yrVxyX+UDa5jcUqab3letEGuvWnYvtac=";
  };

  patches = [
    # Fix running tests
    # https://github.com/PDAL/PDAL/issues/4280
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/PDAL/PDAL/pull/4291.patch";
      sha256 = "sha256-jFS+trwMRBfm+MpT0CcuD/hdYmfyuQj2zyoe06B6G9U=";
    })
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    curl
    gdal
    hdf5-cpp
    LASzip
    libgeotiff
    libtiff
    libxml2
    openscenegraph
    postgresql
    proj
    tiledb
    xercesc
    zlib
    zstd
  ] ++ lib.optionals enableE57 [
    libe57format
  ];

  cmakeFlags = lib.cmakeBools ({
    WITH_COMPLETION = true;
    WITH_TESTS = true;
    BUILD_PGPOINTCLOUD_TESTS = false;
  }
  // lib.attrsets.prefixAttrsNameWith "BUILD_PLUGIN_" {
    E57 = enableE57;
    HDF = true;
    PGPOINTCLOUD = true;
    TILEDB = true;

    # Plugins can probably not be made work easily:
    CPD = false;
    FBX = false; # Autodesk FBX SDK is gratis+proprietary; not packaged in nixpkgs
    GEOWAVE = false;
    I3S = false;
    ICEBRIDGE = false;
    MATLAB = false;
    MBIO = false;
    MRSID = false;
    NITF = false;
    OCI = false;
    RDBLIB = false; # Riegl rdblib is proprietary; not packaged in nixpkgs
    RIVLIB = false;
  });

  doCheck = true;

  disabledTests = [
    # Tests failing due to TileDB library implementation, disabled also
    # by upstream CI.
    # See: https://github.com/PDAL/PDAL/blob/bc46bc77f595add4a6d568a1ff923d7fe20f7e74/.github/workflows/linux.yml#L81
    "pdal_io_tiledb_writer_test"
    "pdal_io_tiledb_reader_test"
    "pdal_io_tiledb_time_writer_test"
    "pdal_io_tiledb_time_reader_test"
    "pdal_io_tiledb_bit_fields_test"
    "pdal_io_tiledb_utils_test"
    "pdal_io_e57_read_test"
    "pdal_io_e57_write_test"
    "pdal_io_stac_reader_test"

    # Segfault
    "pdal_io_hdf_reader_test"

    # Failure
    "pdal_app_plugin_test"
  ];

  checkPhase = ''
    runHook preCheck
    # tests are flaky and they seem to fail less often when they don't run in
    # parallel
    ctest -j 1 --output-on-failure -E '^${lib.concatStringsSep "|" finalAttrs.disabledTests}$'
    runHook postCheck
  '';

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "pdal --version";
      version = "pdal ${finalAttrs.finalPackage.version}";
    };
    pdal = callPackage ./tests.nix { pdal = finalAttrs.finalPackage; };
    pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = with lib; {
    description = "PDAL is Point Data Abstraction Library. GDAL for point cloud data";
    homepage = "https://pdal.io";
    license = licenses.bsd3;
    maintainers = teams.geospatial.members;
    platforms = platforms.all;
    pkgConfigModules = [ "pdal" ];
  };
})
