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
    name    TEXT NOT NULL,
    address VARCHAR NOT NULL,
    phone   INTEGER NOT NULL,
    email   VARCHAR NOT NULL,

    PRIMARY KEY (cust_id),
    CONSTRAINT cust_total_participation
        CHECK (cust_id IN Owns(cust_id))
    /* constraint total participation of
    Customers in Owns */
);

CREATE TABLE Cancels (
    cancel_date     DATE,
    refund_amt      INTEGER,
    package_credit  INTEGER,
    cust_id         INTEGER,

    PRIMARY KEY (cancel_date),
    FOREIGN KEY (cust_id) REFERENCES Customers
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Owns (
    cc_number   INTEGER,
    cust_id     INTEGER,
    from_date   DATE,

    PRIMARY KEY (cc_number),
    FOREIGN KEY (cust_id) REFERENCES Customers
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Registers (
    reg_date DATE,

    PRIMARY KEY (reg_date)
    /* unsure how to link this to Owns
    and Sessions */

)

CREATE TABLE Credit_cards (
    cc_number       INTEGER,
    CVV             INTEGER,
    expiry_date     DATE,

    PRIMARY KEY (cc_number),
    FOREIGN KEY (cc_number) REFERENCES Owns
        ON DELETE CASCADE
        ON UPDATE CASCADE
    /*is this correct*/
);

CREATE TABLE Course_packages (
    package_id              INTEGER,
    num_free_registrations  INTEGER,
    sale_start_date         DATE,
    sale_end_date           DATE,
    name                    TEXT,
    price                   INTEGER,

    PRIMARY KEY (package_id)
);

CREATE TABLE Buys (
    buy_date                    DATE,
    num_remaining_redemptions   INTEGER,
    package_id                  INTEGER,
    cc_number                   INTEGER,

    PRIMARY KEY (buy_date),
    FOREIGN KEY (package_id) REFERENCES Course_packages,
    FOREIGN KEY (cc_number) REFERENCES Owns
);

CREATE TABLE Redeems (
    redeem_date     DATE,
    package_id      INTEGER,
    cc_number       INTEGER,
    buy_date        DATE,
    session_id      SERIAL, /* why is it yellow */

    PRIMARY KEY (redeem_date)
    FOREIGN KEY (package_id) REFERENCES Course_packages,
    FOREIGN KEY (cc_number) REFERENCES Owns,
    FOREIGN KEY (session_id) REFERENCES Sessions       

    
);

