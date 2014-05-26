#
# spec file for package kdevelop
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Copyright (c) 2007-2008  Amilcar Lucas  <amilcar@kdevelop.org>
# Copyright (c) 2003-2006  Than Ngo       <than@redhat.com>
# Copyright (c) 2002-2006  Laurent Montel <lmontel@mandriva.com>
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

#########################################################################################
# Commom part
#########################################################################################
%define branch_source_date 20081218
%define kdevelop_version 3.5.4
%define kde_version 3.4.0
%define qt_version 3.3.2

%if 0%{?suse_version} != 0
%define name kdevelop3
%else
%define name kdevelop
%endif
Name:           %{name}
URL:            http://www.kdevelop.org/
Version:        %{kdevelop_version}
Release:        1
Summary:        Integrated Development Environment for the X Window System, Qt, KDE, and GNOME
License:        GPL (GNU General Public License)
Group:          Development/Tools/IDE
Provides:       kdevelop
Obsoletes:      kdevelop
Obsoletes:      gideon
Obsoletes:      kdevelop2
#Autoreqprov:    on
Source:         http://download.kde.org/download.php?url=stable/3.5.10/kdevelop-%{version}.tar.bz2
#Source1:        ftp://129.187.206.68/pub/unix/ide/KDevelop/c_cpp_reference-2.0.2_for_KDE_3.2.tar.bz2
%if 0%{?mandriva_version}
Source2:	kdevelop-3.0-Makefile.PL
Epoch:          3
%endif
%if 0%{?fedora_version}
Epoch:          9
Obsoletes:      kdevelop-c_c++_ref
#Patch1:        c_cpp_reference-2.0.2-config.patch
#Patch2:        kde-libtool.patch
%endif
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Packager:       Amilcar Lucas  <amilcar@kdevelop.org>

#########################################################################################
# SuSE, openSUSE
#########################################################################################
%if 0%{?suse_version}

# it is a qt3 based application
BuildRequires:  qt3-devel >= %{qt_version}
# For the entire kdelibs infrastructure
BuildRequires:  kdelibs3-devel >= %{kde_version}
%if %suse_version < 1010
BuildRequires:  update-desktop-files
# for the kdevassistant
BuildRequires:  qt3-devel-doc >= %{qt_version}
%endif
%if %suse_version < 1000
BuildRequires:  libjpeg-devel
%endif
# for the cvsservice (cvs support)
BuildRequires:  kdesdk3-devel >= %{kde_version}
# for the presistent class store (PCS)
BuildRequires:  db-devel >= 4.1
BuildRequires:  doxygen
BuildRequires:  graphviz >= 1.8.7
# For the QMake parser
BuildRequires:  flex >= 2.5.4
# for svn support
BuildRequires:  subversion-devel
#BuildRequires:  apr
%if %suse_version > 1030
# for the svn-merge functionality provided by subversion 1.5
BuildRequires:  sqlite-devel
%endif
# Nice to have KDE API documentation integrated in KDevelop
Requires:       kdelibs3-devel-doc >= %{kde_version}
Requires:       kdebase3 >= %{kde_version}
Requires:       kdesdk3 >= %{kde_version}
Requires:       cvs /usr/bin/make
Requires:       perl >= 5.004
Requires:       graphviz >= 1.8.7
Requires:       db >= 4.1
#For debugging with GDB-MI support
Requires:       gdb >= 6.4
Requires:       ctags >= 5
Requires:       libtool >= 1.4
Requires:       qt3-devel-tools >= %{qt_version}

# ruby templates in there
Requires:       kdebindings3-ruby >= %{kde_version}
# python templates in there
Requires:       kdebindings3-python >= %{kde_version}
%endif

#########################################################################################
# Mandriva
#########################################################################################
%if 0%{?mandriva_version}
%define __libtoolize    /bin/true

%define use_enable_final 0
%{?_no_enable_final: %{expand: %%global use_enable_final 0}}

