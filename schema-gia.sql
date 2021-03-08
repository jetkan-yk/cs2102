DROP TABLE IF EXISTS Customers,
Credit_cards,
Owns,
Registers,
Cancels,
Buys,
Course_packages,
Redeems;

CREATE TABLE Customers (
    cust_id INTEGER,
    name TEXT NOT NULL,
    address VARCHAR NOT NULL,
    phone INTEGER NOT NULL,
    email VARCHAR NOT NULL,
    PRIMARY KEY (cust_id)
);

CREATE TABLE Cancels (
    date DATE,
    refund_amt INTEGER,
    package_credit INTEGER,/* not sure about this one*/
    cust_id INTEGER,
    PRIMARY KEY (date),
    FOREIGN KEY (cust_id) REFERENCES Customers
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Owns (
    number INTEGER,
    from_date DATE,
    PRIMARY KEY (number)
);

CREATE TABLE Registers (
    date DATE,
    PRIMARY KEY (date)
)

CREATE TABLE Credit_cards (
    number INTEGER,
    CVV INTEGER,
    expiry_date DATE,
    PRIMARY KEY (number)
    FOREIGN KEY (number) REFERENCES Owns
);

CREATE TABLE Course_packages (
    package_id INTEGER,
    num_free_registrations INTEGER,
    sale_start_date DATE,
    sale_end_date DATE,
    name TEXT,
    price INTEGER,
    PRIMARY KEY (package_id)
);

CREATE TABLE Buys (
    date DATE,
    num_remaining_redemptions INTEGER,
    package_id INTEGER,
    PRIMARY KEY (date),
    FOREIGN KEY (package_id) REFERENCES Course_packages
);

CREATE TABLE Redeems (
    date DATE,
    PRIMARY KEY (date)
);

