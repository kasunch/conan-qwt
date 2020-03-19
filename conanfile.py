from conans import ConanFile, tools, VisualStudioBuildEnvironment
from conans.tools import cpu_count, os_info, SystemPackageTool
from conans.util.files import load
from conans.errors import ConanException
import os, sys
from distutils.spawn import find_executable

class QwtConan(ConanFile):
    name = "qwt"
    description = "Qt Widgets for Technical Applications"
    settings = "os", "arch", "compiler", "build_type"
    url = "https://github.com/kasunch/conan-qwt"
    homepage = "https://qwt.sourceforge.io/"
    topics = ("conan", "qt", "ui", "qwt")
    options = {
        "shared": [True, False],
        "plot": [True, False],
        "widgets": [True, False],
        "svg": [True, False],
        "opengl": [True, False],
        "mathml": [True, False],
        "designer": [True, False],
        "examples": [True, False],
        "playground": [True, False]
    }
    default_options = {
        "shared": False,
        "plot" : True,
        "widgets": True,
        "svg": True,
        "opengl": True,
        "mathml": True,
        "designer": False,
        "examples": False,
        "playground": False
    }

    exports_sources = ["FindQwt.cmake"]

    def source(self):
        svn = tools.SVN()
        svn.checkout(**self.conan_data["sources"][self.version])

    def requirements(self):
        self.requires("qt/5.14.1@bincrafters/stable")

        if self.options.svg:
            self.options["qt"].qtsvg = True
 
    def build(self):
        qwt_config_file_path = os.path.join(self.source_folder, "qwtconfig.pri" )
        self.output.info("Configuring " + qwt_config_file_path)
        qwt_config = load(qwt_config_file_path)
        qwt_config += "\nQWT_CONFIG %s= QwtDll" % ("+" if self.options.shared else "-")
        qwt_config += "\nQWT_CONFIG %s= QwtPlot" % ("+" if self.options.plot else "-")
        qwt_config += "\nQWT_CONFIG %s= QwtWidgets" % ("+" if self.options.widgets else "-")
        qwt_config += "\nQWT_CONFIG %s= QwtSvg" % ("+" if self.options.svg else "-")
        qwt_config += "\nQWT_CONFIG %s= QwtOpenGL" % ("+" if self.options.opengl else "-")
        qwt_config += "\nQWT_CONFIG %s= QwtMathML" % ("+" if self.options.mathml else "-")
        qwt_config += "\nQWT_CONFIG %s= QwtDesigner" % ("+" if self.options.designer else "-")
        qwt_config += "\nQWT_CONFIG %s= QwtExamples" % ("+" if self.options.examples else "-")
        qwt_config += "\nQWT_CONFIG %s= QwtPlayground" % ("+" if self.options.playground else "-")
        qwt_config = qwt_config.encode("utf-8")

        with open(qwt_config_file_path, "wb") as handle:
            handle.write(qwt_config)

        qwt_build_string = "CONFIG += %s" % ("release" if self.settings.build_type=="Release" else "debug")
        qwt_build_file_path = os.path.join(self.source_folder, "qwtbuild.pri")
        tools.replace_in_file(qwt_build_file_path, "CONFIG           += debug_and_release", qwt_build_string)
        tools.replace_in_file(qwt_build_file_path, "CONFIG           += build_all", "")
        tools.replace_in_file(qwt_build_file_path, "CONFIG           += release", qwt_build_string)

        if self.settings.os == "Windows":
            if self.settings.compiler == "Visual Studio":
                self._build_msvc()
            else:
                raise ConanException("Not yet implemented for this compiler")
        else:
            self._build_unix()

    def _build_unix(self):
        qmake_command = os.path.join(self.deps_cpp_info['qt'].rootpath, "bin", "qmake")
        build_command = find_executable("make")
        if build_command:
            build_args = ["-j", str(cpu_count())]
        else:
            raise ConanException("Cannot find make")

        self.output.info("Using '%s'" % (qmake_command))
        self.output.info("Using '%s %s' to build" % (build_command, " ".join(build_args)))

        self.run("cd %s && %s -r qwt.pro" % (self.source_folder, qmake_command))
        self.run("cd %s && %s %s" % (self.source_folder, 
                                    build_command,
                                    " ".join(build_args)))

    def _build_msvc(self, args = ""):
        qmake_command = os.path.join(self.deps_cpp_info['qt'].rootpath, "bin", "qmake")
        build_command = find_executable("jom.exe")
        if build_command:
            build_args = ["-j", str(cpu_count())]
        else:
            build_command = "nmake.exe"
            build_args = []

        self.output.info("Using '%s %s' to build" % (build_command, " ".join(build_args)))

        env_build = VisualStudioBuildEnvironment(self)

        with tools.environment_append(env_build.vars):
            vcvars = tools.vcvars_command(self.settings)
            self.run("cd %s && %s && %s -r qwt.pro" % (self.source_folder, vcvars, qmake_command))
            self.run("cd %s && %s && %s %s" % (self.source_folder, 
                                                vcvars, 
                                                build_command, 
                                                " ".join(build_args)))

    def package(self):
        self.copy("FindQwt.cmake", ".", ".")
        self.copy("*.h", dst="include", src=os.path.join(self.source_folder, "src"), excludes="moc")
        self.copy("*qwt.lib", dst="lib", keep_path=False)
        self.copy("*.dll", dst="lib", keep_path=False)
        self.copy("*.so", dst="lib", keep_path=False)
        self.copy("*.dylib", dst="lib", keep_path=False)
        self.copy("*.a", dst="lib", keep_path=False)

    def package_info(self):
        self.cpp_info.libs = ["qwt"]