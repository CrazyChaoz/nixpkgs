{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  python3,
  perl,
  autoPatchelfHook,
  pkg-config,
  abseil-cpp,
  eigen,
  git,
  runCommand,
  fetchzip,
  zlib,
  patchelf,
}:

stdenv.mkDerivation rec {
  pname = "tensorflow-lite";
  version = "2.20.0";

  src = fetchFromGitHub {
    owner = "tensorflow";
    repo = "tensorflow";
    rev = "v${version}";
    hash = "sha256-nGWQ+T5FmL+hZucbjQlCRTJM1i//gSzua1QxcBFeqwM=";
  };

  farmhash = stdenv.mkDerivation {
    pname = "farmhash";
    version = "master";

    src = fetchFromGitHub {
      owner = "yasushi-saito";
      repo = "farmhash";
      rev = "master";
      hash = "sha256-S4vGDqeqmi4S9RsnCUW1D3n/LKpGM0Cr7x+ur6QbobI=";
    };

    nativeBuildInputs = [
      pkg-config
      perl
    ];

    meta = with lib; {
      description = "FarmHash, a family of hash functions.";
      homepage = "https://github.com/google/farmhash";
      platforms = platforms.all;
    };
  };

  fft-file = fetchTarball {
    url = "https://storage.googleapis.com/mirror.tensorflow.org/github.com/petewarden/OouraFFT/archive/v1.0.tar.gz";
    sha256 = "sha256:1gla8m477din9k7jnbkzzbvc0wzw2rn97skxwf0k0mwcdf6vlhcs";
  };

  gemmlowp-file = fetchFromGitHub {
    owner = "google";
    repo = "gemmlowp";
    rev = "16e8662c34917be0065110bfcd9cc27d30f52fdf";
    sha256 = "sha256-e6AeRhZioIiTG5R+IA9g2GBqI4o74wijJYmqINLOtQs=";
  };

  neon2sse-file = fetchTarball {
    url = "https://storage.googleapis.com/mirror.tensorflow.org/github.com/intel/ARM_NEON_2_x86_SSE/archive/a15b489e1222b2087007546b4912e21293ea86ff.tar.gz";
    sha256 = "sha256:0pfl7m1b8ddzl6ac30ghlg2575kzx550cmg54akn0knxvfk5kpyv";
  };

  cpuinfo-file = fetchzip {
    url = "https://github.com/pytorch/cpuinfo/archive/de0ce7c7251372892e53ce9bc891750d2c9a4fd8.zip";
    sha256 = "sha256-lWD8fLIMnvuWtp2hbReRHgF19+dTqSFGu3VmYUsjPt8=";
  };

  ml_dtypes-file = fetchzip {
    url = "https://github.com/jax-ml/ml_dtypes/archive/00d98cd92ade342fef589c0470379abb27baebe9.zip";
    sha256 = "sha256-jY3g0+Uebdj+C2HLfXXq1fO/gnJMQQE/AE0RfxjI5f4=";
  };

  ruy-file = fetchzip {
    url = "https://github.com/google/ruy/archive/3286a34cc8de6149ac6844107dfdffac91531e72.zip";
    sha256 = "sha256-2l2RA/VHF9VgHzkPtFdtpVQJtgUw+iT7q4rUBT4R3GE=";
  };

  pthreadpool-file = fetchzip {
    url = "https://github.com/google/pthreadpool/archive/c2ba5c50bb58d1397b693740cf75fad836a0d1bf.zip";
    sha256 = "sha256-aAoOCv6rzMsgP4wbcOsmB102SZJp759wK4Hu+zm/6xM=";
  };

  fp16-file = fetchzip {
    url = "https://github.com/Maratyszcza/FP16/archive/0a92994d729ff76a58f692d3028ca1b64b145d91.zip";
    sha256 = "sha256-m2d9bqZoGWzuUPGkd29MsrdscnJRtuIkLIMp3fMmtRY=";
  };

  fxdiv-file = fetchzip {
    url = "https://github.com/Maratyszcza/FXdiv/archive/63058eff77e11aa15bf531df5dd34395ec3017c8.zip";
    sha256 = "sha256-LjX5kivfHbqCIA5pF9qUvswG1gjOFo3CMpX0VR+Cn38=";
  };

  opencl-file = fetchzip {
    url = "https://github.com/KhronosGroup/OpenCL-Headers/archive/dcd5bede6859d26833cd85f0d6bbcee7382dc9b3.zip";
    sha256 = "sha256-94rZeGuVvzQVBvwxpJWiiDs+RxTQqWKs0jeYzqBiQew=";
  };

  vulkan-file = fetchzip {
    url = "https://github.com/KhronosGroup/Vulkan-Headers/archive/32c07c0c5334aea069e518206d75e002ccd85389.zip";
    sha256 = "sha256-drdsTSvhhsWqit94G0Nkg5obCp3UaC5F/1/ZwjOmots=";
  };

  opengl-file = fetchzip {
    url = "https://github.com/KhronosGroup/OpenGL-Registry/archive/0cb0880d91581d34f96899c86fc1bf35627b4b81.zip";
    sha256 = "sha256-pSONBYgBPhelflF0DA1Uf5jyqLhGU0jr7DF35ZrIYyY=";
  };

  pthreadpool-modded =
    runCommand "pthreadpool-modded"
      {
      }
      ''
        mkdir -p $out
        cp -r '${pthreadpool-file}/.' $out/

        chmod +w $out/cmake

        sed -i '16,17c\
        URL file://${fxdiv-file}\
        URL_HASH SHA256=2e35f9922bdf1dba82200e6917da94becc06d608ce168dc23295f4551f829f7f\
        ' $out/cmake/DownloadFXdiv.cmake
      '';

  egl-file = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "EGL-Registry";
    rev = "649981109e263b737e7735933c90626c29a306f2";
    sha256 = "sha256-X1tK/WB+zm+Y+bYywt6sxUb1cVc4YMZluW+wtiYcjE8=";
  };

  xnnpack-file = fetchFromGitHub {
    owner = "google";
    repo = "XNNPACK";
    rev = "585e73e63cb35c8a416c83a48ca9ab79f7f7d45e";
    sha256 = "sha256-mqJMVjZ4rn5O3J/qI/N7HbnMdMSarPYHTIqNBmjZv0Q=";
  };

  protobuf-file = fetchFromGitHub {
    owner = "protocolbuffers";
    repo = "protobuf";
    rev = "90b73ac3f0b10320315c2ca0d03a5a9b095d2f66";
    sha256 = "sha256-17WAhwUvxIQD/QCyQglPVElQ38D/J1FA32hZ8Q8kID0=";
  };

  flatbuffers-file = fetchFromGitHub {
    owner = "google";
    repo = "flatbuffers";
    rev = "e6463926479bd6b330cbcf673f7e917803fd5831";
    sha256 = "sha256-arpxR5mUXQctDIfCOgi7fOlJ9A+hcQKL3vQ3/rXgdWE=";
  };

  abseil-file = fetchFromGitHub {
    owner = "abseil";
    repo = "abseil-cpp";
    rev = "d9e4955c65cd4367dd6bf46f4ccb8cd3d100540b";
    sha256 = "sha256-QTywqQCkyGFpdbtDBvUwz9bGXxbJs/qoFKF6zYAZUmQ=";
  };

  nativeBuildInputs = [
    cmake
    python3
    perl
    autoPatchelfHook
    pkg-config
    git
  ];

  buildInputs = [
    # Add any libraries required for building TensorFlow Lite
    eigen
    #abseil-cpp
    farmhash
    zlib
  ];

  # If TensorFlow Lite uses a subdirectory for CMake, set sourceRoot
  sourceRoot = "source/tensorflow/lite";

  cmakeFlags = [
    # Add any necessary CMake flags here, e.g.:
    "-DCMAKE_BUILD_TYPE=Release"
    "-DTFLITE_ENABLE_GPU=ON"
    "-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON"
    "-Wno-dev"
    "-DSYSTEM_FARMHASH=ON"
    "-DBUILD_SHARED_LIBS=ON"
  ];
  
  postPatch = ''
    # Apply any patches needed for GCC compatibility, etc.
    sed -e '1i #include <cstdint>' -i kernels/internal/spectrogram.cc

    # replace line 24 in tools/cmake/modules/fft2d.cmake
    # from internet URL to local path
    sed -i '24s|https://storage.googleapis.com/mirror.tensorflow.org/github.com/petewarden/OouraFFT/archive/v1.0.tar.gz|file://'${fft-file}'|g' tools/cmake/modules/fft2d.cmake

    # replace line 22-32 in tools/cmake/modules/gemmlowp.cmake
    # from internet URL to local path
    sed -i '24,32c\
      URL file://${gemmlowp-file}\
      URL_HASH SHA256=7ba01e461662a088931b947e200f60d8606a238a3be308a32589aa20d2ceb50b\
      LICENSE_FILE "LICENSE"\
      LICENSE_URL "file://${gemmlowp-file}/LICENSE"\
    ' tools/cmake/modules/gemmlowp.cmake

    # replace line 23 in tools/cmake/modules/neon2sse.cmake
    # from internet URL to local path
    sed -i '23s|https://storage.googleapis.com/mirror.tensorflow.org/github.com/intel/ARM_NEON_2_x86_SSE/archive/a15b489e1222b2087007546b4912e21293ea86ff.tar.gz|file://'${neon2sse-file}'|g' tools/cmake/modules/neon2sse.cmake

    # replace line 22-30 in tools/cmake/modules/cpuinfo.cmake
    # from internet URL to local path
    sed -i '24,27c\
      URL file://${cpuinfo-file}\
      URL_HASH SHA256=9560fc7cb20c9efb96b69da16d17911e0175f7e753a92146bb7566614b233edf\
      LICENSE_FILE "LICENSE"\
      LICENSE_URL "file://${cpuinfo-file}/LICENSE"\
    ' tools/cmake/modules/cpuinfo.cmake

    # replace line 24-34 in tools/cmake/modules/ml_dtypes.cmake
    # from internet URL to local path
    sed -i '24,34c\
      URL file://${ml_dtypes-file}\
      URL_HASH SHA256=8d8de0d3e51e6dd8fe0b61cb7d75ead5f3bf82724c41013f004d117f18c8e5fe\
      LICENSE_FILE "LICENSE"\
      LICENSE_URL "file://${ml_dtypes-file}/LICENSE"\
    ' tools/cmake/modules/ml_dtypes.cmake

    # replace line 24-27 in tools/cmake/modules/ruy.cmake
    # from internet URL to local path
    sed -i '24,27c\
      URL file://${ruy-file}\
      URL_HASH SHA256=da5d9103f54717d5601f390fb4576da55409b60530fa24fbab8ad4053e11dc61\
      LICENSE_FILE "LICENSE"\
      LICENSE_URL "file://${ruy-file}/LICENSE"\
    ' tools/cmake/modules/ruy.cmake


    # replace line 22 in cmake/DownloadPThreadPool.cmake
    # from internet URL to local path
    sed -i '22s|https://github.com/google/pthreadpool/archive/c2ba5c50bb58d1397b693740cf75fad836a0d1bf.zip|file://'${pthreadpool-modded}'|g' cmake/DownloadPThreadPool.cmake


    # replace line 27 in cmake/DownloadFP16.cmake
    # from internet URL to local path
    sed -i '27s|https://github.com/Maratyszcza/FP16/archive/0a92994d729ff76a58f692d3028ca1b64b145d91.zip|file://'${fp16-file}'|g' cmake/DownloadFP16.cmake



    # replace line 24-28 in tools/cmake/modules/opencl_headers.cmake
    # from internet URL to local path
    sed -i '24,28c\
      URL file://${opencl-file}\
      URL_HASH SHA256=f78ad9786b95bf341506fc31a495a2883b3e4714d0a962acd23798cea06241ec\
      LICENSE_FILE "LICENSE"\
      LICENSE_URL "file://${opencl-file}/LICENSE"\
    ' tools/cmake/modules/opencl_headers.cmake

    # replace line 24-27 in tools/cmake/modules/vulkan_headers.cmake
    # from internet URL to local path
    sed -i '24,27c\
      URL file://${vulkan-file}\
      URL_HASH SHA256=76b76c4d2be186c5aa8adf781b4364839a1b0a9dd4682e45ff5fd9c233a6a2db\
      LICENSE_FILE "LICENSE.txt"\
      LICENSE_URL "file://${vulkan-file}/LICENSE.txt"\
    ' tools/cmake/modules/vulkan_headers.cmake

    # replace line 24-29 in tools/cmake/modules/opengl_headers.cmake
    # from internet URL to local path
    sed -i '24,32c\
      URL file://${opengl-file}\
      URL_HASH SHA256=a5238d0588013e17a57e51740c0d547f98f2a8b8465348ebec3177e59ac86326\
      LICENSE_FILE "LICENSE.txt"\
      #this repository does not contain a license file, but per https://www.khronos.org/legal/Khronos_Apache_2.0_CLA\
      LICENSE_URL "file://${vulkan-file}/LICENSE.txt"\
      SOURCE_DIR "''${CMAKE_BINARY_DIR}/opengl_headers"\
    ' tools/cmake/modules/opengl_headers.cmake

    # replace line 24-29 in tools/cmake/modules/egl_headers.cmake
    # from internet URL to local path
    sed -i '24,32c\
      URL file://${egl-file}\
      URL_HASH SHA256=a5238d0588013e17a57e51740c0d547f98f2a8b8465348ebec3177e59ac86326\
      LICENSE_FILE "LICENSE.txt"\
      #this repository does not contain a license file, but per https://www.khronos.org/legal/Khronos_Apache_2.0_CLA\
      LICENSE_URL "file://${vulkan-file}/LICENSE.txt"\
      SOURCE_DIR "''${CMAKE_BINARY_DIR}/egl_headers"\
    ' tools/cmake/modules/egl_headers.cmake

    # replace line 24-27 in tools/cmake/modules/xnnpack.cmake
    # from internet URL to local path
    sed -i '24,27c\
      URL file://${xnnpack-file}\
      URL_HASH SHA256=9aa24c563678ae7e4edc9fea23f37b1db9cc74c49aacf6074c8a8d0668d9bf44 \
      LICENSE_FILE "LICENSE"\
      LICENSE_URL "file://${xnnpack-file}/LICENSE"\
    ' tools/cmake/modules/xnnpack.cmake

    # replace line 20-23 in tools/cmake/modules/protobuf.cmake
    # from internet URL to local path
    sed -i '20,23c\
      URL file://${protobuf-file}\
      URL_HASH SHA256=d7b58087052fc48403fd00b242094f544950dfc0ff275140df6859f10f24203d\
      LICENSE_FILE "LICENSE"\
      LICENSE_URL "file://${protobuf-file}/LICENSE"\
    ' tools/cmake/modules/protobuf.cmake

    # replace line 24-29 in tools/cmake/modules/flatbuffers.cmake
    # from internet URL to local path
    sed -i '24,29c\
      URL file://${flatbuffers-file}\
      URL_HASH SHA256=6aba714799945d072d0c87c23a08bb7ce949f40fa171028bdef437feb5e07561\
      LICENSE_FILE "LICENSE"\
      LICENSE_URL "file://${flatbuffers-file}/LICENSE"\
    ' tools/cmake/modules/flatbuffers.cmake


    # replace line 25-30 in tools/cmake/modules/abseil-cpp.cmake
    # from internet URL to local path
    sed -i '25,30c\
      URL file://${abseil-file}\
      URL_HASH SHA256=413cb0a900a4c8616975bb4306f530cfd6c65f16c9b3faa814a17acd80195264\
      LICENSE_FILE "LICENSE"\
      LICENSE_URL "file://${abseil-file}/LICENSE"\
    ' tools/cmake/modules/abseil-cpp.cmake


  '';

  preConfigure = ''

    cmakeFlagsArray+=(
       "-DCMAKE_CXX_FLAGS='-DTF_MAJOR_VERSION=2 -DTF_MINOR_VERSION=20 -DTF_PATCH_VERSION=0 -DTF_VERSION_SUFFIX=${"''"}'"
      "-DCMAKE_C_FLAGS='-DTF_MAJOR_VERSION=2 -DTF_MINOR_VERSION=20 -DTF_PATCH_VERSION=0 -DTF_VERSION_SUFFIX=${"''"}'"
     )

    patchShebangs configure
  '';
  
  

  installPhase = ''
    mkdir -p $out/{bin,lib,include,everything}

    # Copy built libraries

    # Copy binaries if any (e.g. benchmark tools)
    find . -type f -executable -name "benchmark_model*" -exec cp {} $out/bin \;
    # Copy binaries if any (e.g. benchmark tools)
    find . -type f  -name "*.a" -exec cp {} $out/lib \;
    find . -type f  -name "*.so" -exec cp {} $out/lib \;
    
    ls -al $out/lib/
    
    # Copy headers
    find . -type f -name '*.h' | while read f; do
      path="$out/include/''${f#./}"
      install -D "$f" "$path"
      chmod -x "$path"
    done
            
    ${patchelf}/bin/patchelf --print-needed $out/lib/libtensorflow-lite.so
    ${patchelf}/bin/patchelf --remove-needed libfft2d_fftsg2d.so \
    --remove-needed libXNNPACK.so \
    --remove-needed libfft2d_fftsg.so \
    --remove-needed libeight_bit_int_gemm.so \
    --remove-needed libpthreadpool.so \
    --remove-needed libcpuinfo.so \
    --remove-needed libabsl_status.so \
    --remove-needed libabsl_flags_internal.so \
    --remove-needed libabsl_flags_marshalling.so \
    --remove-needed libabsl_flags_reflection.so \
    --remove-needed libabsl_raw_hash_set.so \
    --remove-needed libabsl_hash.so \
    --remove-needed libabsl_bad_variant_access.so \
    --remove-needed libabsl_city.so \
    --remove-needed libabsl_low_level_hash.so \
    --remove-needed libabsl_hashtablez_sampler.so \
    --remove-needed libabsl_flags_config.so \
    --remove-needed libabsl_flags_program_name.so \
    --remove-needed libabsl_flags_private_handle_accessor.so \
    --remove-needed libabsl_flags_commandlineflag.so \
    --remove-needed libabsl_flags_commandlineflag_internal.so \
    --remove-needed libabsl_cord.so \
    --remove-needed libabsl_cordz_info.so \
    --remove-needed libabsl_cord_internal.so \
    --remove-needed libabsl_cordz_functions.so \
    --remove-needed libabsl_exponential_biased.so \
    --remove-needed libabsl_cordz_handle.so \
    --remove-needed libabsl_synchronization.so \
    --remove-needed libabsl_graphcycles_internal.so \
    --remove-needed libabsl_kernel_timeout_internal.so \
    --remove-needed libabsl_tracing_internal.so \
    --remove-needed libabsl_time.so \
    --remove-needed libabsl_civil_time.so \
    --remove-needed libabsl_time_zone.so \
    --remove-needed libabsl_crc_cord_state.so \
    --remove-needed libabsl_crc32c.so \
    --remove-needed libabsl_crc_internal.so \
    --remove-needed libabsl_crc_cpu_detect.so \
    --remove-needed libabsl_bad_optional_access.so \
    --remove-needed libabsl_leak_check.so \
    --remove-needed libabsl_stacktrace.so \
    --remove-needed libabsl_str_format_internal.so \
    --remove-needed libabsl_strerror.so \
    --remove-needed libabsl_symbolize.so \
    --remove-needed libabsl_strings.so \
    --remove-needed libabsl_int128.so \
    --remove-needed libabsl_strings_internal.so \
    --remove-needed libabsl_string_view.so \
    --remove-needed libabsl_throw_delegate.so \
    --remove-needed libabsl_malloc_internal.so \
    --remove-needed libabsl_base.so \
    --remove-needed libabsl_spinlock_wait.so \
    --remove-needed libabsl_debugging_internal.so \
    --remove-needed libabsl_demangle_internal.so \
    --remove-needed libabsl_demangle_rust.so \
    --remove-needed libabsl_decode_rust_punycode.so \
    --remove-needed libabsl_utf8_for_code_point.so \
    --remove-needed libabsl_bad_any_cast_impl.so \
    --remove-needed libabsl_raw_logging_internal.so \
    --remove-needed libabsl_log_severity.so \
    $out/lib/libtensorflow-lite.so
    
    ${patchelf}/bin/patchelf --add-needed $out/lib/libfft2d_fftsg2d.so \
    --add-needed $out/lib/libXNNPACK.so \
    --add-needed $out/lib/libfft2d_fftsg.so \
    --add-needed $out/lib/libeight_bit_int_gemm.so \
    --add-needed $out/lib/libpthreadpool.so \
    --add-needed $out/lib/libcpuinfo.so \
    --add-needed $out/lib/libabsl_status.so \
    --add-needed $out/lib/libabsl_flags_internal.so \
    --add-needed $out/lib/libabsl_flags_marshalling.so \
    --add-needed $out/lib/libabsl_flags_reflection.so \
    --add-needed $out/lib/libabsl_raw_hash_set.so \
    --add-needed $out/lib/libabsl_hash.so \
    --add-needed $out/lib/libabsl_bad_variant_access.so \
    --add-needed $out/lib/libabsl_city.so \
    --add-needed $out/lib/libabsl_low_level_hash.so \
    --add-needed $out/lib/libabsl_hashtablez_sampler.so \
    --add-needed $out/lib/libabsl_flags_config.so \
    --add-needed $out/lib/libabsl_flags_program_name.so \
    --add-needed $out/lib/libabsl_flags_private_handle_accessor.so \
    --add-needed $out/lib/libabsl_flags_commandlineflag.so \
    --add-needed $out/lib/libabsl_flags_commandlineflag_internal.so \
    --add-needed $out/lib/libabsl_cord.so \
    --add-needed $out/lib/libabsl_cordz_info.so \
    --add-needed $out/lib/libabsl_cord_internal.so \
    --add-needed $out/lib/libabsl_cordz_functions.so \
    --add-needed $out/lib/libabsl_exponential_biased.so \
    --add-needed $out/lib/libabsl_cordz_handle.so \
    --add-needed $out/lib/libabsl_synchronization.so \
    --add-needed $out/lib/libabsl_graphcycles_internal.so \
    --add-needed $out/lib/libabsl_kernel_timeout_internal.so \
    --add-needed $out/lib/libabsl_tracing_internal.so \
    --add-needed $out/lib/libabsl_time.so \
    --add-needed $out/lib/libabsl_civil_time.so \
    --add-needed $out/lib/libabsl_time_zone.so \
    --add-needed $out/lib/libabsl_crc_cord_state.so \
    --add-needed $out/lib/libabsl_crc32c.so \
    --add-needed $out/lib/libabsl_crc_internal.so \
    --add-needed $out/lib/libabsl_crc_cpu_detect.so \
    --add-needed $out/lib/libabsl_bad_optional_access.so \
    --add-needed $out/lib/libabsl_leak_check.so \
    --add-needed $out/lib/libabsl_stacktrace.so \
    --add-needed $out/lib/libabsl_str_format_internal.so \
    --add-needed $out/lib/libabsl_strerror.so \
    --add-needed $out/lib/libabsl_symbolize.so \
    --add-needed $out/lib/libabsl_strings.so \
    --add-needed $out/lib/libabsl_int128.so \
    --add-needed $out/lib/libabsl_strings_internal.so \
    --add-needed $out/lib/libabsl_string_view.so \
    --add-needed $out/lib/libabsl_throw_delegate.so \
    --add-needed $out/lib/libabsl_malloc_internal.so \
    --add-needed $out/lib/libabsl_base.so \
    --add-needed $out/lib/libabsl_spinlock_wait.so \
    --add-needed $out/lib/libabsl_debugging_internal.so \
    --add-needed $out/lib/libabsl_demangle_internal.so \
    --add-needed $out/lib/libabsl_demangle_rust.so \
    --add-needed $out/lib/libabsl_decode_rust_punycode.so \
    --add-needed $out/lib/libabsl_utf8_for_code_point.so \
    --add-needed $out/lib/libabsl_bad_any_cast_impl.so \
    --add-needed $out/lib/libabsl_raw_logging_internal.so \
    --add-needed $out/lib/libabsl_log_severity.so \
    $out/lib/libtensorflow-lite.so
    
    ${patchelf}/bin/patchelf --remove-needed libfft2d_fftsg.so \
    $out/lib/libfft2d_fftsg2d.so
    
    ${patchelf}/bin/patchelf --add-needed $out/lib/libfft2d_fftsg.so \
    $out/lib/libfft2d_fftsg2d.so
    
    ${patchelf}/bin/patchelf --remove-needed libfft2d_fftsg.so \
    $out/lib/libfft2d_fftsg3d.so
    
    ${patchelf}/bin/patchelf --add-needed $out/lib/libfft2d_fftsg.so \
    $out/lib/libfft2d_fftsg3d.so
    
    
    ${patchelf}/bin/patchelf --remove-needed libfeature_proto.so \
    $out/lib/libexample_proto.so
    
    ${patchelf}/bin/patchelf --add-needed $out/lib/libfeature_proto.so \
    $out/lib/libexample_proto.so
    
    
    ${patchelf}/bin/patchelf \
    --remove-needed libpthreadpool.so \
    --remove-needed libcpuinfo.so \
    $out/lib/libXNNPACK.so
    
    ${patchelf}/bin/patchelf \
    --add-needed $out/lib/libpthreadpool.so \
    --add-needed $out/lib/libcpuinfo.so \
    $out/lib/libXNNPACK.so
        
    
    ldd $out/lib/libtensorflow-lite.so
    ls -al $out/lib/
  '';

  # installPhase = ''
  #   mkdir -p $out/{bin,lib,include,everything}


  #   # Copy binaries if any (e.g. benchmark tools)
  #   find . -type f -executable -name "benchmark_model*" -exec cp {} $out/bin \;
    
    
  #   find . -type f -name "*.a" -exec cp {} $out/lib \;
  #   find . -type f -name "*.so" -exec cp {} $out/lib \;

    
  #   ls -al $out/lib/
    
  #   # Copy headers
  #   find . -type f -name '*.h' | while read f; do
  #     path="$out/include/''${f#./}"
  #     install -D "$f" "$path"
  #     chmod -x "$path"
  #   done
        
    
  # '';

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
    broken = false;
  };
}