%define compile_apidox 0
%{?_no_apidox: %{expand: %%global compile_apidox 0}}

%define unstable 0
%{?_unstable: %{expand: %%global unstable 1}}

%if %unstable
%define dont_strip 1
%endif

%define lib_name_orig libkdevelop
%if 0%{?mandriva_version} < 2008
%define lib_major 3
%define lib_name %mklibname kdevelop %lib_major
%endif
%define old_lib_major 2
%define old_lib_name %mklibname kdevelop %old_lib_major
%if 0%{?mandriva_version} >= 2008
%define major 3
%define libname %mklibname kdevelop %{major}
%define develname %mklibname %{name} -d
%endif

#BuildRequires:  libqt3 >= %{qt_version}
BuildRequires:  qt3-devel >= %{qt_version}
BuildRequires:  kdelibs-devel >= %{kde_version}
BuildRequires:  python
BuildRequires:  python-devel
BuildRequires:  libjpeg-devel
BuildRequires:  png-devel
%if 0%{?mandriva_version} <= 2006
BuildRequires:  XFree86-devel
%else
BuildRequires:  X11-devel
%endif
# for the kdevassistant
BuildRequires:  qt3-static-devel >= %{qt_version}
BuildRequires:  libart_lgpl-devel
# For the QMake parser
#BuildRequires:  flex >= 2.5.4
# for the cvsservice
BuildRequires:  libkdesdk-cervisia-devel >= %{kde_version}
BuildRequires:  graphviz >= 1.8.6
BuildRequires:  qt3-doc >= %{qt_version}
BuildRequires:  db-devel >= 4.1
# for svn support
BuildRequires:  subversion-devel
BuildRequires:  apr-devel
BuildRequires:  apr-util-devel
# doxygen is always required in order to build the parts/doxygen/ subdir
BuildRequires:  doxygen
%py_requires -d

#Requires: enscript 
Requires: gcc-c++ 
Requires: gcc-cpp 
#Requires: arts 
#Requires: openssl-devel
#Requires: kdegraphics kdelibs-devel kdesdk  kdeutils
Requires: kdelibs-devel-doc >= %{kde_version}
Requires: kdesdk >= %{kde_version}
Requires: kdebase >= %{kde_version}
%if 0%{?mandriva_version} <= 2006
Requires: XFree86-devel
%else
Requires: libx11-devel
%endif
Requires: jpeg-devel 
Requires: qt3 >= %{qt_version}
Requires: make 
Requires: perl >= 5.0004
#Requires: sgml-tools 
Requires: gettext 
Requires: libz-devel
Requires: ctags >= 5
Requires: png-devel libart_lgpl-devel
Requires: libtool >= 1.4
Requires: automake >= 1.6
Requires: autoconf >= 2.52
# required by the autoconf/automake projects
Requires: awk
Requires: db >= 4.1
%if 0%{?mandriva_version} < 2008
Requires: %lib_name = %epoch:%version-%release
%else
Requires:	%{libname} = %epoch:%version-%release
%endif
Requires: kdesdk-cervisia >= %{kde_version}
Requires: doxygen
Requires: graphviz >= 1.8.6
Requires(post): desktop-file-utils
Requires(postun): desktop-file-utils
Conflicts: mandrake-mime <= 0.4-5mdk
%endif

#########################################################################################
# Fedora, RHEL or CentOS
#########################################################################################
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
%define debug 0
%define final 0

%define qt_epoch 1
%define kdelibs_epoch 6

%define make_cvs 1

%define disable_gcc_check_and_hidden_visibility 1

Requires(post):   /sbin/ldconfig
Requires(postun): /sbin/ldconfig
Requires: kdelibs-devel >= %{kdelibs_epoch}:%{kde_version}
Requires: kdesdk >= %{kde_version}
Requires: make
Requires: perl >= 0:5.004
Requires: libtool >= 1.4
#Requires: flex >= 2.5.4
Requires: qt-designer >= %{qt_epoch}:%{qt_version}
Requires: db4 >= 4.1

