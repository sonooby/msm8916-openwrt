# SPDX-License-Identifier: GPL-2.0-only

ifeq ($(SUBTARGET),msm8916)

define Build/generate-squashfs-gpt
	chmod +x $(TOPDIR)/target/linux/$(BOARD)/image/generate_squashfs_gpt.sh
	$(TOPDIR)/target/linux/$(BOARD)/image/generate_squashfs_gpt.sh $@
endef

define Build/install-flasher
	$(CP) $(TOPDIR)/target/linux/$(BOARD)/image/flash.sh $@
	chmod +x $@
endef

define Build/generate-firmware
	chmod +x $(TOPDIR)/target/linux/$(BOARD)/image/generate_firmware.sh
	TOPDIR="$(TOPDIR)" \
	$(TOPDIR)/target/linux/$(BOARD)/image/generate_firmware.sh $@
endef

define Device/msm8916
	SOC := msm8916
	CMDLINE := "earlycon console=tty0 console=ttyMSM0,115200 root=/dev/mmcblk0p14 rootfstype=squashfs rootwait"
	FEATURES := squashfs
	IMAGE/system.img := append-rootfs | append-metadata
	ARTIFACTS := squashfs-gpt_both0.bin flash.sh firmware.zip
	ARTIFACT/squashfs-gpt_both0.bin := generate-squashfs-gpt
	ARTIFACT/flash.sh := install-flasher
	ARTIFACT/firmware.zip := generate-firmware
endef

define Device/yiming-uz801v3
	$(Device/msm8916)
	DEVICE_VENDOR := YiMing
	DEVICE_MODEL := uz801v3
	SUPPORTED_DEVICES := yiming,uz801-v3
	FILESYSTEMS := squashfs
	DEVICE_PACKAGES := wpad-basic-wolfssl rmtfs uci-usb-gadget \
		block-mount f2fs-tools tar \
		msm-firmware-dumper reboot-edl qcom-carrier-autocfg
endef
TARGET_DEVICES += yiming-uz801v3

define Device/generic-uf02
	$(Device/msm8916)
	DEVICE_VENDOR := Generic
	DEVICE_MODEL := UF02 (250605 V0S)
	SUPPORTED_DEVICES := uf02,250605v0s
	FILESYSTEMS := squashfs
	DEVICE_PACKAGES := wpad-basic-wolfssl rmtfs uci-usb-gadget \
		block-mount f2fs-tools tar \
		msm-firmware-dumper reboot-edl qcom-carrier-autocfg
endef
TARGET_DEVICES += generic-uf02

define Device/generic-ufi001b
	$(Device/msm8916)
	DEVICE_VENDOR := Generic
	DEVICE_MODEL := UFI001B
	DEVICE_DTS := msm8916-generic-ufi001b
	SUPPORTED_DEVICES := ufi001b,250605v0s
	FILESYSTEMS := squashfs
	DEVICE_PACKAGES := wpad-basic-wolfssl rmtfs uci-usb-gadget \
		block-mount f2fs-tools tar \
		msm-firmware-dumper reboot-edl qcom-carrier-autocfg
endef
TARGET_DEVICES += generic-ufi001b

define Device/generic-hmu05
	$(Device/msm8916)
	DEVICE_VENDOR := Generic
	DEVICE_MODEL := HMU05
	DEVICE_DTS := msm8916-generic-hmu05
	SUPPORTED_DEVICES := hmu05,250605v0s
	FILESYSTEMS := squashfs
	DEVICE_PACKAGES := wpad-basic-wolfssl rmtfs uci-usb-gadget \
		block-mount f2fs-tools tar \
		msm-firmware-dumper reboot-edl qcom-carrier-autocfg qcom-time-daemon
endef
TARGET_DEVICES += generic-hmu05

define Device/thwc-uf896
	$(Device/msm8916)
	DEVICE_VENDOR := THWC
	DEVICE_MODEL := UF896
	DEVICE_DTS := msm8916-thwc-uf896
	SUPPORTED_DEVICES := thwc,uf896
	FILESYSTEMS := squashfs
	DEVICE_PACKAGES := wpad-basic-wolfssl rmtfs uci-usb-gadget \
		block-mount f2fs-tools tar \
		msm-firmware-dumper reboot-edl qcom-carrier-autocfg

	# Produce a RAM-only initramfs Android boot image for the first hardware
	# test. It intentionally has no root=/dev/mmcblk... argument, so it can be
	# started with `fastboot boot` while the working Debian eMMC stays intact.
	KERNEL_INITRAMFS = kernel-bin | gzip | append-dtb | aboot-img-initramfs
	KERNEL_INITRAMFS_SUFFIX := -boot.img

	# Do not publish the generic MSM8916 firmware bundle/flasher for UF896.
	# generate_firmware.sh currently builds lk2nd for yiming,uz801-v3, which is
	# not an acceptable UF896 bootloader payload. Keep only the GPT artifact for
	# offline inspection; it is not used for the RAM-only test.
	ARTIFACTS := squashfs-gpt_both0.bin
	ARTIFACT/squashfs-gpt_both0.bin := generate-squashfs-gpt
endef
TARGET_DEVICES += thwc-uf896

endif
