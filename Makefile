CC=gcc
CFLAGS=-Wall -Wstrict-prototypes -Werror -fPIC -std=c99 -D_GNU_SOURCE
LD_SONAME=-Wl,-soname,libnss_octopass.so.2
LIBRARY=libnss_octopass.so.2.0
LINKS=libnss_octopass.so.2 libnss_octopass.so

PREFIX=/usr
LIBDIR=$(PREFIX)/lib64
ifeq ($(wildcard $(LIBDIR)/.*),)
LIBDIR=$(PREFIX)/lib
endif
BINDIR=$(PREFIX)/bin
BUILD=tmp/libs
CACHE=/var/cache/octopass

SOURCES=Makefile octopass.h octopass*.c nss_octopass*.c octopass.conf.example COPYING
VERSION=$(shell awk -F\" '/^\#define OCTOPASS_VERSION / { print $$2; exit }' octopass.h)
CRITERION_VERSION=2.3.0

INFO_COLOR=\033[1;34m
RESET=\033[0m
BOLD=\033[1m

default: build
build: nss_octopass octopass_cli

build_dir:
	test -d $(BUILD) || mkdir -p $(BUILD)

cache_dir:
	test -d $(CACHE) || mkdir -p $(CACHE)

deps:
	@echo -e "$(INFO_COLOR)==> $(RESET)$(BOLD)Installing Dependencies$(RESET)"
	git clone --depth=1 https://github.com/vstakhov/libucl.git tmp/libucl
	pushd tmp/libucl; ./autogen.sh; ./configure && make && make install; popd
	git clone --depth=1 https://github.com/allanjude/uclcmd.git tmp/uclcmd

depsdev: build_dir cache_dir
	test -f $(BUILD)/criterion.tar.bz2 || curl -sL https://github.com/Snaipe/Criterion/releases/download/v$(CRITERION_VERSION)/criterion-v$(CRITERION_VERSION)-linux-x86_64.tar.bz2 -o $(BUILD)/criterion.tar.bz2
	cd $(BUILD); tar xf criterion.tar.bz2; cd ../
	mv $(BUILD)/criterion-v$(CRITERION_VERSION)/include/criterion /usr/include/criterion
	mv $(BUILD)/criterion-v$(CRITERION_VERSION)/lib/libcriterion.* $(LIBDIR)/

nss_octopass: build_dir cache_dir
	$(CC) $(CFLAGS) -c nss_octopass-passwd.c -o $(BUILD)/nss_octopass-passwd.o
	$(CC) $(CFLAGS) -c nss_octopass-group.c -o $(BUILD)/nss_octopass-group.o
	$(CC) $(CFLAGS) -c nss_octopass-shadow.c -o $(BUILD)/nss_octopass-shadow.o
	$(CC) $(CFLAGS) -c octopass.c -o $(BUILD)/octopass.o
	$(CC) -shared $(LD_SONAME) -o $(BUILD)/$(LIBRARY) \
		$(BUILD)/octopass.o \
		$(BUILD)/nss_octopass-passwd.o \
		$(BUILD)/nss_octopass-group.o \
		$(BUILD)/nss_octopass-shadow.o \
		-lcurl -ljansson

octopass_cli: build_dir cache_dir
	$(CC) $(CFLAGS) -c nss_octopass-passwd_cli.c -o $(BUILD)/nss_octopass-passwd_cli.o
	$(CC) $(CFLAGS) -c nss_octopass-group_cli.c -o $(BUILD)/nss_octopass-group_cli.o
	$(CC) $(CFLAGS) -c nss_octopass-shadow_cli.c -o $(BUILD)/nss_octopass-shadow_cli.o
	$(CC) $(CFLAGS) -c octopass_cli.c -o $(BUILD)/octopass_cli.o
	$(CC) -o $(BUILD)/octopass \
		$(BUILD)/octopass_cli.o \
		$(BUILD)/nss_octopass-passwd_cli.o \
		$(BUILD)/nss_octopass-group_cli.o \
		$(BUILD)/nss_octopass-shadow_cli.o \
		-lcurl -ljansson

test: depsdev testdev

testdev:
	@echo -e "$(INFO_COLOR)==> $(RESET)$(BOLD)Testing$(RESET)"
	$(CC) octopass_test.c \
		nss_octopass-passwd_test.c \
		nss_octopass-group_test.c \
		nss_octopass-shadow_test.c -lcurl -ljansson -lcriterion -o $(BUILD)/test && \
		$(BUILD)/test --verbose

format:
	@echo -e "$(INFO_COLOR)==> $(RESET)$(BOLD)Formatting$(RESET)"
	for f in $(ls *.{c,h}); do\
		clang-format -i $f;\
	done
	test -z "$$(git status -s -uno)"

install: install_lib install_cli

install_lib:
	@echo -e "$(INFO_COLOR)==> $(RESET)$(BOLD)Installing as Libraries$(RESET)"
	[ -d $(LIBDIR) ] || install -d $(LIBDIR)
	install $(BUILD)/$(LIBRARY) $(LIBDIR)
	cd $(LIBDIR); for link in $(LINKS); do ln -sf $(LIBRARY) $$link ; done;

install_cli:
	@echo -e "$(INFO_COLOR)==> $(RESET)$(BOLD)Installing as Command$(RESET)"
	cp $(BUILD)/octopass $(BINDIR)/octopass

dist:
	@echo -e "$(INFO_COLOR)==> $(RESET)$(BOLD)Distributing$(RESET)"
	rm -rf octopass-$(VERSION) octopass-$(VERSION).tar octopass-$(VERSION).tar.gz
	mkdir octopass-$(VERSION)
	cp $(SOURCES) octopass-$(VERSION)
	tar cf octopass-$(VERSION).tar octopass-$(VERSION)
	gzip -9 octopass-$(VERSION).tar
	rm -rf octopass-$(VERSION)

dist_debian:
	rm -rf octopass-$(VERSION) octopass-$(VERSION).tar octopass-$(VERSION).orig.tar.xz
	mkdir octopass-$(VERSION)
	cp $(SOURCES) octopass octopass-$(VERSION)
	tar cvf octopass-$(VERSION).tar octopass-$(VERSION)
	xz -v octopass-$(VERSION).tar
	mv octopass-$(VERSION).tar.xz octopass-$(VERSION).orig.tar.xz
	rm -rf octopass-$(VERSION)

rpm: dist
	mv octopass-$(VERSION).tar.gz /root/rpmbuild/SOURCES
	spectool -g -R rpm/octopass.spec
	rpmbuild -ba rpm/octopass.spec
	cp /root/rpmbuild/RPMS/*/*.rpm /octopass/builds

clean:
	@echo -e "$(INFO_COLOR)==> $(RESET)$(BOLD)Cleaning$(RESET)"
	rm -rf $(TMP)

distclean: clean
	rm -f *~ \#*

.PHONY: clean install build_dir cache_dir nss_octopass octopass_cli dist distclean deps depsdev test testdev rpm