
# Ansible playbooks (локальная подсекция)

Папка `ansible/` содержит плейбуки, переменные и шаблоны для конфигурации сервисов на созданной инфраструктуре (ClickHouse, Vector, Lighthouse/nginx).

Кратко: Terraform создаёт инфраструктуру, `generate_inventory.sh` (при необходимости) формирует инвентарь, затем Ansible `site.yml` применяет роли к хостам.

## Быстрая структура

- `site.yml` — основной плейбук (сыгран в ролях: `ssh_prep`, `clickhouse`, `vector`, `lighthouse`).
- `roles/` — локальные роли, реализованные в этом репозитории:
  - `ssh_prep` — подготовка SSH (known_hosts/facts)
  - `clickhouse` — установка и настройка ClickHouse
  - `vector` — установка и конфигурация Vector
  - `lighthouse` — развёртывание Lighthouse и конфигурация Nginx
- `group_vars/` — переменные групп (`clickhouse.yml`, `vector.yml`, `lighthouse.yml`).
- `inventory/` — примеры инвентаря (`prod.ini`, `template.yml`).
- `templates/` — общие шаблоны (nginx, vector), роли также содержат свои шаблоны.

## Что изменено в репозитории

- Роли были вынесены в `ansible/roles/` и `site.yml` обновлён для использования этих ролей напрямую.
- `requirements.yml` оставляет `community.general` в списке коллекций; роли теперь локальные (не требуется `ansible-galaxy install` для внешних ролей).

## Как запустить (быстро)

1. Убедитесь, что у вас установлены `ansible` и `terraform`.

2. (Опционально) Если вы используете зашифрованные `group_vars`, расшифруйте или подготовьте vault-пароль:

```bash
# при необходимости расшифровать/редактировать
ansible-vault edit ansible/group_vars/clickhouse.yml --ask-vault-pass
```

3. Подготовьте инвентарь (либо используйте `ansible/inventory/prod.ini`, либо запустите `generate_inventory.sh` в корне):

```bash
./generate_inventory.sh
```

4. Запустите плейбук:

```bash
cd ansible
ansible-playbook -i inventory/prod.ini site.yml -u <ssh_user> --ask-become-pass
```

5. Для выполнения только одной роли можно использовать `--tags`/`--limit` с `site.yml` или запускать плейбук с `--limit <host>`.

## Переменные и Vault

- Все групповые переменные находятся в `group_vars/`.
- Чувствительные значения храните в Ansible Vault. Пример работы с Vault см. ниже.

## Советы и примечания

- Файлы `group_vars` содержат некоторые дополнительные параметры (например, расширяемые структуры для ClickHouse). Если роль была упрощена, часть параметров может быть не использована — можно очистить `group_vars` для простоты.
- Роли сделаны минимальными и содержат README внутри `ansible/roles/<role>/README.md` с описанием переменных и поведения.
- Рекомендуется протестировать плейбук с `--check` и `--limit` на тестовом хосте перед применением в продакшн.

## Полезные команды

```bash
# Проверить синтаксис
ansible-playbook --syntax-check -i inventory/prod.ini site.yml

# Прогон в режиме проверки
ansible-playbook -i inventory/prod.ini site.yml --check --diff

# Запуск с Vault-паролем из файла
ansible-playbook -i inventory/prod.ini site.yml --vault-password-file ~/.ansible_vault_pass
```

---

