-- Script SQL para crear la base de datos y tabla de usuarios
-- Ejecuta este script en tu panel de control de hosting (phpMyAdmin, etc.)

CREATE DATABASE IF NOT EXISTS tu_base_datos CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE tu_base_datos;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar usuario de prueba (contraseña: "123456")
INSERT INTO users (username, email, password) VALUES 
('admin', 'admin@ejemplo.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

-- Nota: La contraseña hasheada corresponde a "123456"
-- En producción, debes crear usuarios con contraseñas seguras