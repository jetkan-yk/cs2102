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
    address TEXT NOT NULL,
    phone   INTEGER NOT NULL,
    email   TEXT NOT NULL,

    PRIMARY KEY (cust_id),
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
    from_date   DATE DEFAULT NOW,

    PRIMARY KEY (cc_number),
    FOREIGN KEY (cc_number) REFERENCES Customers
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (cust_id) REFERENCES Customers
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Registers (
    reg_date        DATE DEFAULT NOW,
    cc_number       INTEGER,
    course_id       INTEGER,
    offering_id     INTEGER,
    session_id      INTEGER,

    PRIMARY KEY (reg_date),
    FOREIGN KEY (cc_number) REFERENCES Owns
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (course_id, offering_id, session_id) REFERENCES Sessions
        ON DELETE CASCADE
        ON UPDATE CASCADE

);

CREATE TABLE Credit_cards (
    cc_number       INTEGER,
    CVV             INTEGER,
    expiry_date     DATE,

    PRIMARY KEY (cc_number)
);

CREATE TABLE Course_packages (
    package_id              SERIAL, /*system generated*/
    num_free_registrations  INTEGER,
    sale_start_date         DATE,
    sale_end_date           DATE
                            CONSTRAINT startdate_before_enddate
                                CHECK (sale_start_date < sale_end_date),
    name                    TEXT,
    price                   INTEGER NOT NULL
                            CONSTRAINT non_negative_price
                                CHECK (price >= 0),

    PRIMARY KEY (package_id)
);

CREATE TABLE Buys (
    buy_date                    DATE DEFAULT NOW,
    num_free_registrations      INTEGER, /* this may be necessary for proc later */
    num_remaining_redemptions   INTEGER,
    package_id                  INTEGER,
    cc_number                   INTEGER,

    PRIMARY KEY (buy_date),
    FOREIGN KEY (package_id) REFERENCES Course_packages
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (num_free_registrations) REFERENCES Course_packages
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (cc_number) REFERENCES Owns
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Redeems (
    redeem_date     DATE DEFAULT NOW,
    package_id      INTEGER,
    cc_number       INTEGER,
    buy_date        DATE,
    course_id       INTEGER,
    offering_id     INTEGER,
    session_id      INTEGER,

    PRIMARY KEY (redeem_date)
    FOREIGN KEY (package_id) REFERENCES Course_packages
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (cc_number) REFERENCES Owns
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (course_id, offering_id, session_id) REFERENCES Sessions
        ON DELETE CASCADE
        ON UPDATE CASCADE           
);

