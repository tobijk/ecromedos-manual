Summary: A powerful and user-friendly XML document authoring system
Name: ecromedos-doc
Version: ###TAG###
Release: 1
License: GNU Free Documentation License
Group: Documentation
Source: http://ecromedos.net/files/2.0.0/manual/pkg/ecromedos-doc-%{version}.tar.gz
BuildRoot: /var/tmp/%{name}-buildroot
BuildRequires: ecromedos

%description
ecromedos is an integrated solution for XML-based publishing in print
and on the Web. It is primarily targeted at, but not limited to, the
creation of technical documentation in the field of Computer Science.

This package contains the documentation.

%prep
%setup -q

%build
mkdir tmp html pdf
# make pdf
cd tmp && ecromedos -fxelatex -s ../style/latex-style.xml ../src/manual.xml
cd tmp && xelatex report.tex && xelatex report.tex && xelatex report.tex
cp tmp/report.pdf pdf/manual.pdf
# make xhtml
cd html && ecromedos -fxhtml ../src/manual.xml

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/share/doc/packages/ecromedos-doc

for dir in html pdf; do 
  if [ -d $dir ]; then 
    cp -a "$dir" $RPM_BUILD_ROOT/usr/share/doc/packages/ecromedos-doc/
  fi
done

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/usr/share/doc/packages/ecromedos-doc

%changelog
* Sun Jan 10 2010 Tobias Koch <tobias@ecromedos.net> 
- Initial release of version 2.0r0

