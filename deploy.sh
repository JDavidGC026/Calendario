#!/bin/bash

# Script de deploy para aplicación React con PHP/MySQL
# Para hosting compartido o servidor Linux

set -e  # Salir si hay algún error

echo "=========================================="
echo "  DEPLOY DE APLICACIÓN REACT + PHP/MySQL"
echo "=========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si se ejecuta como root o con sudo
if [[ $EUID -eq 0 ]]; then
    print_warning "Ejecutándose como root"
else
    print_status "Verificando permisos sudo..."
    if ! sudo -n true 2>/dev/null; then
        print_error "Este script requiere permisos sudo"
        exit 1
    fi
fi

# Verificar dependencias
print_status "Verificando dependencias..."

if ! command -v node &> /dev/null; then
    print_error "Node.js no está instalado"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    print_error "npm no está instalado"
    exit 1
fi

if ! command -v mysql &> /dev/null; then
    print_warning "MySQL client no encontrado, pero continuando..."
fi

print_success "Dependencias verificadas"

# Solicitar credenciales de MySQL
echo ""
print_status "Configuración de base de datos MySQL"
echo "Por favor, ingresa las credenciales de tu base de datos:"

read -p "Host de MySQL (default: localhost): " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -p "Usuario de MySQL: " DB_USER
if [[ -z "$DB_USER" ]]; then
    print_error "El usuario de MySQL es requerido"
    exit 1
fi

read -s -p "Contraseña de MySQL: " DB_PASS
echo ""
if [[ -z "$DB_PASS" ]]; then
    print_error "La contraseña de MySQL es requerida"
    exit 1
fi

read -p "Nombre de la base de datos: " DB_NAME
if [[ -z "$DB_NAME" ]]; then
    print_error "El nombre de la base de datos es requerido"
    exit 1
fi

read -p "Clave secreta para JWT (default: auto-generada): " JWT_SECRET
if [[ -z "$JWT_SECRET" ]]; then
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || echo "mi_clave_secreta_$(date +%s)")
fi

# Verificar conexión a MySQL
print_status "Verificando conexión a MySQL..."
if command -v mysql &> /dev/null; then
    if mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1;" &> /dev/null; then
        print_success "Conexión a MySQL exitosa"
    else
        print_warning "No se pudo verificar la conexión a MySQL, pero continuando..."
    fi
fi

# Instalar dependencias del proyecto
print_status "Instalando dependencias del proyecto..."
if [[ -f "package.json" ]]; then
    npm install
    print_success "Dependencias instaladas"
else
    print_error "No se encontró package.json en el directorio actual"
    exit 1
fi

# Construir la aplicación
print_status "Construyendo la aplicación React..."
npm run build
print_success "Aplicación construida exitosamente"

# Crear directorio de destino
DEST_DIR="/var/www/html/Calendario"
print_status "Creando directorio de destino: $DEST_DIR"

sudo mkdir -p "$DEST_DIR"
sudo chown -R www-data:www-data "$DEST_DIR" 2>/dev/null || sudo chown -R apache:apache "$DEST_DIR" 2>/dev/null || true

