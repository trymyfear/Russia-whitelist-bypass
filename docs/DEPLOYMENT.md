# Руководство по развертыванию Whitelist Bypass

В данном руководстве описан пошаговый процесс поднятия и настройки двух серверов (Зарубежного и Российского релея) с нуля.

---

## 1. Подготовка инфраструктуры

Вам понадобятся два сервера под управлением **Ubuntu 22.04 LTS** или **Ubuntu 24.04 LTS**:

### Сервер 1: Российский Релей (Relay)
* **Рекомендуемые провайдеры**:
  * [Yandex Cloud Compute](https://cloud.yandex.ru/) (зона `ru-central1-a/b/c/d`, минимальный инстанс 2 vCPU 20%, 1 ГБ RAM, статический публичный IPv4).
  * [VK Cloud](https://mcs.mail.ru/) / [Selectel](https://selectel.ru/).
* **Минимальные характеристики**: 1 vCPU, 1 GB RAM, 10 GB Disk.
* **Сеть**: Статический публичный IPv4.

### Сервер 2: Зарубежный Выход (Exit)
* **Рекомендуемые провайдеры**: Hetzner, DigitalOcean, Vultr, PQ Hosting, Aeza, Scaleway и др.
* **Локация**: Нидерланды, Германия, Финляндия, Швеция.
* **Минимальные характеристики**: 1 vCPU, 1 GB RAM.

---

## 2. Автоматическое развертывание (Рекомендуется)

### Этап 1: Настройка Зарубежного сервера (Foreign VPS)

1. Подключитесь к зарубежному серверу по SSH:
   ```bash
   ssh root@IP_ЗАРУБЕЖНОГО_СЕРВЕРА
   ```
2. Склонируйте репозиторий и запустите скрипт:
   ```bash
   git clone https://github.com/trymyfear/Russia-whitelist-bypass.git /tmp/wlb
   cd /tmp/wlb
   sudo bash scripts/deploy-foreign.sh
   ```
3. Сохраните выведенные значения:
   ```text
   FOREIGN_REALITY_PUBLIC_KEY=...
   FOREIGN_SHORT_ID=...
   HOP_UUID=...
   FOREIGN_SNI=www.yahoo.com
   ```

---

### Этап 2: Настройка Российского релея (Russian Relay)

1. Подключитесь к российскому серверу по SSH:
   ```bash
   ssh user@IP_РОССИЙСКОГО_СЕРВЕРА
   ```
2. Склонируйте репозиторий:
   ```bash
   git clone https://github.com/trymyfear/Russia-whitelist-bypass.git /tmp/wlb
   cd /tmp/wlb
   ```
3. Экспортируйте параметры зарубежного сервера и запустите деплой:
   ```bash
   export FOREIGN_IP="IP_ЗАРУБЕЖНОГО_СЕРВЕРА"
   export FOREIGN_REALITY_PUBLIC_KEY="ВАШ_FOREIGN_REALITY_PUBLIC_KEY"
   export FOREIGN_SHORT_ID="ВАШ_FOREIGN_SHORT_ID"
   export HOP_UUID="ВАШ_HOP_UUID"

   sudo -E bash scripts/deploy-relay.sh
   ```

4. Скрипт завершит установку и напечатает готовую VLESS-ссылку:
   ```text
   PRIMARY CLIENT VLESS LINK:
   vless://UUID@IP_РЕЛЕЯ:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=ya.ru&fp=chrome&pbk=...
   ```

---

## 3. Проверка работоспособности

### Проверка статуса сервисов на серверах:
* **На релее**:
  ```bash
  sudo systemctl status whitelist-bypass-relay.service
  ```
* **На зарубежном сервере**:
  ```bash
  sudo systemctl status whitelist-bypass-foreign.service
  ```

Оба сервиса должны быть в состоянии `active (running)`.

### Сквозной тест туннеля:
На российском релее можно выполнить диагностический скрипт:
```bash
sudo bash /tmp/wlb/scripts/run-direct-foreign-test.sh
```
В выводе должен появиться IP-адрес вашего зарубежного VPS (`DIRECT_FOREIGN_EGRESS=...`).

---

## 4. Настройка локального управления устройствами

Для добавления новых пользователей или отзыва ключей со своего компьютера:

1. Склонируйте репозиторий к себе на ПК:
   ```bash
   git clone https://github.com/trymyfear/Russia-whitelist-bypass.git
   cd whitelistbypass
   ```
2. Скопируйте `config.env.example` в `config.env`:
   ```bash
   cp config.env.example config.env
   ```
3. Заполните `config.env` значениями ваших серверов (`RUSSIAN_IP`, `RELAY_REALITY_PUBLIC_KEY`, `RELAY_SHORT_ID` и путь к вашему SSH ключу).

Теперь вы можете в одну команду добавлять устройства:
* **Windows (PowerShell)**:
  ```powershell
  .\scripts\add-device.ps1 -Name "iphone-alice"
  ```
* **Linux / macOS (Bash)**:
  ```bash
  ./scripts/add-device.sh iphone-alice
  ```
Скрипт выведет VLESS-ссылку и сохранит QR-код в папку `artifacts/private/`.
