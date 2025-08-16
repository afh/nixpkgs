{ fetchurl }:
let
  kertex_T-version = "0.99.27.00";
in
{
  version = kertex_T-version;

  adobe-source =
    let
      version = "2011.12.31";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/adobe_${version}.tar.gz";
      hash = "sha256-UC1AnaeeX62tbcOo9pqAOO5H2hyqB0IHyqnwFxjmBAQ=";
    };

  ams-source =
    let
      version = "3.04";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/ams_${version}.tar.gz";
      hash = "sha256-wThCDW070iwIznT88bm+deBkhFIaHyfrf7DGGPoW7ck=";
    };

  bibtex-source =
    let
      version = "0.99d";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/bibtex_${version}.tar.gz";
      hash = "sha256-+ak9EQOnLJbxrSBwuzJ6hfvOBF/dA898vFWzvzcmzGQ=";
    };

  etex-source =
    let
      version = "2.1.0.1";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/etex_${version}.tar.gz";
      hash = "sha256-qzbNfWO2lw0NYmQvOqZyuG1nWJhqecnZVy3IhiY7bng=";
    };

  kertex_M-source =
    let
      version = "1.1.0.2";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/kertex_M_${version}.tar.gz";
      hash = "sha256-UmKUbIqiBNk3OhzxPC7mKMwlOEVH5EZowU0OZHxya7k=";
    };

  kertex_T-source = fetchurl {
    url = "https://downloads.kergis.com/kertex/kertex_T_${kertex_T-version}.tar.gz";
    hash = "sha256-56ZWwnYFqeoQOdkrAqUaIw7MXVKX+FzhA6VBZ/6iGhY=";
  };

  knuth-source =
    let
      version = "2021.02.10";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/knuth_${version}.tar.gz";
      hash = "sha256-biyNPLUjqhqck/CCDTlGu80YFiL49aLUNOQ0b4xjsdU=";
    };

  prote_doc =
    let
      version = "0-unstable-2025-10-31";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/prote_man.pdf";
      hash = "sha256-+DEwZz26Y24nvuKT7dqTvFLiuipHveIXKJVLfOzkp50=";
    };

  risk_comp-source =
    let
      version = "1.20.99.6";
    in
    fetchurl {
      url = "https://downloads.kergis.com/kertex/risk_comp_${version}.tar.gz";
      hash = "sha256-2RV6w8S6ScJz7NWuZppaq/TqliWSme/XTFa8qRYakYw=";
    };

  #pkgtools =
  #  let
  #    version = "0-unstable-2025-10-31";
  #  in
  # fetchurl {
  #  url = "https://downloads.kergis.com/kertex/pkg/src/pkgtools.zip";
  #  hash = "sha256-ct4seLpNwxOU5o01UdhJZtPNIDEP4F4Nk25TGazdtB4=";
  #  stripRoot = false;
  #};
}
