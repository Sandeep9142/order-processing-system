CREATE TABLE Inventory (
    inventory_id INT PRIMARY KEY,
    product_id INT,
    quantity_on_hand INT,
    last_updated DATE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);