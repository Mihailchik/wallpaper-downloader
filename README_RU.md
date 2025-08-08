# Загрузчик Обоев

PowerShell скрипт для автоматического скачивания обоев с Unsplash API. Загружает высококачественные обои (4K) и автоматически управляет ими.

## Возможности

- 🖼️ **Высокое Качество**: Скачивает 4K обои (3840x2160)
- 🔄 **Умное Управление**: Хранит максимум 30 обоев, автоматически удаляет старые
- 🚫 **Без Дубликатов**: Отслеживает скачанные обои, избегает повторов
- 🤫 **Тихая Работа**: Работает незаметно в фоне, логирует только ошибки
- 📅 **Готов к Планировщику**: Идеально подходит для автоматизации через Планировщик задач Windows
- 🧹 **Автоочистка**: Удаляет старые логи и историю (7 дней)
- 🔄 **Два API**: Использует Unsplash + Pixabay для надежности

## Быстрый Старт

### 1. Получить API ключи
**Unsplash API (Основной):**
1. Перейти на [Unsplash Developers](https://unsplash.com/developers)
2. Создать новое приложение
3. Получить Access Key

**Pixabay API (Резервный):**
1. Перейти на [Pixabay API](https://pixabay.com/api/docs/)
2. Зарегистрироваться и получить API ключ
3. Опционально, но рекомендуется для надежности

### 2. Настроить Конфигурацию
1. Скопировать `config.example.json` в `config.json`
2. Добавить ваши данные Unsplash API
3. Указать путь к папке для обоев

### 3. Запустить Скрипт
```powershell
# Скачать 20 обоев (по умолчанию)
.\WallpaperDownloader.ps1

# Скачать определенное количество
.\WallpaperDownloader.ps1 -Count 10
```

## Конфигурация

Отредактируйте `config.json`:
```json
{
    "unsplash": {
        "applicationId": "ВАШ_ID_ПРИЛОЖЕНИЯ",
        "accessKey": "ВАШ_КЛЮЧ_ДОСТУПА",
        "secretKey": "ВАШ_СЕКРЕТНЫЙ_КЛЮЧ"
    },
    "pixabay": {
        "apiKey": "ВАШ_КЛЮЧ_PIXABAY"
    },
    "folders": {
        "wallpapers": "C:\\Users\\ВашеИмя\\Pictures\\wallpapers"
    },
    "settings": {
        "maxWallpapersPerFolder": 20,
        "imageWidth": 3840,
        "imageHeight": 2160
    }
}
```

## Автоматизация через Планировщик задач Windows

### Вариант 1: Запуск через 10 минут после включения компьютера

1. **Открыть Планировщик задач:**
   - Win + R → `taskschd.msc` → Enter

2. **Создать задание:**
   - Action → Create Basic Task
   - Name: `Wallpaper at Startup`
   - Description: `Скачивание обоев через 10 минут после запуска`

3. **Настроить триггер:**
   - When: `When the computer starts`
   - Next

4. **Настроить действие:**
   - What action: `Start a program`
   - Program/script: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\путь\к\WallpaperDownloader.ps1"`
   - Start in: `C:\путь\к\папке\скрипта`
   - Next → Finish

5. **Добавить задержку:**
   - Найти созданное задание в списке
   - Двойной клик → вкладка Triggers
   - Edit → Advanced settings
   - ✅ Delay task for: `10 minutes`
   - OK

### Вариант 2: Ежедневно в 16:00

1. **Создать новое задание:**
   - Action → Create Basic Task
   - Name: `Wallpaper Daily 4PM`
   - Description: `Ежедневное скачивание обоев в 16:00`

2. **Настроить триггер:**
   - When: `Daily`
   - Start: `16:00:00`
   - Recur every: `1 days`
   - Next

3. **Настроить действие:**
   - What action: `Start a program`
   - Program/script: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\путь\к\WallpaperDownloader.ps1"`
   - Start in: `C:\путь\к\папке\скрипта`
   - Next → Finish

### Дополнительные настройки для обоих заданий:

**Для каждого задания:**
1. Двойной клик на задание
2. **General tab:**
   - ✅ Run whether user is logged on or not
   - ✅ Run with highest privileges
3. **Settings tab:**
   - ✅ Allow task to be run on demand
   - ✅ If the task fails, restart every: `1 minute` for up to `3 times`
4. OK

## Обработка Ошибок и Надежность

- **Два API**: Автоматически переключается на Pixabay при превышении лимита Unsplash
- **Принудительная Очистка**: Поддерживает максимум 30 файлов независимо от ошибок API
- **Тихое Логирование**: Ошибки в `wallpaper_downloader.log`, без спама в консоль
- **Умная Очистка**: Очистка по истории + принудительная по количеству файлов
- **Автовосстановление**: Удаляет старые логи и историю (7 дней)

## Экстренное Прекращение

### Способы остановки:
1. **Через Диспетчер задач:** Ctrl + Shift + Esc → найти `powershell.exe` → End Task
2. **Через Планировщик:** Task Scheduler → найти задание → Right click → End
3. **Через PowerShell:** `Stop-Process -Name powershell -Force`

### Что произойдет:
- ✅ Скачанные файлы останутся
- ✅ История сохранится
- ⚠️ Частично скачанный файл может быть поврежден
- 🔄 При следующем запуске скрипт восстановится

## Структура Проекта

```
wallpaper-downloader/
├── WallpaperDownloader.ps1    # Основной скрипт
├── config.example.json        # Шаблон конфигурации
├── README.md                  # Документация (English)
├── README_RU.md              # Документация (Русский)
└── .gitignore                # Правила Git

# Генерируемые файлы (не в репозитории):
├── config.json               # Ваша конфигурация
├── history.json              # История скачиваний
└── wallpaper_downloader.log  # Логи ошибок
```

## Системные Требования

- Windows PowerShell 5.0+
- Подключение к интернету
- API ключ Unsplash (бесплатный)

## Лицензия

MIT License - свободно используйте и изменяйте!