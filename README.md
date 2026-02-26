# ansible-netology

Инфраструктурный репозиторий для развёртывания сервиса сбора и хранения логов в облаке с помощью
Terraform (создание инфраструктуры) и Ansible (конфигурация сервисов).

Коротко: Terraform создаёт машины/сети, `generate_inventory.sh` формирует инвентарь, затем Ansible `site.yml` применяет роли к хостам.

**Ключевые компоненты**

- `terraform/` — конфигурация инфраструктуры (создание VMs, сети, security groups).
- `ansible/` — плейбуки, `group_vars/`, локальные `roles/` и шаблоны для развёртывания сервисов:
  - ClickHouse — аналитическая БД
  - Vector — агент сбора логов
  - Lighthouse + nginx — веб-интерфейс/публичная часть
- `generate_inventory.sh` — скрипт для генерации инвентаря Ansible (если применяется)

**Структура (кратко)**

- `terraform/` — main.tf, variables.tf, provider.tf и т.д.
- `ansible/site.yml` — основной плейбук (теперь использует локальные роли: `ssh_prep`, `clickhouse`, `vector`, `lighthouse`).
- `ansible/roles/` — локальные роли реализующие логику установки сервисов.
- `ansible/group_vars/` — переменные для групп хостов.
- `ansible/inventory/` — примеры инвентаря и шаблоны.

## Быстрый старт

1. Установите требования (Terraform, Ansible):

```bash
ansible --version
terraform --version
```

2. Подготовьте инфраструктуру (пример):

```bash
cd terraform
terraform init
terraform plan -out plan.tfplan
terraform apply "plan.tfplan"
```

3. (Опционально) Сгенерируйте инвентарь:

```bash
./generate_inventory.sh
```

4. Запустите Ansible-плейбук:

```bash
cd ansible
ansible-playbook -i inventory/prod.ini site.yml -u <ssh_user> --ask-become-pass
```

5. Полезные проверки:

```bash
# Проверка синтаксиса
ansible-playbook --syntax-check -i inventory/prod.ini site.yml

# Прогон в режиме dry-run
ansible-playbook -i inventory/prod.ini site.yml --check --diff
```

## Vault и безопасность

- Если в `group_vars/` есть чувствительные данные, используйте `ansible-vault`.
- Пример редактирования зашифрованного файла:

```bash
ansible-vault edit ansible/group_vars/clickhouse.yml --ask-vault-pass
```

Не храните пароль от Vault в репозитории.

## Примечания и рекомендации

- README в `ansible/` обновлён и отражает текущую организацию ролей.
- Некоторые переменные в `group_vars/clickhouse.yml` являются избыточными для упрощённой роли — можно привести к необходимому минимуму.
- Рекомендуется протестировать `site.yml` с `--limit` и `--check` перед применением в продакшн.

Если хотите, могу: сгенерировать `roles/` в более полном виде, выполнить `ansible-playbook --syntax-check` или подготовить `Makefile`/скрипты для удобного запуска.

./generate_inventory.sh
# или, при необходимости, выполняйте из каталога проекта
# bash generate_inventory.sh
```

4) Установите роли Ansible (при необходимости):

```bash
ansible-galaxy install -r ansible/requirements.yml -p ./ansible/roles
```

5) Запустите плейбук Ansible:

```bash
cd ansible
ansible-playbook -i inventory/prod.ini site.yml -u <ssh_user> --ask-become-pass
```

(Замените `<ssh_user>` на подходящего SSH-пользователя и настройте SSH-ключи/доступ.)

## Переменные и кастомизация

- Задавайте значения Terraform в [terraform/terraform.tfvars](terraform/terraform.tfvars) или через переменные окружения.
- Групповые переменные Ansible находятся в `ansible/group_vars/`.
- Шаблоны для сервисов — в `ansible/inventory/templates/`.