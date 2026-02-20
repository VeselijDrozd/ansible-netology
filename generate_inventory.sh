#!/bin/bash

echo "🚀 Генерируем inventory из Terraform outputs..."

cd terraform
terraform output -raw inventory > ../ansible/inventory/prod.ini

echo "✅ Inventory создан: ansible/inventory/prod.ini"
cat ../ansible/inventory/prod.ini