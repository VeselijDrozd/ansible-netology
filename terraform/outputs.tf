output "clickhouse_ip" {
  value = yandex_compute_instance.clickhouse.network_interface.0.nat_ip_address
}

output "vector_ip" {
  value = yandex_compute_instance.vector.network_interface.0.nat_ip_address
}

output "lighthouse_ip" {
  value = yandex_compute_instance.lighthouse.network_interface.0.nat_ip_address
}

output "inventory" {
  value = <<-EOF
[clickhouse]
clickhouse-1 ansible_host=${yandex_compute_instance.clickhouse.network_interface.0.nat_ip_address} ansible_user=rocky

[vector]
vector-1 ansible_host=${yandex_compute_instance.vector.network_interface.0.nat_ip_address} ansible_user=rocky

[lighthouse]
lighthouse-1 ansible_host=${yandex_compute_instance.lighthouse.network_interface.0.nat_ip_address} ansible_user=rocky
  EOF
}