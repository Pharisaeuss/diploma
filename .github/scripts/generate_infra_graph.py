#!/usr/bin/env python3
"""
generate_infra_graph.py
Parses all Terraform state files in a directory and produces a single
merged Graphviz DOT file (and optionally renders it to SVG/PNG).

Usage:
    python generate_infra_graph.py \
        --states-dir ./downloaded-states \
        --output    ./graphs/infra.dot \
        --format    svg          # also renders; omit to only emit .dot
        --env       dev          # label on the diagram title
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional

# ── resource-type → short display label ──────────────────────────────────────
TYPE_LABELS = {
    "aws_vpc":                        "VPC",
    "aws_subnet":                     "Subnet",
    "aws_internet_gateway":           "IGW",
    "aws_nat_gateway":                "NAT GW",
    "aws_route_table":                "Route Table",
    "aws_route_table_association":    "RT Assoc",
    "aws_security_group":             "SG",
    "aws_security_group_rule":        "SG Rule",
    "aws_lb":                         "ALB",
    "aws_lb_listener":                "LB Listener",
    "aws_lb_target_group":            "Target Group",
    "aws_autoscaling_group":          "ASG",
    "aws_autoscaling_attachment":     "ASG Attach",
    "aws_autoscaling_policy":         "ASG Policy",
    "aws_launch_template":            "Launch Tmpl",
    "aws_instance":                   "EC2",
    "aws_key_pair":                   "Key Pair",
    "aws_iam_role":                   "IAM Role",
    "aws_iam_policy":                 "IAM Policy",
    "aws_iam_role_policy_attachment": "IAM Attach",
    "aws_iam_instance_profile":       "Instance Profile",
    "aws_s3_bucket":                  "S3 Bucket",
    "aws_s3_bucket_policy":           "S3 Policy",
    "aws_rds_instance":               "RDS",
    "aws_db_subnet_group":            "DB Subnet Grp",
    "aws_elasticache_cluster":        "ElastiCache",
    "aws_cloudwatch_metric_alarm":    "CW Alarm",
    "aws_ssm_parameter":              "SSM Param",
    "aws_ecr_repository":             "ECR Repo",
    "aws_ecs_cluster":                "ECS Cluster",
    "aws_ecs_service":                "ECS Service",
    "aws_ecs_task_definition":        "ECS Task Def",
    "aws_route53_record":             "R53 Record",
    "aws_route53_zone":               "R53 Zone",
    "aws_acm_certificate":            "ACM Cert",
}

# ── resource-type → cluster color (Graphviz named colors) ────────────────────
TYPE_COLORS = {
    "network":   ("#dbeafe", "#1d4ed8"),  # blue family
    "compute":   ("#dcfce7", "#15803d"),  # green
    "storage":   ("#fef9c3", "#a16207"),  # yellow
    "database":  ("#ede9fe", "#6d28d9"),  # purple
    "security":  ("#fee2e2", "#b91c1c"),  # red
    "observ":    ("#f0fdf4", "#166534"),  # light green
    "default":   ("#f1f5f9", "#475569"),  # slate
}

def resource_category(rtype: str) -> str:
    if rtype in ("aws_vpc", "aws_subnet", "aws_internet_gateway",
                 "aws_nat_gateway", "aws_route_table",
                 "aws_route_table_association"):
        return "network"
    if rtype in ("aws_lb", "aws_lb_listener", "aws_lb_target_group",
                 "aws_autoscaling_group", "aws_autoscaling_attachment",
                 "aws_autoscaling_policy", "aws_launch_template",
                 "aws_instance", "aws_key_pair",
                 "aws_ecs_cluster", "aws_ecs_service", "aws_ecs_task_definition"):
        return "compute"
    if rtype in ("aws_s3_bucket", "aws_s3_bucket_policy",
                 "aws_ecr_repository"):
        return "storage"
    if rtype in ("aws_rds_instance", "aws_db_subnet_group",
                 "aws_elasticache_cluster"):
        return "database"
    if rtype in ("aws_security_group", "aws_security_group_rule",
                 "aws_iam_role", "aws_iam_policy",
                 "aws_iam_role_policy_attachment", "aws_iam_instance_profile",
                 "aws_acm_certificate"):
        return "security"
    if rtype in ("aws_cloudwatch_metric_alarm", "aws_ssm_parameter",
                 "aws_route53_record", "aws_route53_zone"):
        return "observ"
    return "default"


def safe_id(s: str) -> str:
    """Convert an arbitrary string to a valid Graphviz node id."""
    return re.sub(r"[^a-zA-Z0-9_]", "_", s)


def extract_name(resource: dict) -> str:
    """Try to pull a human-readable name out of resource attributes."""
    instances = resource.get("instances", [])
    if not instances:
        return resource.get("name", "")
    attrs = instances[0].get("attributes", {})
    for key in ("name", "id", "bucket", "parameter_name"):
        if attrs.get(key):
            val = str(attrs[key])
            # truncate long ARNs / bucket names
            if len(val) > 32:
                val = "…" + val[-28:]
            return val
    return resource.get("name", "")


def parse_state(path: Path) -> tuple[list[dict], list[tuple[str, str]]]:
    """
    Returns:
        resources  – list of dicts with keys: address, type, name, module, display
        edges      – list of (from_address, to_address)
    """
    with open(path) as f:
        state = json.load(f)

    resources = []
    edges = []

    for res in state.get("resources", []):
        rtype = res.get("type", "")
        # skip data sources — they don't represent real infra objects
        if res.get("mode") == "data":
            continue
        module = res.get("module", "root")
        name   = res.get("name", "")
        address = f"{module}.{rtype}.{name}" if module != "root" else f"{rtype}.{name}"

        display_type = TYPE_LABELS.get(rtype, rtype.replace("aws_", ""))
        display_name = extract_name(res)
        display = f"{display_type}\\n{display_name}" if display_name else display_type

        resources.append({
            "address":  address,
            "type":     rtype,
            "name":     name,
            "module":   module,
            "display":  display,
            "category": resource_category(rtype),
        })

        for dep in res.get("instances", [{}])[0].get("dependencies", []):
            edges.append((address, dep))

    return resources, edges


def build_dot(
    all_resources: list[dict],
    all_edges:     list[tuple[str, str]],
    env:           str,
) -> str:
    """Render the merged graph as a DOT string."""

    # index addresses for fast lookup
    addr_set = {r["address"] for r in all_resources}

    # group by module
    modules: dict[str, list[dict]] = {}
    for r in all_resources:
        modules.setdefault(r["module"], []).append(r)

    lines = [
        'digraph infra {',
        f'  label="Infrastructure — {env}";',
        '  labelloc=t; labeljust=l;',
        '  fontname="Helvetica,Arial,sans-serif"; fontsize=16;',
        '  rankdir=TB;',
        '  splines=ortho;',
        '  nodesep=0.5; ranksep=0.8;',
        '  node [fontname="Helvetica,Arial,sans-serif" fontsize=11',
        '        shape=box style="filled,rounded" margin="0.15,0.08"];',
        '  edge [fontname="Helvetica,Arial,sans-serif" fontsize=9',
        '        color="#94a3b8" arrowsize=0.7];',
        '',
    ]

    module_list = sorted(modules.keys())
    for idx, module in enumerate(module_list):
        mod_resources = modules[module]
        mod_label = module.replace("module.", "").replace("_", " ").title()

        # pick a bg color for this cluster based on majority category
        cats = [r["category"] for r in mod_resources]
        majority = max(set(cats), key=cats.count)
        bg, border = TYPE_COLORS.get(majority, TYPE_COLORS["default"])

        lines.append(f'  subgraph cluster_{safe_id(module)} {{')
        lines.append(f'    label="{mod_label}";')
        lines.append(f'    style="filled,rounded";')
        lines.append(f'    fillcolor="{bg}";')
        lines.append(f'    color="{border}";')
        lines.append(f'    fontcolor="{border}";')
        lines.append(f'    fontsize=13; fontname="Helvetica Bold,Arial,sans-serif";')
        lines.append( '    margin=16;')
        lines.append('')

        # within each module, group by category with invisible rank helpers
        by_cat: dict[str, list[dict]] = {}
        for r in mod_resources:
            by_cat.setdefault(r["category"], []).append(r)

        for cat, cat_resources in by_cat.items():
            bg_node, border_node = TYPE_COLORS.get(cat, TYPE_COLORS["default"])
            for r in cat_resources:
                nid = safe_id(r["address"])
                lines.append(
                    f'    {nid} [label="{r["display"]}" '
                    f'fillcolor="{bg_node}" color="{border_node}" '
                    f'fontcolor="{border_node}"];'
                )
        lines.append('  }')
        lines.append('')

    # edges — only between known resources
    lines.append('  // dependencies')
    seen_edges: set[tuple[str, str]] = set()
    for src, dst in all_edges:
        # normalise dst — state files sometimes prefix with module path
        if dst not in addr_set:
            # try without module prefix
            dst_short = dst.split(".")[-2] + "." + dst.split(".")[-1]
            match = next((a for a in addr_set if a.endswith(dst_short)), None)
            if not match:
                continue
            dst = match
        if src not in addr_set:
            continue
        key = (src, dst)
        if key in seen_edges:
            continue
        seen_edges.add(key)
        lines.append(f'  {safe_id(src)} -> {safe_id(dst)};')

    lines.append('}')
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description="tfstate → Graphviz diagram")
    parser.add_argument("--states-dir", default="./downloaded-states",
                        help="Directory containing .tfstate files")
    parser.add_argument("--output", default="./graphs/infra.dot",
                        help="Output .dot file path")
    parser.add_argument("--format", choices=["svg", "png", "pdf"],
                        help="Also render to this format via graphviz dot")
    parser.add_argument("--env", default="all",
                        help="Environment label (dev/stage/prod)")
    args = parser.parse_args()

    states_dir = Path(args.states_dir)
    state_files = list(states_dir.rglob("*.tfstate"))

    if not state_files:
        print(f"ERROR: no .tfstate files found in {states_dir}", file=sys.stderr)
        sys.exit(1)

    print(f"Found {len(state_files)} state file(s):")
    all_resources: list[dict] = []
    all_edges:     list[tuple[str, str]] = []

    for sf in sorted(state_files):
        module_name = sf.parent.name
        print(f"  parsing  {sf}  (module: {module_name})")
        try:
            res, edges = parse_state(sf)
            # prefix addresses with the directory module name when the state
            # itself uses "root" — makes cross-file edges readable
            for r in res:
                if r["module"] == "root":
                    r["module"] = f"module.{module_name}"
                    r["address"] = f"module.{module_name}.{r['type']}.{r['name']}"
            all_resources.extend(res)
            all_edges.extend(edges)
            print(f"           {len(res)} resources, {len(edges)} dep edges")
        except Exception as exc:
            print(f"  WARNING: could not parse {sf}: {exc}", file=sys.stderr)

    if not all_resources:
        print("ERROR: no resources found after parsing all state files.", file=sys.stderr)
        sys.exit(1)

    print(f"\nTotal: {len(all_resources)} resources, {len(all_edges)} edges")

    dot_str = build_dot(all_resources, all_edges, args.env)

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(dot_str)
    print(f"DOT written → {out_path}")

    if args.format:
        rendered = out_path.with_suffix(f".{args.format}")
        cmd = ["dot", f"-T{args.format}", str(out_path), "-o", str(rendered)]
        print(f"Rendering  → {rendered}")
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ERROR from graphviz:\n{result.stderr}", file=sys.stderr)
            sys.exit(1)
        print(f"Done       → {rendered}")


if __name__ == "__main__":
    main()