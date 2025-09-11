# CI/CD Reusable Actions (Org-wide)

All org-wide reusable actions are maintained in this repo under `.github/actions/`.
Consumers in other repositories should reference actions via the full path:

```
uses: msdp-platform/msdp-devops-infrastructure/.github/actions/<action-name>@main
```

Recommendation: after releasing, pin a tag (e.g., `@v1`) instead of `@main`.
