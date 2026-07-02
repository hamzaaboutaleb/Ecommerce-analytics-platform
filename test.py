import os
from dotenv import load_dotenv

load_dotenv()

for key in [
    "DB_HOST",
    "DB_PORT",
    "DB_NAME",
    "DB_USER",
    "DB_PASSWORD",
]:
    value = os.getenv(key)
    print(key, repr(value))