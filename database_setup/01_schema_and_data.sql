-- =========================================================
-- BASE DE DATOS DE PRÁCTICA: COMERCIO
-- PostgreSQL
-- =========================================================

-- Opcional:
-- CREATE DATABASE comercio_practica;

-- Ejecutar después de conectarse a la base de datos.

DROP SCHEMA IF EXISTS comercio CASCADE;
CREATE SCHEMA comercio;

SET search_path TO comercio;

-- =========================================================
-- 1. CLIENTES
-- =========================================================

CREATE TABLE cliente (
    id_cliente BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numero_documento VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    ciudad VARCHAR(80) NOT NULL,
    fecha_nacimiento DATE,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT ck_cliente_correo
        CHECK (correo LIKE '%@%'),

    CONSTRAINT ck_cliente_fecha_nacimiento
        CHECK (
            fecha_nacimiento IS NULL
            OR fecha_nacimiento <= CURRENT_DATE
        )
);


-- =========================================================
-- 2. EMPLEADOS
-- =========================================================

CREATE TABLE empleado (
    id_empleado BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numero_documento VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    cargo VARCHAR(80) NOT NULL,
    salario NUMERIC(12, 2) NOT NULL,
    fecha_contratacion DATE NOT NULL,
    id_supervisor BIGINT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT ck_empleado_salario
        CHECK (salario > 0),

    CONSTRAINT fk_empleado_supervisor
        FOREIGN KEY (id_supervisor)
        REFERENCES empleado(id_empleado)
        ON DELETE SET NULL
);

-- =========================================================
-- 3. CATEGORÍAS
-- =========================================================

