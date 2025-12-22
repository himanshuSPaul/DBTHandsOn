-- SQL script to create and populate the order_status table in the RAW schema
CREATE TABLE RAW.order_status (
    ord_id INT PRIMARY KEY,
    ord_deliver_address VARCHAR(500),
    ord_status VARCHAR(50),
    ord_status_update_ts TIMESTAMP
);

INSERT INTO RAW.order_status (ord_id, ord_deliver_address, ord_status, ord_status_update_ts) VALUES
(1001, '123 Main St New York NY 10001', 'placed', '2025-12-01 10:00:00'),
(1002, '456 Oak Ave Los Angeles CA 90001', 'shipped', '2025-12-02 11:30:00'),
(1003, '789 Pine Rd Chicago IL 60601', 'delivered', '2025-12-03 14:15:00'),
(1004, '321 Elm St Houston TX 77001', 'placed', '2025-12-04 09:45:00'),
(1005, '654 Maple Dr Phoenix AZ 85001', 'shipped', '2025-12-05 16:20:00'),
(1006, '987 Cedar Ln Philadelphia PA 19101', 'delivered', '2025-12-06 13:00:00'),
(1007, '147 Birch Blvd San Antonio TX 78201', 'cancelled', '2025-12-07 10:30:00'),
(1008, '258 Spruce Way San Diego CA 92101', 'placed', '2025-12-08 12:45:00'),
(1009, '369 Willow Ct Dallas TX 75201', 'shipped', '2025-12-09 15:10:00'),
(1010, '741 Ash Ave San Jose CA 95101', 'delivered', '2025-12-10 11:00:00')
;