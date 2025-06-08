CREATE TABLE usuarios_admin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL
);

CREATE TABLE personal (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(15),
    departamento VARCHAR(50),
    puesto VARCHAR(50),
    fecha_ingreso DATE,
    salario DECIMAL(10, 2),
    activo BOOLEAN DEFAULT 1
);
