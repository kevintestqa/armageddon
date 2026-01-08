# Explanation: This is a private clinic front desk—internal LB means nobody outside the corridor can even knock.
resource "google_compute_region_health_check" "nihonmachi_hc01" {
  name   = "nihonmachi-hc01"
  region = var.gcp_region

  https_health_check {
    port = 443
    request_path = "/health"
  }
}

resource "google_compute_region_backend_service" "nihonmachi_backend01" {
  name                  = "nihonmachi-backend01"
  region                = var.gcp_region
  protocol              = "HTTPS"
  health_checks         = [google_compute_region_health_check.nihonmachi_hc01.id]
  load_balancing_scheme = "INTERNAL_MANAGED"

  backend {
    group = google_compute_region_instance_group_manager.nihonmachi_mig01.instance_group
  }
}

resource "google_compute_region_url_map" "nihonmachi_urlmap01" {
  name   = "nihonmachi-urlmap01"
  region = var.gcp_region

  default_service = google_compute_region_backend_service.nihonmachi_backend01.id
}

# Self-signed cert note:
# For simplicity, the instances terminate TLS themselves (Nginx on VM).
# ILB can be configured with certs too, but that’s "Lab 4A-3".
resource "google_compute_region_target_https_proxy" "nihonmachi_httpsproxy01" {
  name   = "nihonmachi-httpsproxy01"
  region = var.gcp_region
  url_map = google_compute_region_url_map.nihonmachi_urlmap01.id

  # Students: For full LB TLS termination, add SSL cert resources here (later).
  # For now: this proxy exists to model the pattern; TLS is handled at instances.
}

# Private forwarding rule (internal IP)
resource "google_compute_forwarding_rule" "nihonmachi_fr01" {
  name                  = "nihonmachi-fr01"
  region                = var.gcp_region
  load_balancing_scheme = "INTERNAL_MANAGED"
  ip_protocol           = "TCP"
  ports                 = ["443"]
  network               = google_compute_network.nihonmachi_vpc01.id
  subnetwork            = google_compute_subnetwork.nihonmachi_subnet01.id
  target                = google_compute_region_target_https_proxy.nihonmachi_httpsproxy01.id
}
