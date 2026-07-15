"""Add profile working hours.

Revision ID: 002_profile_working_hours
Revises: 001_initial
Create Date: 2026-05-03
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "002_profile_working_hours"
down_revision = "001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("profiles", sa.Column("working_hours", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("profiles", "working_hours")
