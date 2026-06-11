/*
TICKET: # 1003 - Customer Purchase Detail Review

REPORTER: Sales Audit Team

ISSUE:
Customer 'Laura Gómez' requested a detailed review of all products included in her orders.
The team needs to know the order date, current order status, product purchased,
category, quantity, unit price, discount percentage, line subtotal, and the representative
who handled the order.

ACTION:
Retrieve Laura Gómez's order detail by joining the customers, orders, order details,
products, categories, and employees tables.

IMPORTANT:
Some orders may not have an assigned employee, so the result must still show those orders.
Use 'Self-Service/Unassigned' when there is no employee.
*/

SET search_path TO comercio;

SELECT 
    p.id_pedido AS orderid,
    p.fecha_pedido AS fecha,
    p.estado AS estado,
    c.nombre || ' ' || c.apellido AS nombre_cliente,
    pr.nombre AS producto,
    cat.nombre AS categoria,
    dp.cantidad AS cantidad,
    dp.precio_unitario AS precio_unidad,
    dp.descuento_porcentaje AS descuento_porc,
    dp.subtotal AS subtotal,
    COALESCE (e.nombre || ' ' || e.apellido, 'Self-Service/Unassigned') AS asesor
FROM pedido p
JOIN cliente c ON p.id_cliente = c.id_cliente
JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
JOIN producto pr ON dp.id_producto = pr.id_producto 
JOIN categoria cat ON cat.id_categoria=pr.id_categoria
LEFT JOIN empleado e ON e.id_empleado = p.id_empleado
WHERE 'Laura Gómez' = c.nombre || ' ' || c.apellido
ORDER BY p.fecha_pedido DESC;

