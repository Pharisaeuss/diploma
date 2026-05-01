"""
database.py — SQLAlchemy engine configured entirely from AWS SSM.

Boot sequence
─────────────
1. Read ENV and AWS_DEFAULT_REGION from the OS environment.
   These two non-secret values are written to SSM by Terraform at
   apply time (see /{env}/app/env and /{env}/app/region parameters).
   The systemd unit picks them up via EnvironmentFile=/etc/fastapi-crud/runtime.env,
   which is written by the boot script (scripts/fetch-runtime-env.sh) on first start.

2. All other config (DB credentials, etc.) is fetched from SSM at
   application startup — NOT baked into the AMI.

Why not .env for secrets?
   The AMI is built without any infrastructure existing yet.  Packer
   runs the Ansible playbook which installs code, venv, and the
   systemd unit — but there is no RDS endpoint to put in a .env file.
   On first EC2 boot the fetch-runtime-env.sh script (installed by
   Ansible) runs as a systemd oneshot *before* fastapi-crud.service
   and writes /etc/fastapi-crud/runtime.env.  fastapi-crud.service
   then reads that file via EnvironmentFile= so DATABASE_URL is
   available to this module when uvicorn imports it.
"""

import os
import logging
import boto3
from botocore.exceptions import ClientError
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

logger = logging.getLogger(__name__)

# ── 1. Non-secret bootstrap config ────────────────────────────────────────────
# Written to /etc/fastapi-crud/runtime.env by fetch-runtime-env.sh on first boot.
# Terraform pipeline stores these in SSM; they are NOT secrets.
ENV        = os.environ.get("ENV", "dev")
AWS_REGION = os.environ.get("AWS_DEFAULT_REGION", "eu-central-1")


# ── 2. SSM helper ─────────────────────────────────────────────────────────────
def _get_ssm(path: str, decrypt: bool = False) -> str:
    """Fetch a single SSM parameter. Raises RuntimeError on failure."""
    ssm = boto3.client("ssm", region_name=AWS_REGION)
    try:
        resp = ssm.get_parameter(Name=path, WithDecryption=decrypt)
        return resp["Parameter"]["Value"]
    except ClientError as e:
        code = e.response["Error"]["Code"]
        raise RuntimeError(
            f"SSM fetch failed for '{path}' (region={AWS_REGION}): {code}"
        ) from e


# ── 3. Build DATABASE_URL ──────────────────────────────────────────────────────
# Precedence:
#   a) DATABASE_URL env var  — set by fetch-runtime-env.sh at boot (preferred)
#   b) Individual SSM params  — fallback / local dev override
#   c) sqlite                 — unit-test / CI stub (no AWS creds needed)

def _build_database_url() -> str:
    # (a) already assembled by boot script
    if url := os.environ.get("DATABASE_URL"):
        logger.info("database: using DATABASE_URL from environment")
        return url

    # (b) individual SSM params (local dev / first-boot fallback)
    try:
        host     = _get_ssm(f"/{ENV}/database/endpoint")
        port     = _get_ssm(f"/{ENV}/database/port")
        name     = _get_ssm(f"/{ENV}/database/name")
        user     = _get_ssm(f"/{ENV}/database/username")
        password = _get_ssm(f"/{ENV}/database/password", decrypt=True)
        url = f"postgresql://{user}:{password}@{host}:{port}/{name}"
        logger.info("database: assembled URL from SSM params (env=%s)", ENV)
        return url
    except RuntimeError as e:
        logger.warning("database: SSM unavailable (%s) — falling back to sqlite", e)

    # (c) local CI stub
    return "sqlite:///./test.db"


DATABASE_URL = _build_database_url()

engine = create_engine(
    DATABASE_URL,
    # sqlite needs different connect_args
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
    pool_pre_ping=True,   # reconnect on stale connections (critical for RDS)
    pool_size=5,
    max_overflow=10,
    pool_recycle=300,     # avoid RDS idle-timeout disconnects
    echo=False,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()