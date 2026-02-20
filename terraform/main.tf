# Создание сети
resource "yandex_vpc_network" "network" {
  name = "clickhouse-network"
}

# Создание подсети
resource "yandex_vpc_subnet" "subnet" {
  name           = "clickhouse-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# 1. Группа безопасности для ClickHouse
resource "yandex_vpc_security_group" "clickhouse-sg" {
  name        = "clickhouse-sg"
  description = "Security group for ClickHouse server"
  network_id  = yandex_vpc_network.network.id

  # SSH для управления
  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # HTTP интерфейс ClickHouse (для Vector и Lighthouse)
  ingress {
    protocol       = "TCP"
    description    = "ClickHouse HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8123
  }

  # Нативный TCP протокол ClickHouse (для клиентов)
  ingress {
    protocol       = "TCP"
    description    = "ClickHouse Native"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 9000
  }

  # Ping для диагностики
  ingress {
    protocol       = "ICMP"
    description    = "ICMP Ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Весь исходящий трафик разрешен
  egress {
    protocol       = "ANY"
    description    = "Any outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# 2. Группа безопасности для Vector
resource "yandex_vpc_security_group" "vector-sg" {
  name        = "vector-sg"
  description = "Security group for Vector"
  network_id  = yandex_vpc_network.network.id

  # SSH для управления
  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # API Vector (для мониторинга)
  ingress {
    protocol       = "TCP"
    description    = "Vector API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8686
  }

  # Доступ к ClickHouse из Vector (по внутренней сети)
  ingress {
    protocol       = "TCP"
    description    = "Access to ClickHouse from Vector"
    v4_cidr_blocks = ["192.168.10.0/24"]
    port           = 8123
  }

  # Ping для диагностики
  ingress {
    protocol       = "ICMP"
    description    = "ICMP Ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Any outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# 3. Группа безопасности для Lighthouse
resource "yandex_vpc_security_group" "lighthouse-sg" {
  name        = "lighthouse-sg"
  description = "Security group for Lighthouse (Nginx)"
  network_id  = yandex_vpc_network.network.id

  # SSH для управления
  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # HTTP для Lighthouse
  ingress {
    protocol       = "TCP"
    description    = "HTTP for Lighthouse"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  # HTTPS (на будущее)
  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  # Доступ к ClickHouse из Lighthouse (для API запросов)
  ingress {
    protocol       = "TCP"
    description    = "Access to ClickHouse from Lighthouse"
    v4_cidr_blocks = ["192.168.10.0/24"]
    port           = 8123
  }

  # Ping для диагностики
  ingress {
    protocol       = "ICMP"
    description    = "ICMP Ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Any outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Поиск образа Rocky Linux 9
data "yandex_compute_image" "rocky" {
  family = "rocky-9-oslogin"
}

# ВМ для ClickHouse
resource "yandex_compute_instance" "clickhouse" {
  name        = "clickhouse-1"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.rocky.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.clickhouse-sg.id]
  }

  metadata = {
    ssh-keys = "${var.vm_user}:${file(var.public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

# ВМ для Vector
resource "yandex_compute_instance" "vector" {
  name        = "vector-1"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.rocky.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.vector-sg.id]
  }

  metadata = {
    ssh-keys = "${var.vm_user}:${file(var.public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

# ВМ для Lighthouse
resource "yandex_compute_instance" "lighthouse" {
  name        = "lighthouse-1"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.rocky.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.lighthouse-sg.id]
  }

  metadata = {
    ssh-keys = "${var.vm_user}:${file(var.public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}