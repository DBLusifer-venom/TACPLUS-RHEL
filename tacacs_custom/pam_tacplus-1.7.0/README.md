# TACACS+ client toolkit

This repository contains three modules that are typically used to perform requests to a TACACS+ server:

* `libtac` - core TACACS+ client library
* `pam_tacplus` - PAM module for authenticating users against TACACS+
* `tacc` - a simple command-line TACACS+ client

The following core TACACS+ functions are supported:

| TACACS+ name   |           PAM name | What it does                        |
|----------------|--------------------|-------------------------------------|
| Authentication | Authenticate       | Is the user who they claim?         |
| Authorization  | Account management | Is the user entitled to service X?  |
| Account        | Session open/close | Record beginning and end of service |

### Recognized options:

| Option             | Management group | Description |
|------------------- | ---------------- | ----------- |
| `debug` | ALL | output debugging information via syslog(3); note, that the debugging is heavy, including passwords! |
| `secret` | ALL | *string* can be specified more than once; secret key used to encrypt/decrypt packets sent/received from the server |
| `server` | auth, session | *string* hostname, IP or hostname:port, can be specified more than once |
| `timeout` | ALL | *integer* connection timeout in seconds; default is 5 seconds |
| `login` | auth | TACACS+ authentication service, this can be *pap*, *chap* or *login*; default is *pap* |
| `prompt` | auth | *string* custom password prompt; use `_` instead of spaces  |
| `acct_all` | session | if multiple servers are supplied, pam\_tacplus will send accounting start/stop packets to all servers on the list |
| `service` | account, session | *string* TACACS+ service for authorization and accounting |
| `protocol` | account, session | *string* TACACS+ protocol for authorization and accounting |

### Basic installation:

To compile from source, the code uses GNU `autotools` and `gnulib`:

```shell
# gnulib is included in this repository under gnulib/
# Ensure it is in your PATH before building
cd pam_tacplus-1.7.0
gnulib-tool --makefile-name=Makefile.gnulib --libtool --import \
                  fcntl crypto/md5 array-list list xlist getrandom realloc-posix \
                  explicit_bzero xalloc getopt-gnu
autoreconf -f -v -i
./configure
make
sudo make install
```

You can use `./configure --libdir=/lib` option to ensure `pam_tacplus.so`
is installed into `/lib/security` along with rather than in `/usr/local`. In such case you need to adjust the
lines in `/etc/pam.d` file accordingly.

#### Outdated gnulib

If you get errors like the one below during `./configure`, you most likely have an outdated `gnulib`
(notably, FreeBSD uses 2014 version):
```shell
error: GL_GENERATE_ALLOCA_H does not appear in AM_CONDITIONAL
```
This is fixed by installing the latest gnulib (included in this repository).

### Quick start
### TACACS+ server

To do anything with TACACS+ protocol we need a TACACS+ server. There are two TACACS+ servers
currently available - they have the same name and temptingly similar but different configuration syntax:

* pro-bono-publico tac_plus (available in FreeBSD net/tacacs)
* shrubbery tac_plus (available on Debian as tacacs+)

### pamtester
I recommend PAM testing utility pamtester.

### PAM configuration

Create `/etc/pam.d/test` with the following contents:
```
#%PAM-1.0
auth       required /usr/local/lib/security/pam_tacplus.so server=127.0.0.1 secret=testkey123
account    required /usr/local/lib/security/pam_tacplus.so server=127.0.0.1 secret=testkey123 service=ppp protocol=ip
session    required /usr/local/lib/security/pam_tacplus.so server=127.0.0.1 secret=testkey123 server=127.0.0.2 secret=testkey123 service=ppp protocol=ip
```

### More on server lists:

1. Having more than one TACACS+ server defined for given management group
has following effects on authentication:

    * if the first server on the list is unreachable or failing
      pam\_tacplus will try to authenticate the user against the other
      servers until it succeeds

    * the `first_hit` option has been deprecated

    * when the authentication function gets a positive reply from
      a server, it saves its address for future use by account
      management function (see below)

2. The account management (authorization) function asks *only one*
TACACS+ server and it ignores the whole server list passed from command
line. It uses server saved by authentication function after successful
authenticating user on that server. We assume that the server is
authoritative for queries about that user.

3. The session management (accounting) functions obtain their server lists
independently from the other functions. This allows you to account user
sessions on different servers than those used for authentication and
authorization.

    * normally, without the `acct_all` modifier, the extra servers
      on the list will be considered as backup servers, mostly like
      in point 1. i.e. they will be used only if the first server
      on the list will fail to accept our accounting packets.

    * with `acct_all` pam_tacplus will try to deliver the accounting
      packets to all servers on the list; failure of one of the servers
      will make it try another one. This is useful when your have several accounting, billing or
      logging hosts and want to have the accounting information appear
      on all of them at the same time.


### TACACS+ client program

The library comes with a simple TACACS+ client program `tacc` which can be used for testing as well as simple scripting. Sample usage:

```
tacc --authenticate --authorize --account --username user1
    --password pass1 --server localhost --remote 1.1.1.1 --tty ttyS0
    --secret enckey1 --service ppp --protocol ip --login pap
```

### Limitations:

* only subset of TACACS+ protocol is supported; it's enough for most need, though
* `tacc` does not support password prompts and other interactive protocol features

### Authors:

* Pawel Krawczyk <pawel.krawczyk@hush.com>
* Jeroen Nijhof <jeroen@jeroennijhof.nl>
