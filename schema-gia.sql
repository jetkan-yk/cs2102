DROP TABLE IF EXISTS Buys,
Cancels,
Course_packages,
Credit_cards,
Customers,
Owns,
Redeems,
Registers CASCADE;

CREATE TABLE Customers (
    cust_id INTEGER,
    name    TEXT    NOT NULL,
    address TEXT    NOT NULL,
    email   TEXT    NOT NULL,
    phone   INTEGER NOT NULL,

    PRIMARY KEY (cust_id)
);

CREATE TABLE Cancels (
    cancel_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cust_id        INTEGER   NOT NULL,
    course_id      INTEGER   NOT NULL,
    offering_id    INTEGER   NOT NULL,
    session_id     INTEGER   NOT NULL,
    refund_amt     INTEGER,
    package_credit BOOLEAN,

    PRIMARY KEY (cancel_ts),
    FOREIGN KEY (cust_id)                            REFERENCES Customers,
    FOREIGN KEY (course_id, offering_id, session_id) REFERENCES Sessions
        ON DELETE CASCADE
);

CREATE TABLE Credit_cards (
    cc_number   INTEGER,
    cvv         INTEGER NOT NULL,
    expiry_date DATE    NOT NULL,

    PRIMARY KEY (cc_number)
);

CREATE TABLE Owns (
    cc_number INTEGER,
    cust_id   INTEGER   NOT NULL,
    owns_ts   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (cc_number),
    FOREIGN KEY (cc_number) REFERENCES Credit_cards,
    FOREIGN KEY (cust_id)   REFERENCES Customers
);

CREATE TABLE Registers (
    registers_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cc_number    INTEGER   NOT NULL,
    course_id    INTEGER   NOT NULL,
    offering_id  INTEGER   NOT NULL,
    session_id   INTEGER   NOT NULL,

    PRIMARY KEY (registers_ts),
    FOREIGN KEY (cc_number)                          REFERENCES Owns,
    FOREIGN KEY (course_id, offering_id, session_id) REFERENCES Sessions
        ON DELETE CASCADE
);

CREATE TABLE Course_packages (
    package_id      SERIAL,
    name            TEXT    NOT NULL,
    num_free_reg    INTEGER NOT NULL,
                    CONSTRAINT non_negative_num_free_reg
                         CHECK (num_free_reg >= 0),
    price           INTEGER NOT NULL
                    CONSTRAINT non_negative_price
                         CHECK (price >= 0),
    sale_start_date DATE    NOT NULL,
    sale_end_date   DATE    NOT NULL
                    CONSTRAINT start_date_before_end_date
                         CHECK (sale_start_date <= sale_end_date),

    PRIMARY KEY (package_id)
);

CREATE TABLE Buys (
    buys_ts           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    package_id        INTEGER   NOT NULL,
    cc_number         INTEGER   NOT NULL,
    num_remain_redeem INTEGER   NOT NULL,

    PRIMARY KEY (buys_ts),
    FOREIGN KEY (package_id) REFERENCES Course_packages,
    FOREIGN KEY (cc_number)  REFERENCES Owns
);

CREATE TABLE Redeems (
    redeems_ts  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    buys_ts     TIMESTAMP NOT NULL,
    course_id   INTEGER   NOT NULL,
    offering_id INTEGER   NOT NULL,
    session_id  INTEGER   NOT NULL,

    PRIMARY KEY (redeems_ts),
    FOREIGN KEY (buys_ts)                            REFERENCES Buys,
    FOREIGN KEY (course_id, offering_id, session_id) REFERENCES Sessions
        ON DELETE CASCADE
);
