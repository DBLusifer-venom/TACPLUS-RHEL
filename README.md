# TACPLUS-RHEL

Self-contained TACACS+ PAM authentication module for RHEL 9.

## Contents

```
TACPLUS-RHEL/
├── tacacs_custom/
│   ├── pam_tacplus-1.7.0/    # pam_tacplus source (patched for RHEL 9)
│   ├── gnulib/               # gnulib build-time dependency
│   ├── patches/              # RHEL 9 compatibility patch
│   ├── setup.sh              # Repository setup script
│   └── pam_tacplus-1.7.0.tar.gz
├── .gitignore
└── README.md
```

## What is this?

pam_tacplus is a PAM module that authenticates Linux users against a TACACS+ server (e.g. Cisco, Ivanti Policy Secure). This repository contains:

- **pam_tacplus v1.7.0** source with RHEL 9 compatibility patch
- **gnulib** build-time dependency (included, no external fetch needed)
- **Custom RPM spec** for building RHEL 9 packages

## Build from Source

```bash
cd tacacs_custom/pam_tacplus-1.7.0
export PATH=../gnulib:$PATH

gnulib-tool --makefile-name=Makefile.gnulib --libtool --import \
    fcntl crypto/md5 array-list list xlist getrandom realloc-posix \
    explicit_bzero xalloc getopt-gnu

autoreconf -fvi
./configure --prefix=/usr --libdir=/usr/lib64 --enable-pamdir=/usr/lib64/security
make
sudo make install
```

## Build RPM

```bash
cd tacacs_custom
tar czf /tmp/pam_tacplus-1.7.0.tar.gz --exclude='.git' pam_tacplus-1.7.0/
cp /tmp/pam_tacplus-1.7.0.tar.gz ~/rpmbuild/SOURCES/

rpmbuild -ba ~/rpmbuild/SPECS/pam-tacplus-rhel9.spec
```

## RHEL 9 Patch

The `configure.ac` file is patched to remove `gl_PREREQ_EXPLICIT_BZERO`, which is not recognized by RHEL 9's packaged autotools. See `patches/001-fix-gnulib-rhel9.patch`.

## License

GPL v2 (see `pam_tacplus-1.7.0/COPYING`)
