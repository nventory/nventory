Name: nventory-client
Summary: nVentory client
Version: 1.1
Release: 1
Group: Applications/System
License: MIT
buildarch: noarch
# RPM's automagic dependency handling captures most of our Perl module
# dependencies.  But perl-Crypt-SSLeay is special because perl-libwww-perl
# doesn't list it as a dependency, as it only tries to use it if you try
# to access an HTTPS URL.  So we have to explicitly list it as a dependency
# to ensure yum pulls it in.
# We also depend on dmidecode, but that is provided by different
# packages depending on the version of RHEL, so we do some magic
# in the Makefile to handle that.
Requires: perl-Crypt-SSLeay, crontabs
BuildRoot: %{_builddir}/%{name}-buildroot
%description
nVentory client

%files
%defattr(-,root,root)
/usr/nventory
/usr/bin/nv
/etc/cron.d/nventory

