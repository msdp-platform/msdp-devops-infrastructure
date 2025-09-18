#!/usr/bin/env python3
"""External DNS plugin installer implemented in Python."""

from __future__ import annotations

import json
import logging
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional

import yaml


class InstallError(Exception):
    """Raised when installation cannot continue."""


def configure_logging() -> None:
    level_name = os.getenv("EXTERNAL_DNS_INSTALL_LOG_LEVEL", "INFO").upper()
    level = getattr(logging, level_name, logging.INFO)
    logging.basicConfig(level=level, format="%(levelname)s %(message)s")


def require_env(var_name: str, message: Optional[str] = None) -> str:
    value = os.getenv(var_name)
    if value in (None, ""):
        raise InstallError(message or f"Environment variable {var_name} must be set")
    return value


def optional_env(var_name: str, default: Optional[str] = None) -> Optional[str]:
    value = os.getenv(var_name)
    return value if value is not None else default


def detect_dns_provider() -> str:
    candidates = [
        optional_env("DNS_PROVIDER"),
        optional_env("EXTERNAL_DNS_PROVIDER"),
        optional_env("PROVIDER"),
        optional_env("CLOUD_PROVIDER"),
    ]
    for candidate in candidates:
        if candidate:
            return candidate.lower()
    raise InstallError("DNS provider could not be determined from environment")


def parse_domain_filters(raw: str) -> List[str]:
    raw = raw.strip()
    if not raw:
        return []
    if raw.startswith("["):
        try:
            parsed = json.loads(raw.replace("'", '"'))
            if isinstance(parsed, list):
                return [str(item).strip() for item in parsed if str(item).strip()]
        except json.JSONDecodeError:
            pass
    if "," in raw:
        return [segment.strip() for segment in raw.split(",") if segment.strip()]
    return [raw]


_TEMPLATE_PATTERN = re.compile(r"\$\{([A-Z0-9_]+)(:-([^}]*))?}" )


def render_template(content: str, env: Dict[str, str]) -> str:
    def replacer(match: re.Match[str]) -> str:
        var = match.group(1)
        default = match.group(3) if match.group(3) is not None else ""
        return env.get(var, default)

    return _TEMPLATE_PATTERN.sub(replacer, content)


