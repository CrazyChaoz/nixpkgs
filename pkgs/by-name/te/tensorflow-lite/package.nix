{
  stdenv,
  buildPackages,
  buildBazelPackage,
  fetchFromGitHub,
  lib,
  perl,
}:
let
  buildPlatform = stdenv.buildPlatform;
  hostPlatform = stdenv.hostPlatform;
  pythonEnv = buildPackages.python312.withPackages (
    ps: with ps; [
      distutils
      numpy
      cython
    ]
  );
  bazelDepsSha256ByBuildAndHost = {
    x86_64-linux = {
      x86_64-linux = "sha256-hInf6KQ4N3sOTtklMkY2ATsOsHOnkfK1mSQGjxWqFZk=";
      #x86_64-linux = lib.fakeHash;
      aarch64-linux = lib.fakeHash;
    };
    aarch64-linux = {
      aarch64-linux = lib.fakeHash;
    };
  };
  bazelHostConfigName.aarch64-linux = "elinux_aarch64";
  bazelDepsSha256ByHost =
    bazelDepsSha256ByBuildAndHost.${buildPlatform.system}
      or (throw "unsupported build system ${buildPlatform.system}");
  bazelDepsSha256 =
    bazelDepsSha256ByHost.${hostPlatform.system}
      or (throw "unsupported host system ${hostPlatform.system} with build system ${buildPlatform.system}");
in
buildBazelPackage rec {
  name = "tensorflow-lite";
  version = "2.19.0"; #https://www.tensorflow.org/install/source#cpu

  src = fetchFromGitHub {
    owner = "tensorflow";
    repo = "tensorflow";
    rev = "v${version}";
    hash = "sha256-61Ceoed8D65IvipM0OsXJ3xGWi5jtUDPUxhYNOffImU=";
  };

  bazel = buildPackages.bazel_6;

  nativeBuildInputs = [
    pythonEnv
    perl
  ];

  bazelTargets = [
    "//tensorflow/lite/c:libtensorflowlite_c.so"
    "//tensorflow/lite:libtensorflowlite.so"
    "//tensorflow/lite/tools/benchmark:benchmark_model"
    "//tensorflow/lite/tools/benchmark:benchmark_model_performance_options"
  ];

  bazelFlags =
    [
      "--config=opt"
      "--cxxopt=-x"
      "--cxxopt=c++"
      "--host_cxxopt=-x"
      "--host_cxxopt=c++"
      # workaround for https://github.com/bazelbuild/bazel/issues/15359
      "--spawn_strategy=sandboxed"
      "--sandbox_debug"

    ]
    ++ lib.optionals (hostPlatform.system != buildPlatform.system) [
      "--config=${bazelHostConfigName.${hostPlatform.system}}"
    ];

  bazelBuildFlags = [ "--cxxopt=--std=c++17" ];

  buildAttrs = {
    installPhase = ''
      mkdir -p $out/{bin,lib}

      # copy the libs and binaries into the output dir
      cp ./bazel-bin/tensorflow/lite/c/libtensorflowlite_c.so $out/lib
      cp ./bazel-bin/tensorflow/lite/libtensorflowlite.so $out/lib
      cp ./bazel-bin/tensorflow/lite/tools/benchmark/benchmark_model $out/bin
      cp ./bazel-bin/tensorflow/lite/tools/benchmark/benchmark_model_performance_options $out/bin

      find . -type f -name '*.h' | while read f; do
        path="$out/include/''${f/.\//}"
        install -D "$f" "$path"

        # remove executable bit from headers
        chmod -x "$path"
      done
    '';
  };

  fetchAttrs.sha256 = bazelDepsSha256;

  HERMETIC_PYTHON_VERSION = "3.12";
  PYTHON_BIN_PATH = "${pythonEnv}/bin/python3.12";
  PYTHON_LIB_PATH = "${pythonEnv}/lib/python3.12/site-packages";
  CLANG_COMPILER_PATH = "${buildPackages.clang}/bin/clang";

  dontAddBazelOpts = true;
  removeRulesCC = false;

  postPatch = ''
    rm .bazelversion

    # Fix gcc-13 build failure by including missing include headers
    sed -e '1i #include <cstdint>' -i \
      tensorflow/lite/kernels/internal/spectrogram.cc
  '';

  preConfigure = ''
    patchShebangs configure
  '';
  preBuild = ''
    ##############################################################
    # DEBUG
    # check if /usr/bin/env python3 works
    # required in https://github.com/bazelbuild/bazel/blob/6.5.0/src/main/java/com/google/devtools/build/lib/bazel/rules/python/BazelPythonSemantics.java#L254
    ##############################################################
    if ! command -v /usr/bin/env python3 &> /dev/null; then
      echo "Error: /usr/bin/env python3 not found"
      exit 1
    fi
    echo "We can use /usr/bin/env python3"
    ################################################################
  '';


  # configure script freaks out when parameters are passed
  dontAddPrefix = true;
  configurePlatforms = [ ];

  meta = with lib; {
    description = "Open source deep learning framework for on-device inference";
    homepage = "https://www.tensorflow.org/lite";
    license = licenses.asl20;
    maintainers = with maintainers; [
      mschwaig
      cpcloud
    ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
