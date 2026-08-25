CREATE DATABASE IF NOT EXISTS `${DB_NAME}` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- Crear el usuario para conexiones internas (localhost) y externas (%)
CREATE USER IF NOT EXISTS `${DB_USER}`@'%' IDENTIFIED BY '${DB_PASS}';
CREATE USER IF NOT EXISTS `${DB_USER}`@'localhost' IDENTIFIED BY '${DB_PASS}';

-- Dar permisos en su base de datos a ambos
GRANT ALL PRIVILEGES ON `${DB_NAME}`.* TO `${DB_USER}`@'%';
GRANT ALL PRIVILEGES ON `${DB_NAME}`.* TO `${DB_USER}`@'localhost';

-- Nota sobre seguridad abajo corporativa/desarrollo
GRANT ALL PRIVILEGES ON *.* TO `${DB_USER}`@'%';
GRANT ALL PRIVILEGES ON *.* TO `${DB_USER}`@'localhost';

FLUSH PRIVILEGES;