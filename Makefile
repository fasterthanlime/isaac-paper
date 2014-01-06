
DEBUG_FLAGS+=-pg -O0 +-w
#RELEASE_FLAGS+=-pg -O3 -q -j4 ../../isaac.use
RELEASE_FLAGS+=-pg -O3 -vv -j4 ../../isaac.use

TESTER_LAIR=/home/amos/Dropbox/isaac/builds

WIN32_TOOLCHAIN=i686-w64-mingw32
OSX32_TOOLCHAIN=i686-apple-darwin11
MAX_GLIBC=2.17

VERSION=$(shell ./utils/version.sh)
ASSETS=assets

normal:
	rock -v ${DEBUG_FLAGS} --cc=clang

run: normal
	./isaac

rnu: run

rn: run

deploy: clean
	@echo "Building Paper Isaac v${VERSION}..."
	@$(MAKE) release-all -j4
	@$(MAKE) upload
	
release-all: linux-release win32-release osx32-release

# Builds

## Linux

LINUX32_CHROOT=/chroots/wheezy32
LINUX32_DEV=${LINUX32_CHROOT}/root/Dev

LINUX64_CHROOT=/chroots/wheezy64
LINUX64_DEV=${LINUX64_CHROOT}/root/Dev

rockmake:
	@echo "[BUILD] Preparing C files for chroot compilation..."
	@rock --driver=make

linux64: rockmake
	@echo "[BUILD] Linux 64-bit..."
	@mkdir -p stage/linux64
	@sudo rm -rf ${LINUX64_DEV}/isaac-build
	@sudo cp -rf build ${LINUX64_DEV}/isaac-build
	@./utils/linux/chroot-build.sh ${LINUX64_CHROOT}
	@cp -rf ${LINUX64_DEV}/isaac-build/isaac stage/linux64/isaac-linux64
	@mkdir -p stage/linux64/libs
	@./utils/linux/copy-libs.sh ${LINUX64_CHROOT} /root/Dev/isaac-build/isaac stage/linux64/libs

linux32: rockmake
	@echo "[BUILD] Linux 32-bit..."
	@mkdir -p stage/linux32
	@sudo rm -rf ${LINUX32_DEV}/isaac-build
	@sudo cp -rf build ${LINUX32_DEV}/isaac-build
	@./utils/linux/chroot-build.sh ${LINUX32_CHROOT}
	@cp -rf ${LINUX32_DEV}/isaac-build/isaac stage/linux32/isaac-linux32
	@mkdir -p stage/linux32/libs
	@./utils/linux/copy-libs.sh ${LINUX32_CHROOT} /root/Dev/isaac-build/isaac stage/linux32/libs

## Windows

win32: isaac.res
	@echo "[BUILD] Windows 32-bit..."
	@mkdir -p stage/win32
	@cp -f isaac.res stage/win32
	@cd stage/win32 && \
	  PKG_CONFIG_PATH=/usr/${WIN32_TOOLCHAIN}/lib/pkgconfig \
	  PATH=/usr/${WIN32_TOOLCHAIN}/bin:${PATH} \
	  rock ${RELEASE_FLAGS} --host=${WIN32_TOOLCHAIN} +-static-libgcc -o=isaac-win32.exe
	@rm stage/win32/isaac.res

isaac.res:
	@echo "[BUILD] Windows resources..."
	@${WIN32_TOOLCHAIN}-windres -i isaac.rc -o isaac.res -O coff

## Mac

osx32:
	@echo "[BUILD] OSX 32-bit..."
	@mkdir -p stage/osx32
	@cd stage/osx32 && \
	  PKG_CONFIG_PATH=/usr/${OSX32_TOOLCHAIN}/usr/lib/pkgconfig/ \
	  PATH=/usr/${OSX32_TOOLCHAIN}/usr/bin/:/usr/${OSX32_TOOLCHAIN}/bin:${PATH} \
	  rock ${RELEASE_FLAGS} --host=${OSX32_TOOLCHAIN} --gc=dynamic -o=isaac-osx32 --bannedflag=-fno-pie

# Releases

## Linux

LINUX_NAME="isaac-$(VERSION)-linux"
LINUX_STAGE="stage/$(LINUX_NAME)"
LINUX_ARCHIVE="builds/$(VERSION)/$(LINUX_NAME).tar.gz"
LINUX_DEST="builds/$(VERSION)/$(LINUX_NAME)"

linux-release: linux32 linux64
	$(MAKE) linux-package

