#!/usr/bin/env python3
"""
Simple Python script to insert rows into a PostgreSQL database.
Database connection parameters are read from environment variables.
"""

import os
import sys
import time

import psycopg2
from psycopg2 import Error, OperationalError


def get_db_config():
    """Get database configuration from environment variables."""
    config = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": int(os.getenv("DB_PORT", 5432)),
        "user": os.getenv("DB_USERNAME"),
        "password": os.getenv("DB_PASSWORD"),
        "database": os.getenv("DB_NAME", "db1"),
        "batch_size": int(os.getenv("BATCH_SIZE", 1)),
        "batch_count": int(os.getenv("BATCH_COUNT", 1)),
        "sleep_ms": int(os.getenv("SLEEP_MS", 1000)),
        "message_length": int(os.getenv("MESSAGE_LENGTH", 1000)),
    }

    if not config["user"] or not config["password"]:
        print("Error: DB_USERNAME and DB_PASSWORD environment variables are required")
        sys.exit(1)

    return config


def create_connection(config):
    """Create a database connection."""
    try:
        connection = psycopg2.connect(
            user=config["user"],
            password=config["password"],
            host=config["host"],
            port=config["port"],
            dbname=config["database"],
        )
        print(
            f"Successfully connected to PostgreSQL database at {config['host']}:{config['port']}"
        )
        return connection
    except Error as e:
        print(f"Error connecting to PostgreSQL: {e}")
        return None


def reconnect_forever(config):
    """Block until a new connection can be established (same intent as mysql reconnect loop)."""
    while True:
        print("Connection lost. Reconnecting...")
        conn = create_connection(config)
        if conn is not None and not conn.closed:
            return conn
        time.sleep(5)


def create_sample_table(connection):
    """Create a sample table for demonstration."""
    cursor = connection.cursor()
    
    create_table_query = """
    CREATE TABLE IF NOT EXISTS messages (
        id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
        message TEXT NOT NULL
    )
    """

    try:
        cursor.execute(create_table_query)
        connection.commit()
        print("Sample table 'messages' created successfully")
    except Error as e:
        print(f"Error creating table: {e}")
    finally:
        cursor.close()


def insert_sample_data(connection, batch_size, message_length):
    """Insert sample data into the messages table."""
    cursor = connection.cursor()

    insert_query = """
    INSERT INTO messages (created_at, message)
    VALUES (NOW(), %s)
    """
    messages_data = [
        (str(i).zfill(9) + "".rjust(message_length - 9, "."),)
        for i in range(batch_size)
    ]
    try:
        cursor.executemany(insert_query, messages_data)
        connection.commit()
        inserted = cursor.rowcount if cursor.rowcount >= 0 else batch_size
        print(f"Successfully inserted {inserted} rows into messages table")

        cursor.execute("SELECT COUNT(*) FROM messages")
        count = cursor.fetchone()[0]
        print(f"Total number of rows in messages table: {count}")

        cursor.execute("SELECT * FROM messages ORDER BY id DESC LIMIT 1")
        rows = cursor.fetchall()

        print("\nRecently inserted messages:")
        print("-" * 80)
        print(f"{'ID':<5} {'Date':<26} {'Message':<60}")
        print("-" * 80)

        for row in rows:
            print(f"{row[0]:<5} {str(row[1]):<26} {row[2]:<60}")

    except Error as e:
        print(f"Error inserting data: {e}")
        connection.rollback()
        raise
    finally:
        cursor.close()


def main():
    """Main function to demonstrate PostgreSQL insertion."""
    print("PostgreSQL Database Insert Script")
    print("=" * 40)

    config = get_db_config()
    print(
        f"Connecting to database '{config['database']}' at {config['host']}:{config['port']}"
    )

    connection = create_connection(config)

    if not connection:
        sys.exit(1)

    create_sample_table(connection)

    try:
        for i in range(config["batch_count"]):
            try:
                print(f"\n--- Batch {i + 1}/{config['batch_count']} ---")
                insert_sample_data(
                    connection, config["batch_size"], config["message_length"]
                )
                print(f"Sleeping for {config['sleep_ms']} ms...")
                time.sleep(config["sleep_ms"] / 1000)
            except OperationalError:
                connection = reconnect_forever(config)
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        if connection is not None and not connection.closed:
            connection.close()
            print("\nPostgreSQL connection closed")


if __name__ == "__main__":
    main()
