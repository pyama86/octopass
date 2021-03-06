Summary:          Management linux user and authentication with the organization/team on Github.
Name:             octopass
Version:          0.3.5
Release:          1
License:          GPLv3
URL:              https://github.com/linyows/octopass
Source:           %{name}-%{version}.tar.gz
Group:            System Environment/Base
Packager:         linyows <linyows@gmail.com>
%if 0%{?rhel} < 6
Requires:         glibc curl-devel jansson-devel
%else
Requires:         glibc libcurl-devel jansson-devel
%endif
BuildRequires:    gcc make
BuildRoot:        %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:        i386, x86_64

%define debug_package %{nil}

%description
This is linux user management tool with the organization/team on github, and authentication.
Depending on github for user management, there are certain risks,
but features easy handling and ease of operation.

%prep
%setup -q -n %{name}-%{version}

%build
make

%install
%{__rm} -rf %{buildroot}
mkdir -p %{buildroot}/usr/{lib64,bin}
mkdir -p %{buildroot}%{_sysconfdir}
make PREFIX=%{buildroot}/usr install
install -d -m 755 %{buildroot}/var/cache/octopass
install -m 644 octopass.conf.example %{buildroot}%{_sysconfdir}/octopass.conf.example

%clean
%{__rm} -rf %{buildroot}

%post

%preun

%postun

%files
%defattr(-, root, root)
/usr/lib64/libnss_octopass.so
/usr/lib64/libnss_octopass.so.2
/usr/lib64/libnss_octopass.so.2.0
/usr/bin/octopass
/var/cache/octopass
/etc/octopass.conf.example

%changelog
* Thu Sep 14 2017 linyows <linyows@gmail.com> - 0.3.5-1
- Bugfixes
* Sun May 07 2017 linyows <linyows@gmail.com> - 0.3.3-1
- Fix segmentation fault
* Tue Feb 28 2017 linyows <linyows@gmail.com> - 0.3.2-1
- Example typo
* Mon Feb 27 2017 linyows <linyows@gmail.com> - 0.3.1-1
- Bugfixes
* Sun Feb 26 2017 linyows <linyows@gmail.com> - 0.3.0-1
- Support shared-users option
* Sun Feb 19 2017 linyows <linyows@gmail.com> - 0.2.0-1
- Change implementation in Go to C
* Fri Feb 03 2017 linyows <linyows@gmail.com> - 0.1.0-1
- Initial packaging