linux-package:
	@echo "[PACKAGE] Linux..."
	@rm -rf $(LINUX_STAGE)
	@mkdir -p $(LINUX_STAGE)
	@mkdir -p $(LINUX_STAGE)/binaries
	@cp -f stage/linux32/isaac-linux32 stage/linux64/isaac-linux64 \
	  $(LINUX_STAGE)/binaries
	#@strip $(LINUX_STAGE)/binaries/*
	@mkdir -p $(LINUX_STAGE)/libs/32
	@mkdir -p $(LINUX_STAGE)/libs/64
	@cp -rf stage/linux32/libs/* $(LINUX_STAGE)/libs/32
	@cp -rf stage/linux64/libs/* $(LINUX_STAGE)/libs/64
	LD_LIBRARY_PATH=$(LINUX_STAGE)/libs/32 \
	  utils/linux/check-glibc.sh stage/linux32/isaac-linux32 || exit 32
	LD_LIBRARY_PATH=$(LINUX_STAGE)/libs/64 \
	  utils/linux/check-glibc.sh stage/linux64/isaac-linux64 || exit 64
	#@strip $(LINUX_STAGE)/libs/32/* $(LINUX_STAGE)/libs/64/*
	@cp -rf $(ASSETS) $(LINUX_STAGE)/
	@cp -rf skeletons/linux/isaac.sh $(LINUX_STAGE)
	@chmod +x $(LINUX_STAGE)/isaac.sh
	@mkdir -p builds/$(VERSION)
	@test -f $(TESTER_LAIR) || (mkdir -p $(TESTER_LAIR)/isaac-linux; cp -rf $(LINUX_STAGE)/* $(TESTER_LAIR)/isaac-linux)
	@mkdir -p $(LINUX_DEST)
	@cp -rf $(LINUX_STAGE)/* $(LINUX_DEST)/
	@rm -rf $(LINUX_STAGE)
	@echo "Linux build done!"

## Windows

WIN32_LIBS="SDL2 SDL2_mixer glew32 libogg-0 libvorbis-0 libvorbisfile-3 libpng16-16 libwinpthread-1 libgcc_s_sjlj-1"
WIN32_NAME="isaac-$(VERSION)-win32"
WIN32_STAGE="stage/$(WIN32_NAME)"
WIN32_DEST="builds/$(VERSION)/$(WIN32_NAME)"

win32-release: win32
	$(MAKE) win32-package

win32-package:
	@echo "[PACKAGE] Windows 32-bit..."
	@rm -rf $(WIN32_STAGE)
	@mkdir -p $(WIN32_STAGE)
	@cp -rf $(ASSETS) $(WIN32_STAGE)
	@cp -f stage/win32/isaac-win32.exe $(WIN32_STAGE)
	@./utils/win/copy-libs.sh $(WIN32_STAGE) $(WIN32_TOOLCHAIN) $(WIN32_LIBS)
	#@$(WIN32_TOOLCHAIN)-strip $(WIN32_STAGE)/game/*.dll $(WIN32_STAGE)/game/*.exe
	@cp -rf skeletons/win32/*.dll $(WIN32_STAGE)
	@mkdir -p builds/$(VERSION)
	@test -f $(TESTER_LAIR) || (mkdir -p $(TESTER_LAIR)/isaac-win32; cp -rf $(WIN32_STAGE)/* $(TESTER_LAIR)/isaac-win32)
	@rm -rf $(WIN32_DEST)
	@mkdir -p $(WIN32_DEST)
	@cp -rf $(WIN32_STAGE)/* $(WIN32_DEST)/
	@rm -rf $(WIN32_STAGE)
	@echo "Windows build done!"

## Mac

OSX32_LIBS="libGLEW libSDL2-2 libSDL2_mixer-2 libfreetype libmxml libpng16 libogg libvorbis libvorbisfile libchipmunk"
OSX32_NAME="isaac-$(VERSION)-osx32.app"
OSX32_STAGE="stage/$(OSX32_NAME)"
OSX32_FINAL_NAME="PaperIsaac.app"
OSX32_DEST="builds/$(VERSION)/$(OSX32_NAME)"

osx32-release: osx32
	$(MAKE) osx32-package

osx32-package:
	@echo "[PACKAGE] OSX 32-bit..."
	@rm -rf $(OSX32_STAGE)
	@mkdir -p $(OSX32_STAGE)
	@mkdir -p $(OSX32_STAGE)/Contents/MacOS
	@cp -f ./skeletons/osx32/Info.pList $(OSX32_STAGE)/Contents/
	@cp -f ./skeletons/osx32/isaac.sh $(OSX32_STAGE)/Contents/MacOS/
	@chmod +x $(OSX32_STAGE)/Contents/MacOS/isaac.sh
	@cp -rf $(ASSETS) $(OSX32_STAGE)/Contents/MacOS/
	@cp -f stage/osx32/isaac-osx32 $(OSX32_STAGE)/Contents/MacOS/
	#@/usr/$(OSX32_TOOLCHAIN)/bin/$(OSX32_TOOLCHAIN)-strip $(OSX32_STAGE)/Contents/MacOS/isaac-osx32
	@mkdir -p $(OSX32_STAGE)/Contents/Resources
	@cp -f art/isaac.icns $(OSX32_STAGE)/Contents/Resources
	@mkdir -p $(OSX32_STAGE)/Contents/MacOS/libs
	@./utils/osx/copy-libs.sh $(OSX32_STAGE)/Contents/MacOS/libs/ /usr/$(OSX32_TOOLCHAIN)/usr $(OSX32_LIBS)
	@test -f $(TESTER_LAIR) || (mkdir -p $(TESTER_LAIR)/isaac-osx32.app; cp -rf $(OSX32_STAGE)/* $(TESTER_LAIR)/isaac-osx32.app)
	@cp -rf $(OSX32_STAGE)/* $(OSX32_DEST)/
	#@rm -rf $(OSX32_STAGE)
	@echo "OSX build done!"

# Cleanup

OBJS = isaac isaac.res isaac.dSYM stage

clean:
	rm -rf $(OBJS) .libs rock_tmp

.PHONY: clean normal