CREATE TABLE categoria (
    id_categoria BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(250),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- =========================================================
-- 4. PROVEEDORES
-- =========================================================

CREATE TABLE proveedor (
    id_proveedor BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nit VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    correo VARCHAR(150),
    telefono VARCHAR(20),
    ciudad VARCHAR(80),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- =========================================================
-- 5. PRODUCTOS
-- =========================================================

CREATE TABLE producto (
    id_producto BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    precio NUMERIC(12, 2) NOT NULL,
    costo NUMERIC(12, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    stock_minimo INTEGER NOT NULL DEFAULT 5,
    id_categoria BIGINT NOT NULL,
    id_proveedor BIGINT,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT ck_producto_precio
        CHECK (precio > 0),

    CONSTRAINT ck_producto_costo
        CHECK (costo >= 0),

    CONSTRAINT ck_producto_stock
        CHECK (stock >= 0),

    CONSTRAINT ck_producto_stock_minimo
        CHECK (stock_minimo >= 0),

    CONSTRAINT ck_producto_precio_costo
        CHECK (precio >= costo),

    CONSTRAINT fk_producto_categoria
        FOREIGN KEY (id_categoria)
        REFERENCES categoria(id_categoria),

    CONSTRAINT fk_producto_proveedor
        FOREIGN KEY (id_proveedor)
        REFERENCES proveedor(id_proveedor)
        ON DELETE SET NULL
);

-- =========================================================
-- 6. PEDIDOS
-- =========================================================

CREATE TABLE pedido (
    id_pedido BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente BIGINT NOT NULL,
    id_empleado BIGINT,
    fecha_pedido TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    direccion_entrega VARCHAR(250) NOT NULL,
    ciudad_entrega VARCHAR(80) NOT NULL,
    observacion TEXT,
    subtotal NUMERIC(14, 2) NOT NULL DEFAULT 0,
    impuesto NUMERIC(14, 2) NOT NULL DEFAULT 0,
    descuento NUMERIC(14, 2) NOT NULL DEFAULT 0,
    total NUMERIC(14, 2) NOT NULL DEFAULT 0,

    CONSTRAINT ck_pedido_estado
        CHECK (
            estado IN (
                'PENDIENTE',
                'PAGADO',
                'ENVIADO',
                'ENTREGADO',
                'CANCELADO'
            )
        ),

    CONSTRAINT ck_pedido_valores
        CHECK (
            subtotal >= 0
            AND impuesto >= 0
            AND descuento >= 0
            AND total >= 0
        ),

    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES cliente(id_cliente),

    CONSTRAINT fk_pedido_empleado
        FOREIGN KEY (id_empleado)
        REFERENCES empleado(id_empleado)
        ON DELETE SET NULL
);

-- =========================================================
-- 7. DETALLE DE PEDIDOS
-- =========================================================

CREATE TABLE detalle_pedido (
    id_detalle BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pedido BIGINT NOT NULL,
    id_producto BIGINT NOT NULL,
    cantidad INTEGER NOT NULL,
    precio_unitario NUMERIC(12, 2) NOT NULL,
    descuento_porcentaje NUMERIC(5, 2) NOT NULL DEFAULT 0,
    subtotal NUMERIC(14, 2)
        GENERATED ALWAYS AS (
            ROUND(
                cantidad
                * precio_unitario
                * (1 - descuento_porcentaje / 100),
                2
            )
        ) STORED,

    CONSTRAINT uq_detalle_pedido_producto
        UNIQUE (id_pedido, id_producto),

    CONSTRAINT ck_detalle_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT ck_detalle_precio
        CHECK (precio_unitario > 0),

    CONSTRAINT ck_detalle_descuento
        CHECK (
            descuento_porcentaje >= 0
            AND descuento_porcentaje <= 100
        ),

    CONSTRAINT fk_detalle_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES pedido(id_pedido)
        ON DELETE CASCADE,

    CONSTRAINT fk_detalle_producto
        FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto)
);

-- =========================================================
-- 8. PAGOS
-- =========================================================

CREATE TABLE pago (
    id_pago BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_pedido BIGINT NOT NULL,
    fecha_pago TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metodo_pago VARCHAR(30) NOT NULL,
    valor NUMERIC(14, 2) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'APROBADO',
    referencia VARCHAR(100),

    CONSTRAINT ck_pago_metodo
        CHECK (
            metodo_pago IN (
                'EFECTIVO',
                'TARJETA',
                'TRANSFERENCIA',
                'PSE'
            )
        ),

    CONSTRAINT ck_pago_estado
        CHECK (
            estado IN (
                'PENDIENTE',
                'APROBADO',
                'RECHAZADO',
                'REEMBOLSADO'
            )
        ),

    CONSTRAINT ck_pago_valor
        CHECK (valor > 0),

    CONSTRAINT fk_pago_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES pedido(id_pedido)
        ON DELETE CASCADE
);

-- =========================================================
-- 9. MOVIMIENTOS DE INVENTARIO
-- =========================================================

CREATE TABLE movimiento_inventario (
    id_movimiento BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_producto BIGINT NOT NULL,
    tipo_movimiento VARCHAR(20) NOT NULL,
    cantidad INTEGER NOT NULL,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descripcion VARCHAR(250),
    id_pedido BIGINT,

    CONSTRAINT ck_movimiento_tipo
        CHECK (
            tipo_movimiento IN (
                'ENTRADA',
                'SALIDA',
                'AJUSTE_POSITIVO',
                'AJUSTE_NEGATIVO'
            )
        ),

    CONSTRAINT ck_movimiento_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT fk_movimiento_producto
        FOREIGN KEY (id_producto)
        REFERENCES producto(id_producto),

    CONSTRAINT fk_movimiento_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES pedido(id_pedido)
        ON DELETE SET NULL
);

-- =========================================================
-- 10. ÍNDICES
-- =========================================================

CREATE INDEX ix_cliente_ciudad
    ON cliente(ciudad);

CREATE INDEX ix_cliente_fecha_registro
    ON cliente(fecha_registro);

CREATE INDEX ix_producto_nombre
    ON producto(nombre);

CREATE INDEX ix_producto_categoria
    ON producto(id_categoria);

CREATE INDEX ix_producto_proveedor
    ON producto(id_proveedor);

CREATE INDEX ix_pedido_cliente
    ON pedido(id_cliente);

CREATE INDEX ix_pedido_fecha
    ON pedido(fecha_pedido);

CREATE INDEX ix_pedido_estado
    ON pedido(estado);

CREATE INDEX ix_detalle_producto
    ON detalle_pedido(id_producto);

CREATE INDEX ix_pago_pedido
    ON pago(id_pedido);

CREATE INDEX ix_movimiento_producto_fecha
    ON movimiento_inventario(id_producto, fecha_movimiento);








SET search_path TO comercio;

-- =========================================================
-- CATEGORÍAS
-- =========================================================

INSERT INTO categoria (nombre, descripcion)
VALUES
    ('Computadores', 'Computadores portátiles y de escritorio'),
    ('Celulares', 'Teléfonos celulares y accesorios'),
    ('Monitores', 'Monitores para oficina y gaming'),
    ('Periféricos', 'Teclados, ratones, cámaras y audífonos'),
    ('Almacenamiento', 'Discos duros y unidades de estado sólido'),
    ('Muebles', 'Muebles para oficina y hogar'),
    ('Redes', 'Equipos y accesorios de conectividad');

-- =========================================================
-- PROVEEDORES
-- =========================================================

INSERT INTO proveedor (nit, nombre, correo, telefono, ciudad)
VALUES
    ('900100001-1', 'Tecnología Nacional SAS', 'ventas@tecnacional.com', '6044441001', 'Medellín'),
    ('900100002-2', 'Distribuciones Andinas SAS', 'contacto@andinas.com', '6015552002', 'Bogotá'),
    ('900100003-3', 'Importaciones del Caribe SAS', 'ventas@caribe.com', '6053333003', 'Barranquilla'),
    ('900100004-4', 'Muebles Modernos SAS', 'pedidos@mueblesmodernos.com', '6022224004', 'Cali'),
    ('900100005-5', 'Redes Colombia SAS', 'comercial@redescolombia.com', '6044445005', 'Medellín');

-- =========================================================
-- CLIENTES
-- =========================================================

INSERT INTO cliente (
    numero_documento,
    nombre,
    apellido,
    correo,
    telefono,
    ciudad,
    fecha_nacimiento,
    fecha_registro,
    activo
)
VALUES
    ('10000001', 'Laura', 'Gómez', 'laura.gomez@email.com', '3001111111', 'Medellín', '1995-03-15', '2025-01-10 09:00:00-05', TRUE),
    ('10000002', 'Carlos', 'Rodríguez', 'carlos.rodriguez@email.com', '3002222222', 'Bogotá', '1988-07-20', '2025-01-15 10:30:00-05', TRUE),
    ('10000003', 'Ana', 'Martínez', 'ana.martinez@email.com', '3003333333', 'Cali', '1999-11-05', '2025-02-01 14:20:00-05', TRUE),
    ('10000004', 'Juan', 'López', 'juan.lopez@email.com', '3004444444', 'Medellín', '1992-01-30', '2025-02-08 08:10:00-05', TRUE),
    ('10000005', 'Sofía', 'Hernández', 'sofia.hernandez@email.com', '3005555555', 'Barranquilla', '1997-06-18', '2025-02-14 16:40:00-05', TRUE),
    ('10000006', 'Andrés', 'Pérez', 'andres.perez@email.com', '3006666666', 'Bogotá', '1985-09-12', '2025-03-02 11:15:00-05', TRUE),
    ('10000007', 'Valentina', 'Ramírez', 'valentina.ramirez@email.com', '3007777777', 'Pereira', '2000-04-25', '2025-03-10 13:00:00-05', TRUE),
    ('10000008', 'Mateo', 'Torres', 'mateo.torres@email.com', NULL, 'Medellín', '1994-12-08', '2025-03-18 07:50:00-05', TRUE),
    ('10000009', 'Camila', 'Restrepo', 'camila.restrepo@email.com', '3009999999', 'Cali', '1998-02-14', '2025-04-03 17:30:00-05', FALSE),
    ('10000010', 'Daniel', 'Vargas', 'daniel.vargas@email.com', '3010000000', 'Bogotá', '1990-10-10', '2025-04-15 09:45:00-05', TRUE),
    ('10000011', 'Mariana', 'Castro', 'mariana.castro@email.com', '3011111111', 'Cartagena', '1996-05-22', '2025-05-05 12:00:00-05', TRUE),
    ('10000012', 'Felipe', 'Moreno', 'felipe.moreno@email.com', NULL, 'Medellín', '1987-08-17', '2025-05-20 15:25:00-05', TRUE);

-- =========================================================
-- EMPLEADOS
-- Primero se insertan los empleados sin supervisor.
-- =========================================================

INSERT INTO empleado (
    numero_documento,
    nombre,
    apellido,
    cargo,
    salario,
    fecha_contratacion
)
VALUES
    ('20000001', 'Mónica', 'Álvarez', 'Gerente comercial', 8500000, '2020-01-15'),
    ('20000002', 'Ricardo', 'Suárez', 'Gerente de operaciones', 7800000, '2020-03-01');

INSERT INTO empleado (
    numero_documento,
    nombre,
    apellido,
    cargo,
    salario,
    fecha_contratacion,
    id_supervisor
)
VALUES
    ('20000003', 'Natalia', 'Ríos', 'Asesora comercial', 3200000, '2022-04-10', 1),
    ('20000004', 'Diego', 'Giraldo', 'Asesor comercial', 3100000, '2022-07-18', 1),
    ('20000005', 'Paula', 'Cárdenas', 'Asesora comercial', 3400000, '2023-02-01', 1),
    ('20000006', 'Esteban', 'Mejía', 'Auxiliar de bodega', 2200000, '2023-06-12', 2),
    ('20000007', 'Lucía', 'Ospina', 'Auxiliar de bodega', 2250000, '2024-01-20', 2);

-- =========================================================
-- PRODUCTOS
-- =========================================================

INSERT INTO producto (
    codigo,
    nombre,
    descripcion,
    precio,
    costo,
    stock,
    stock_minimo,
    id_categoria,
    id_proveedor
)
VALUES
    ('PC-001', 'Portátil Lenovo IdeaPad', 'Portátil de 15 pulgadas, 16 GB RAM', 2800000, 2200000, 15, 5, 1, 1),
    ('PC-002', 'Portátil ASUS VivoBook', 'Portátil de 14 pulgadas, 8 GB RAM', 2400000, 1900000, 8, 4, 1, 2),
    ('PC-003', 'Computador de escritorio', 'Equipo Core i5, 16 GB RAM', 2600000, 2050000, 5, 3, 1, 1),
    ('CEL-001', 'Samsung Galaxy A55', 'Celular de 256 GB', 1750000, 1350000, 25, 8, 2, 3),
    ('CEL-002', 'Xiaomi Redmi Note', 'Celular de 128 GB', 950000, 710000, 30, 10, 2, 3),
    ('MON-001', 'Monitor LG 24 pulgadas', 'Monitor IPS Full HD', 720000, 510000, 20, 5, 3, 2),
    ('MON-002', 'Monitor Samsung 27 pulgadas', 'Monitor IPS de 75 Hz', 980000, 720000, 12, 4, 3, 2),
    ('PER-001', 'Teclado mecánico', 'Teclado con iluminación RGB', 280000, 170000, 40, 10, 4, 1),
    ('PER-002', 'Mouse inalámbrico', 'Mouse ergonómico inalámbrico', 95000, 55000, 50, 15, 4, 1),
    ('PER-003', 'Cámara web Full HD', 'Cámara web 1080p', 210000, 130000, 18, 5, 4, 2),
    ('PER-004', 'Audífonos Bluetooth', 'Audífonos con micrófono', 320000, 210000, 22, 7, 4, 3),
    ('ALM-001', 'SSD 1 TB', 'Unidad de estado sólido SATA', 380000, 270000, 35, 10, 5, 1),
    ('ALM-002', 'Disco duro externo 2 TB', 'Disco USB 3.0', 420000, 310000, 16, 5, 5, 2),
    ('MUE-001', 'Escritorio ajustable', 'Escritorio ajustable en altura', 1450000, 980000, 7, 3, 6, 4),
    ('MUE-002', 'Silla ergonómica', 'Silla con soporte lumbar', 890000, 620000, 10, 4, 6, 4),
    ('RED-001', 'Router WiFi 6', 'Router de doble banda', 460000, 325000, 14, 5, 7, 5),
    ('RED-002', 'Switch de red 8 puertos', 'Switch Gigabit Ethernet', 240000, 160000, 20, 6, 7, 5),
    ('PER-005', 'Base refrigerante', 'Base para portátil con ventiladores', 125000, 75000, 0, 5, 4, 1);

-- =========================================================
-- PEDIDOS
-- =========================================================

INSERT INTO pedido (
    id_cliente,
    id_empleado,
    fecha_pedido,
    estado,
    direccion_entrega,
    ciudad_entrega,
    observacion
)
VALUES
    (1, 3, '2025-01-15 10:00:00-05', 'ENTREGADO', 'Calle 10 #20-30', 'Medellín', NULL),
    (2, 4, '2025-01-25 14:30:00-05', 'ENTREGADO', 'Carrera 7 #80-20', 'Bogotá', 'Entregar en portería'),
    (1, 3, '2025-02-05 09:15:00-05', 'ENTREGADO', 'Calle 10 #20-30', 'Medellín', NULL),
    (3, 5, '2025-02-18 16:20:00-05', 'CANCELADO', 'Avenida 6 #15-10', 'Cali', 'Cliente canceló'),
    (4, 3, '2025-03-02 11:45:00-05', 'ENTREGADO', 'Calle 45 #30-15', 'Medellín', NULL),
    (5, 4, '2025-03-12 08:30:00-05', 'ENVIADO', 'Carrera 50 #70-40', 'Barranquilla', NULL),
    (6, 5, '2025-03-28 13:10:00-05', 'ENTREGADO', 'Calle 100 #15-25', 'Bogotá', NULL),
    (2, 4, '2025-04-04 15:00:00-05', 'ENTREGADO', 'Carrera 7 #80-20', 'Bogotá', NULL),
    (7, 3, '2025-04-17 10:25:00-05', 'PAGADO', 'Avenida 30 #12-18', 'Pereira', NULL),
    (8, 5, '2025-05-01 12:35:00-05', 'ENTREGADO', 'Calle 60 #42-10', 'Medellín', NULL),
    (10, 4, '2025-05-16 17:40:00-05', 'ENVIADO', 'Calle 120 #10-30', 'Bogotá', 'Llamar antes de entregar'),
    (11, 3, '2025-06-03 09:50:00-05', 'PENDIENTE', 'Carrera 4 #35-20', 'Cartagena', NULL),
    (1, 5, '2025-06-10 14:00:00-05', 'PAGADO', 'Calle 10 #20-30', 'Medellín', NULL),
    (6, 4, '2025-06-21 11:10:00-05', 'ENTREGADO', 'Calle 100 #15-25', 'Bogotá', NULL),
    (4, 3, '2025-07-08 08:45:00-05', 'ENTREGADO', 'Calle 45 #30-15', 'Medellín', NULL),
    (12, NULL, '2025-07-20 16:15:00-05', 'PENDIENTE', 'Carrera 55 #20-16', 'Medellín', NULL);

-- =========================================================
-- DETALLES
-- Los precios representan el valor histórico de venta.
-- =========================================================

INSERT INTO detalle_pedido (
    id_pedido,
    id_producto,
    cantidad,
    precio_unitario,
    descuento_porcentaje
)
VALUES
    (1, 1, 1, 2800000, 5),
    (1, 9, 1, 95000, 0),

    (2, 4, 1, 1750000, 0),
    (2, 11, 1, 320000, 10),

    (3, 6, 2, 720000, 5),
    (3, 8, 1, 280000, 0),

    (4, 2, 1, 2400000, 0),

    (5, 14, 1, 1450000, 8),
    (5, 15, 1, 890000, 5),

    (6, 5, 2, 950000, 0),
    (6, 10, 1, 210000, 0),

    (7, 3, 1, 2600000, 10),
    (7, 12, 2, 380000, 0),

    (8, 7, 1, 980000, 0),
    (8, 8, 2, 280000, 5),
    (8, 9, 2, 95000, 0),

    (9, 16, 1, 460000, 0),
    (9, 17, 2, 240000, 0),

    (10, 2, 1, 2400000, 5),
    (10, 13, 1, 420000, 0),

    (11, 4, 2, 1750000, 5),
    (11, 11, 2, 320000, 0),

    (12, 6, 1, 720000, 0),
    (12, 10, 2, 210000, 0),

    (13, 1, 1, 2800000, 10),
    (13, 12, 1, 380000, 0),

    (14, 14, 1, 1450000, 0),
    (14, 8, 1, 280000, 0),
    (14, 9, 1, 95000, 0),

    (15, 15, 2, 890000, 10),
    (15, 6, 1, 720000, 0),

    (16, 16, 1, 460000, 0),
    (16, 9, 2, 95000, 0);

-- =========================================================
-- ACTUALIZAR TOTALES DE LOS PEDIDOS
-- IVA utilizado: 19 %
-- Los pedidos cancelados también conservan su valor histórico.
-- =========================================================

UPDATE pedido p
SET
    subtotal = calculo.subtotal,
    impuesto = ROUND(calculo.subtotal * 0.19, 2),
    total = ROUND(calculo.subtotal * 1.19, 2)
FROM (
    SELECT
        id_pedido,
        SUM(subtotal) AS subtotal
    FROM detalle_pedido
    GROUP BY id_pedido
) AS calculo
WHERE p.id_pedido = calculo.id_pedido;

-- Descuento adicional de pedido para algunos registros.

UPDATE pedido
SET
    descuento = 50000,
    total = total - 50000
WHERE id_pedido IN (5, 10);

-- =========================================================
-- PAGOS
-- =========================================================

INSERT INTO pago (
    id_pedido,
    fecha_pago,
    metodo_pago,
    valor,
    estado,
    referencia
)
SELECT
    id_pedido,
    fecha_pedido + INTERVAL '1 hour',
    CASE
        WHEN id_pedido % 4 = 0 THEN 'PSE'
        WHEN id_pedido % 3 = 0 THEN 'TRANSFERENCIA'
        WHEN id_pedido % 2 = 0 THEN 'TARJETA'
        ELSE 'EFECTIVO'
    END,
    total,
    'APROBADO',
    'REF-' || LPAD(id_pedido::TEXT, 6, '0')
FROM pedido
WHERE estado IN ('PAGADO', 'ENVIADO', 'ENTREGADO');

-- Pago rechazado para un pedido pendiente.

INSERT INTO pago (
    id_pedido,
    fecha_pago,
    metodo_pago,
    valor,
    estado,
    referencia
)
SELECT
    id_pedido,
    fecha_pedido + INTERVAL '30 minutes',
    'TARJETA',
    total,
    'RECHAZADO',
    'REF-RECHAZADA-12'
FROM pedido
WHERE id_pedido = 12;

-- Pedido con dos pagos parciales.

DELETE FROM pago
WHERE id_pedido = 13;

INSERT INTO pago (
    id_pedido,
    fecha_pago,
    metodo_pago,
    valor,
    estado,
    referencia
)
VALUES
    (13, '2025-06-10 14:20:00-05', 'PSE', 1500000, 'APROBADO', 'PARCIAL-13-1'),
    (13, '2025-06-11 08:10:00-05', 'TRANSFERENCIA', 1484520, 'APROBADO', 'PARCIAL-13-2');

-- =========================================================
-- MOVIMIENTOS DE INVENTARIO
-- =========================================================

INSERT INTO movimiento_inventario (
    id_producto,
    tipo_movimiento,
    cantidad,
    fecha_movimiento,
    descripcion
)
SELECT
    id_producto,
    'ENTRADA',
    stock + 20,
    '2025-01-01 08:00:00-05',
    'Inventario inicial'
FROM producto;

INSERT INTO movimiento_inventario (
    id_producto,
    tipo_movimiento,
    cantidad,
    fecha_movimiento,
    descripcion,
    id_pedido
)
SELECT
    dp.id_producto,
    'SALIDA',
    dp.cantidad,
    p.fecha_pedido,
    'Salida asociada al pedido ' || p.id_pedido,
    p.id_pedido
FROM detalle_pedido dp
INNER JOIN pedido p
    ON p.id_pedido = dp.id_pedido
WHERE p.estado <> 'CANCELADO';

-- Algunos ajustes manuales.

INSERT INTO movimiento_inventario (
    id_producto,
    tipo_movimiento,
    cantidad,
    fecha_movimiento,
    descripcion
)
VALUES
    (8, 'AJUSTE_NEGATIVO', 2, '2025-04-10 10:00:00-05', 'Productos dañados'),
    (12, 'AJUSTE_POSITIVO', 3, '2025-05-08 15:30:00-05', 'Corrección de inventario'),
    (18, 'AJUSTE_NEGATIVO', 5, '2025-06-01 09:20:00-05', 'Unidades defectuosas');

-- =========================================================
-- VERIFICACIÓN
-- =========================================================

SELECT COUNT(*) AS cantidad_clientes FROM cliente;
SELECT COUNT(*) AS cantidad_productos FROM producto;
SELECT COUNT(*) AS cantidad_pedidos FROM pedido;
SELECT COUNT(*) AS cantidad_detalles FROM detalle_pedido;