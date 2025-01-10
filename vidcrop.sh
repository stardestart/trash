#Этот скрипт написан на Bash и предназначен для обработки видеофайлов с определенным расширением. Вот основные шаги, которые выполняет скрипт:
#
#    1)Запрос расширения видеофайла:
#        Скрипт запрашивает у пользователя ввод расширения видеофайла (например, mp4, avi и т.д.). Ввод должен содержать только буквы и цифры.
#
#    2)Поиск видеофайлов:
#        После получения корректного расширения, скрипт ищет все видеофайлы с указанным расширением в текущем каталоге и сохраняет их в массив name.
#
#    3)Обработка каждого видеофайла:
#        Для каждого найденного видеофайла:
#            a)Скрипт использует ffprobe для получения ширины (w), высоты (h) и угла поворота (r) видео.
#            b)Вычисляется разница между шириной и высотой (diff).
#
#    4)Открытие видеофайла:
#        Видео открывается с помощью xdg-open.
#
#    5)Выбор действия:
#        a)Пользователю предлагается выбрать одно из двух действий: "Обработать и сохранить" или "Пропустить и удалить".
#        Если выбрано "Обработать и сохранить":
#            a1)Если видео вертикальное (ширина меньше высоты или угол поворота 90/270 градусов), пользователю предлагается выбрать, как обрезать видео (верхнюю, центральную или нижнюю часть) или оставить его вертикальным.
#            a2)В зависимости от выбора, используется ffmpeg для обработки видео и сохранения его с новым именем (добавляется суффикс _processed).
#        b)Если выбрано "Пропустить и удалить", видеофайл просто удаляется.
#
while true; do
# Вывод приглашения для ввода
    printf "\033[47m\033[30mВведите расширение видеофайла:\033[0m\033[32m *."
# Чтение ввода
    read -e ext
# Проверка на наличие только букв и цифр
    if [[ "$ext" =~ ^[a-zA-Z0-9]+$ ]]; then
        break  # Выход из цикла, если ввод корректен
    else
        echo -e "\033[41m\033[30mОшибка: Ввод должен содержать только буквы и цифры. Попробуйте снова.\033[0m\033[32m"
    fi
done
mapfile -t name < <(find . -name "*.$ext")
for (( i=0; i<"${#name[*]}"; i++ )); do
# Получение ширины видео
    w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "${name[$i]}")
# Получение высоты видео
    h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "${name[$i]}")
# Получение угла поворота видео
    r=$(ffprobe -v error -select_streams v:0 -show_entries stream_side_data=rotation -of default=noprint_wrappers=1:nokey=1 "${name[$i]}")
# Вычисление разницы между шириной и высотой
    diff=$(($w - $h))
    if [ $diff -lt 0 ]; then
        diff=$((diff * -1))
    fi
# Открытие видеофайла
    xdg-open "${name[$i]}" &> /dev/null &
    PS3="$(echo -e ">")"
    select menudel in "Обработать и сохранить." "Пропустить."; do
        case "$menudel" in
            "Обработать и сохранить.")
                echo "$w x $h ${name[$i]} - $r"
                if [[ "$r" == "-90" || "$r" == "90" || "$w" -lt "$h" ]]; then
                    echo -e "\033[41m\033[30mВертикальное видео?\033[0m\033[32m"
                    PS3="$(echo -e ">")"
                    select menuyesorno in "Да." "Нет."; do
                        case "$menuyesorno" in
                            "Да.")
                                PS3="$(echo -e ">")"
                                select menuscreen in "Обрезать и сохранить вверхнюю часть видеофайла." "Обрезать и сохранить центральную часть видеофайла." "Обрезать и сохранить нижнюю часть видеофайла." "Оставить видеофайл вертикальным."; do
                                    case "$menuscreen" in
                                        "Обрезать и сохранить вверхнюю часть видеофайла.")
                                            ffmpeg -i "${name[$i]}" -c:v hevc_nvenc -qp 25 -preset slow -map_metadata -1 -c:a ac3 -vf crop=iw:iw:0:0 "${name[$i]%.*}_processed.mp4"
                                            break
                                            ;;
                                        "Обрезать и сохранить центральную часть видеофайла.")
                                            ffmpeg -i "${name[$i]}" -c:v hevc_nvenc -qp 25 -preset slow -map_metadata -1 -c:a ac3 -vf crop=iw:iw:0:$(($diff / 2)) "${name[$i]%.*}_processed.mp4"
                                            break
                                            ;;
                                        "Обрезать и сохранить нижнюю часть видеофайла.")
                                            ffmpeg -i "${name[$i]}" -c:v hevc_nvenc -qp 25 -preset slow -map_metadata -1 -c:a ac3 -vf crop=iw:iw:0:$diff "${name[$i]%.*}_processed.mp4"
                                            break
                                            ;;
                                        "Оставить видеофайл вертикальным.")
                                            ffmpeg -i "${name[$i]}" -c:v hevc_nvenc -qp 25 -preset slow -map_metadata -1 -c:a ac3 "${name[$i]%.*}_processed.mp4"
                                            break
                                            ;;
                                        *) echo -e "\033[41m\033[30mЧто значит - "$REPLY"?\033[0m\033[32m";;
                                    esac
                                done
                                break
                                ;;
                            "Нет.")
                                ffmpeg -i "${name[$i]}" -c:v hevc_nvenc -qp 25 -preset slow -map_metadata -1 -c:a ac3 "${name[$i]%.*}_processed.mp4"
                                break
                                ;;
                            *) echo -e "\033[41m\033[30mЧто значит - "$REPLY"?\033[0m\033[32m";;
                        esac
                    done
                else
                    ffmpeg -i "${name[$i]}" -c:v hevc_nvenc -qp 25 -preset slow -map_metadata -1 -c:a ac3 "${name[$i]%.*}_processed.mp4"
                fi
                break
                ;;
            "Пропустить.")
                break
                ;;
            *) echo -e "\033[41m\033[30mЧто значит - "$REPLY"?\033[0m\033[32m";;
        esac
    done
done
