SHELL=/bin/bash

BASE_DIR := manifests

.PHONY: clean
clean: clean-image clean-jop

.PHONY: clean-image
clean-image:
	docker container prune -f
	docker image prune -a

.PHONY: clean-jop
clean-job:
	kubectl delete jobs $(shell kubectl get jobs -o jsonpath="{.items[?(@.status.succeeded==1)].metadata.name}")

.PHONY: install
install: init-cluster install-metrics-server install-mysql install-postgres install-redis install-mailhog install-minio install-elasticsearch install-jaeger install-prometheus install-thanos install-grafana install-promtail install-loki install-kibana install-ingress

.PHONY: init-cluster
init-cluster:
	kubectl apply -f $(BASE_DIR)/namespaces.yaml
	helm repo add stable https://kubernetes-charts.storage.googleapis.com
	helm repo add codecentric https://codecentric.github.io/helm-charts
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo add loki https://grafana.github.io/loki/charts
	helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
	helm repo add elastic https://helm.elastic.co
	helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
	helm repo add banzaicloud https://kubernetes-charts.banzaicloud.com
	helm repo update

.PHONY: install-metrics-server
install-metrics-server:
	$(eval namespace := kube-system)
	helm upgrade -i metrics-server \
		--namespace $(namespace) \
		--set args={--kubelet-insecure-tls} \
		stable/metrics-server \
		--wait

.PHONY: install-mysql
install-mysql:
	$(eval namespace := ds)
	helm dependency update --skip-refresh charts/mysql
	helm upgrade -i mysql --namespace $(namespace) charts/mysql \
		--set hostPath="$(HOME)/.docker/Volumes/mysql" \
		--wait

.PHONY: install-postgres
install-postgres:
	$(eval namespace := ds)
	helm upgrade -i postgres --namespace $(namespace) -f charts/postgres/values.yaml stable/postgresql --wait

.PHONY: install-redis
install-redis:
	$(eval namespace := ds)
	helm upgrade -i redis --namespace $(namespace) -f charts/redis/values.yaml bitnami/redis --wait

.PHONY: install-mailhog
install-mailhog:
	$(eval namespace := ds)
	helm upgrade -i mailhog --namespace $(namespace) -f charts/mailhog/values.yaml codecentric/mailhog --wait

.PHONY: install-minio
install-minio:
	$(eval namespace := ds)
	helm upgrade -i minio stable/minio \
		--namespace $(namespace) \
		-f charts/minio/values.yaml \
		--version=5.0.15 \
		--wait

.PHONY: install-elasticsearch
install-elasticsearch:
	$(eval namespace := ds)
	helm upgrade -i elasticsearch --namespace $(namespace) -f charts/elasticsearch/values.yaml elastic/elasticsearch

.PHONY: install-jaeger
install-jaeger:
	$(eval namespace := monitoring)
	helm upgrade -i jaeger --namespace $(namespace) --wait -f charts/jaeger/values.yaml jaegertracing/jaeger

.PHONY: install-ingress
install-ingress:
	$(eval namespace := kube-system)
	helm upgrade -i nginx-ingress stable/nginx-ingress \
		--namespace $(namespace) \
		-f charts/nginx-ingress/values.yaml \
		--version=1.33.0

.PHONY: install-promtail
install-promtail:
	$(eval namespace := monitoring)
	helm upgrade -i promtail loki/promtail \
		--namespace $(namespace) \
		-f charts/promtail/values.yaml \
		--version=0.22.1 \
		--wait

.PHONY: install-loki
install-loki:
	$(eval namespace := monitoring)
	helm upgrade -i loki loki/loki \
		--namespace $(namespace) \
		-f charts/loki/values.yaml \
		--version=0.28.1

.PHONY: install-prometheus
install-prometheus:
	$(eval namespace := monitoring)
	helm upgrade -i prometheus stable/prometheus \
		--namespace $(namespace) \
		-f charts/prometheus/values.yaml \
		--version=11.0.2

.PHONY: install-grafana
install-grafana:
	$(eval namespace := monitoring)
	helm upgrade -i grafana --namespace $(namespace) -f charts/grafana/values.yaml stable/grafana

.PHONY: install-kibana
install-kibana:
	$(eval namespace := monitoring)
	helm upgrade -i kibana --namespace $(namespace) -f charts/kibana/values.yaml elastic/kibana

.PHONY: install-thanos
install-thanos:
	$(eval namespace := monitoring)
	helm upgrade -i thanos banzaicloud/thanos \
		--namespace $(namespace) \
		-f charts/thanos/values.yaml \
		--version=0.3.18 \
		--wait