def run_cmd(
    command: List[str],
    *,
    input_text: Optional[str] = None,
    capture_output: bool = False,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    logging.debug("Running command: %s", " ".join(command))
    result = subprocess.run(
        command,
        input=input_text,
        text=True,
        capture_output=capture_output,
        check=False,
    )
    if check and result.returncode != 0:
        stdout = result.stdout.strip() if result.stdout else ""
        stderr = result.stderr.strip() if result.stderr else ""
        raise InstallError(
            f"Command failed ({' '.join(command)}): return code {result.returncode}\n"
            f"stdout: {stdout}\nstderr: {stderr}"
        )
    return result


@dataclass
class InstallContext:
    plugin_name: str
    plugin_dir: Path
    namespace: str
    cloud_provider: str
    dns_provider: str
    environment: str
    cluster_name: str
    domain_filters: List[str]
    txt_owner_id: str
    txt_prefix: Optional[str]
    aws_auth_mode: Optional[str]
    aws_region: Optional[str]
    aws_credentials_secret_name: str
    aws_role_arn: Optional[str]
    aws_web_identity_token_file: Optional[str]
    plugin_version: str
    temp_values_file: Path


def gather_context() -> InstallContext:
    plugin_dir = Path(__file__).resolve().parent
    plugin_name = optional_env("PLUGIN_NAME", "external-dns")
    namespace = optional_env("NAMESPACE", "external-dns-system")
    cloud_provider = require_env("CLOUD_PROVIDER")
    dns_provider = detect_dns_provider()
    environment = optional_env("ENVIRONMENT", "")
    cluster_name = require_env("CLUSTER_NAME")
    domain_filters_raw = require_env("DOMAIN_FILTERS")
    domain_filters = parse_domain_filters(domain_filters_raw)
    if not domain_filters:
        raise InstallError("DOMAIN_FILTERS must contain at least one domain")
    txt_owner_id = require_env("TXT_OWNER_ID")
    txt_prefix = optional_env("TXT_PREFIX")
    plugin_version = optional_env("PLUGIN_VERSION", "1.13.1")
    aws_credentials_secret = optional_env(
        "AWS_CREDENTIALS_SECRET_NAME", "external-dns-aws-credentials"
    )

    aws_auth_mode: Optional[str] = None
    aws_region = None
    aws_role_arn = optional_env("AWS_ROLE_ARN")
    aws_web_identity_file = optional_env(
        "AWS_WEB_IDENTITY_TOKEN_FILE",
        "/var/run/secrets/azure/tokens/azure-identity-token",
    )

    if dns_provider == "aws":
        aws_region = require_env("AWS_REGION")
        access_key = optional_env("AWS_ACCESS_KEY_ID")
        secret_key = optional_env("AWS_SECRET_ACCESS_KEY")
        if access_key and secret_key:
            aws_auth_mode = "static"
        elif aws_role_arn:
            aws_auth_mode = "oidc"
        else:
            raise InstallError(
                "Either AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY or AWS_ROLE_ARN must be provided "
                "when using AWS as DNS provider"
            )

    if dns_provider == "azure":
        require_env("AZURE_SUBSCRIPTION_ID")
        require_env("AZURE_RESOURCE_GROUP")

    temp_values_path = Path(tempfile.gettempdir()) / f"external-dns-values-{cluster_name}.yaml"

    return InstallContext(
        plugin_name=plugin_name,
        plugin_dir=plugin_dir,
        namespace=namespace,
        cloud_provider=cloud_provider,
        dns_provider=dns_provider,
        environment=environment,
        cluster_name=cluster_name,
        domain_filters=domain_filters,
        txt_owner_id=txt_owner_id,
        txt_prefix=txt_prefix,
        aws_auth_mode=aws_auth_mode,
        aws_region=aws_region,
        aws_credentials_secret_name=aws_credentials_secret,
        aws_role_arn=aws_role_arn,
        aws_web_identity_token_file=aws_web_identity_file,
        plugin_version=plugin_version,
        temp_values_file=temp_values_path,
    )


def read_values_template(path: Path) -> Dict[str, Any]:
    if not path.exists():
        raise InstallError(f"Values file not found: {path}")
    content = path.read_text()
    rendered = render_template(content, dict(os.environ))
    data = yaml.safe_load(rendered) or {}
    if not isinstance(data, dict):
        raise InstallError(f"Unexpected data structure in values file: {path}")
    return data


def update_values_for_provider(context: InstallContext, values: Dict[str, Any]) -> None:
    if context.dns_provider == "aws":
        extra_env: List[Dict[str, Any]] = values.get("extraEnv", []) or []
        if context.aws_auth_mode == "oidc":
            extra_env.extend(
                [
                    {"name": "AWS_REGION", "value": context.aws_region},
                    {"name": "AWS_ROLE_ARN", "value": context.aws_role_arn},
                    {
                        "name": "AWS_WEB_IDENTITY_TOKEN_FILE",
                        "value": context.aws_web_identity_token_file,
                    },
                ]
            )
        elif context.aws_auth_mode == "static":
            extra_env.extend(
                [
                    {"name": "AWS_REGION", "value": context.aws_region},
                    {
                        "name": "AWS_ACCESS_KEY_ID",
                        "valueFrom": {
                            "secretKeyRef": {
                                "name": context.aws_credentials_secret_name,
                                "key": "aws-access-key-id",
                            }
                        },
                    },
                    {
                        "name": "AWS_SECRET_ACCESS_KEY",
                        "valueFrom": {
                            "secretKeyRef": {
                                "name": context.aws_credentials_secret_name,
                                "key": "aws-secret-access-key",
                            }
                        },
                    },
                ]
            )
        values["extraEnv"] = extra_env

    if context.dns_provider == "azure":
        azure_section = values.get("azure", {}) or {}
        azure_section["useManagedIdentityExtension"] = False
        azure_section.pop("userAssignedIdentityID", None)
        values["azure"] = azure_section

        service_account = values.get("serviceAccount")
        if isinstance(service_account, dict):
            service_account.pop("annotations", None)


def ensure_domain_filters(values: Dict[str, Any], context: InstallContext) -> None:
    existing = values.get("domainFilters")
    if isinstance(existing, list) and existing:
        return
    values["domainFilters"] = context.domain_filters


def ensure_txt_settings(values: Dict[str, Any], context: InstallContext) -> None:
    values["txtOwnerId"] = context.txt_owner_id
    if context.txt_prefix:
        values["txtPrefix"] = context.txt_prefix


def prepare_values_file(context: InstallContext) -> None:
    values_path = context.plugin_dir / "values" / f"{context.dns_provider}.yaml"
    values = read_values_template(values_path)

    update_values_for_provider(context, values)
    ensure_domain_filters(values, context)
    ensure_txt_settings(values, context)

    context.temp_values_file.write_text(yaml.safe_dump(values, sort_keys=False))
    logging.info("Prepared Helm values file: %s", context.temp_values_file)


def ensure_namespace(namespace: str) -> None:
    manifest = {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {"name": namespace},
    }
    run_cmd(["kubectl", "apply", "-f", "-"], input_text=yaml.safe_dump(manifest))


def label_namespace(namespace: str, labels: Dict[str, str]) -> None:
    for key, value in labels.items():
        run_cmd(
            [
                "kubectl",
                "label",
                "namespace",
                namespace,
                f"{key}={value}",
                "--overwrite",
            ]
        )


def configure_aws_secret(context: InstallContext) -> None:
    if context.aws_auth_mode != "static":
        return

    secret_cmd = [
        "kubectl",
        "create",
        "secret",
        "generic",
        context.aws_credentials_secret_name,
        "--namespace",
        context.namespace,
        f"--from-literal=aws-access-key-id={require_env('AWS_ACCESS_KEY_ID')}",
        f"--from-literal=aws-secret-access-key={require_env('AWS_SECRET_ACCESS_KEY')}",
        "--dry-run=client",
        "-o",
        "yaml",
    ]
    secret_manifest = run_cmd(secret_cmd, capture_output=True).stdout
    run_cmd(["kubectl", "apply", "-f", "-"], input_text=secret_manifest)
    logging.info(
        "Configured AWS credentials secret: %s", context.aws_credentials_secret_name
    )


def install_chart(context: InstallContext) -> None:
    run_cmd(["helm", "repo", "add", "external-dns", "https://kubernetes-sigs.github.io/external-dns/"])
    run_cmd(["helm", "repo", "update"])

    ensure_namespace(context.namespace)
    label_namespace(
        context.namespace,
        {
            "app.kubernetes.io/managed-by": "plugin-manager",
            "app.kubernetes.io/name": "external-dns",
        },
    )

    configure_aws_secret(context)

    run_cmd(
        [
            "helm",
            "upgrade",
            "--install",
            "external-dns",
            "external-dns/external-dns",
            "--namespace",
            context.namespace,
            "--values",
            str(context.temp_values_file),
            "--version",
            context.plugin_version,
            "--timeout",
            "300s",
            "--wait",
            "--atomic",
        ]
    )
    logging.info("External DNS Helm release applied successfully")


def health_check(context: InstallContext) -> None:
    run_cmd(
        [
            "kubectl",
            "wait",
            "--for=condition=available",
            "deployment/external-dns",
            "--namespace",
            context.namespace,
            "--timeout",
            "300s",
        ]
    )
    run_cmd(
        [
            "kubectl",
            "get",
            "pods",
            "-n",
            context.namespace,
            "-l",
            "app.kubernetes.io/name=external-dns",
        ]
    )

    result = run_cmd(
        [
            "kubectl",
            "get",
            "pods",
            "-n",
            context.namespace,
            "-l",
            "app.kubernetes.io/name=external-dns",
            "-o",
            "jsonpath={.items[0].metadata.name}",
        ],
        capture_output=True,
    )
    pod_name = result.stdout.strip()
    if pod_name:
        health_cmd = [
            "kubectl",
            "exec",
            "-n",
            context.namespace,
            pod_name,
            "--",
            "wget",
            "-q",
            "--spider",
            "http://localhost:7979/healthz",
        ]
        try:
            run_cmd(health_cmd)
            logging.info("Health endpoint responded successfully")
        except InstallError as exc:
            logging.warning("Health endpoint check failed: %s", exc)
        run_cmd(
            [
                "kubectl",
                "logs",
                "-n",
                context.namespace,
                pod_name,
                "--tail",
                "10",
            ]
        )


def verify_installation(context: InstallContext) -> None:
    run_cmd(["kubectl", "get", "all", "-n", context.namespace])
    run_cmd(["kubectl", "get", "serviceaccount", "-n", context.namespace])
    run_cmd(["kubectl", "get", "clusterrole", "-l", "app.kubernetes.io/name=external-dns"])
    run_cmd(
        [
            "kubectl",
            "get",
            "clusterrolebinding",
            "-l",
            "app.kubernetes.io/name=external-dns",
        ]
    )


def cleanup_on_failure(context: InstallContext) -> None:
    logging.info("Running cleanup after failure")
    run_cmd(
        ["helm", "uninstall", "external-dns", "--namespace", context.namespace],
        check=False,
    )
    run_cmd(
        ["kubectl", "delete", "namespace", context.namespace, "--ignore-not-found=true"],
        check=False,
    )


def print_summary(context: InstallContext) -> None:
    logging.info("Installation summary:")
    logging.info("  Namespace: %s", context.namespace)
    logging.info("  Cloud Provider: %s", context.cloud_provider)
    logging.info("  DNS Provider: %s", context.dns_provider)
    if context.aws_auth_mode:
        logging.info("  AWS Auth Mode: %s", context.aws_auth_mode)
        if context.aws_auth_mode == "static":
            logging.info(
                "  AWS Credentials Secret: %s", context.aws_credentials_secret_name
            )
    logging.info("  Domain Filters: %s", ", ".join(context.domain_filters))
    logging.info("  TXT Owner ID: %s", context.txt_owner_id)
    logging.info(
        "Check status with: kubectl get pods -n %s", context.namespace
    )


def main() -> None:
    configure_logging()
    try:
        context = gather_context()
        logging.info("Installing plugin: %s", context.plugin_name)
        logging.info("Environment: %s", context.environment)
        logging.info("Cloud Provider: %s", context.cloud_provider)
        logging.info("DNS Provider: %s", context.dns_provider)
        logging.info("Cluster: %s", context.cluster_name)

        prepare_values_file(context)
        install_chart(context)
        health_check(context)
        verify_installation(context)
        print_summary(context)
    except InstallError as exc:
        logging.error("Installation failed: %s", exc)
        try:
            context = locals().get("context")
            if isinstance(context, InstallContext):
                cleanup_on_failure(context)
        except Exception as cleanup_exc:  # pragma: no cover - best effort
            logging.error("Cleanup failed: %s", cleanup_exc)
        sys.exit(1)


if __name__ == "__main__":
    main()
