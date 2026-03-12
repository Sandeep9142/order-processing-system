CREATE TABLE Payments (
    payment_id INT PRIMARY KEY,
    order_id INT,
    amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    payment_date DATE,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);