# 🚨 Quick Reference - Architecture Anti-Patterns

## ❌ **NEVER DO THIS**

### **Kustomize + Helm Double Tooling**
```yaml
# DON'T - Unnecessary complexity
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
helmCharts:
  - name: grafana
    repo: https://grafana.github.io/helm-charts
    version: 6.61.0
```

### **Hardcoded Component Lists**
```yaml
# DON'T - Hard to maintain
components:
  - grafana
  - prometheus
  - argocd
  # Adding new component = editing multiple files
```

### **Manual Infrastructure Commands**
```bash
# DON'T - Inconsistent, error-prone
kubectl apply -f some-file.yaml
helm install grafana grafana/grafana
```

## ✅ **ALWAYS DO THIS**

### **Pure Helm for Charts**
```bash
# DO - Clean and simple
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values values.yaml \
  --create-namespace
```

### **Pure Kustomize for Custom YAML**
```bash
# DO - When you have custom manifests
kubectl apply -k infrastructure/platforms/networking/external-dns/
```

### **Configuration-Driven**
```yaml
# DO - Single source of truth
components:
  - name: grafana
    type: helm
    chart: grafana/grafana
    namespace: monitoring
```

### **GitHub Actions for Everything**
```yaml
# DO - Consistent, traceable
- name: Deploy Component
  uses: ./.github/actions/deploy-helm-component
  with:
    component: ${{ matrix.component }}
```

## 🎯 **Decision Tree**

```
New Component?
├── Has Helm Chart? → Use Pure Helm
├── Custom YAML? → Use Pure Kustomize
└── Need Both? → Split into separate components
```

## 📋 **Checklist Before Adding Components**

- [ ] Is it a Helm chart? → Use `deploy-helm-component` action
- [ ] Is it custom YAML? → Use `deploy-yaml-component` action
- [ ] Is it defined in `global.yaml`? → Add to component registry
- [ ] Does it follow DRY principles? → No repeated logic
- [ ] Is it modular? → Independent of other components

## 🚨 **Red Flags to Watch For**

- 🔴 **kustomization.yaml** with `helmCharts` section
- 🔴 **Hardcoded** component names in pipeline
- 🔴 **Manual** kubectl/helm commands
- 🔴 **Repeated** version checking logic
- 🔴 **Mixed** deployment strategies for same component

---

**Remember**: If it feels complex, it probably is. Keep it simple! 🎯
