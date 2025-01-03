{ glibcLocales }:

self: super: with self;

{
  pyfdt = buildPythonPackage rec {
    pname = "pyfdt";
    version = "0.3";
    src = fetchPypi {
      inherit pname version;
      sha256 = "1w7lp421pssfgv901103521qigwb12i6sk68lqjllfgz0lh1qq31";
    };
  };

  autopep8_1_4_3 = buildPythonPackage rec {
    pname = "autopep8";
    version = "1.4.3";
    src = fetchPypi {
      inherit pname version;
      sha256 = "13140hs3kh5k13yrp1hjlyz2xad3xs1fjkw1811gn6kybcrbblik";
    };
    propagatedBuildInputs = [
      pycodestyle
    ];
    checkInputs = [ glibcLocales ];
    LC_ALL = "en_US.UTF-8";
    doCheck = false;
  };

  cmake-format = buildPythonPackage rec {
    pname = "cmake_format";
    version = "0.4.5";
    src = fetchPypi {
      inherit pname version;
      sha256 = "0nl78yb6zdxawidp62w9wcvwkfid9kg86n52ryg9ikblqw428q0n";
    };
    propagatedBuildInputs = [
      jinja2
      pyyaml
    ];
    doCheck = false;
  };

  guardonce = buildPythonPackage rec {
    pname = "guardonce";
    version = "2.4.0";
    src = fetchPypi {
      inherit pname version;
      sha256 = "0sr7c1f9mh2vp6pkw3bgpd7crldmaksjfafy8wp5vphxk98ix2f7";
    };
    buildInputs = [
      nose
    ];
  };

  concurrencytest = buildPythonPackage rec {
    pname = "concurrencytest";
    version = "0.1.2";
    src = fetchPypi {
      inherit pname version;
      sha256 = "1n62h3wyq2i3aqwns0hsrh3nl3qqh9512pncbwvrm55rrnswbab4";
    };
    propagatedBuildInputs = [ subunit testtools ];
  };

  sel4-deps = buildPythonPackage rec {
    pname = "sel4-deps";
    version = "0.3.1";
    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-ubSn2l3Zd2xH4k2+brPNwn53hdfi4Qtbt4qzxB7Zsic=";
    };
    postPatch = ''
      substituteInPlace setup.py --replace-fail bs4 beautifulsoup4
    '';
    propagatedBuildInputs = [
      six
      future
      jinja2
      lxml
      ply
      psutil
      beautifulsoup4
      sh
      pexpect
      pyaml
      jsonschema
      pyfdt
      cmake-format
      guardonce
      autopep8_1_4_3
      pyelftools
      libarchive-c
      # not listed in requirements.txt
      setuptools
    ];
  };
}