BuildRequires: autoconf
BuildRequires: automake
BuildRequires: libtool
%if 0%{?fedora_version} > 8
BuildRequires: kdelibs3-devel >= %{kde_version}
%else
BuildRequires: kdelibs-devel >= %{kde_version}
%endif
BuildRequires:  gcc-c++
%if 0%{?fedora_version} > 8
BuildRequires:  qt3
BuildRequires:  qt3-devel >= %{qt_version}
BuildRequires:  kdelibs3-devel >= %{kde_version}
%else
BuildRequires:  qt
BuildRequires:  qt-devel >= %{qt_version}
BuildRequires:  kdelibs-devel >= %{kde_version}
%endif
BuildRequires:  db4-devel >= 4.1
%if 0%{?rhel_version} != 406
BuildRequires:  kdesdk-devel >= %{kde_version}
%endif
BuildRequires:  doxygen
# Both RHEL and CentOS do not provide graphviz
%if 0%{?fedora_version}
BuildRequires:  graphviz >= 1.8.6
%endif
# For the QMake parser
BuildRequires:  flex >= 2.5.4
%if 0%{?rhel_version} != 406
# for svn support
BuildRequires:  subversion-devel >= 1.3
BuildRequires:  apr-devel
BuildRequires:  neon-devel
%endif
%endif

%description
An integrated development environment (IDE) that allows you to write
programs for the X Window System, the Qt library, or KDE. It includes a
documentation browser, a source code editor with syntax highlighting, a
GUI for the compiler, and much more.



Authors:
--------
    Andreas Pakulat
    Robert Gruber
    Jens Dagerbo
    Alexander Dymo
    Vladimir Prus
    Matt Rogers
    Megan Webb
    Richard Dale
    Anne-Marie Mahfouf
    Amilcar do Carmo Lucas
    David Nolden
    Jonas Jacobi
    Stephan Binner
    Andras Mantia
    Oliver Kellogg


#########################################################################################
# SUSE
#########################################################################################
%if 0%{?suse_version}
%prep
%setup -q -n kdevelop-%{version}
#%patch0
#%patch1
#%patch2
#%patch4
# source the standard build environment as defined in kdelibs3 package
. /etc/opt/kde3/common_options 
# replace the admin/ folder with the version from kdelibs3 (will work for sure with
# current autoconf and automake) and create Makefile.in and configure script.
update_admin --no-unsermake --no-final

%build
. /etc/opt/kde3/common_options
export CFLAGS="-fno-strict-aliasing $CFLAGS"
./configure $configkde \
  --with-kdelibsdoxy-dir=/opt/kde3/share/doc/HTML/en/kdelibs-apidocs \
  --with-pythondir=%_libdir/python \
  --with-qtdoc-dir=/usr/%_lib/qt3/doc/html \
%if %suse_version < 1010
  --disable-subversion \
%endif
  --disable-final
do_make %{?jobs:-j %jobs}

%install
. /etc/opt/kde3/common_options
make DESTDIR=${RPM_BUILD_ROOT} $INSTALL_TARGET
# use our admin tar ball (commented out because KDevelop already uses an updated admin/ )
#tar cfvz ${RPM_BUILD_ROOT}/opt/kde3/share/apps/kdevappwizard/template-common/admin.tar.gz admin
%suse_update_desktop_file    kdevelop            Development IDE
%suse_update_desktop_file    kdevelop_c_cpp      Development IDE
%suse_update_desktop_file    kdevelop_kde_cpp    Development IDE
%suse_update_desktop_file    kdevelop_ruby       Development IDE
%suse_update_desktop_file    kdevelop_scripting  Development IDE
%suse_update_desktop_file    kdevassistant       Development Documentation
%suse_update_desktop_file    kdevdesigner        Development GUIDesigner
%find_lang kdevelop
rm -rf $RPM_BUILD_ROOT/opt/kde3/kdevbdb/docs/CVS
kde_post_install

