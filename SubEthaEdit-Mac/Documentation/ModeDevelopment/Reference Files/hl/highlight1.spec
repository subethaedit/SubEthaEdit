# Test file for rpmspec.xml

# Comments start with a # in column="0":

# Some comment

# When they don't start in column="0", that they are not recognized as comments:
 # This isn't a comment.
# RPM spec says clear that comments must start at the begin of the line. However, in practice
# the RPM software is more permissive, depending on the context. But for our syntax highlighting,
# we stay with the official, strict rule for comments. Comments should not contain the character
# % (which is marked as error), but 2 of them are okay: %%. TODO is higlighted.

# A spec file starts with "Normal" context. Here, you can specify values for some tags:
Name:                kradioripper-unstable # Note that here in no comment possible!
# Some tag can have parameters: Any char in paranthesis:
Summary:             Recorder for internet radios (based on Streamripper)  
Summary(de.UTF-8):   Aufnahmeprogramm für Internetradios (basiert auf Streamripper)
Requires( / (  = ):  Some value
# If tags are used that are not known, they are not highlighted:
Invalidtag:          Some value
  
# You can use conditions in specs (highlighted with region markers):
%if 0%{?mandriva_version}  
Release:             %mkrel 1.2
%else  
Release:             0  
%endif  
# You must use these special macros (%%if etc.) always at the start of the line - if not,
# that's an error. You must also always use the specified form. Everything else is an
# error:
 %if
%{if}
%if(some options)
# However, this are different macros and therefore correct:
%ifx
%{ifx}
%ifx(some options)

# This special comment is treated and highlighted like a tag:
# norootforbuild  
# It can't have parameters, so every following non-whitespace character is an error:
# norootforbuild  DONT WRITE ANYTHING HERE!
  
# This following "Conflicts" tag will be removed by set-version.sh,  
# if it is a "kradioripper" release (and not a "kradioripper-unstable" release)...  
Conflicts:           kradioripper  
  
  
%description  
# Here, a new section starts. It contains a value for the RPM field "description" and is therefor
# colored like values:
A KDE program for ripping internet radios. Based on StreamRipper.  
  
Authors:  
--------  
    Tim Fechtner  
  
  
# A section start can have parameters:
%description -l de.UTF-8  
Ein KDE-Aufnahmeprogramm für Internetradios. Basiert auf StreamRipper.  
  
Autoren:  
--------  
    Tim Fechtner  
  
# These sections starts are errors:
 %description not at the first line
%{description} wrong form
%description(no options allowed, only parameters!)
  
  
%prep  
# This starts a section that defines the commands to prepare the build.
# q means quit. n sets the directory:  
%setup -q -n kradioripper  
echo Test
# Macros can have different forms: Valid:
%abc
%abcÄndOfMacro
%abc(def)EndOfMacro
%{abc}EndOfMacro
%{something but no single %}EndOfMacro
%{abc:def}EndOfMacro
%(abc)
# Invalid:
%ÄInvalidChar
%
%)
%}
# You can use macros inside of macro calls: Fine:
%{something %but no %{sin%(fine)gle} }EndOfMacro
# Bad:
%{No closing paranthesis (No syntax highlightig for this error available)
  
  
%build  
cmake ./ -DCMAKE_INSTALL_PREFIX=%{_prefix}  
%__make %{?jobs:-j %jobs}  
  
  
%install  
%if 0%{?suse_version}  
%makeinstall  
%suse_update_desktop_file kradioripper  
%endif  
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}  
make install DESTDIR=%{buildroot}  
desktop-file-install --delete-original --vendor fedora --dir=%{buildroot}/%{_datadir}/applications/kde4 %{buildroot}/%{_datadir}/applications/kde4/kradioripper.desktop  
%endif  
%if 0%{?mandriva_version}  
%makeinstall_std  
%endif  
  
  
%clean  
rm -rf "%{buildroot}"  
  
  
%files  
%defattr(-,root,root)  
%if 0%{?fedora_version} || 0%{?rhel_version} || 0%{?centos_version}  
%{_datadir}/applications/kde4/fedora-kradioripper.desktop  
%else  
%{_datadir}/applications/kde4/kradioripper.desktop  
%endif  
%{_bindir}/kradioripper  
%{_datadir}/locale/*/LC_MESSAGES/kradioripper.mo  
%if 0%{?mandriva_version}  
# TODO The %%doc macro is actually broken for mandriva 2009 in build service...
%dir %{_datadir}/apps/kradioripper  
%{_datadir}/apps/kradioripper/*  
%else  
%doc COPYING LICENSE LICENSE.GPL2 LICENSE.GPL3 NEWS WARRANTY  
%dir %{_datadir}/kde4/apps/kradioripper  
%{_datadir}/kde4/apps/kradioripper/*  
%endif  
  
  
%changelog  
# Changelog lines should start with "* " or "- ":
* Thu Dec 23 2008 Tim Fechtner 0.4.28  
- disabling debug packages
* Wed Nov 26 2008 Tim Fechtner 0.4.8  
- support for localization  
- installing the hole _datadir/kde4/apps/kradioripper/* instead of single files  
* Fri Nov 14 2008 Tim Fechtner 0.4.7  
- recommanding streamripper at least in versio 1.63  
* Thu Nov 11 2008 Tim Fechtner 0.4.4  
- revolving ambigiously dependency for Mandriva explicitly when using openSUSE build service  
* Wed Oct 08 2008 Tim Fechtner 0.4.2  
- Integrated Mandriva support. Thanks to Bock & Busse System GbR: http://www.randosweb.de  
* Sun Sep 14 2008 Tim Fechtner 0.3.0-1  
- streamripper no longer requiered but only recommended  
* Sat Sep 13 2008 Tim Fechtner 0.2.1-1  
- ported to openSUSE build service  
- support for Fedora 9  
* Sat May 24 2008 Detlef Reichelt <detlef@links2linux.de> 0.2.1-0.pm.1  
- initial build for packman  
  
