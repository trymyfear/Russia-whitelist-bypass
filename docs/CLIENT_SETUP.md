# Настройка клиентских приложений для Whitelist Bypass

Для подключения к серверу Whitelist Bypass требуется клиент с поддержкой протоколов **VLESS + REALITY + XTLS-Vision** и **uTLS (Chrome Fingerprint)**.

---

## 📱 Клиенты для iOS

### 1. Streisand (Рекомендуется)
1. Установите [Streisand в App Store](https://apps.apple.com/app/streisand/id6450534064).
2. Скопируйте ссылку `vless://...` в буфер обмена.
3. Откройте приложение и нажмите **«+»** в правом верхнем углу ➔ **«Import from Clipboard»** (Импортировать из буфера).
4. Либо отсканируйте сгенерированный QR-код через значок камеры.
5. Нажмите кнопку подключения.

### 2. V2Box
1. Установите [V2Box в App Store](https://apps.apple.com/app/v2box-v2ray-client/id6446814043).
2. Перейдите во вкладку **Configs** ➔ **«+»** ➔ **«Import V2ray URL from Clipboard»** или **«Scan QR Code»**.
3. Выберите профиль, включите переключатель на главном экране.

### 3. FoXray
1. Установите [FoXray в App Store](https://apps.apple.com/app/foxray/id6448892567).
2. Нажмите **«+»** ➔ **«Import from Clipboard»** или отсканируйте QR.
3. Подключитесь.

---

## 🤖 Клиенты для Android

### 1. v2rayNG (Рекомендуется)
1. Скачайте последнюю версию [v2rayNG с GitHub Releases](https://github.com/2dust/v2rayNG/releases) или Google Play.
2. Нажмите значок **«+»** в верхнем меню ➔ **«Импорт конфигурации из буфера обмена»** (или сканирование QR).
3. Нажмите на подключение (круглую кнопку в правом нижнем углу).

### 2. NekoBox for Android
1. Скачайте [NekoBox с GitHub Releases](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases).
2. Нажмите **«+»** ➔ **«Импорт из буфера обмена»**.
3. В настройках роутинга убедитесь, что включен режим **VPN Service**.

### 3. Hiddify Next
1. Скачайте [Hiddify с GitHub Releases](https://github.com/hiddify/hiddify-app/releases) или Google Play.
2. Нажмите **«New Profile»** ➔ **«Add from Clipboard»**.
3. Нажмите **Connect**.

---

## 💻 Клиенты для Windows / macOS / Linux

* **Windows**: [v2rayN](https://github.com/2dust/v2rayN/releases) / [Hiddify Desktop](https://github.com/hiddify/hiddify-app/releases) / [Nekoray](https://github.com/MatsuriDayo/nekoray/releases).
* **macOS**: [FoXray](https://apps.apple.com/app/foxray/id6448892567) / [V2Box](https://apps.apple.com/app/v2box-v2ray-client/id6446814043) / [Hiddify Desktop](https://github.com/hiddify/hiddify-app/releases).
* **Linux**: [Nekoray](https://github.com/MatsuriDayo/nekoray/releases) / `sing-box` / `xray-core`.

---

## ⚙️ Важные параметры при ручной настройке

Если вы настраиваете профиль вручную, убедитесь, что указаны следующие параметры:

| Параметр | Значение | Описание |
|---|---|---|
| **Protocol** | `VLESS` | Базовый протокол |
| **Address** | IP вашего Российского релея | Например `1.2.3.4` |
| **Port** | `443` | Обязательно стандартный HTTPS порт |
| **Flow** | `xtls-rprx-vision` | Критично для маскировки |
| **Encryption** | `none` | Шифрование выполняется внутри TLS/REALITY |
| **Security** | `REALITY` | Технология маскировки под сайт |
| **SNI / ServerName** | `ya.ru` | Домен из белого списка оператора |
| **Fingerprint (fp)** | `chrome` | Имитация TLS ClientHello браузера Chrome |
| **PublicKey (pbk)** | Публичный ключ релея | Сгенерированный при установке |
| **ShortId (sid)** | Short ID релея | Сгенерированный при установке |
| **SpiderX** | `/` | Путь симуляции |

---

## 💡 Советы по стабильности в условиях глушилок

1. **Режим передачи DNS**: В настройках клиента выберите **Remote DNS (Удаленный DNS)** или задайте `1.1.1.1` / `8.8.8.8` через DoH/DoT внутри туннеля, чтобы мобильный оператор не перехватывал DNS-запросы.
2. **Переподключение при смене вышки**: Если при перемещении по городу связь пропала, перезапустите VPN в приложении (передерните тумблер), чтобы инициировать новый TLS-хендшейк.
