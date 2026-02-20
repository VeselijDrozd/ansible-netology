# ansible-netology

Репозиторий для развёртывания инфраструктуры и приложений с помощью Terraform и Ansible.

## Краткое описание

Проект содержит Terraform-конфигурацию для создания инфраструктуры и Ansible-плейбуки для конфигурации сервисов (ClickHouse, Lighthouse, Vector и др.). Есть скрипт для генерации инвентаря Ansible.

## Структура репозитория

- [generate_inventory.sh](generate_inventory.sh) — скрипт генерации инвентаря.
- [ansible/](ansible/) — директория с Ansible-кодом:
  - [ansible/site.yml](ansible/site.yml) — основной плейбук.
  - [ansible/requirements.yml](ansible/requirements.yml) — список ролей для `ansible-galaxy`.
  - [ansible/group_vars/](ansible/group_vars/) — переменные групп:
    - [ansible/group_vars/clickhouse.yml](ansible/group_vars/clickhouse.yml)
    - [ansible/group_vars/lighthouse.yml](ansible/group_vars/lighthouse.yml)
    - [ansible/group_vars/vector.yml](ansible/group_vars/vector.yml)
  - [ansible/inventory/](ansible/inventory/) — пример/шаблоны инвентаря:
    - [ansible/inventory/prod.ini](ansible/inventory/prod.ini)
    - [ansible/inventory/template.yml](ansible/inventory/template.yml)
    - [ansible/inventory/templates/nginx.conf.j2](ansible/inventory/templates/nginx.conf.j2)
    - [ansible/inventory/templates/vector.toml.j2](ansible/inventory/templates/vector.toml.j2)
- [terraform/](terraform/) — Terraform-конфигурация:
  - [terraform/main.tf](terraform/main.tf)
  - [terraform/variables.tf](terraform/variables.tf)
  - [terraform/terraform.tfvars](terraform/terraform.tfvars)
  - [terraform/provider.tf](terraform/provider.tf)

## Быстрый старт

1) Установите зависимости:

```bash
# Terraform и Ansible должны быть установлены в системе
ansible --version
terraform --version
```

2) Подготовьте Terraform и создайте инфраструктуру:

```bash
cd terraform
terraform init
terraform plan -out plan.tfplan
terraform apply "plan.tfplan"
```

3) Сгенерируйте инвентарь (если используется скрипт):

```bash
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