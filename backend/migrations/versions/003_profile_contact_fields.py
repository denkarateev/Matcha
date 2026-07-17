"""Add business contact fields to profiles.

Revision ID: 003_profile_contact_fields
Revises: 002_profile_working_hours
Create Date: 2026-07-17
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "003_profile_contact_fields"
down_revision = "002_profile_working_hours"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("profiles", sa.Column("contact_name", sa.Text(), nullable=True))
    op.add_column("profiles", sa.Column("contact_position", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("profiles", "contact_position")
    op.drop_column("profiles", "contact_name")
