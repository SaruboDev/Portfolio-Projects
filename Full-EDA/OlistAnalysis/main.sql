-- Making the Geolocation View with only the means.

DROP VIEW IF EXISTS mean_geolocation;

CREATE VIEW mean_geolocation AS 
WITH mean_geo AS (
    SELECT geolocation_zip_code_prefix, AVG(geolocation_lat) AS mean_geo_lat, AVG(geolocation_lng) AS mean_geo_lng FROM geolocation
    GROUP BY geolocation_zip_code_prefix
)

SELECT * FROM mean_geo;

-- Making the View for the Delivery Date Estimation.

DROP VIEW IF EXISTS customer_order_time_finished;

CREATE VIEW customer_order_time_finished AS

WITH customer_order_time AS (
    SELECT
    -- Customer Location
        ord.customer_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        geo.mean_geo_lat AS customer_geo_lat,
        geo.mean_geo_lng AS customer_geo_lng,

    -- Seller Location
        ordit.seller_id,
        sells.seller_zip_code_prefix,
        sells.seller_city,
        sells.seller_state,
        geo2.mean_geo_lat AS seller_geo_lat,
        geo2.mean_geo_lng AS seller_geo_lng,

    -- Order Factors
        ord.order_id,
        ordit.order_item_id,
        COUNT(prod.product_id) AS count_product_id, -- We count each product in the group, so we only get 1 line for each
        SUM(prod.product_weight_g) AS sum_product_weight_g, -- For all measurements i'll consider as if each box is separate, so we just get the total
        SUM(prod.product_height_cm) AS sum_product_height_cm,
        SUM(prod.product_width_cm) AS sum_product_width_cm,
        SUM(prod.product_length_cm) AS sum_product_length_cm,
        SUM(ordit.freight_value) AS summed_freight_value,

    -- Order timestamps
        MIN(order_purchase_timestamp) AS min_order_purchase_timestamp, -- Should be the same across all if their order item id is continuous, but we get the min one
        MAX(order_delivered_carrier_date) AS max_order_delivered_carrier_date,
        MAX(order_delivered_customer_date) AS max_order_delivered_customer_date,
        MAX(order_estimated_delivery_date) AS max_order_estimated_delivery_date
    FROM orders AS ord

    LEFT JOIN customers AS cust ON cust.customer_id = ord.customer_id
    LEFT JOIN order_items AS ordit ON ord.order_id = ordit.order_id
    LEFT JOIN products AS prod ON ordit.product_id = prod.product_id
    LEFT JOIN sellers AS sells ON ordit.seller_id = sells.seller_id
    LEFT JOIN mean_geolocation AS geo ON geo.geolocation_zip_code_prefix = customer_zip_code_prefix
    LEFT JOIN mean_geolocation AS geo2 ON geo2.geolocation_zip_code_prefix = seller_zip_code_prefix

    WHERE order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL
    GROUP BY
        ord.order_id, 
        ord.customer_id, 
        ordit.seller_id,
        cust.customer_zip_code_prefix, 
        cust.customer_city, 
        cust.customer_state,
        sells.seller_zip_code_prefix, 
        sells.seller_city, 
        sells.seller_state
),
customer_order_time_finished AS (
    -- Just counted the days between the client bought the item(s) and when the delivery completed.
    SELECT *,
    (julianday(max_order_delivered_customer_date) - julianday(min_order_purchase_timestamp)) AS delivery_days
    FROM customer_order_time
)
SELECT * FROM customer_order_time_finished;

-- Making the EDA dataset with the most important columns through every table.

DROP VIEW IF EXISTS eda_olist_complete;

CREATE VIEW eda_olist_complete AS
WITH customer_seller_clean AS
(SELECT
    cust.customer_unique_id,
    cust.customer_city,
    cust.customer_state,

    ords_it.seller_id,
    sells.seller_city,
    sells.seller_state,

    ords_it.product_id,
    nam.product_category_name_english,
    prod.product_weight_g,
    prod.product_length_cm,
    prod.product_height_cm,
    prod.product_width_cm,
    ords_it.price,
    ords_it.freight_value,

    pays.payment_type,
    pays.payment_installments,
    pays.payment_value,

    ords.order_id,
    ords.order_status,
    ords.order_purchase_timestamp,
    ords.order_approved_at,
    ords.order_delivered_customer_date,

    revs.review_id,
    revs.review_score,
    revs.review_comment_title,
    revs.review_comment_message,
    revs.review_creation_date,
    revs.review_answer_timestamp

FROM customers AS cust
LEFT JOIN orders AS ords ON cust.customer_id = ords.customer_id
LEFT JOIN order_items AS ords_it ON ords.order_id = ords_it.order_id
LEFT JOIN sellers AS sells ON ords_it.seller_id = sells.seller_id
LEFT JOIN products AS prod ON ords_it.product_id = prod.product_id
LEFT JOIN name_translations AS nam ON prod.product_category_name = nam.product_category_name
LEFT JOIN order_payments AS pays ON ords.order_id = pays.order_id
LEFT JOIN order_reviews AS revs ON ords.order_id = revs.order_id

WHERE
    cust.customer_city IS NOT NULL
    AND cust.customer_state IS NOT NULL
    AND ords_it.seller_id IS NOT NULL
    AND nam.product_category_name_english IS NOT NULL
    and ords.order_delivered_customer_date IS NOT NULL
)
SELECT * FROM customer_seller_clean