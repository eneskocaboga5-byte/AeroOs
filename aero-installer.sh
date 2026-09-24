#!/bin/sh

# Renkler ve Terminal Ayarlari
BG_BLUE="\033[44;37m"
TEXT_WHITE="\033[1;37m"
INVERSE="\033[7m"
RESET="\033[0m"
HIDE_CURSOR="\033[?25l"
SHOW_CURSOR="\033[?25h"

# TUI Menu Motoru
draw_menu() {
    TITLE="$1"
    shift
    NUM_ITEMS=$#
    CURRENT_INDEX=1

    stty -echo -icanon min 1 time 0 2>/dev/null
    printf "$HIDE_CURSOR"

    while true; do
        clear
        echo -e "${BG_BLUE}========================================================================${RESET}"
        echo -e "${BG_BLUE}             AeroOs v4.0 Ultimate TUI Installation Wizard              ${RESET}"
        echo -e "${BG_BLUE}                    Lead Architect: Enes Kocaboga                       ${RESET}"
        echo -e "${BG_BLUE}========================================================================${RESET}"
        echo -e "\n === $TITLE ===\n"
        echo " [Kullanim: Yon tuslari ile gezinin, secmek icin ENTER tusuna basin]"
        echo " ----------------------------------------------------------------------"

        I=1
        for item in "$@"; do
            if [ $I -eq $CURRENT_INDEX ]; then
                echo -e "  --> ${INVERSE} $item ${RESET}"
            else
                echo -e "      $item"
            fi
            I=$(expr $I + 1)
        done
        echo " ----------------------------------------------------------------------"

        read -r -n 1 KEY
        if [ "$KEY" = "$(printf '\033')" ]; then
            read -r -n 2 SUBKEY
            if [ "$SUBKEY" = "[A" ]; then
                CURRENT_INDEX=$(expr $CURRENT_INDEX - 1)
                [ $CURRENT_INDEX -lt 1 ] && CURRENT_INDEX=$NUM_ITEMS
            elif [ "$SUBKEY" = "[B" ]; then
                CURRENT_INDEX=$(expr $CURRENT_INDEX + 1)
                [ $CURRENT_INDEX -gt $NUM_ITEMS ] && CURRENT_INDEX=1
            fi
        elif [ -z "$KEY" ] || [ "$KEY" = "" ] || [ "$(printf '%s' "$KEY" | od -An -tx1 | tr -d ' ')" = "0a" ]; then
            break
        fi
    done

    printf "$SHOW_CURSOR"
    stty echo icanon 2>/dev/null
    return $CURRENT_INDEX
}

# ==================== HOS GELDINIZ EKRANI ====================
draw_menu "AeroOs Kurulum Sihirbazina Hos Geldiniz!" "SISTEMI YUKLEMEYE BASLA" "YUKLEMEVI IPTAL ET VE CIK"
CHOICE=$?
if [ $CHOICE -ne 1 ]; then clear; echo "[!] Kurulum iptal edildi."; exit 1; fi