# Copiar archivos del build
print_status "Copiando archivos de la aplicación..."
sudo cp -r dist/* "$DEST_DIR/"
print_success "Archivos de aplicación copiados"

# Crear directorio API
print_status "Configurando backend PHP..."
sudo mkdir -p "$DEST_DIR/api"

# Crear archivo de configuración PHP con las credenciales proporcionadas
print_status "Generando configuración de base de datos..."

sudo tee "$DEST_DIR/api/config.php" > /dev/null <<EOF
<?php
// Configuración de la base de datos
define('DB_HOST', '$DB_HOST');
define('DB_USER', '$DB_USER');
define('DB_PASS', '$DB_PASS');
define('DB_NAME', '$DB_NAME');

// Configuración de CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

// Manejar preflight requests
if (\$_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Función para conectar a la base de datos
function getDBConnection() {
    try {
        \$pdo = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
            DB_USER,
            DB_PASS,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]
        );
        return \$pdo;
    } catch (PDOException \$e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Error de conexión a la base de datos']);
        exit;
    }
}

// Función para generar JWT simple (para hosting compartido)
function generateToken(\$userId) {
    \$header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
    \$payload = json_encode(['user_id' => \$userId, 'exp' => time() + (24 * 60 * 60)]); // 24 horas
    
    \$headerEncoded = base64url_encode(\$header);
    \$payloadEncoded = base64url_encode(\$payload);
    
    \$signature = hash_hmac('sha256', \$headerEncoded . "." . \$payloadEncoded, '$JWT_SECRET', true);
    \$signatureEncoded = base64url_encode(\$signature);
    
    return \$headerEncoded . "." . \$payloadEncoded . "." . \$signatureEncoded;
}

function base64url_encode(\$data) {
    return rtrim(strtr(base64_encode(\$data), '+/', '-_'), '=');
}
?>
EOF

# Copiar archivo de login
sudo cp public/api/login.php "$DEST_DIR/api/"

# Crear archivo SQL con las credenciales correctas
print_status "Generando script SQL..."

sudo tee "$DEST_DIR/api/setup_database.sql" > /dev/null <<EOF
-- Script SQL para crear la base de datos y tabla de usuarios
-- Ejecuta este script en tu panel de control de hosting (phpMyAdmin, etc.)

CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE \`$DB_NAME\`;

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
INSERT IGNORE INTO users (username, email, password) VALUES 
('admin', 'admin@ejemplo.com', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

-- Nota: La contraseña hasheada corresponde a "123456"
-- En producción, debes crear usuarios con contraseñas seguras
EOF

# Configurar permisos
print_status "Configurando permisos..."
sudo chown -R www-data:www-data "$DEST_DIR" 2>/dev/null || sudo chown -R apache:apache "$DEST_DIR" 2>/dev/null || true
sudo chmod -R 755 "$DEST_DIR"
sudo chmod 644 "$DEST_DIR/api/config.php"

# Intentar crear la base de datos automáticamente
print_status "Intentando crear la base de datos automáticamente..."
if command -v mysql &> /dev/null; then
    if mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" < "$DEST_DIR/api/setup_database.sql" 2>/dev/null; then
        print_success "Base de datos configurada automáticamente"
    else
        print_warning "No se pudo configurar la base de datos automáticamente"
        print_warning "Ejecuta manualmente el archivo: $DEST_DIR/api/setup_database.sql"
    fi
else
    print_warning "MySQL client no disponible"
    print_warning "Ejecuta manualmente el archivo: $DEST_DIR/api/setup_database.sql"
fi

# Verificar si Apache/Nginx está corriendo
print_status "Verificando servidor web..."
if systemctl is-active --quiet apache2 2>/dev/null; then
    print_success "Apache está corriendo"
    WEB_SERVER="Apache"
elif systemctl is-active --quiet nginx 2>/dev/null; then
    print_success "Nginx está corriendo"
    WEB_SERVER="Nginx"
elif systemctl is-active --quiet httpd 2>/dev/null; then
    print_success "Apache (httpd) está corriendo"
    WEB_SERVER="Apache"
else
    print_warning "No se detectó servidor web corriendo"
    WEB_SERVER="Desconocido"
fi

# Crear archivo de información del deploy
sudo tee "$DEST_DIR/DEPLOY_INFO.txt" > /dev/null <<EOF
===========================================
INFORMACIÓN DEL DEPLOY
===========================================

Fecha de deploy: $(date)
Directorio: $DEST_DIR
Servidor web: $WEB_SERVER

Base de datos:
- Host: $DB_HOST
- Usuario: $DB_USER
- Base de datos: $DB_NAME

Credenciales de prueba:
- Usuario: admin
- Contraseña: 123456

URLs de acceso:
- Aplicación: http://localhost/Calendario/
- API Login: http://localhost/Calendario/api/login.php

Archivos importantes:
- Configuración PHP: $DEST_DIR/api/config.php
- Script SQL: $DEST_DIR/api/setup_database.sql

Notas:
- Si usas un dominio, reemplaza 'localhost' con tu dominio
- Asegúrate de que PHP esté habilitado en tu servidor
- Para HTTPS, actualiza las URLs correspondientes
EOF

echo ""
echo "=========================================="
print_success "¡DEPLOY COMPLETADO EXITOSAMENTE!"
echo "=========================================="
echo ""
print_status "Información del deploy:"
echo "  📁 Directorio: $DEST_DIR"
echo "  🌐 URL: http://localhost/Calendario/"
echo "  🔑 Usuario de prueba: admin / 123456"
echo ""
print_status "Próximos pasos:"
echo "  1. Verifica que tu servidor web esté corriendo"
echo "  2. Accede a http://localhost/Calendario/"
echo "  3. Si hay problemas con la BD, ejecuta: $DEST_DIR/api/setup_database.sql"
echo ""
print_warning "Recuerda:"
echo "  - Cambiar las credenciales por defecto en producción"
echo "  - Usar HTTPS en producción"
echo "  - Revisar los logs del servidor web si hay errores"
echo ""
print_success "¡La aplicación está lista para usar!"