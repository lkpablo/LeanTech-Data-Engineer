
import csv
import random
from datetime import date, timedelta
from pathlib import Path

SEED = 42
DATA_DIR = Path(__file__).resolve().parent
N_CUSTOMERS, N_PRODUCTS, N_SALES = 200, 50, 5000
FIRST_SALE, LAST_SALE = date(2025, 1, 1), date(2026, 9, 30)

FIRST_NAMES = ["Ana", "Luis", "Maria", "John", "Emma", "Carlos", "Sofia", "Liam", "Lucia", "Noah",
               "Valentina", "James", "Camila", "Oliver", "Isabella", "Mateo", "Mia", "Lucas", "Elena", "Daniel"]
LAST_NAMES = ["Garcia", "Smith", "Rodriguez", "Johnson", "Martinez", "Brown", "Lopez", "Williams", "Gonzalez",
              "Jones", "Perez", "Miller", "Sanchez", "Davis", "Ramirez", "Wilson", "Torres", "Moore", "Flores", "Taylor"]
DOMAINS = ["gmail.com", "outlook.com", "yahoo.com", "icloud.com"]


COUNTRIES = [
    "United States", "USA", "U.S.A.", "united states", "Colombia", "colombia ", "Mexico", "México",
    "Brazil", "Brasil", "United Kingdom", "UK", "Germany", "Spain", "España", "Canada", "France",
    "Argentina", "Chile", "Peru", "Perú",
]
CATEGORIES = {
    "Electronics": ["Headphones", "Keyboard", "Monitor", "Webcam", "Speaker"],
    "Home": ["Lamp", "Chair", "Desk", "Shelf", "Rug"],
    "Sports": ["Yoga Mat", "Dumbbell", "Bike Helmet", "Water Bottle", "Running Belt"],
    "Books": ["Novel", "Cookbook", "Atlas", "Biography", "Comic"],
    "Toys": ["Puzzle", "Board Game", "Robot Kit", "Building Set", "Plush"],
}


def write(name, header, rows):
    with open(DATA_DIR / name, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)


def customers():
    rows = []
    for customer_id in range(1, N_CUSTOMERS + 1):
        first, last = random.choice(FIRST_NAMES), random.choice(LAST_NAMES)
        email = f"{first}.{last}{customer_id}@{random.choice(DOMAINS)}".lower()
        rows.append([customer_id, f"{first} {last}", email, random.choice(COUNTRIES)])

    planted = {}
    picks = iter(random.sample(range(N_CUSTOMERS), 18))
    for _ in range(5):                                   
        rows[next(picks)][2] = ""
    for bad in ["ana.garcia@", "luis.lopez.gmail.com", "maria@@yahoo.com", "john smith@gmail.com", "n/a"]:
        rows[next(picks)][2] = bad                       
    for bad in ["", "Narnia", "Atlantis", "XX"]:         
        rows[next(picks)][3] = bad
    for _ in range(2):                                   
        rows[next(picks)][1] = ""
    for i in (next(picks), next(picks)):                 
        rows.append([rows[i][0], rows[i][1], rows[i][2].replace("@", ".new@") or "dup@gmail.com", rows[i][3]])
    planted.update(missing_email=5, malformed_email=5, missing_or_unknown_country=4, missing_name=2, duplicate_id=2)
    return rows, planted


def products():
    rows = []
    product_id = 1
    for category, names in CATEGORIES.items():
        for name in names:
            for variant in ("Basic", "Pro"):
                rows.append([product_id, f"{name} {variant}", category, f"{random.uniform(5, 400):.2f}"])
                product_id += 1
    picks = iter(random.sample(range(N_PRODUCTS), 7))
    for bad in ["-15.00", "-120.50"]:                    
        rows[next(picks)][3] = bad
    for _ in range(2):                                   
        rows[next(picks)][3] = ""
    rows[next(picks)][3] = "N/A"                         
    for _ in range(2):                                   
        rows[next(picks)][2] = ""
    return rows, dict(negative_price=2, missing_price=2, non_numeric_price=1, missing_category=2)


def sales(prices):
    rows = []
    days = (LAST_SALE - FIRST_SALE).days
    for transaction_id in range(1, N_SALES + 1):
        product_id = random.randint(1, N_PRODUCTS)
        quantity = random.choices([1, 2, 3, 4], weights=[60, 25, 10, 5])[0]
        amount = f"{prices.get(product_id, 50.0) * quantity:.2f}"
        rows.append([transaction_id, (FIRST_SALE + timedelta(days=random.randint(0, days))).isoformat(),
                     random.randint(1, N_CUSTOMERS), product_id, amount])

    picks = iter(random.sample(range(N_SALES), 38))
    for _ in range(10):                                  
        rows[next(picks)][4] = f"-{random.uniform(5, 300):.2f}"
    for bad in ["abc", "12,50", "N/A", "$45.00", "ten"]: 
        rows[next(picks)][4] = bad
    for _ in range(5):                                   
        rows[next(picks)][4] = ""
    for bad in ["2026-02-30", "13/45/2025", "2025-13-01", "", "yesterday"]:  
        rows[next(picks)][1] = bad
    for unknown in range(9001, 9006):                    
        rows[next(picks)][2] = unknown
    for unknown in range(901, 906):                      
        rows[next(picks)][3] = unknown
    for i in (next(picks), next(picks), next(picks)):    
        rows.append(list(rows[i]))
    return rows, dict(negative_amount=10, non_numeric_amount=5, missing_amount=5, invalid_or_missing_date=5,
                      unknown_customer=5, unknown_product=5, duplicate_id=3)


def main():
    random.seed(SEED)
    customer_rows, customer_issues = customers()
    product_rows, product_issues = products()
    prices = {int(r[0]): float(r[3]) for r in product_rows if r[3].replace(".", "", 1).isdigit()}
    sale_rows, sale_issues = sales(prices)

    write("customers.csv", ["CustomerID", "Name", "Email", "Country"], customer_rows)
    write("products.csv", ["ProductID", "ProductName", "Category", "Price"], product_rows)
    write("sales.csv", ["TransactionID", "Date", "CustomerID", "ProductID", "Amount"], sale_rows)

    for name, rows, issues in (("customers.csv", customer_rows, customer_issues),
                               ("products.csv", product_rows, product_issues),
                               ("sales.csv", sale_rows, sale_issues)):
        print(f"{name:<14}{len(rows):>6} rows   planted: {issues}")


if __name__ == "__main__":
    main()
