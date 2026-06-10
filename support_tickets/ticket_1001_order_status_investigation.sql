/*
TICKET: # 1001 - Order Status Investigation
REPORTER: Customer Experience Team
ISSUE: Customer 'Juan López' requested a complete breakdown of his order history, current statuses, and the name of the representative who handled each case.
ACTION: Retrieve order history by joining the orders, customers, and employees tables.
*/

SET search_path TO comercio;

SELECT 
    p.id_pedido AS order_id,
    p.fecha_pedido AS order_date,
    p.estado AS current_status,
    c.nombre || ' ' || c.apellido AS customer_name,
    COALESCE(e.nombre || ' ' || e.apellido, 'Self-Service/Unassigned') AS handled_by,
    p.total AS order_total
FROM pedido p
JOIN cliente c 
    ON p.id_cliente = c.id_cliente
LEFT JOIN empleado e 
    ON p.id_empleado = e.id_empleado
WHERE c.correo = 'juan.lopez@email.com'
ORDER BY p.fecha_pedido DESC;