# ==================== 1. ADIM: DISK SECIMI ====================
DISKS=""
for disk in /sys/block/*; do
    DISK_NAME=$(basename $disk)
    
    is_valid=0
    case "$DISK_NAME" in
        sd*|vd*|hd*|nvme*) is_valid=1 ;;
    esac

    if [ $is_valid -eq 1 ]; then
        if [ -f "$disk/size" ]; then
            SECTORS=$(cat "$disk/size")
            SIZE_MB=$(expr $SECTORS / 2048 2>/dev/null)
            DISKS="$DISKS /dev/${DISK_NAME}_[${SIZE_MB}_MB]"
        fi
    fi
done

if [ -z "$DISKS" ]; then
    clear; echo " [ HATA ] Sistemde kurulabilir hicbir sabit disk algilanamadi!"; exit 1
fi

draw_menu "HEDEF SABIT DISK SECIMI" $DISKS
DISK_CHOICE=$?
TARGET_RAW=$(echo $DISKS | cut -d' ' -f$DISK_CHOICE)
TARGET_DISK=$(echo $TARGET_RAW | cut -d'_' -f1 | cut -d'/' -f3)

# ==================== 2. ADIM: TABLO SECIMI ====================
draw_menu "BOLUMLEME TABLO TURU" "GPT GUID Partition Table - Modern" "MBR Master Boot Record - Klasik"
TABLE_CHOICE=$?

# ==================== 3. ADIM: DOSYA SISTEMI ====================
draw_menu "KOK DIZIN DOSYA SISTEMI SECIMI" "ext4 Standart ve Kararli Linux Sistemi" "btrfs Modern Gelismis Snapshot Destekli" "xfs Buyuk Veriler Icin Performansli"
FS_CHOICE=$?
if [ $FS_CHOICE -eq 2 ]; then
    FS_TYPE="btrfs"
elif [ $FS_CHOICE -eq 3 ]; then
    FS_TYPE="xfs"
else
    FS_TYPE="ext4"
fi

# ==================== TIMEZONE SECIMI ====================
draw_menu "SISTEM SAAT DILIMI SECIMI" "Europe-Istanbul Turkiye Saati" "UTC Evrensel Zaman Koordinesi"
TZ_CHOICE=$?
if [ $TZ_CHOICE -eq 1 ]; then TIMEZONE="Europe/Istanbul"; else TIMEZONE="UTC"; fi

# ==================== NETWORKING PROFILE ====================
draw_menu "AG KARTI YAPILANDIRMASI" "DHCP - Otomatik IP Adresi Al" "STATIC - Yerel Sabit IP Ayarla"
NET_CHOICE=$?

# ==================== SOFTWARE PROFILES ====================
draw_menu "EKSTRA YAZILIM PAKETI PROFILLERI" "Minimal - Sadece Temel Sistem" "Hacker Suite - cmatrix ve Sistem Araclari Dahil"
SW_CHOICE=$?

# ==================== 4. ADIM: KULLANICI AYARLARI ====================
clear
echo -e "${BG_BLUE}========================================================================${RESET}"
echo -e "${BG_BLUE}                     STEP 4: SYSTEM & USER SECURITY                    ${RESET}"
echo -e "${BG_BLUE}========================================================================${RESET}"
echo ""
printf " 1) Cihaz adini belirleyin [AeroOs-Enes]: "
read SYS_HOSTNAME
[ -z "$SYS_HOSTNAME" ] && SYS_HOSTNAME="AeroOs-Enes"

printf " 2) Sistem Yoneticisi sifresini yazin: "
read ROOT_PASSWORD
[ -z "$ROOT_PASSWORD" ] && ROOT_PASSWORD="root"

echo ""
printf " 3) Yeni standart kullanici adi [enes]: "
read NEW_USER
[ -z "$NEW_USER" ] && NEW_USER="enes"

printf " 4) Sifre yazin: "
read USER_PASSWORD
[ -z "$USER_PASSWORD" ] && USER_PASSWORD="enes"

# ==================== 5. ADIM: OZET VE ONAY ====================
draw_menu "KURULUM OZETI VE SON ONAY" "YUKLEMEVI BASLAT" "VAZGEC VE CIK"
CONFIRM_CHOICE=$?
if [ $CONFIRM_CHOICE -ne 1 ]; then clear; echo "[!] Kurulum sonlandirildi."; exit 1; fi

# ==================== GERCEK DISK AKSIYONU ====================
clear
echo " [*] Disk uzerinde bolumler olusturuluyor..."
if [ "$TABLE_CHOICE" = "1" ]; then
    printf "g\nn\n1\n\n+100M\nn\n2\n\n\nw\n" | fdisk /dev/$TARGET_DISK >/dev/null 2>&1
else
    printf "o\nn\np\n1\n\n+100M\nn\np\n2\n\n\nw\n" | fdisk /dev/$TARGET_DISK >/dev/null 2>&1
fi
sleep 1

echo " [*] Bolum tablosu yenileniyor (mdev)..."
mdev -s ; sleep 1

echo " [*] /dev/${TARGET_DISK}2 bolumu $FS_TYPE olarak bicimlendiriliyor..."
mkfs.$FS_TYPE -F /dev/${TARGET_DISK}2 >/dev/null 2>&1 || mkfs.$FS_TYPE /dev/${TARGET_DISK}2 >/dev/null 2>&1
sleep 1

echo " [*] AeroOs dosyalari kalici hafizaya enjekte ediliyor..."
mkdir -p /mnt/target
mount /dev/${TARGET_DISK}2 /mnt/target
cp -a /bin /sbin /usr /lib /lib64 /etc /init /mnt/target/ 2>/dev/null
echo "$SYS_HOSTNAME" > /mnt/target/etc/hostname
echo "$TIMEZONE" > /mnt/target/etc/timezone

if [ $NET_CHOICE -eq 2 ]; then
    sed -i 's/udhcpc -i eth0/ifconfig eth0 10.0.2.15 netmask 255.255.255.0 up/g' /mnt/target/init 2>/dev/null
fi

echo " [*] Kullanici hesaplari ve SUDO yetkilendirmesi yaziliyor..."
touch /mnt/target/etc/passwd /mnt/target/etc/group /mnt/target/etc/shadow
chmod 600 /mnt/target/etc/shadow

echo "root:x:0:0:root:/root:/bin/sh" > /mnt/target/etc/passwd
echo "$NEW_USER:x:1000:1000:$NEW_USER:/home/$NEW_USER:/bin/sh" >> /mnt/target/etc/passwd

echo "root:x:0:" > /mnt/target/etc/group
echo "wheel:x:10:$NEW_USER" >> /mnt/target/etc/group
echo "$NEW_USER:x:1000:" >> /mnt/target/etc/group

echo "root:$ROOT_PASSWORD" | chroot /mnt/target chpasswd 2>/dev/null
echo "$NEW_USER:$USER_PASSWORD" | chroot /mnt/target chpasswd 2>/dev/null

mkdir -p /mnt/target/etc/sudoers.d
echo "root ALL=(ALL:ALL) ALL" > /mnt/target/etc/sudoers
echo "%wheel ALL=(ALL:ALL) ALL" >> /mnt/target/etc/sudoers
chmod 440 /mnt/target/etc/sudoers

mkdir -p /mnt/target/home/$NEW_USER
chown -R 1000:1000 /mnt/target/home/$NEW_USER

if [ $SW_CHOICE -eq 2 ] && [ -f "/bin/cmatrix" ]; then
    echo " [*] Hacker Suite paketleri enjekte ediliyor..."
    cp /bin/cmatrix /mnt/target/bin/ 2>/dev/null
fi

mkdir -p /mnt/target/proc /mnt/target/sys /mnt/target/dev /mnt/target/tmp
sleep 1

echo " [*] Senkronizasyon yapiliyor..."
sync ; umount /mnt/target ; sleep 1

clear
echo -e "${BG_BLUE}========================================================================${RESET}"
echo -e "${BG_BLUE}       🎉 TEBRIKLER ENES KOCABOGA! AEROOS BASARIYLA KURULDU! 🎉        ${RESET}"
echo -e "${BG_BLUE}========================================================================${RESET}"
echo ""
echo " Kurulum Hedefi:  /dev/$TARGET_DISK ($FS_TYPE)"
echo " Saat Dilimi:     $TIMEZONE"
echo " Olusturulan Kullanici: $NEW_USER"
echo -e "${BG_BLUE}========================================================================${RESET}"
