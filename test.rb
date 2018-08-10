class Test < Formula
  desc "Object oriented framework for large scale data analysis"
  homepage "https://root.cern.ch"
  url "https://root.cern.ch/download/root_v6.14.02.source.tar.gz"
  version "6.14.02"
  sha256 "93816519523e87ac75924178d87112d1573eaa108fc65691aea9a9dd5bc05b3e"
  head "http://root.cern.ch/git/root.git"

  bottle do
    sha256 "735843cdf42536af424d90471cba12e4834f42b728b40b2d170b6dc13dd863c1" => :high_sierra
    sha256 "d77502bde56a1b0aa8c2d2f8b249f730c77d92c9d3729cbaf6a721052a6ad669" => :sierra
    sha256 "7b3f1c52f9aa32d8e7c47376b1ae74b09e94df9030c10e4bc87d8e556298fdc6" => :el_capitan
  end

  depends_on "cmake" => :build
  depends_on "carlomt/linux/davix"
  depends_on "fftw"
  depends_on "gcc" # for gfortran.
  # depends_on "graphviz"
  depends_on "gsl"
  depends_on "lz4"
  depends_on "openssl"
  depends_on "pcre"
  depends_on "tbb"
  depends_on "xrootd"
  depends_on "xz" # For LZMA.
  depends_on "python" => :recommended
  depends_on "python@2" => :optional

  needs :cxx11

  skip_clean "bin"


  def install
    # Work around "error: no member named 'signbit' in the global namespace"
    ENV.delete("SDKROOT") if DevelopmentTools.clang_build_version >= 900

    # Freetype/afterimage/gl2ps/lz4 are vendored in the tarball, so are fine.
    # However, this is still permitting the build process to make remote
    # connections. As a hack, since upstream support it, we inreplace
    # this file to "encourage" the connection over HTTPS rather than HTTP.
    inreplace "cmake/modules/SearchInstalledSoftware.cmake",
              "http://lcgpackages",
              "https://lcgpackages"

    args = std_cmake_args + %W[
      -Dgnuinstall=ON
      -DCMAKE_INSTALL_ELISPDIR=#{elisp}
      -Dbuiltin_freetype=ON
      -Dbuiltin_cfitsio=OFF
      -Ddavix=ON
      -Dfitsio=OFF
      -Dfftw3=ON
      -Dfortran=ON
      -Dgdml=ON
      -Dmathmore=ON
      -Dminuit2=ON
      -Dmysql=OFF
      -Dpgsql=OFF
      -Droofit=ON
      -Dssl=ON
      -Dimt=ON
      -Dxrootd=ON
      -Dtmva=ON
      -Dgeocad=ON
    ]

    if build.with?("python") && build.with?("python@2")
      odie "Root: Does not support building both python 2 and 3 wrappers"
    elsif build.with?("python") || build.with?("python@2")
      if build.with? "python@2"
        ENV.prepend_path "PATH", Formula["python@2"].opt_libexec/"bin"
        python_executable = Utils.popen_read("which python").strip
        python_version = Language::Python.major_minor_version("python")
      elsif build.with? "python"
        python_executable = Utils.popen_read("which python3").strip
        python_version = Language::Python.major_minor_version("python3")
      end

      python_prefix = Utils.popen_read("#{python_executable} -c 'import sys;print(sys.prefix)'").chomp
      python_include = Utils.popen_read("#{python_executable} -c 'from distutils import sysconfig;print(sysconfig.get_python_inc(True))'").chomp
      args << "-Dpython=ON"

      # cmake picks up the system's python dylib, even if we have a brewed one
      
      # if File.exist? "#{python_prefix}/Python"
      #   python_library = "#{python_prefix}/Python"
      # elsif File.exist? "#{python_prefix}/lib/lib#{python_version}.a"
      #   python_library = "#{python_prefix}/lib/lib#{python_version}.a"
      # elsif File.exist? "#{python_prefix}/lib/lib#{python_version}.dylib"
      #   python_library = "#{python_prefix}/lib/lib#{python_version}.dylib"
      # else
      #   odie "No libpythonX.Y.{a,dylib} file found!"
      # end
      python_library = "#{python_prefix}/lib/lib#{python_version}.so"
      args << "-DPYTHON_EXECUTABLE='#{python_executable}'"
      args << "-DPYTHON_INCLUDE_DIR='#{python_include}'"
      args << "-DPYTHON_LIBRARY='#{python_library}'"
    else
      args << "-Dpython=OFF"
    end

    mkdir "builddir" do
    end
  end

  def caveats; <<~EOS
    python prefix: #{python_prefix}       
    python library: #{python_library}       
    python include dir: #{python_include}   
    python executable: #{python_executable}
  EOS
  end
  
end
