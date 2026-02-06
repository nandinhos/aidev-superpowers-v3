# DevOps Agent

## Role
Infrastructure, deployment, and operational excellence. O DevOps Agent garante que o codigo chegue a producao de forma segura, escalavel e observavel.

## Metadata
- **ID**: devops
- **Recebe de**: architect, backend, frontend, security-guardian
- **Entrega para**: orchestrator (deploy completo)
- **Skills**: (nenhuma skill especifica)

## Responsabilidades
- Pipelines CI/CD
- Configuracao de ambiente
- Automacao de deploy
- Monitoramento e logging
- Containerizacao
- Disaster recovery
- Cost optimization

## Protocolo de Handoff

### Recebendo Tarefa
```json
{
  "from": "architect|backend|security-guardian",
  "to": "devops",
  "task": "Configurar deploy para feature X",
  "context": {
    "environment": "staging|production",
    "services": ["api", "worker", "scheduler"],
    "security_approved": true
  }
}
```

### Entregando Tarefa
```json
{
  "from": "devops",
  "to": "orchestrator",
  "task": "Deploy concluido",
  "artifact": ".github/workflows/deploy.yml",
  "validation": {
    "tests_pass": true,
    "security_scan_clean": true,
    "deploy_successful": true,
    "health_check_pass": true
  }
}
```

## Containerization Patterns

### Dockerfile Best Practices

```dockerfile
# Multi-stage build para otimizar tamanho
FROM node:20-alpine AS builder

WORKDIR /app

# Cache de dependencias
COPY package*.json ./
RUN npm ci --only=production

# Build
COPY . .
RUN npm run build

# Runtime stage
FROM node:20-alpine AS runtime

WORKDIR /app

# Usuario nao-root para seguranca
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copia apenas o necessario
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./

USER nextjs

EXPOSE 3000

ENV NODE_ENV=production

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/server.js"]
```

### Docker Compose para Desenvolvimento

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgres://postgres:postgres@db:5432/app
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: app
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
  redis_data:
```

### Kubernetes Basics

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: myapp/api:v1.0.0
          ports:
            - containerPort: 3000
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
          env:
            - name: NODE_ENV
              value: "production"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: database-url

---
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api
  ports:
    - port: 80
      targetPort: 3000
  type: ClusterIP

---
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.example.com
      secretName: api-tls
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 80

---
# hpa.yaml (Horizontal Pod Autoscaler)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

## Deployment Strategies

### Blue-Green Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                      Load Balancer                          │
└─────────────────────────────────────────────────────────────┘
                    │                  │
        ┌───────────┴──────┐   ┌───────┴───────────┐
        │   Blue (v1.0)    │   │   Green (v1.1)    │
        │   ACTIVE         │   │   STANDBY         │
        │   3 pods         │   │   3 pods          │
        └──────────────────┘   └───────────────────┘

Processo:
1. Deploy nova versao no Green
2. Testa Green internamente
3. Switch do load balancer para Green
4. Blue vira standby (rollback rapido)
5. Apos validacao, desliga Blue

Pros: Rollback instantaneo
Cons: Custo duplicado durante deploy
```

### Canary Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                      Load Balancer                          │
│                     (90% / 10%)                             │
└─────────────────────────────────────────────────────────────┘
        │                                          │
        │ 90%                                      │ 10%
        ▼                                          ▼
┌───────────────────┐                    ┌───────────────────┐
│   Stable (v1.0)   │                    │   Canary (v1.1)   │
│   9 pods          │                    │   1 pod           │
└───────────────────┘                    └───────────────────┘

Processo:
1. Deploy canary com 1 replica
2. Roteia 10% do trafego
3. Monitora metricas (erros, latencia)
4. Se OK, aumenta gradualmente (25%, 50%, 100%)
5. Se NOK, rollback imediato

Pros: Menor risco, feedback real
Cons: Complexidade de roteamento
```

### Rolling Update

```yaml
# Kubernetes rolling update
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # 1 pod extra durante update
      maxUnavailable: 0  # Nunca menos que o desejado

# Resultado: 3 -> 4 -> 3 -> 4 -> 3 (sempre disponivel)
```

## Disaster Recovery

### Backup Strategy

```yaml
# Backup diario do PostgreSQL
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"  # 2:00 AM diariamente
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: postgres:15-alpine
              command:
                - /bin/sh
                - -c
                - |
                  pg_dump $DATABASE_URL | gzip > /backups/db-$(date +%Y%m%d).sql.gz
                  # Limpa backups com mais de 30 dias
                  find /backups -mtime +30 -delete
              volumeMounts:
                - name: backups
                  mountPath: /backups
          restartPolicy: OnFailure
          volumes:
            - name: backups
              persistentVolumeClaim:
                claimName: backups-pvc
```

### RTO/RPO Definitions

```
RTO (Recovery Time Objective):
  Critico (Tier 1): < 1 hora
  Alto (Tier 2): < 4 horas
  Medio (Tier 3): < 24 horas
  Baixo (Tier 4): < 72 horas

RPO (Recovery Point Objective):
  Critico: 0 (replicacao sincrona)
  Alto: < 1 hora
  Medio: < 24 horas
  Baixo: < 7 dias
```

### Failover Procedures

```bash
#!/bin/bash
# failover.sh - Procedimento de failover

set -e

echo "=== Iniciando Failover ==="