%clean
rm -rf $RPM_BUILD_ROOT

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

# the -devel package
%package devel
Group:          Development/Tools/IDE
Summary:        Integrated Development Environment: Build Environment
Requires:       kdevelop3 = %version

%description devel
Development files to develop KDevelop itself. KDevelop is an integrated
development environment (IDE) that allows you to write
programs for the X Window System, the Qt library, or KDE. It includes a
documentation browser, a source code editor with syntax highlighting, a
GUI for the compiler, and much more.


%files devel
%defattr(-,root,root)
/opt/kde3/include/*
/opt/kde3/%_lib/libprofileengine.so
/opt/kde3/%_lib/liblang_interfaces.so
/opt/kde3/%_lib/liblang_debugger.so
/opt/kde3/%_lib/libkinterfacedesigner.so
/opt/kde3/%_lib/libkdevwidgets.so
/opt/kde3/%_lib/libkdevshell.so
/opt/kde3/%_lib/libkdevqmakeparser.so
/opt/kde3/%_lib/libkdevpropertyeditor.so
/opt/kde3/%_lib/libkdevextras.so
/opt/kde3/%_lib/libkdevelop.so
/opt/kde3/%_lib/libkdevcppparser.so
/opt/kde3/%_lib/libkdevcatalog.so
/opt/kde3/%_lib/libkdevbuildtoolswidgets.so
/opt/kde3/%_lib/libkdevbuildbase.so
/opt/kde3/%_lib/libgdbmi_parser.so
/opt/kde3/%_lib/libdocumentation_interfaces.so
/opt/kde3/%_lib/libdesignerintegration.so
/opt/kde3/%_lib/libd.so
/opt/kde3/%_lib/libd.la
/opt/kde3/%_lib/libdesignerintegration.la
/opt/kde3/%_lib/libdocumentation_interfaces.la
/opt/kde3/%_lib/libgdbmi_parser.la
/opt/kde3/%_lib/libkdevbuildbase.la
/opt/kde3/%_lib/libkdevbuildtoolswidgets.la
/opt/kde3/%_lib/libkdevcatalog.la
/opt/kde3/%_lib/libkdevcppparser.la
/opt/kde3/%_lib/libkdevelop.la
/opt/kde3/%_lib/libkdevextras.la
/opt/kde3/%_lib/libkdevpropertyeditor.la
/opt/kde3/%_lib/libkdevqmakeparser.la
/opt/kde3/%_lib/libkdevshell.la
/opt/kde3/%_lib/libkdevwidgets.la
/opt/kde3/%_lib/libkinterfacedesigner.la
/opt/kde3/%_lib/liblang_debugger.la
/opt/kde3/%_lib/liblang_interfaces.la
/opt/kde3/%_lib/libprofileengine.la

%files -f kdevelop.lang
%defattr(-,root,root)
%dir /opt/kde3/share/desktop-directories
%doc /opt/kde3/share/doc/HTML/en/kde_app_devel
%doc /opt/kde3/share/doc/HTML/en/kdevelop-apidocs
/opt/kde3/share/applications/kde/*
/opt/kde3/share/apps/*
%config /opt/kde3/share/config/*
/opt/kde3/share/icons/??color
/opt/kde3/bin/*
%dir /opt/kde3/%_lib/kconf_update_bin
/opt/kde3/%_lib/kconf_update_bin/kdev-gen-settings-kconf_update
/opt/kde3/%_lib/kde3/kded_kdevsvnd.so
/opt/kde3/%_lib/kde3/kio_chm.so
/opt/kde3/%_lib/kde3/kio_csharpdoc.so
/opt/kde3/%_lib/kde3/kio_kdevsvn.so
/opt/kde3/%_lib/kde3/kio_perldoc.so
/opt/kde3/%_lib/kde3/kio_pydoc.so
/opt/kde3/%_lib/kde3/libclearcaseintegrator.so
/opt/kde3/%_lib/kde3/libcvsserviceintegrator.so
/opt/kde3/%_lib/kde3/libdocchmplugin.so
/opt/kde3/%_lib/kde3/libdoccustomplugin.so
/opt/kde3/%_lib/kde3/libdocdevhelpplugin.so
/opt/kde3/%_lib/kde3/libdocdoxygenplugin.so
/opt/kde3/%_lib/kde3/libdockdevtocplugin.so
/opt/kde3/%_lib/kde3/libdocqtplugin.so
/opt/kde3/%_lib/kde3/libkchmpart.so
/opt/kde3/%_lib/kde3/libkdev*.so
/opt/kde3/%_lib/kde3/libperforceintegrator.so
/opt/kde3/%_lib/kde3/libsubversionintegrator.so
/opt/kde3/%_lib/kde3/kded_kdevsvnd.la
/opt/kde3/%_lib/kde3/kio_chm.la
/opt/kde3/%_lib/kde3/kio_csharpdoc.la
/opt/kde3/%_lib/kde3/kio_kdevsvn.la
/opt/kde3/%_lib/kde3/kio_perldoc.la
/opt/kde3/%_lib/kde3/kio_pydoc.la
/opt/kde3/%_lib/kde3/libclearcaseintegrator.la
/opt/kde3/%_lib/kde3/libcvsserviceintegrator.la
/opt/kde3/%_lib/kde3/libdocchmplugin.la
/opt/kde3/%_lib/kde3/libdoccustomplugin.la
/opt/kde3/%_lib/kde3/libdocdevhelpplugin.la
/opt/kde3/%_lib/kde3/libdocdoxygenplugin.la
/opt/kde3/%_lib/kde3/libdockdevtocplugin.la
/opt/kde3/%_lib/kde3/libdocqtplugin.la
/opt/kde3/%_lib/kde3/libkchmpart.la
/opt/kde3/%_lib/kde3/libkdev*.la
/opt/kde3/%_lib/kde3/libperforceintegrator.la
/opt/kde3/%_lib/kde3/libsubversionintegrator.la
/opt/kde3/%_lib/libprofileengine.so.*
/opt/kde3/%_lib/liblang_interfaces.so.*
/opt/kde3/%_lib/liblang_debugger.so.*
/opt/kde3/%_lib/libkinterfacedesigner.so.*
/opt/kde3/%_lib/libkdevwidgets.so.*
/opt/kde3/%_lib/libkdevshell.so.*
/opt/kde3/%_lib/libkdevqmakeparser.so.*
/opt/kde3/%_lib/libkdevpropertyeditor.so.*
/opt/kde3/%_lib/libkdevextras.so.*
/opt/kde3/%_lib/libkdevelop.so.*
/opt/kde3/%_lib/libkdevcppparser.so.*
/opt/kde3/%_lib/libkdevcatalog.so.*
/opt/kde3/%_lib/libkdevbuildtoolswidgets.so.*
/opt/kde3/%_lib/libkdevbuildbase.so.*
/opt/kde3/%_lib/libgdbmi_parser.so.*
/opt/kde3/%_lib/libdocumentation_interfaces.so.*
/opt/kde3/%_lib/libdesignerintegration.so.*
/opt/kde3/%_lib/libd.so.*
/opt/kde3/share/desktop-directories/kde-development-kdevelop.directory
/opt/kde3/share/mimelnk/*/*.desktop
/opt/kde3/share/services/*
/opt/kde3/share/servicetypes/*
%endif



#########################################################################################
# Mandriva
#########################################################################################
%if 0%{?mandriva_version}

%post
%update_menus
%if 0%{?mandriva_version} > 2006
%{update_desktop_database}
%update_icon_cache crystalsvg
%endif


%postun
%clean_menus
%if 0%{?mandriva_version} > 2006
%{clean_desktop_database}
%clean_icon_cache crystalsvg
%endif

%files
%defattr(-,root,root) 
%_bindir/*
%_datadir/applications/kde/*
%_libdir/kde3/*
%_datadir/apps/*
%_datadir/desktop-directories/kde-development-kdevelop.directory
%_datadir/icons/*/*/*/*
%_datadir/config/kdeveloprc
%_datadir/mimelnk/*/*.desktop
%_datadir/services/*
%_datadir/servicetypes/*
%if 0%{?mandriva_version} < 2008
%_menudir/*
%endif
%_libdir/kconf_update_bin/kdev-gen-settings-kconf_update
%_datadir/config/kdevassistantrc

#------------------------------------------------

%if 0%{?mandriva_version} < 2008
%package -n %lib_name-devel
%else
%package -n %{develname}
%endif
Summary: Development files for kdevelop
Group: Development/KDE and Qt

Obsoletes: kdevelop-devel, %old_lib_name-devel
Provides: kdevelop-devel = %epoch:%version-%release
%if 0%{?mandriva_version} < 2008
Requires: %lib_name = %epoch:%version-%release
%else
Requires:	%{libname} = %epoch:%version-%release
Obsoletes:	%mklibname %{name} 3 -d
%endif

%if 0%{?mandriva_version} < 2008
%description -n %lib_name-devel
%else
%description -n %{develname}
%endif
Development files for kdevelop.

%if 0%{?mandriva_version} < 2008
%files -n %lib_name-devel
%else
%files -n %{develname}
%endif
%defattr(-,root,root)
%_libdir/*.so
%dir %_includedir/kdevelop
%dir %_includedir/kinterfacedesigner
%_includedir/*/*

