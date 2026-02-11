import sqlite3
import pandas as pd
import os

import csv
from tqdm import tqdm

def create_database(connection):
    """
    Creates the new database
    """
    all_csvs = [f for f in os.listdir('datasets') if f.endswith('.csv')]

    for file in all_csvs:
        table_name = file.replace(".csv", "").replace("olist_", "").replace("_dataset", "")

        path = os.path.join("datasets", file)
        df = pd.read_csv(path)
        df.to_sql(table_name, connection, if_exists = "replace", index = False)

    connection.close()
    return

def convert_to_csv(connection, list_of_tables: str|list):
    """
    Converts given tables to a .csv file.
    """
    if not isinstance(list_of_tables, list):
        list_of_tables = [list_of_tables]

    cursor = connection.cursor()

    for file in list_of_tables:
        print(f"Starting to convert {file}.")
        cursor.execute(f"SELECT * FROM {file};")

        filename = f"completed_datasets/{file}.csv"
        with open(filename, "w", newline="") as csv_file:
            print(f"Opened {filename}.")
            csv_writer = csv.writer(csv_file)
            headers = [column[0] for column in cursor.description]

            csv_writer.writerow(headers)
            for row in tqdm(cursor):
                csv_writer.writerow(row)
            # csv_writer.writerows(cursor)
    return


def main():
    conn = sqlite3.connect("olist_ecommerce.db")

    creates: bool = False
    if creates == True:
        create_database(conn)

    transfers: bool = True
    if transfers == True:
        convert_to_csv(conn, "eda_olist_complete")

if __name__ == "__main__":
    main()
