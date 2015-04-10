# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit eutils

DESCRIPTION="NVIDIA Tegra3 X.org driver"
HOMEPAGE="https://developer.nvidia.com/linux-tegra"
SRC_URI="http://developer.download.nvidia.com/mobile/tegra/l4t/r16.5.0/cardhu_release_armhf/Tegra30_Linux_R16.5_armhf.tbz2"


LICENSE="nvidia"
SLOT="0"
KEYWORDS="arm ~arm"
IUSE="+X"

DEPEND="=media-libs/tegra3-codecs-${PV}
        X? (
           <x11-base/xorg-server-1.15.2-r1
           <x11-drivers/xf86-input-synaptics-1.8.0
           <app-eselect/eselect-opengl-1.3.1-r2
           <media-libs/mesa-10.3.7-r2
           <x11-proto/glproto-1.4.17-r1
           <x11-base/xorg-drivers-1.17
        )
        >=media-libs/libjpeg-turbo-1.2.1"

RDEPEND="${DEPEND}"

S="${WORKDIR}/Linux_for_Tegra/nv_tegra/"


RESTRICT="bindist strip mirror"

# Install nvidia library:
# the first parameter is the library to install
# the second parameter is the provided soversion
# the third parameter is the target directory if its not /usr/lib
donvidia() {
	# Full path to library minus SOVER
	MY_LIB="$1"

	# SOVER to use
	MY_SOVER="$2"

	# Where to install
	MY_DEST="$3"

	if [[ -z "${MY_DEST}" ]]; then
		MY_DEST="/usr/$(get_libdir)"
		action="dolib.so"
	else
		exeinto ${MY_DEST}
		action="doexe"
	fi

	# Get just the library name
	libname=$(basename $1)

	# Install the library with the correct SOVER
	${action} ${MY_LIB}.${MY_SOVER} || \
		die "failed to install ${libname}"

	# If SOVER wasn't 1, then we need to create a .1 symlink
	if [[ "${MY_SOVER}" != "1" ]]; then
		dosym ${libname}.${MY_SOVER} \
			${MY_DEST}/${libname}.1 || \
			die "failed to create ${libname} symlink"
	fi

	# Always create the symlink from the raw lib to the .1
	dosym ${libname}.1 \
		${MY_DEST}/${libname} || \
		die "failed to create ${libname} symlink"
}

pkg_setup() {
	NV_LIB="${S}/usr/lib"
	NV_X11="${NV_LIB}/xorg/modules/drivers"
	NV_SOVER=1
}

src_unpack() {

	# since we have multiple package, unpack it one by one
	IFS=' ' read -ra F <<< "$A"
	for i in "${F[@]}"; do
		unpack "${i}"
	done

	cd "${S}"
	unpack ./nvidia_drivers.tbz2


	# create dummy file .gles-only, this file is used to let eselect-opengl
	# know we only have gles libs
	cd "${S}/usr/lib"
	touch .gles-only

	# remove libjpeg.so since it will let some package build
	# failed and conflict with libjpeg-turbo
	rm libjpeg.so
}

src_install() {
	local inslibdir=$(get_libdir)
	local GL_ROOT="/usr/$(get_libdir)/opengl/tegra3/lib"
	local libdir=${NV_LIB}

	if use X; then
		# The GLES libraries
		donvidia ${libdir}/libEGL.so ${NV_SOVER} ${GL_ROOT}
		donvidia ${libdir}/libGLESv1_CM.so ${NV_SOVER} ${GL_ROOT}
		donvidia ${libdir}/libGLESv2.so 2 ${GL_ROOT}

		# Since we only have gles lib, we need to add .gles-only
		# to make eselect-opengl work properly
		#touch /usr/$(get_libdir)/opengl/tegra3/.gles-only
		insinto /usr/$(get_libdir)/opengl/tegra3
		doins ${libdir}/.gles-only

		# Install Xorg DDX driver
		insinto /usr/$(get_libdir)/xorg/modules/drivers
		doins -r ${NV_X11} || die "failed to install tegra_drv.so"
	fi

	# Install firmwares, tegra version info
	insinto /
	doins -r lib etc

	# Install other libs
	cd ${libdir}
	for i in *.so; do
		dolib.so $i
	done

	# Install udev rules
	insinto /etc/udev/reules.d
	doins "${FILESDIR}/99-tegra-devices.rules" || die "failed to install 99-tegra-devices.rules"

	# Install enctune
	insinto /etc
	doins "${FILESDIR}/enctune.conf" || die "failed to install enctune.conf"

	# Install xorg.conf
	insinto /etc/X11
	doins "${FILESDIR}/xorg.conf" || die "failed to install xorg.conf"

	# Install 01-nvidia-tegra-drivers.start
	insinto /etc/local.d
	doins "${FILESDIR}/01-nvidia-tegra-drivers.start" || die "failed to install 01-nvidia-tegra-drivers.start"
}

pkg_preinst() {
		# Clean the dynamic libGLES stuff's home to ensure
	    # we dont have stale libs floating around
	    if [ -d "${ROOT}"/usr/lib/opengl/tegra3 ] ; then
			rm -rf "${ROOT}"/usr/lib/opengl/tegra3/*
	    fi
}

pkg_postinst() {

	# Switch to the tegra3 implementation
	use X && "${ROOT}"/usr/bin/eselect opengl set --use-old tegra3

	elog "You must be in the video group to use the NVIDIA Tegra3 device"
	elog "For more info, read the docs at"
	elog "http://www.gentoo.org/doc/en/nvidia-guide.xml#doc_chap3_sect6"
	elog
        elog "Plase cd to /usr/lib/xorg/modules/drivers and execute:"
        elog "ln -s tegra_drv.(XABIVERSION).so tegra_drv.so"
        elog "If you are unsure what is your XABI Version please refer to the output of startx"
	elog "To use the NVIDIA Tegra3 GLX, run \"eselect opengl set tegra3\""
	elog
	if ! use X; then
		elog "You have elected to not install the X.org driver. Along with"
		elog "this the OpenGLES libraries were not installed."
		elog
	fi
}

pkg_prerm() {
	use X && "${ROOT}"/usr/bin/eselect opengl set --use-old xorg-x11
}

pkg_postrm() {
	use X && "${ROOT}"/usr/bin/eselect opengl set --use-old xorg-x11
}
