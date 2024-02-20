resource "helm_release" "delta-network-chart" {
    count            = var.is_delta_network_chart_enabled ? 1 : 0
    name             = "${var.delta_network_chart_namespace}-delta-network-chart-${var.k8s_cluster_version}"
    chart            = "${var.deltacm_home}/kubernetes/helmcharts/delta-network-chart/"
    create_namespace = true
    namespace        = var.delta_network_chart_namespace

    values = [
        "${fileexists("${var.deltacm_home}/kubernetes/values/delta-network-chart.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/delta-network-chart.values.yaml") : file("/dev/null")}",
        "${fileexists("${var.deltacm_home}/kubernetes/values/delta-network-chart.${var.delta_network_chart_namespace}.values.yaml") ? file("${var.deltacm_home}/kubernetes/values/delta-network-chart.${var.delta_network_chart_namespace}.values.yaml") : file("/dev/null")}"
    ]
}
