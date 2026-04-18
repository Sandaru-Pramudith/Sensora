-- --------------------------------------------------
--           SENSORA DATABASE SCHEMA
--  MySQL | Fruit Spoilage Detection via Gas Sensors
-- ---------------------------------------------------------


USE sensora;


-- 1. USERS

CREATE TABLE users (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(150) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    mobile_number VARCHAR(20)  NOT NULL UNIQUE,  
    date_of_birth DATE         NOT NULL,
    password_hash VARCHAR(255) NOT NULL,          
    role          ENUM('admin', 'operator', 'viewer') DEFAULT 'viewer',
    is_active     BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login    TIMESTAMP NULL,

    INDEX idx_email  (email),
    INDEX idx_mobile (mobile_number)
);

USE sensora;

CREATE TABLE device (
    device_id VARCHAR(50) NOT NULL PRIMARY KEY,
    wifi_ssid VARCHAR(64) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    INDEX idx_id (device_id)
);

CREATE TABLE basket (
    basket_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    location VARCHAR(100) NOT NULL DEFAULT 'Main Isle',
    fruit_type VARCHAR(50) NOT NULL DEFAULT 'Bananna',

    FOREIGN KEY (device_id) REFERENCES device(device_id),
    INDEX idx_fruit_type (fruit_type),
    INDEX idx_location (location)
);

CREATE TABLE sensor_reading (
    read_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    basket_id INT UNSIGNED NOT NULL,

    temp FLOAT NOT NULL,
    hum FLOAT NOT NULL,
    eco2 FLOAT NOT NULL,
    tvoc FLOAT NOT NULL,
    aqi FLOAT NOT NULL,
    mq_raw FLOAT NOT NULL,
    mq_volts FLOAT NOT NULL,

    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (device_id) REFERENCES device(device_id),
    FOREIGN KEY (basket_id) REFERENCES basket(basket_id),

    INDEX idx_device_time (device_id, recorded_at),
    INDEX idx_basket_time (basket_id, recorded_at)
);

CREATE TABLE prediction (
    pred_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    read_id BIGINT UNSIGNED NOT NULL,
    basket_id INT UNSIGNED NOT NULL,
    device_id VARCHAR(50) NOT NULL,

    spoil_stage BOOLEAN NOT NULL,
    hours_left FLOAT NULL,

    predicted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (read_id) REFERENCES sensor_reading(read_id),
    FOREIGN KEY (basket_id) REFERENCES basket(basket_id),
    FOREIGN KEY (device_id) REFERENCES device(device_id),

    INDEX idx_basket_predicted (basket_id, predicted_at),
    INDEX idx_device_predicted (device_id, predicted_at)
);

--    6. ALERTS
--    Triggered when spoilage is detected for a batch

CREATE TABLE alerts (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fruit_type  VARCHAR(50)  NOT NULL,            
    location    VARCHAR(100) NOT NULL,            
    status      ENUM('active', 'resolved', 'dismissed') DEFAULT 'active',
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,                 

    INDEX idx_status       (status),
    INDEX idx_detected_at  (detected_at)
);