#------------------------------------------------

%if 0%{?mandriva_version} < 2008
%package -n %lib_name
%else
%package -n %{libname}
%endif
Summary: Libraries files for kdevelop
Group: Development/KDE and Qt
Obsoletes: %old_lib_name
%if 0%{?mandriva_version} < 2008
Provides: %lib_name_orig = %epoch:%version-%release

%description -n %lib_name
Libraries files for kdevelop.

%post -n %lib_name-devel -p /sbin/ldconfig
%postun -n %lib_name-devel -p /sbin/ldconfig

%post -n %lib_name -p /sbin/ldconfig
%postun -n %lib_name -p /sbin/ldconfig

%files -n %lib_name
%else
Provides:	%{libname}_orig = %epoch:%version-%release

%description -n %{libname}
Libraries files for kdevelop.

%post -n %{develname} -p /sbin/ldconfig
%postun -n %{develname} -p /sbin/ldconfig

%post -n %{libname} -p /sbin/ldconfig
%postun -n %{libname} -p /sbin/ldconfig

%files -n %{libname}
%endif
%defattr(-,root,root)
%_libdir/*.la
%_libdir/*.so.*


#------------------------------------------------

%package doc
Summary: Development files for kdevelop
Group: Development/KDE and Qt

%description doc
Documentation kdevelop.

%files doc
%defattr(-,root,root)
%dir %_docdir/HTML/en/kdevelop
%_docdir/HTML/en/kdevelop/*
%dir %_docdir/HTML/en/kde_app_devel
%_docdir/HTML/en/kde_app_devel/*
%doc %_docdir/HTML/en/kdevelop-apidocs

#------------------------------------------------

%prep
%setup -q

%build
%if 0%{?mandriva_version} < 2008
export QTDIR=%_prefix/lib/qt3
%else
export QTDIR=%{qt3dir}
%endif
QTDOCDIR=%_defaultdocdir/qt-*/doc/html

