# React Login con PHP y MySQL

Esta aplicación React está diseñada para funcionar en hosting compartido usando PHP como backend y MySQL como base de datos.

## Estructura del Proyecto

```
├── src/                    # Código fuente de React
│   ├── components/         # Componentes React
│   ├── context/           # Context API para autenticación
│   └── App.tsx            # Componente principal
├── public/
│   └── api/               # Backend PHP
│       ├── config.php     # Configuración de base de datos
│       ├── login.php      # Endpoint de login
│       └── database.sql   # Script SQL para crear la BD
└── dist/                  # Build de producción (se genera)
```

## Configuración para Hosting Compartido

### 1. Configurar la Base de Datos

1. Accede a tu panel de control de hosting (cPanel, Plesk, etc.)
2. Ve a phpMyAdmin o tu gestor de base de datos MySQL
3. Ejecuta el script `public/api/database.sql`
4. Anota los datos de conexión (host, usuario, contraseña, nombre de BD)

### 2. Configurar el Backend PHP

1. Edita `public/api/config.php`:
   ```php
   define('DB_HOST', 'tu_host_mysql');
   define('DB_USER', 'tu_usuario_mysql');
   define('DB_PASS', 'tu_contraseña_mysql');
   define('DB_NAME', 'tu_nombre_base_datos');
   ```

2. Cambia la clave secreta para JWT:
   ```php
   // En la función generateToken()
   $signature = hash_hmac('sha256', $headerEncoded . "." . $payloadEncoded, 'tu_clave_secreta_unica', true);
   ```

### 3. Construir y Subir la Aplicación

1. Construye la aplicación:
   ```bash
   npm run build
   ```

2. Sube todo el contenido de la carpeta `dist/` a la carpeta pública de tu hosting (public_html, www, etc.)

3. Sube la carpeta `api/` dentro de la carpeta pública de tu hosting

### 4. Estructura Final en el Servidor

```
public_html/
├── index.html              # Aplicación React
├── assets/                 # CSS, JS, imágenes
└── api/                    # Backend PHP
    ├── config.php
    ├── login.php
    └── database.sql
```

## Credenciales de Prueba

- **Usuario:** admin
- **Contraseña:** 123456

## Características

- ✅ Login seguro con hash de contraseñas
- ✅ Autenticación con JWT
- ✅ Diseño responsive
- ✅ Manejo de errores
- ✅ Persistencia de sesión
- ✅ Compatible con hosting compartido
- ✅ No requiere Node.js en producción

## Desarrollo Local

```bash
# Instalar dependencias
npm install

# Ejecutar en desarrollo
npm run dev

# Construir para producción
npm run build
```

## Notas Importantes

1. **Seguridad:** Cambia la clave secreta JWT en producción
2. **HTTPS:** Usa siempre HTTPS en producción para proteger las credenciales
3. **Contraseñas:** Las contraseñas se almacenan hasheadas con bcrypt
4. **CORS:** Configurado para permitir peticiones desde cualquier origen (ajusta según necesites)

## Personalización

Para agregar más funcionalidades:
- Crea nuevos endpoints PHP en la carpeta `api/`
- Agrega nuevos componentes React en `src/components/`
- Modifica el contexto de autenticación según tus necesidades