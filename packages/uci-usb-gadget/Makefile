# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=uci-usb-gadget
PKG_VERSION:=1.0.0
PKG_RELEASE:=2

PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Miguel Fuertes <hkfuertes@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	base64 -d ./files/UF896_TOOLS.iso.gz.b64 | gzip -dc > $(PKG_BUILD_DIR)/UF896_TOOLS.iso
	echo "18ff19b550161bdafe3d1cb279eda983a7be00dc63fe5ebe6249098ef6384e0e  $(PKG_BUILD_DIR)/UF896_TOOLS.iso" | sha256sum -c -
endef

define Build/Compile
endef

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=UCI-based USB gadget manager
	DEPENDS:=@USB_GADGET_SUPPORT \
		+kmod-fs-configfs \
		+kmod-usb-gadget \
		+kmod-usb-lib-composite \
		+kmod-usb-gadget-serial \
		+kmod-usb-gadget-mass-storage \
		+kmod-usb-gadget-ncm \
		+kmod-usb-gadget-rndis \
		+coreutils-truncate \
		+coreutils-shuf \
		+coreutils-dd
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	UCI-based USB gadget manager using the kernel configfs interface.

	Configures OpenWrt devices as USB peripherals (RNDIS, ECM, NCM, ACM,
	Mass Storage) when connected to a host. Hardware-agnostic: auto-detects
	the UDC controller and integrates USB ethernet interfaces into the LAN bridge.
	On THWC UF896, an additional ZeroCD layer exposes a read-only tools CD in
	normal NCM mode and switches to a legacy RNDIS-first profile when the host
	ejects that CD.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/usbgadget
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usb-gadget.sh $(1)/usr/sbin/usb-gadget
	$(INSTALL_BIN) ./files/uf896-usb-mode $(1)/usr/sbin/uf896-usb-mode
	$(INSTALL_BIN) ./files/uf896-zerocd $(1)/usr/sbin/uf896-zerocd
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/usb-gadget.init $(1)/etc/init.d/usb-gadget
	$(INSTALL_BIN) ./files/usb-zerocd.init $(1)/etc/init.d/usb-zerocd
	$(INSTALL_DIR) $(1)/etc/rc.d
	$(LN) ../init.d/usb-gadget $(1)/etc/rc.d/S99usb-gadget
	$(LN) ../init.d/usb-zerocd $(1)/etc/rc.d/S99usb-zerocd
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/usbgadget.config $(1)/etc/config/usbgadget
	$(INSTALL_DIR) $(1)/usr/share/usb-gadget
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/UF896_TOOLS.iso $(1)/usr/share/usb-gadget/UF896_TOOLS.iso
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/usb-gadget enable
	/etc/init.d/usb-zerocd enable
}
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/usb-zerocd stop 2>/dev/null || true
	/etc/init.d/usb-zerocd disable 2>/dev/null || true
	/etc/init.d/usb-gadget stop
	/etc/init.d/usb-gadget disable
}
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
