# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

DESCRIPTION="NVIDIA Tegra3 X.org codecs"

HOMEPAGE="https://developer.nvidia.com/linux-tegra"
SRC_URI="http://developer.download.nvidia.com/mobile/tegra/l4t/r16.5.0/cardhu_release_armhf/Tegra30_Linux-codecs_R16.5_armhf.tbz2"


LICENSE="nvidia"
SLOT="0"
KEYWORDS="~arm"

IUSE=""
#DEPEND="=sys-libs/tegra-libs-${PV}"
DEPEND=""
RDEPEND="${DEPEND}"

S="${WORKDIR}"
RESTRICT="strip mirror"

src_unpack() {
	unpack ${A}
	unpack ./restricted_codecs.tbz2
}

src_install() {
	insinto /
	doins -r lib
}