%configure2_5x \
%if %unstable
        --enable-debug=full \
%else
        --disable-debug \
%endif
%if %use_enable_final
        --enable-final \
%endif
        --disable-static \
    --disable-embedded \
    --disable-palmtop \
    --disable-rpath \
%if "%{_lib}" != "lib"
    --enable-libsuffix="%(A=%{_lib}; echo ${A/lib/})" \
%endif
        --with-pic \
   --with-qtdoc-dir=$QTDOCDIR \
   --enable-scripting \
%if 0%{?mandriva_version} < 2005
   --disable-subversion \
%endif
   --with-apr-config=%_bindir/apr-1-config \
   --with-apu-config=%_bindir/apu-1-config \
   --with-kdelibsdoc-dir=%_docdir/HTML/en/ 

%make
%if %compile_apidox
make apidox
%endif

%install
rm -fr %buildroot

####                                                       ####
#### Convert KDE menu structure to Mandriva menu structure ####
####                                                       ####

%makeinstall_std

%if 0%{?mandriva_version} < 2008
# Create LMDK menus
install -d %buildroot/%_datadir/applications/kde/

#Create LMDK menu entries
install -d %buildroot/%_menudir/
for kdev in kdevelop kdevdesigner kdevassistant kdevelop_c_cpp kdevelop_kde_cpp kdevelop_ruby kdevelop_scripting; do
        kdedesktop2mdkmenu.pl kdevelop "More Applications/Development/Development Environments" %buildroot/%_datadir/applications/kde/${kdev}.desktop %buildroot/%_menudir/kdevelop-${kdev}
