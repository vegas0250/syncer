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
		/root/.ssh \
		/root/.tmux.conf \
		/root/.zshrc \
		/root/.bashrc \
		/root/.local \
		/root/.config \
		/root/.oh-my-zsh \
		/root/source-projects \
		--warning=no-all
		

	echo "[OK] Архив успешно создан"
}

extract() {
	echo "[INFO] Распаковываю архив в корень..."

	tar -xzpvf "$ARCHIVE_NAME" -P
}

upload() {

	echo "[INFO] Отправляю архив в object storage..."

	rclone copy -P "$ARCHIVE_NAME" "$STORAGE_PATH"

	echo "[OK] Архив успешно передан: $REMOTE_OBJECT"
}

download() {
	echo "[INFO] Скачиваю архив $REMOTE_OBJECT в архив $ARCHIVE_NAME"
 
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
	download
	extract
	update
	clear

}

update() {
	echo "[INFO] Выполняю дополнительные команды..."

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
