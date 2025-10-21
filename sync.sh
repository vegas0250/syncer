#!/usr/bin/env bash
set -e

# === Настройки ===
ARCHIVE_NAME="ubuntu-env.tar.gz"
STORAGE_PATH="yc:linux-env/" # пример пути для rclone
REMOTE_OBJECT="$STORAGE_PATH$ARCHIVE_NAME"

# === Функции ===

show_help() {
	echo "Использование: sync [команда]"
	echo
	echo "Доступные команды:"
	echo "  sync           - показать это сообщение"
	echo "  sync create    - создать архив системы $ARCHIVE_NAME"
	echo "  sync extract   - распаковать архив в корень системы $ARCHIVE_NAME"
	echo "  sync upload    - загрузить готовый архив ($ARCHIVE_NAME) в object storage ($STORAGE_PATH)"
	echo "  sync download  - загрузить архив ($ARCHIVE_NAME) из object storage ($STORAGE_PATH)"
	echo "  sync push      - создать архив системы ($ARCHIVE_NAME) и отправить в object storage ($STORAGE_PATH)"
	echo "  sync pull      - скачать архив ($ARCHIVE_NAME) и развернуть его в систему"
	echo
}

create() {
	echo "[INFO] Создаю архив системы..."

	tar -czpvf "$ARCHIVE_NAME" \
		--exclude=/dev \
		--exclude=/proc \
		--exclude=/sys \
		--exclude=/run \
		--exclude=/tmp \
		--exclude=/var/tmp \
		--exclude=/mnt \
		--exclude=/media \
		--exclude=/lost+found \
		--exclude=/swapfile \
		--exclude=/boot \
		--exclude=/lib/modules \
		--exclude=/usr/lib/modules \
		--exclude=/usr/lib/wsl \
		--exclude=/usr/src \
		--exclude=/etc/fstab \
		--exclude=/etc/crypttab \
		--exclude=/etc/netplan \
		--exclude=/etc/network/interfaces \
		--exclude=/etc/NetworkManager \
		--exclude=/etc/resolv.conf \
		--exclude=/etc/hostname \
		--exclude=/etc/hosts \
		--exclude=/var/cache \
		--exclude=/var/log \
		--exclude=/var/backups \
		--exclude=/var/lib/docker \
		--exclude=/home/*/.cache \
		--exclude=/home/*/.local/share/Trash \
		--exclude=/home/*/.mozilla/cache \
		--exclude=/home/*/.config/google-chrome/Cache \
		--exclude=/root/.cache \
		--exclude=/root/.vscode-server \
		--exclude=/root/.local/share/Trash \
		--exclude=/root/.mozilla/cache \
		--exclude=/root/.config/google-chrome/Cache \
		--exclude=/root/projects \
		--exclude="$ARCHIVE_NAME" \
		--warning=no-all \
		/

	echo "[OK] Архив успешно создан"
}

extract() {
	echo "[INFO] Распаковываю архив в корень..."

	tar -xzpPf "$ARCHIVE_NAME" \
		--exclude={"/dev","/proc","/sys","/run","/tmp","/mnt","/media","/lost+found","/boot","/etc/fstab","/etc/hostname","/etc/hosts"} \
		-C /
}

upload() {

	echo "[INFO] Отправляю архив в object storage..."

	rclone copy -P "$ARCHIVE_NAME" "$STORAGE_PATH"

	echo "[OK] Архив успешно передан: $REMOTE_OBJECT"
}

download() {
	echo "[INFO] Скачиваю архив..."

	rclone copy -P "$REMOTE_OBJECT" "$ARCHIVE_NAME"

	echo "[OK] Архив успешно скачен $ARCHIVE_NAME"
}

do_push() {
	clear
	create
	upload
}

do_pull() {

	clear
	downlaod
	extract
	update
	clear

}

update() {
	echo "[INFO] Выполняю дополнительные команды..."

	apt autoremove --purge -y

	apt autoclean -y

	apt clean -y

	journalctl --vacuum-time=1s

	rm -rf /tmp/* /var/tmp/*

	rm -rf ~/.cache

	rm -rf /var/crash/*

	rm -rf /var/lib/systemd/coredump/*

	apt update && apt upgrade -y && apt install -f

	echo "[OK] Система обновлена из архива."
}

clear() {
	rm -f "$ARCHIVE_NAME"
}

# === Разбор аргументов ===

case "$1" in
"" | "-h" | "--help") show_help ;;
create) create ;;
extract) extract ;;
upload) upload ;;
download) download ;;
push) do_push ;;
pull) do_pull ;;
*) echo "Неизвестная команда: $1" show_help exit 1 ;;
esac
