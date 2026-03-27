"""
Databasanslutning för Reflektionsarkiv.
Använder mysql-connector-python med dictionary cursor för enkel mappning.
"""
from contextlib import contextmanager

import mysql.connector
from mysql.connector import Error
from mysql.connector.cursor import MySQLCursorDict
from mysql.connector.connection_cext import CMySQLConnection
from mysql.connector.cursor_cext import CMySQLCursorDict

from app.config import settings
from app.text_encoding import repair_mojibake_utf8


def _repair_row_strings(row: dict | None) -> dict | None:
    if not row:
        return row
    return {k: repair_mojibake_utf8(v) if isinstance(v, str) else v for k, v in row.items()}


class RepairingCMySQLCursorDict(CMySQLCursorDict):
    """C-extension dict-cursor; rättar strängfält från UTF-8/latin-1-mojibake."""

    def fetchone(self):
        return _repair_row_strings(super().fetchone())

    def fetchmany(self, size: int = 1):
        return [_repair_row_strings(r) for r in super().fetchmany(size=size)]

    def fetchall(self):
        return [_repair_row_strings(r) for r in super().fetchall()]


class RepairingPyMySQLCursorDict(MySQLCursorDict):
    """Ren-Python dict-cursor (use_pure); samma reparation."""

    def _row_to_python(self, rowdata, desc=None):
        row = super()._row_to_python(rowdata, desc)
        return _repair_row_strings(row)


def repairing_dict_cursor(connection):
    """Rätt dict-cursor för anslutningstyp (C-ext eller ren Python)."""
    if isinstance(connection, CMySQLConnection):
        return connection.cursor(cursor_class=RepairingCMySQLCursorDict)
    return connection.cursor(cursor_class=RepairingPyMySQLCursorDict)


def get_connection():
    """
    Skapar en ny databasanslutning.
    Returnerar connection-objekt eller kastar vid fel.
    """
    try:
        conn = mysql.connector.connect(
            host=settings.DB_HOST,
            port=settings.DB_PORT,
            database=settings.DB_NAME,
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
            charset="utf8mb4",
            collation="utf8mb4_unicode_ci",
            use_unicode=True,
            init_command="SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci",
        )
        return conn
    except Error as e:
        raise RuntimeError(f"Databasanslutning misslyckades: {e}") from e


@contextmanager
def get_cursor(dictionary: bool = True):
    """
    Context manager för att hämta en cursor.
    dictionary=True (standard) ger dict-rader med ev. mojibake-reparerade strängar.
    """
    conn = get_connection()
    cursor = repairing_dict_cursor(conn) if dictionary else conn.cursor()
    try:
        yield cursor
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()


def check_db_connection() -> bool:
    """
    Kontrollerar om backend kan prata med databasen.
    Returnerar True om SELECT 1 lyckas.
    """
    try:
        with get_cursor() as cursor:
            cursor.execute("SELECT 1 AS ok")
            row = cursor.fetchone()
            return row is not None and row.get("ok") == 1
    except Exception:
        return False
