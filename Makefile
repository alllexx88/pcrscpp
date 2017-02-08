.PHONY: all all_shared all_static all_8 all_16 all_32 shared_8 shared_16 shared_32 static_8 static_16 static_32 clean

#compiler
CXX=g++
#archiver - for static libs
AR=ar rcs

PKG_CONFIG:=pkg-config

# get flags from pkg-config, ignore errors here
PCRE_CFLAGS:=$(shell $(PKG_CONFIG) --cflags libpcre 2>/dev/null)
PCRE_LIBS:=$(shell $(PKG_CONFIG) --libs libpcre 2>/dev/null)

PCRE16_CFLAGS:=$(shell $(PKG_CONFIG) --cflags libpcre16 2>/dev/null)
PCRE16_LIBS:=$(shell pkg-config --libs libpcre16 2>/dev/null)

PCRE32_CFLAGS:=$(shell $(PKG_CONFIG) --cflags libpcre32 2>/dev/null)
PCRE32_LIBS:=$(shell $(PKG_CONFIG) --libs libpcre32 2>/dev/null)

CUMMON_LIBS:=

COMMON_CFLAGS=\
-fPIC \
-std=c++11 # least recommended C++ standard, will not compile libpcrscpp32 without C++11 features support

COMMON_CFLAGS+=-O3 # Optimization level

COMMON_CFLAGS+=-g # debug symbols

COMMON_CFLAGS+=-Wall # all warnings

COMMON_CFLAGS+=-Werror # treat warnings as errors

PCRSCPP_VERSION:=0.0.1
PCRSCPP_SO_VERSION:=0

LIBPCRSCPP_shared=libpcrscpp.so.$(PCRSCPP_VERSION)
LIBPCRSCPP_static=libpcrscpp.a

LIBPCRSCPP16_shared=libpcrscpp16.so.$(PCRSCPP_VERSION)
LIBPCRSCPP16_static=libpcrscpp16.a

LIBPCRSCPP32_shared=libpcrscpp32.so.$(PCRSCPP_VERSION)
LIBPCRSCPP32_static=libpcrscpp32.a

#default target
all: all_shared all_static test test16 test32
	@echo "All done"

shared_8: $(LIBPCRSCPP_shared)

shared_16: $(LIBPCRSCPP16_shared)

shared_32: $(LIBPCRSCPP32_shared)

all_shared: shared_8 shared_16 shared_32

static_8: $(LIBPCRSCPP_static)

static_16: $(LIBPCRSCPP16_static)

static_32: $(LIBPCRSCPP32_static)

all_static: static_8 static_16 static_32

$(LIBPCRSCPP_shared): obj/pcrscpp.o
	rm -f $@
	$(CXX) -shared -Wl,-soname,libpcrscpp.so.$(PCRSCPP_SO_VERSION) -o $@  $^ $(PCRE_LIBS) $(CUMMON_LIBS)

$(LIBPCRSCPP_static): obj/pcrscpp.o
	rm -f $@
	$(AR) $@ $^

$(LIBPCRSCPP16_shared): obj/pcrscpp16.o
	rm -f $@
	$(CXX) -shared -Wl,-soname,libpcrscpp16.so.$(PCRSCPP_SO_VERSION) -o $@  $^ $(PCRE16_LIBS) $(CUMMON_LIBS)

$(LIBPCRSCPP16_static): obj/pcrscpp16.o
	rm -f $@
	$(AR) $@ $^

$(LIBPCRSCPP32_shared): obj/pcrscpp32.o
	rm -f $@
	$(CXX) -shared -Wl,-soname,libpcrscpp32.so.$(PCRSCPP_SO_VERSION) -o $@  $^ $(PCRE32_LIBS) $(CUMMON_LIBS)

$(LIBPCRSCPP32_static): obj/pcrscpp32.o
	rm -f $@
	$(AR) $@ $^

