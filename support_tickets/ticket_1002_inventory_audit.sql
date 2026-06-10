/*
TICKET: # 1002 - Inventory Data Quality Audit
REPORTER: Operations Manager
ISSUE: Suspected mismatch between physically registered stock and system-calculated remaining stock based on sales. 
ACTION: Use CTEs to aggregate total sold units per product and compare against current stock and minimum thresholds to identify anomalies.
*/

SET search_path TO comercio;

WITH SalesAggregation AS (
    -- Calculamos cuántas unidades se han vendido realmente (ignorando pedidos cancelados)
    SELECT 
        dp.id_producto,
        SUM(dp.cantidad) as total_unidades_vendidas
    FROM detalle_pedido dp
    JOIN pedido p ON dp.id_pedido = p.id_pedido
    WHERE p.estado != 'CANCELADO'
    GROUP BY dp.id_producto
)
SELECT 
    pr.codigo AS product_code,
    pr.nombre AS product_name,
    pr.stock AS current_system_stock,
    COALESCE(sa.total_unidades_vendidas, 0) AS units_sold,
    pr.stock_minimo AS minimum_required_stock,
    CASE 
        WHEN pr.stock <= 0 THEN 'CRITICAL: OUT OF STOCK'
        WHEN pr.stock <= pr.stock_minimo THEN 'WARNING: LOW STOCK'
        ELSE 'HEALTHY'
    END AS inventory_status
FROM producto pr
LEFT JOIN SalesAggregation sa ON pr.id_producto = sa.id_producto
ORDER BY pr.stock ASC;