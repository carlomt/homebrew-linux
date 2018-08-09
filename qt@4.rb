class QtAT4 < Formula
  desc "Cross-platform application and UI framework"
  homepage "https://www.qt.io/"
  # url "https://download.qt.io/official_releases/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz"
  url "https://download.qt.io/archive/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz"
  # mirror "https://www.mirrorservice.org/sites/download.qt-project.org/official_releases/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz"
  sha256 "e2882295097e47fe089f8ac741a95fef47e0a73a3f3cdf21b56990638f626ea0"
  revision 3

  head "https://code.qt.io/qt/qt.git", :branch => "4.8"

  
  option "with-docs", "Build documentation"

  depends_on "openssl"
  depends_on "dbus" => :optional
  depends_on "mysql" => :optional
  depends_on "postgresql" => :optional

  deprecated_option "qtdbus" => "with-dbus"
  deprecated_option "with-d-bus" => "with-dbus"

  resource "test-project" do
    url "https://gist.github.com/tdsmith/f55e7e69ae174b5b5a03.git",
        :revision => "6f565390395a0259fa85fdd3a4f1968ebcd1cc7d"
  end

  def install
    args = %W[
      -prefix #{prefix}
      -plugindir #{prefix}/lib/qt4/plugins
      -importdir #{prefix}/lib/qt4/imports
      -datadir #{prefix}/etc/qt4
      -release
      -opensource
      -confirm-license
      -fast
      -system-zlib
      -qt-libtiff
      -qt-libpng
      -qt-libjpeg
      -nomake demos
      -nomake examples
      -no-webkit
    ]

    if ENV.compiler == :clang
      args << "-platform"
    end

    args << "-openssl-linked"
    args << "-I" << Formula["openssl"].opt_include
    args << "-L" << Formula["openssl"].opt_lib

    args << "-plugin-sql-mysql" if build.with? "mysql"
    args << "-plugin-sql-psql" if build.with? "postgresql"

    if build.with? "dbus"
      dbus_opt = Formula["dbus"].opt_prefix
      args << "-I#{dbus_opt}/lib/dbus-1.0/include"
      args << "-I#{dbus_opt}/include/dbus-1.0"
      args << "-L#{dbus_opt}/lib"
      args << "-ldbus-1"
      args << "-dbus-linked"
    end

    args << "-nomake" << "docs" if build.without? "docs"

    if MacOS.prefer_64_bit?
      args << "-arch" << "x86_64"
    else
      args << "-arch" << "x86"
    end
    
    system "./configure", "-embedded", *args
    system "make"
    ENV.deparallelize
    system "make", "install"
    
    # Delete qmake, as we'll be rebuilding it
    system "rm", "bin/qmake"
    system "rm", "#{bin}/qmake"
    system "make", "clean"
    
    # Patch the configure script so the built qmake can find Webkit if installed
    inreplace "configure", '=$QT_INSTALL_PREFIX"`', "=#{HOMEBREW_PREFIX}\"`"
    inreplace "configure", '=$QT_INSTALL_DOCS"`', "=#{HOMEBREW_PREFIX}/doc\"`"
    inreplace "configure", '=$QT_INSTALL_HEADERS"`', "=#{HOMEBREW_PREFIX}/include\"`"
    inreplace "configure", '=$QT_INSTALL_LIBS"`', "=#{HOMEBREW_PREFIX}/lib\"`"
    inreplace "configure", '=$QT_INSTALL_BINS"`', "=#{HOMEBREW_PREFIX}/bin\"`"
    inreplace "configure", '=$QT_INSTALL_PLUGINS"`', "=#{HOMEBREW_PREFIX}/lib/qt4/plugins\"`"
    inreplace "configure", '=$QT_INSTALL_IMPORTS"`', "=#{HOMEBREW_PREFIX}/lib/qt4/imports\"`"
    inreplace "configure", '=$QT_INSTALL_DATA"`', "=#{HOMEBREW_PREFIX}/etc/qt4\"`"
    inreplace "configure", '=$QT_INSTALL_SETTINGS"`', "=#{HOMEBREW_PREFIX}\"`"

    # Run ./configure again, to rebuild qmake
    system "./configure", *args
    bin.install "bin/qmake"

    # what are these anyway?
    (bin+"pixeltool.app").rmtree
    (bin+"qhelpconverter.app").rmtree

    # Some config scripts will only find Qt in a "Frameworks" folder
    frameworks.install_symlink Dir["#{lib}/*.framework"]

    # The pkg-config files installed suggest that headers can be found in the
    # `include` directory. Make this so by creating symlinks from `include` to
    # the Frameworks' Headers folders.
    Pathname.glob("#{lib}/*.framework/Headers") do |path|
      include.install_symlink path => path.parent.basename(".framework")
    end
    
  end

  def caveats; <<~EOS
    We agreed to the Qt opensource license for you.
    If this is unacceptable you should uninstall.

    Phonon is not supported on macOS Sierra or with Xcode 8.
    
    WebKit is no longer included for security reasons. If you absolutely
    need it, it can be installed with `brew install qt-webkit@2.3`.
    EOS
  end

  test do
    Encoding.default_external = "UTF-8" unless RUBY_VERSION.start_with? "1."
    resource("test-project").stage testpath
    system bin/"qmake"
    system "make"
    assert_match(/GitHub/, pipe_output(testpath/"qtnetwork-test 2>&1", nil, 0))
  end
  
  bottle do
    root_url "https://dl.bintray.com/cartr/bottle-qt4"
  end
end
