# OpenWrt для 4G-модемов на Qualcomm Snapdragon 410 (MSM8916)

[Русская версия](#русская-версия) · [English version](#english-version)

<a id="русская-версия"></a>

## 🇷🇺 Русская версия

[![OpenWrt Version](https://img.shields.io/badge/OpenWrt-25.12.5-blue.svg)](https://openwrt.org/)
[![Kernel](https://img.shields.io/badge/Linux_Kernel-6.12-green.svg)](https://kernel.org/)
[![Architecture](https://img.shields.io/badge/Arch-aarch64-orange.svg)](https://en.wikipedia.org/wiki/AArch64)
[![License](https://img.shields.io/badge/License-GPL--2.0-lightgrey.svg)](LICENSE)

Это форк OpenWrt для USB-модемов, донглов и карманных маршрутизаторов на Qualcomm Snapdragon 410 / MSM8916 (и близких MSM8939), с основной текущей разработкой и аппаратным тестированием на **THWC UF896**.

### 🎯 Для какого оборудования сделаны текущие доработки

Основная активная ветка этого форка — [`thwc-uf896-openwrt-25.12`](https://github.com/sonooby/msm8916-openwrt/tree/thwc-uf896-openwrt-25.12). Все новые USB-функции, описанные ниже, разрабатывались и проверялись на реальном устройстве:

- **Модель:** THWC UF896 4G Modem Stick
- **Board ID:** `thwc,uf896`
- **Профиль OpenWrt:** `thwc-uf896`
- **SoC:** Qualcomm MSM8916 / Snapdragon 410, ARM64
- **ОЗУ тестового устройства:** 512 МБ
- **Основной LAN через USB:** `192.168.8.1/24`
- **OpenWrt:** 25.12.5
- **Ядро:** Linux 6.12

> [!IMPORTANT]
> **ZeroCD, автоматическое переключение NCM → RNDIS, стабильный USB serial и Windows-совместимость проверены именно на THWC UF896.** В репозитории остаются профили HMU05, UFI001B, UZ801 и UF02, но текущая ветка ориентирована прежде всего на UF896 и изменения на остальных платах не проходили такой же полный регрессионный цикл.

Проект использует современное ядро Linux 6.12, ModemManager, Qualcomm WCN36xx Wi-Fi, USB ConfigFS, постоянный EXT4 overlay на eMMC и программные пути восстановления через EDL/Fastboot.

---

## 🚀 Основные возможности

- **⚡ USB-сеть без ручной установки драйверов на современных Windows:** CDC NCM подключается к `br-lan`, устройство доступно по `192.168.8.1`, DHCP работает на модеме.
- **🪟 Автопривязка Microsoft UsbNcm:** для UF896 добавлен Microsoft OS descriptor `WINNCM`, поэтому Windows 10/11 автоматически использует штатный `UsbNcm Host Device` без ручного выбора INF через «Диспетчер устройств».
- **💿 ZeroCD как у классических USB-модемов:** UF896 экспортирует read-only CD-ROM `UF896_TOOLS` вместе с NCM и ACM.
- **🔁 Legacy RNDIS по команде Eject:** если в Windows нажать **«Извлечь»** для `UF896_TOOLS`, модем автоматически перестраивает USB gadget и переходит в профиль **RNDIS + ACM + CD-ROM**. RNDIS создаётся первым интерфейсом, что необходимо для корректного запуска штатного драйвера Windows.
- **↩️ Возврат в обычный режим:** команда `uf896-usb-mode normal` возвращает **NCM + ACM + CD-ROM**. После обычной перезагрузки UF896 всегда стартует в NORMAL/NCM.
- **🆔 Стабильный USB serial:** серийный номер формируется детерминированно из eMMC CID. Windows больше не создаёт новые экземпляры сетевого адаптера и COM-порта после каждого перезапуска USB gadget.
- **🔗 Стабильные MAC-адреса:** MAC для NCM/RNDIS генерируются детерминированно из стабильного серийного номера устройства.
- **📟 USB Serial Console:** CDC ACM предоставляет консоль `/dev/ttyGS0`; на Windows появляется стабильный COM-порт.
- **📶 Wi-Fi при первом запуске:** WCN36xx поднимается как точка доступа `OpenWrt` 2.4 ГГц на поддерживаемых платах.
- **🌐 4G LTE и ModemManager:** обнаружение SIM, APN и MBN-профилей операторов через `qcom-carrier-autocfg`.
- **💾 Постоянный eMMC overlay:** `rootfs_data` используется как EXT4 overlay с проверкой и безопасным восстановлением `e2fsck -p`.
- **💡 Аппаратные индикаторы:** поддержка LED для Wi-Fi, LTE/интернета и состояния подсистем на поддерживаемых платах.
- **🔄 Sysupgrade:** перед обновлением выполняется корректное завершение сервисов/подсистем для снижения риска kernel panic.
- **🛡️ HMU05 No-Sleep Fix:** отдельный аппаратно-ограниченный патч для HMU05 предотвращает известное зависание Hexagon DSP после перехода в сон.
- **🚑 Reboot to EDL:** `reboot-edl` переводит устройство в Qualcomm EDL (`05c6:9008`).
- **⚙️ Reboot to Fastboot:** `reboot-fastboot` переводит поддерживаемое устройство в Fastboot.

---

## 🔌 USB-режимы THWC UF896

### NORMAL — режим по умолчанию

После загрузки UF896 работает как составное USB-устройство:

```text
ACM + NCM + UF896_TOOLS CD-ROM
bcdDevice 0x0101
LAN 192.168.8.1/24
```

На Windows 10/11 ожидаются:

```text
UsbNcm Host Device
USB Serial / COM
UF896 TOOLS USB Device
```

CD-ROM содержит документацию/служебные файлы и доступен только для чтения.

### LEGACY — RNDIS для старых Windows

В Проводнике Windows выберите для `UF896_TOOLS` **«Извлечь»**. Watcher определяет извлечение носителя и автоматически выполняет:

```text
NORMAL: ACM + NCM + CD-ROM
            ↓ Eject
LEGACY: RNDIS + ACM + CD-ROM
```

В Legacy-профиле:

```text
RNDIS — первый USB interface
bcdDevice 0x0102
DHCP/Gateway/DNS: 192.168.8.1
```

После переключения CD-ROM снова вставляется автоматически. Проверенный результат на Windows — штатный `Remote NDIS Compatible Device`, DHCP-адрес `192.168.8.x` и рабочий доступ к `192.168.8.1`.

Вернуться в NCM можно из OpenWrt:

```bash
uf896-usb-mode normal
```

Состояние USB-режима и ZeroCD:

```bash
uf896-zerocd status
uf896-usb-mode status
```

После перезагрузки устройство всегда начинает работу в NORMAL/NCM.

---

## 📟 Поддерживаемые устройства

| Board target | Профиль | Модель | SoC | ОЗУ | Основные возможности |
| :-- | :-- | :-- | :-- | :-- | :-- |
| **`thwc,uf896`** | **`thwc-uf896`** | **THWC UF896 4G Modem Stick** | MSM8916 | 512 МБ (тестовое устройство) | **NCM/ACM, WINNCM, ZeroCD, Eject→RNDIS, стабильный serial/MAC, Wi-Fi, LTE** |
| `hmu05` | `generic-hmu05` | Generic HMU05 (250605 V0S) | MSM8916 | 512 МБ | NCM, ACM, Wi-Fi, LTE, No-Sleep Patch, Ramoops, EDL/Fastboot |
| `ufi001b` | `generic-ufi001b` | Generic UFI001B | MSM8916 | 512 МБ | NCM, ACM, Wi-Fi, LTE, EDL/Fastboot, Ramoops |
| `uz801` | `yiming-uz801v3` | YiMing UZ801 v3 | MSM8916 | 512 МБ | NCM, ACM, Wi-Fi, LTE, EDL/Fastboot, изменённая разводка LED |
| `uf02` | `generic-uf02` | Generic UF02 / UF2 | MSM8916 | 512 МБ | NCM, ACM, Wi-Fi, LTE, EDL/Fastboot |

> [!WARNING]
> Не прошивайте UF896 загрузчиком, `firmware.zip` или образом, предназначенным для HMU05/UFI001B/UZ801/UF02. Профиль `thwc-uf896` специально отделён от generic-профилей. В текущей ветке generic firmware bundle/flasher для UF896 намеренно не публикуется, чтобы исключить применение несовместимого bootloader payload.

---

## 🔄 Режимы восстановления

### Перезагрузка в EDL

Из SSH или USB-консоли:

```bash
reboot-edl
```

Хост должен увидеть:

```text
05c6:9008 Qualcomm HS-USB QDLoader 9008
```

Проверка в Linux:

```bash
lsusb | grep 05c6:9008
```

EDL позволяет выполнять низкоуровневое восстановление через `edl`/`qdl`.

### Перезагрузка в Fastboot

```bash
reboot-fastboot
```

Проверка:

```bash
fastboot devices
```

### Android / ADB → EDL

Если на исходной системе доступен ADB:

```bash
adb reboot edl
```

---

## ⚡ Прошивка

### 1. Вход в Qualcomm EDL (`05c6:9008`)

Возможные способы:

- аппаратные EDL test points при подключении USB;
- `adb reboot edl` из Android;
- `reboot-edl` из OpenWrt.

Проверка:

```bash
lsusb | grep 05c6:9008
```

### Сценарий A: первый переход со штатного Android на OpenWrt

> [!CAUTION]
> **Не записывайте вслепую отдельные boot/rootfs или загрузочные разделы от другой модели.** На заводской Android-разметке находятся уникальные данные радиотракта и калибровок: `fsc`, `fsg`, `modemst1`, `modemst2`, `modem`, `persist`, `sec`. Их потеря может привести к утрате IMEI, MAC, RF-калибровок или полной неработоспособности модема.

Для generic-профилей, где сборка создаёт штатный `*-flash.sh`, используется сгенерированный скрипт из `openwrt/bin/targets/msm89xx/msm8916/`:

```bash
cd openwrt/bin/targets/msm89xx/msm8916/
chmod +x openwrt-msm89xx-msm8916-<board>-flash.sh
./openwrt-msm89xx-msm8916-<board>-flash.sh
```

Он выполняет резервное копирование критичных разделов, перестройку GPT, запись firmware/boot/rootfs, восстановление калибровок и перезагрузку.

> [!IMPORTANT]
> **Для THWC UF896 этот generic-сценарий не применяется автоматически.** Профиль `thwc-uf896` намеренно не публикует generic `firmware.zip`/`flash.sh`, потому что bootloader payload от других MSM8916-плат не считается безопасным для UF896. Используйте только UF896-специфичный, проверенный порядок установки и образы из ветки/релиза, предназначенные именно для `thwc-uf896`.

### Сценарий B: обновление уже установленного OpenWrt

Предпочтительный путь — штатный `sysupgrade`, сохраняющий конфигурацию и overlay.

При чистом восстановлении уже подготовленного устройства через EDL допускается запись только тех разделов, которые соответствуют конкретной плате и текущей GPT. Не переносите bootloader/NV-разделы между моделями.

---

## 🔧 Fastboot recovery

Если загрузчик конкретной платы поддерживает Fastboot:

```bash
reboot-fastboot
fastboot devices
```

Fastboot предназначен для загрузочных/восстановительных операций и не заменяет резервное копирование уникальных Qualcomm NV/калибровочных разделов.

---

## 🔄 Sysupgrade

`sysupgrade` сохраняет постоянный `rootfs_data` overlay. Перед обновлением платформенный код корректно завершает сервисы и подсистемы.

Проверка overlay:

```bash
mount | grep overlay
```

Ожидаемый вид:

```text
/dev/mmcblk0p15 on /overlay type ext4 (rw,noatime)
overlayfs:/overlay on / type overlay (...)
```

Перед `mount_root` выполняется проверка EXT:

```text
rootfs_data: ext filesystem detected
rootfs_data: running e2fsck -p
rootfs_data: filesystem errors repaired
mount_root: switching to ext4 overlay
```

Существующая EXT4 не форматируется только из-за найденных исправимых ошибок; новая файловая система создаётся только если подходящая EXT не обнаружена.

---

## 🔌 Доступ к устройству по умолчанию

| Сервис | Доступ | По умолчанию |
| :-- | :-- | :-- |
| **LuCI** | `http://192.168.8.1` | пароль root необходимо задать |
| **SSH** | `ssh root@192.168.8.1` | на чистой сборке пароль может быть пустым — **задайте `passwd`** |
| **USB Serial Console** | `/dev/ttyACM0` / COM | консоль root через ACM |
| **USB Ethernet (UF896 NORMAL)** | CDC NCM | `192.168.8.1/24`, DHCP |
| **USB Ethernet (UF896 LEGACY)** | RNDIS | `192.168.8.1/24`, DHCP |
| **UF896 Tools CD** | `UF896_TOOLS` | read-only CD-ROM |
| **Wi-Fi AP** | SSID `OpenWrt`, 2.4 ГГц | на чистой конфигурации может быть открыт |
| **EDL** | `reboot-edl` | Qualcomm USB `05c6:9008` |
| **Fastboot** | `reboot-fastboot` | `fastboot devices` |

> [!WARNING]
> После первого запуска обязательно задайте пароль root командой `passwd` и настройте защиту Wi-Fi перед эксплуатацией в недоверенной сети.

---

## 📶 SIM, автоподбор оператора и перезагрузка

После установки SIM `qcom-carrier-autocfg` определяет MCC-MNC/IMSI через ModemManager, выбирает APN и при необходимости Qualcomm Carrier MBN (`mcfg_sw.mbn`).

Если требуемый MBN отличается от установленного, система синхронизирует файловые системы и выполняет **однократную автоматическую перезагрузку**, чтобы Hexagon DSP загрузил новый профиль. Это ожидаемое поведение, а не bootloop.

После перезагрузки совпадающий MBN повторно не заменяется, поэтому дополнительных перезапусков не требуется; ModemManager создаёт LTE bearer с подходящим APN/IP-стеком.

При hot-swap SIM:

- тот же MBN/совместимое семейство — подключение обычно восстанавливается без reboot;
- другое MBN-семейство — возможна однократная перезагрузка для загрузки нового профиля.

Мониторинг:

```bash
logread -f -e carrier-autocfg
```

Пример первого определения оператора:

```text
[carrier-autocfg] Started MSM8916 SIM Carrier Auto-Provisioning Engine
[carrier-autocfg] Matched carrier in global APN database for MCC-MNC 405861
[carrier-autocfg] Deploying Carrier MBN 'generic/apac/reliance/commerci/mcfg_sw.mbn' into /lib/firmware/MCFG_SW.MBN...
[carrier-autocfg] Carrier MBN radio firmware updated for 'Reliance Jio'. Scheduling automatic reboot in 3 seconds to initialize Hexagon DSP...
```

После перезагрузки:

```text
[carrier-autocfg] Active Carrier MBN already matches generic/apac/reliance/commerci/mcfg_sw.mbn.
[carrier-autocfg] Boot-time carrier provisioning completed successfully. No reboot required.
[carrier-autocfg] Requesting ModemManager bearer connection for APN 'jionet' (ipv4v6)...
```

---

## 📂 Разметка eMMC

Разметка зависит от профиля/ёмкости eMMC; типовой OpenWrt layout содержит:

| Раздел | Метка | Тип | Назначение |
| :-- | :-- | :-- | :-- |
| `modem` | `modem` | VFAT/raw | Qualcomm modem/WCNSS firmware |
| `persist` | `persist` | EXT4 | заводские калибровки, Wi-Fi NVRAM |
| `boot` | `boot` | Raw | ядро Linux + DTB |
| `rootfs` | `system/rootfs` | SquashFS | read-only OpenWrt rootfs |
| `rootfs_data` | `rootfs_data` | EXT4 | постоянный writable overlay |

Номера и размеры разделов необходимо сверять с конкретной платой и её GPT; не переносите таблицу разделов между разными аппаратными вариантами без проверки.

---

## 📦 Репозиторий пакетов и драйверов

Проект использует APK feeds для OpenWrt 25.12.5. Landing page:

https://akbar-npj.github.io/msm8916-openwrt/

Пример подключения feed:

```bash
cat << 'EOF' > /etc/apk/repositories.d/customfeeds.list
https://akbar-npj.github.io/msm8916-openwrt/releases/25.12.5/targets/msm89xx/msm8916/packages/packages.adb
EOF

apk update
```

Примеры:

```bash
apk add kmod-usb-net-rtl8152
apk add luci-app-wireguard
```

---

## 📜 Лицензия

Проект распространяется по **GNU General Public License v2.0 (GPL-2.0)**. Компоненты Qualcomm firmware dumper используют BSD-3-Clause.

---

<a id="english-version"></a>

# 🇬🇧 English version — OpenWrt for Qualcomm Snapdragon 410 (MSM8916) 4G LTE USB Sticks & Modems

[![OpenWrt Version](https://img.shields.io/badge/OpenWrt-25.12.5-blue.svg)](https://openwrt.org/)
[![Kernel](https://img.shields.io/badge/Linux_Kernel-6.12-green.svg)](https://kernel.org/)
[![Architecture](https://img.shields.io/badge/Arch-aarch64-orange.svg)](https://en.wikipedia.org/wiki/AArch64)
[![License](https://img.shields.io/badge/License-GPL--2.0-lightgrey.svg)](LICENSE)

This fork provides OpenWrt for Qualcomm Snapdragon 410 / MSM8916 (and related MSM8939) USB modems, dongles and pocket routers. The current development focus and full hardware validation are on **THWC UF896**.

## 🎯 Hardware targeted by the current work

The active hardware branch is [`thwc-uf896-openwrt-25.12`](https://github.com/sonooby/msm8916-openwrt/tree/thwc-uf896-openwrt-25.12). The new USB functionality described below was developed and tested on a physical:

- **Model:** THWC UF896 4G Modem Stick
- **Board ID:** `thwc,uf896`
- **OpenWrt profile:** `thwc-uf896`
- **SoC:** Qualcomm MSM8916 / Snapdragon 410, ARM64
- **RAM on the tested unit:** 512 MB
- **USB LAN:** `192.168.8.1/24`
- **OpenWrt:** 25.12.5
- **Kernel:** Linux 6.12

> [!IMPORTANT]
> **ZeroCD, automatic NCM → RNDIS switching, stable USB serial handling and Windows compatibility have been fully tested on THWC UF896.** HMU05, UFI001B, UZ801 and UF02 profiles remain in the repository, but this branch is UF896-focused and those boards have not received the same regression testing for the new USB layer.

The project includes Linux 6.12, ModemManager, Qualcomm WCN36xx Wi-Fi, USB ConfigFS, persistent EXT4 eMMC overlay storage and software-triggered EDL/Fastboot recovery paths.

---

## 🚀 Key Features

- **⚡ Plug-and-Play USB Networking:** CDC NCM is attached to `br-lan` and served at `192.168.8.1/24` with DHCP.
- **🪟 Microsoft UsbNcm auto-binding:** UF896 exposes the Microsoft OS descriptor `WINNCM`, allowing Windows 10/11 to bind the inbox `UsbNcm Host Device` driver without manual INF selection.
- **💿 ZeroCD:** UF896 exposes a read-only `UF896_TOOLS` CD-ROM together with NCM and ACM, similar to classic USB cellular modems.
- **🔁 Eject-to-Legacy RNDIS:** choosing **Eject** for `UF896_TOOLS` in Windows automatically rebuilds the composite gadget as **RNDIS + ACM + CD-ROM**. RNDIS is intentionally the first USB function for Windows compatibility.
- **↩️ Return to normal:** `uf896-usb-mode normal` restores **NCM + ACM + CD-ROM**. A normal reboot always starts UF896 in NORMAL/NCM mode.
- **🆔 Stable USB serial:** the device serial is derived deterministically from the eMMC CID so Windows no longer creates a new network/COM instance after each gadget restart.
- **🔗 Stable MAC addresses:** NCM/RNDIS MAC addresses are deterministically derived from the stable device identity.
- **📟 USB Serial Console:** CDC ACM exposes `/dev/ttyGS0` and a stable host COM/ttyACM port.
- **📶 First-Boot Wi-Fi Auto-Start:** Qualcomm WCN36xx support provides an `OpenWrt` 2.4 GHz AP on supported boards.
- **🌐 4G LTE + ModemManager:** SIM/carrier detection, APN selection and Qualcomm Carrier MBN handling through `qcom-carrier-autocfg`.
- **💾 Persistent eMMC Storage:** EXT4 `rootfs_data` overlay with preinit checking and `e2fsck -p` repair.
- **💡 Hardware Status LEDs:** Wi-Fi/LTE/subsystem LED handling on supported boards.
- **🔄 Safer Sysupgrade:** graceful service/subsystem teardown before upgrade.
- **🛡️ HMU05 No-Sleep Fix:** hardware-gated Hexagon DSP sleep-stall workaround for HMU05.
- **🚑 Reboot to Qualcomm EDL:** `reboot-edl` enters USB `05c6:9008` recovery mode.
- **⚙️ Reboot to Fastboot:** `reboot-fastboot` enters Fastboot where supported.

---

## 🔌 THWC UF896 USB modes

### NORMAL — default mode

After boot, UF896 enumerates as:

```text
ACM + NCM + UF896_TOOLS CD-ROM
bcdDevice 0x0101
LAN 192.168.8.1/24
```

On Windows 10/11 the expected devices are:

```text
UsbNcm Host Device
USB Serial / COM
UF896 TOOLS USB Device
```

The tools CD is read-only.

### LEGACY — RNDIS for older Windows

In Windows Explorer choose **Eject** on `UF896_TOOLS`. The watcher detects media removal and automatically performs:

```text
NORMAL: ACM + NCM + CD-ROM
            ↓ Eject
LEGACY: RNDIS + ACM + CD-ROM
```

Legacy profile details:

```text
RNDIS is the first USB interface
bcdDevice 0x0102
DHCP/Gateway/DNS: 192.168.8.1
```

The tools CD is reinserted after the switch. The validated Windows result is the inbox `Remote NDIS Compatible Device`, a DHCP address in `192.168.8.x`, and working access to `192.168.8.1`.

Return to NCM:

```bash
uf896-usb-mode normal
```

Inspect state:

```bash
uf896-zerocd status
uf896-usb-mode status
```

After reboot the device always starts in NORMAL/NCM.

---

## 📟 Supported Devices

| Board target | Profile | Device | SoC | RAM | Main features |
| :-- | :-- | :-- | :-- | :-- | :-- |
| **`thwc,uf896`** | **`thwc-uf896`** | **THWC UF896 4G Modem Stick** | MSM8916 | 512 MB (tested unit) | **NCM/ACM, WINNCM, ZeroCD, Eject→RNDIS, stable serial/MAC, Wi-Fi, LTE** |
| `hmu05` | `generic-hmu05` | Generic HMU05 (250605 V0S) | MSM8916 | 512 MB | NCM, ACM, Wi-Fi, LTE, No-Sleep Patch, Ramoops, EDL/Fastboot |
| `ufi001b` | `generic-ufi001b` | Generic UFI001B | MSM8916 | 512 MB | NCM, ACM, Wi-Fi, LTE, EDL/Fastboot, Ramoops |
| `uz801` | `yiming-uz801v3` | YiMing UZ801 v3 | MSM8916 | 512 MB | NCM, ACM, Wi-Fi, LTE, EDL/Fastboot, swapped LED mapping |
| `uf02` | `generic-uf02` | Generic UF02 / UF2 | MSM8916 | 512 MB | NCM, ACM, Wi-Fi, LTE, EDL/Fastboot |

> [!WARNING]
> Do not flash UF896 with a bootloader, `firmware.zip`, or image intended for HMU05/UFI001B/UZ801/UF02. The `thwc-uf896` profile is deliberately separated from generic profiles. The current branch intentionally does not publish the generic firmware bundle/flasher for UF896 because bootloader payloads from other MSM8916 boards are not considered safe for it.

---

## 🔄 Recovery and Reboot Modes

### Reboot to EDL

From SSH or USB serial console:

```bash
reboot-edl
```

Expected host-side USB identity:

```text
05c6:9008 Qualcomm HS-USB QDLoader 9008
```

Linux check:

```bash
lsusb | grep 05c6:9008
```

EDL can be used with tools such as `edl` or `qdl` for low-level recovery.

### Reboot to Fastboot

```bash
reboot-fastboot
fastboot devices
```

### Android / ADB → EDL

```bash
adb reboot edl
```

---

## ⚡ Flashing Firmware

### 1. Enter Qualcomm EDL (`05c6:9008`)

Possible methods:

- hardware EDL test points while connecting USB;
- `adb reboot edl` from Android;
- `reboot-edl` from OpenWrt.

Verify:

```bash
lsusb | grep 05c6:9008
```

### Scenario A: first migration from stock Android to OpenWrt

> [!CAUTION]
> **Do not blindly write boot/rootfs or bootloader partitions from another board.** Factory Android layouts contain device-unique radio/calibration data including `fsc`, `fsg`, `modemst1`, `modemst2`, `modem`, `persist`, and `sec`. Losing them can destroy IMEI, MAC addresses, RF calibration, or modem functionality.

For generic profiles that produce the standard `*-flash.sh`, use the generated script from `openwrt/bin/targets/msm89xx/msm8916/`:

```bash
cd openwrt/bin/targets/msm89xx/msm8916/
chmod +x openwrt-msm89xx-msm8916-<board>-flash.sh
./openwrt-msm89xx-msm8916-<board>-flash.sh
```

The script backs up critical partitions, updates GPT, writes the board firmware/boot/rootfs, restores calibration data, and reboots.

> [!IMPORTANT]
> **THWC UF896 does not automatically use this generic path.** The `thwc-uf896` profile intentionally does not publish generic `firmware.zip`/`flash.sh`, because bootloader payloads from another MSM8916 board are not accepted as safe for UF896. Use only a UF896-specific validated installation procedure and artifacts explicitly built for `thwc-uf896`.

### Scenario B: updating an existing OpenWrt installation

The preferred path is standard `sysupgrade`, which preserves configuration and overlay storage.

For clean EDL recovery of an already prepared device, write only partitions that match the exact board and its current GPT. Never copy bootloader/NV partitions between board models.

---

## 🔧 Fastboot Recovery

If the board bootloader supports Fastboot:

```bash
reboot-fastboot
fastboot devices
```

Fastboot is a boot/recovery transport and does not replace backups of Qualcomm device-unique NV/calibration partitions.

---

## 🔄 Sysupgrade

The OpenWrt sysupgrade path preserves persistent `rootfs_data`. Platform code tears down services/subsystems before upgrading.

Verify overlay:

```bash
mount | grep overlay
```

Expected form:

```text
/dev/mmcblk0p15 on /overlay type ext4 (rw,noatime)
overlayfs:/overlay on / type overlay (...)
```

Preinit filesystem checking runs before `mount_root`:

```text
rootfs_data: ext filesystem detected
rootfs_data: running e2fsck -p
rootfs_data: filesystem errors repaired
mount_root: switching to ext4 overlay
```

An existing EXT filesystem is not reformatted simply because repairable errors are found; a new filesystem is created only when no suitable EXT filesystem exists.

---

## 🔌 Default Device Access

| Service | Access | Default |
| :-- | :-- | :-- |
| **LuCI** | `http://192.168.8.1` | set a root password |
| **SSH** | `ssh root@192.168.8.1` | a clean image may initially have no password — **run `passwd`** |
| **USB Serial Console** | `/dev/ttyACM0` / COM | root console via ACM |
| **USB Ethernet (UF896 NORMAL)** | CDC NCM | `192.168.8.1/24`, DHCP |
| **USB Ethernet (UF896 LEGACY)** | RNDIS | `192.168.8.1/24`, DHCP |
| **UF896 Tools CD** | `UF896_TOOLS` | read-only CD-ROM |
| **Wi-Fi AP** | SSID `OpenWrt`, 2.4 GHz | may be open on a clean configuration |
| **EDL** | `reboot-edl` | Qualcomm USB `05c6:9008` |
| **Fastboot** | `reboot-fastboot` | `fastboot devices` |

> [!WARNING]
> Set a root password with `passwd` and secure Wi-Fi before using the device on an untrusted network.

---

## 📶 SIM Detection, Carrier Auto-Provisioning & Reboot Behavior

After SIM insertion, `qcom-carrier-autocfg` uses ModemManager to identify MCC-MNC/IMSI, select APN settings, and if necessary deploy a Qualcomm Carrier MBN (`mcfg_sw.mbn`).

If the required MBN differs from the active one, the system syncs storage and performs a **one-time automatic reboot** so the Hexagon DSP can load the new profile. This is expected behavior, not a bootloop.

After reboot, a matching MBN is not replaced again, so no additional reboot is required; ModemManager creates the LTE bearer with the selected APN/IP stack.

SIM hot-swap behavior:

- same/compatible MBN family — connectivity can normally recover without reboot;
- different MBN family — one reboot may be required to load the new profile.

Monitor provisioning:

```bash
logread -f -e carrier-autocfg
```

Example initial detection:

```text
[carrier-autocfg] Started MSM8916 SIM Carrier Auto-Provisioning Engine
[carrier-autocfg] Matched carrier in global APN database for MCC-MNC 405861
[carrier-autocfg] Deploying Carrier MBN 'generic/apac/reliance/commerci/mcfg_sw.mbn' into /lib/firmware/MCFG_SW.MBN...
[carrier-autocfg] Carrier MBN radio firmware updated for 'Reliance Jio'. Scheduling automatic reboot in 3 seconds to initialize Hexagon DSP...
```

After reboot:

```text
[carrier-autocfg] Active Carrier MBN already matches generic/apac/reliance/commerci/mcfg_sw.mbn.
[carrier-autocfg] Boot-time carrier provisioning completed successfully. No reboot required.
[carrier-autocfg] Requesting ModemManager bearer connection for APN 'jionet' (ipv4v6)...
```

---

## 📂 eMMC Partition Layout

Exact numbering and size depend on the board/eMMC capacity. A typical OpenWrt layout contains:

| Partition | Label | Type | Purpose |
| :-- | :-- | :-- | :-- |
| `modem` | `modem` | VFAT/raw | Qualcomm modem/WCNSS firmware |
| `persist` | `persist` | EXT4 | factory calibration and Wi-Fi NVRAM |
| `boot` | `boot` | Raw | Linux kernel + DTB |
| `rootfs` | `system/rootfs` | SquashFS | read-only OpenWrt rootfs |
| `rootfs_data` | `rootfs_data` | EXT4 | persistent writable overlay |

Always verify the actual GPT of the exact board before performing low-level writes. Do not transplant partition tables between different hardware variants without validation.

---

## 📦 Package & Kernel Driver Repository

Project APK feeds for OpenWrt 25.12.5 are published through GitHub Pages:

https://akbar-npj.github.io/msm8916-openwrt/

Example feed setup:

```bash
cat << 'EOF' > /etc/apk/repositories.d/customfeeds.list
https://akbar-npj.github.io/msm8916-openwrt/releases/25.12.5/targets/msm89xx/msm8916/packages/packages.adb
EOF

apk update
```

Examples:

```bash
apk add kmod-usb-net-rtl8152
apk add luci-app-wireguard
```

---

## 📜 License

This project is licensed under the **GNU General Public License v2.0 (GPL-2.0)**. Qualcomm firmware dumper components use the BSD-3-Clause License.