obj:
	@mkdir -p "$@"

obj/pcrscpp.o: src/pcrscpp.cpp src/pcrscpp_macros.h include/pcrscpp.h|obj
	rm -f $@
	@$(PKG_CONFIG) --version 2>&1 >/dev/null || \
		(echo "Error: cannot find pkg-config. Try setting PKG_CONFIG make variable"; exit 1)
	@$(PKG_CONFIG) libpcre 2>&1 >/dev/null || \
		(echo "Error: $(PKG_CONFIG) cannot find libpcre"; exit 1)
	$(CXX) -Iinclude $(PCRE_CFLAGS) $(COMMON_CFLAGS) -UPCRSCPP16 -UPCRSCPP32 -c src/pcrscpp.cpp -o $@

obj/pcrscpp16.o: src/pcrscpp.cpp src/pcrscpp_macros.h include/pcrscpp.h|obj
	rm -f $@
	@$(PKG_CONFIG) --version 2>&1 >/dev/null || \
		(echo "Error: cannot find pkg-config. Try setting PKG_CONFIG make variable"; exit 1)
	@$(PKG_CONFIG) libpcre16 2>&1 >/dev/null || \
		(echo "Error: $(PKG_CONFIG) cannot find libpcre16"; exit 1)
	$(CXX) -Iinclude $(PCRE16_CFLAGS) $(COMMON_CFLAGS) -DPCRSCPP16 -UPCRSCPP32 -c src/pcrscpp.cpp -o $@

obj/pcrscpp32.o: src/pcrscpp.cpp src/pcrscpp_macros.h include/pcrscpp.h|obj
	rm -f $@
	@$(PKG_CONFIG) --version 2>&1 >/dev/null || \
		(echo "Error: cannot find pkg-config. Try setting PKG_CONFIG make variable"; exit 1)
	@$(PKG_CONFIG) libpcre32 2>&1 >/dev/null || \
		(echo "Error: $(PKG_CONFIG) cannot find libpcre32"; exit 1)
	$(CXX) -Iinclude $(PCRE16_CFLAGS) $(COMMON_CFLAGS) -UPCRSCPP16 -DPCRSCPP32 -c src/pcrscpp.cpp -o $@

clean:
	rm -f   obj/pcrscpp.o obj/pcrscpp16.o obj/pcrscpp32.o \
		$(LIBPCRSCPP_shared) $(LIBPCRSCPP_static) \
		$(LIBPCRSCPP16_shared) $(LIBPCRSCPP16_static) \
		$(LIBPCRSCPP32_shared) $(LIBPCRSCPP32_static) \
		obj/test.o test obj/test16.o test16 obj/test32.o test32

obj/test.o: src/test.cpp $(LIBPCRSCPP_static)|obj
	$(CXX) -Iinclude $(PCRE_CFLAGS) $(COMMON_CFLAGS) -c src/test.cpp -o obj/test.o

test: obj/test.o
	$(CXX) $^ $(LIBPCRSCPP_static) $(PCRE_LIBS) $(CUMMON_LIBS) -o $@

obj/test16.o: src/test16.cpp $(LIBPCRSCPP16_static)|obj
	$(CXX) -Iinclude $(PCRE16_CFLAGS) $(COMMON_CFLAGS) -c src/test16.cpp -o obj/test16.o

test16: obj/test16.o
	$(CXX) $^ $(LIBPCRSCPP16_static) $(PCRE16_LIBS) $(CUMMON_LIBS) -o $@

obj/test32.o: src/test32.cpp $(LIBPCRSCPP16_static)|obj
	$(CXX) -Iinclude $(PCRE16_CFLAGS) $(COMMON_CFLAGS) -c src/test32.cpp -o obj/test32.o

test32: obj/test32.o
	$(CXX) $^ $(LIBPCRSCPP32_static) $(PCRE32_LIBS) $(CUMMON_LIBS) -o $@

