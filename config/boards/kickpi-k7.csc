# Rockchip RK3576 octa core
BOARD_NAME="KICKPI K7"
BOARDFAMILY="rk35xx"
BOOTCONFIG="kickpi-k7-rk3576_defconfig"
BOOT_LOGO="desktop"
BOOT_FDT_FILE="rockchip/rk3576-kickpi-k7.dtb"
BOOT_SCENARIO="spl-blobs"
LINUXCONFIG='linux-rk3576-kickpi'
KERNEL_TARGET="vendor"
FULL_DESKTOP="yes"
IMAGE_PARTITION_TABLE="gpt"
BOARD_MAINTAINER=""
PACKAGE_LIST_BOARD="vim rfkill bluetooth bluez bluez-tools alsa-ucm-conf cloud-guest-utils busybox net-tools"
DDR_BLOB="rk35/rk3576_ddr_lp4_1560MHz_lp5_2736MHz_v1.08.bin"

function post_family_tweaks__kickpi-k7_naming_audios() {
	display_alert "$BOARD" "Renaming kickpi-k7 audios" "info"

	mkdir -p $SDCARD/etc/udev/rules.d/
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmi0-sound", ENV{SOUND_DESCRIPTION}="HDMI0 Audio"' > $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-dp0-sound", ENV{SOUND_DESCRIPTION}="DP0 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-es8388-sound", ENV{SOUND_DESCRIPTION}="ES8388 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules

	return 0
}

function post_family_tweaks__kickpi_k7() {
	display_alert "$BOARD" "start kickpi config" "info"
    
    cp -frv $SRC/packages/bsp/kickpi/bin/* $SDCARD/usr/bin/
    
    cp -v $SRC/packages/bsp/kickpi/kickpi-hardware.service $SDCARD/etc/systemd/system/kickpi-hardware.service

    mkdir -p $SDCARD/lib/firmware/rtl_bt/
	cp -v $SRC/packages/bsp/kickpi/rtl_bt/* $SDCARD/lib/firmware/rtl_bt/

    mkdir -p $SDCARD/etc/init.d/
    cp -v $SRC/packages/bsp/kickpi/kickpi.sh $SDCARD/etc/init.d/kickpi.sh

    cp -frv $SRC/packages/bsp/kickpi/usr/* $SDCARD/usr/
    cp -frv $SRC/packages/bsp/kickpi/etc/* $SDCARD/etc/

	chroot_sdcard systemctl enable kickpi-hardware.service

	return 0
}

function post_family_tweaks__preset_configs() {
	display_alert "$BOARD" "preset configs for rootfs" "info"

	# Preset user default shell, you can choose bash or  zsh
	echo "PRESET_USER_SHELL=bash" >> "${SDCARD}"/root/.not_logged_in_yet

	# Set PRESET_CONNECT_WIRELESS=y if you want to connect wifi manually at first login
	echo "PRESET_CONNECT_WIRELESS=n" >> "${SDCARD}"/root/.not_logged_in_yet

	# Set SET_LANG_BASED_ON_LOCATION=n if you want to choose "Set user language based on your location?" with "n" at first login
	echo "SET_LANG_BASED_ON_LOCATION=n" >> "${SDCARD}"/root/.not_logged_in_yet

	# Preset default locale
	echo "PRESET_LOCALE=en_US.UTF-8" >> "${SDCARD}"/root/.not_logged_in_yet

	# Preset timezone
	echo "PRESET_TIMEZONE=Etc/UTC" >> "${SDCARD}"/root/.not_logged_in_yet

	# Preset root password
	echo "PRESET_ROOT_PASSWORD=root" >> "${SDCARD}"/root/.not_logged_in_yet

	# Preset username
	echo "PRESET_USER_NAME=kickpi" >> "${SDCARD}"/root/.not_logged_in_yet

	# Preset user password
	echo "PRESET_USER_PASSWORD=kickpi" >> "${SDCARD}"/root/.not_logged_in_yet

	# Preset user default realname
	echo "PRESET_DEFAULT_REALNAME=kickpi" >> "${SDCARD}"/root/.not_logged_in_yet
}
