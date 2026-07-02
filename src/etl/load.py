import pandas as pd
import sqlalchemy as sa
from sqlalchemy import create_engine
import os
from datetime import datetime

# ========================= CONFIG =========================
# Change these according to your PostgreSQL setup
DB_USER = "postgres"          # your username
DB_PASSWORD = "hamza2002" # change this
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "ecommerce_db"

# Create connection string
DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(DATABASE_URL)

DATA_PATH = "data/raw/"
# =======================================================

def load_csv_to_db(file_name, table_name, if_exists='replace'):
    """Load CSV file into PostgreSQL table"""
    file_path = os.path.join(DATA_PATH, file_name)
    
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Loading {file_name} into table '{table_name}'...")
    
    # Read CSV
    df = pd.read_csv(file_path)
    
    # Basic cleaning
    df.columns = [col.lower().strip() for col in df.columns]
    
    # Convert date columns if they exist
    date_cols = [col for col in df.columns if 'date' in col or 'time' in col]
    for col in date_cols:
        try:
            df[col] = pd.to_datetime(df[col], errors='coerce')
        except:
            pass
    
    # Load to database
    df.to_sql(table_name, engine, if_exists=if_exists, index=False, method='multi', chunksize=10000)
    
    print(f"Loaded {len(df):,} rows into '{table_name}' table\n")

# ========================= MAIN =========================
if __name__ == "__main__":
    print("Starting ETL Process...\n")
    
    load_csv_to_db("customers.csv", "customers")
    load_csv_to_db("products.csv", "products")
    load_csv_to_db("sessions.csv", "sessions")
    load_csv_to_db("orders.csv", "orders")
    load_csv_to_db("order_items.csv", "order_items")
    load_csv_to_db("events.csv", "events")
    load_csv_to_db("reviews.csv", "reviews")
    
    print("All data loaded successfully!")