done
%else
(
cd %{buildroot}/%name-%version/
rm -rf perl-kdevelop
mkdir perl-kdevelop/
cd perl-kdevelop/
install -m 0755 %SOURCE2 Makefile.PL
ln ../parts/appwizard/common/kdevelop.pm kdevelop.pm
perl Makefile.PL INSTALLDIRS=vendor
make install DESTDIR=%buildroot
)
%endif

%clean
rm -fr %buildroot
%endif



#########################################################################################
# Fedora, RHEL or CentOS
#########################################################################################
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}
%prep

%setup -q
#%setup -q -a1

%build
export KDEDIR=%{_prefix}
%if 0%{?fedora_version} >= 5
QTDIR="" && source "%{_sysconfdir}/profile.d/qt.sh"
%else
QTDIR="" && source /etc/profile.d/qt.sh
%endif
export FLAGS="$RPM_OPT_FLAGS"
# c references
#pushd c_cpp_reference-2.0.2_for_KDE_3.2
#%configure \
#  --with-qt-libraries=$QTDIR/lib \
#  --with-qt-includes=$QTDIR/include \
#  --with-extra-libs=%{_libdir}
#popd
%configure \
   --enable-new-ldflags \
   --disable-dependency-tracking \
%if %{disable_gcc_check_and_hidden_visibility}
   --disable-gcc-hidden-visibility \
%endif
   --disable-rpath \
%if %{debug} == 0
   --disable-debug \
   --disable-warnings \
%endif
%if %{final}
  --enable-final \
%endif
  --with-qtdoc-dir=%{_docdir}/qt-devel-%{qt_version}/html/ \
  --with-kdelibsdoc-dir=%{_docdir}/HTML/en/kdelibs-apidocs/ \
  --with-qt-libraries=$QTDIR/lib \
  --with-extra-libs=%{_libdir}
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make DESTDIR=$RPM_BUILD_ROOT install
#make -C c_cpp_reference-2.0.2_for_KDE_3.2 DESTDIR=$RPM_BUILD_ROOT install

# remove useless files
rm -rf $RPM_BUILD_ROOT%{_prefix}/kdevbdb

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc %{_docdir}/HTML/en/*
%{_bindir}/*
%{_libdir}/kde3/*
%{_libdir}/lib*
%{_libdir}/kconf_update_bin/*
%{_includedir}/*
%{_datadir}/applications/kde/*
%{_datadir}/apps/*
%config %{_datadir}/config/*
%{_datadir}/desktop-directories/*
%{_datadir}/icons/*/*/*/*
%{_datadir}/mimelnk/application/*
%{_datadir}/mimelnk/text/*
%{_datadir}/services/*
%{_datadir}/servicetypes/*
%endif

