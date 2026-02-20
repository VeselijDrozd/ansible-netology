# Ansible playbooks

Поддиректория `ansible/` содержит плейбуки, переменные и шаблоны для конфигурации сервисов на созданной инфраструктуре.

## Цель

Основной плейбук `site.yml` выполняет настройку и развёртывание наборов сервисов (ClickHouse, Lighthouse, Vector, nginx и т.д.) на хостах, объявленных в инвентаре. Плейбуки ориентированы на повторяемое, идемпотентное приведение серверов к ожидаемому состоянию.

## Структура

- `site.yml` — основной плейбук, который включает роли и/или импортирует другие плейбуки.
- `requirements.yml` — список сторонних ролей для `ansible-galaxy`.
- `group_vars/` — переменные, применяемые к группам хостов (например, `clickhouse.yml`, `lighthouse.yml`, `vector.yml`).
- `inventory/` — шаблоны и примеры инвентаря:
  - `prod.ini` — пример ini-инвентаря для запуска в продакшн.
  - `template.yml` — пример YAML-инвентаря для динамической генерации.
  - `templates/` — Jinja2-шаблоны конфигураций (например, `nginx.conf.j2`, `vector.toml.j2`).
- `roles/` — локальные роли (если используются). Если роли внешние — они указываются в `requirements.yml`.

## Как запускать

1. (Опционально) Установите роли из `requirements.yml`:

```bash
ansible-galaxy install -r ansible/requirements.yml -p ./ansible/roles
```

2. Сгенерируйте или подготовьте инвентарь (например, `generate_inventory.sh` в корне репозитория создаёт `ansible/inventory/prod.ini`).

3. Запуск основного плейбука:

```bash
cd ansible
ansible-playbook -i inventory/prod.ini site.yml -u <ssh_user> --ask-become-pass
```

4. Полезные опции:
- Проверить синтаксис:

```bash
ansible-playbook --syntax-check -i inventory/prod.ini site.yml
```

- Запустить только теги:

```bash
ansible-playbook -i inventory/prod.ini site.yml --tags "nginx,vector"
```

- Запустить конкретную роль (если `site.yml` использует include/roles с тегами):

```bash
ansible-playbook -i inventory/prod.ini site.yml --tags "role:clickhouse"
```

## Переменные

- Групповые переменные находятся в `group_vars/` и переопределяют значения по умолчанию в ролях.
- Чувствительные данные храните в Ansible Vault или используйте внешние секрет-менеджеры.

Пример структуры переменных для ClickHouse (в `group_vars/clickhouse.yml`):

```yaml
clickhouse_version: "23.3"
clickhouse_users:
  - name: metrics
    password: "{{ vault_clickhouse_metrics_password }}"
```

## Роли и idempotency

Роли должны быть идемпотентными: повторный запуск плейбука не должен портить конфигурацию. Если добавляете/меняете роль — добавьте теги и проверки `when`/`changed_when` для безопасных обновлений.

## Ansible Vault

- Файл `group_vars/clickhouse.yml` зашифрован с помощью Ansible Vault в этом репозитории.

- Примеры команд для работы с зашифрованными переменными:

```bash
# Редактировать файл (спросит пароль):
ansible-vault edit ansible/group_vars/clickhouse.yml --ask-vault-pass

# Или использовать файл с паролем (без интерактивного ввода):
ansible-vault edit ansible/group_vars/clickhouse.yml --vault-password-file /path/to/vault_pass.txt

# Запуск плейбука с вводом пароля Vault:
ansible-playbook -i inventory/prod.ini site.yml --ask-vault-pass

# Запуск плейбука с файлом пароля:
ansible-playbook -i inventory/prod.ini site.yml --vault-password-file /path/to/vault_pass.txt
```

- Чтобы создать защищённый файл пароля (на локальной машине):

```bash
printf '%s' "<your_vault_password>" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
# затем использовать --vault-password-file ~/.ansible_vault_pass
```

- Не храните файл пароля в репозитории и не передавайте его третьим лицам.

## Отладка и проверка

- Для отладки запускайте с `-vvv`.
- Используйте `--check` и `--diff` для предварительного просмотра изменений:

```bash
ansible-playbook -i inventory/prod.ini site.yml --check --diff
```