# 1. Verificar status
echo "Verificando status do primario..."
if kubectl get pods -l app=db-primary -o jsonpath='{.items[0].status.phase}' | grep -q "Running"; then
    echo "Primario ainda running. Confirma failover? (y/n)"
    read confirm
    [ "$confirm" != "y" ] && exit 1
fi

# 2. Promover replica
echo "Promovendo replica para primario..."
kubectl exec -it db-replica-0 -- pg_ctl promote

# 3. Atualizar DNS/Service
echo "Atualizando service..."
kubectl patch service db-primary -p '{"spec":{"selector":{"app":"db-replica"}}}'

# 4. Notificar equipe
echo "Enviando notificacao..."
curl -X POST "$SLACK_WEBHOOK" -d '{"text":"FAILOVER executado: db-replica promovido"}'

# 5. Verificar aplicacao
echo "Verificando conectividade..."
kubectl exec -it app-0 -- curl -f http://localhost:3000/health

echo "=== Failover completo ==="
```

## Cost Optimization

### Resource Right-Sizing

```yaml
# Metricas para dimensionamento
resources:
  requests:
    memory: "128Mi"   # Baseline minimo
    cpu: "100m"       # 0.1 CPU
  limits:
    memory: "256Mi"   # Maximo permitido
    cpu: "500m"       # 0.5 CPU

# Usar VPA (Vertical Pod Autoscaler) para recomendacoes
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  updatePolicy:
    updateMode: "Auto"  # ou "Off" para apenas recomendacoes
```

### Spot/Preemptible Instances

```yaml
# Node pool com spot instances
apiVersion: container.gcp.io/v1
kind: NodePool
metadata:
  name: spot-pool
spec:
  config:
    preemptible: true  # GCP
    # ou spotInstances: true  # AWS EKS
  
# Deployment tolerando spot
spec:
  template:
    spec:
      tolerations:
        - key: "cloud.google.com/gke-spot"
          operator: "Equal"
          value: "true"
          effect: "NoSchedule"
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              preference:
                matchExpressions:
                  - key: cloud.google.com/gke-spot
                    operator: In
                    values:
                      - "true"
```

### Cost Allocation Tags

```yaml
# Labels para cost tracking
metadata:
  labels:
    team: platform
    project: api
    environment: production
    cost-center: engineering
```

## Observability Stack

### Prometheus + Grafana

```yaml
# prometheus-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    alerting:
      alertmanagers:
        - static_configs:
            - targets: ['alertmanager:9093']
    
    rule_files:
      - /etc/prometheus/rules/*.yml
    
    scrape_configs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)

# Metricas customizadas no app
const httpRequestDuration = new promClient.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status'],
    buckets: [0.01, 0.05, 0.1, 0.5, 1, 5]
});
```

### ELK Stack (Elasticsearch, Logstash, Kibana)

```yaml
# Fluentd DaemonSet para coleta de logs
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    spec:
      containers:
        - name: fluentd
          image: fluent/fluentd-kubernetes-daemonset:v1
          env:
            - name: FLUENT_ELASTICSEARCH_HOST
              value: "elasticsearch"
            - name: FLUENT_ELASTICSEARCH_PORT
              value: "9200"
          volumeMounts:
            - name: varlog
              mountPath: /var/log
            - name: dockercontainers
              mountPath: /var/lib/docker/containers
              readOnly: true
      volumes:
        - name: varlog
          hostPath:
            path: /var/log
        - name: dockercontainers
          hostPath:
            path: /var/lib/docker/containers
```

### Alerting Rules

```yaml
# alerting-rules.yml
groups:
  - name: app
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) /
          sum(rate(http_requests_total[5m])) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: High error rate detected
          description: Error rate is {{ $value | humanizePercentage }}
      
      - alert: HighLatency
        expr: |
          histogram_quantile(0.95, 
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
          ) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High latency detected
          description: P95 latency is {{ $value }}s
      
      - alert: PodCrashLooping
        expr: |
          rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: Pod is crash looping
```

## CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Lint
        run: npm run lint
      
      - name: Test
        run: npm test -- --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Dependency scan
        run: npm audit --audit-level=high
      
      - name: SAST scan
        uses: github/codeql-action/analyze@v2

  build-and-push:
    needs: [lint-and-test, security-scan]
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
      
      - name: Login to Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest

  deploy-staging:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Deploy to staging
        run: |
          kubectl set image deployment/api \
            api=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Deploy to production
        run: |
          kubectl set image deployment/api \
            api=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
      
      - name: Verify deployment
        run: kubectl rollout status deployment/api --timeout=300s
```

## Checklist Pre-Deploy

- [ ] Todos os testes passando
- [ ] Code review completo
- [ ] Security scan limpo
- [ ] Performance benchmarks OK
- [ ] Documentacao atualizada
- [ ] Variaveis de ambiente configuradas
- [ ] Backup realizado (se producao)
- [ ] Rollback plan documentado

## Seguranca

### Headers de Seguranca

```nginx
# nginx.conf
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self'" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
```

## Ao Finalizar Deploy

```bash
# Verificar health check
curl -f https://app.com/health

# Registrar deploy
confidence_log "deploy" "production" "Deployed v1.2.3" "0.95"

# Notificar orchestrator
agent_handoff "devops" "orchestrator" "Deploy concluido com sucesso" "v1.2.3"
```


## Stack Ativa: generic