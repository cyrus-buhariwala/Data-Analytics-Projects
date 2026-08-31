create database e_commerce_activities

select * from user_activities

-- Let's see the numbers that show the sales funnel stages

WITH sales_funnel AS(
	SELECT
		COUNT(DISTINCT CASE WHEN event_type='page_view' THEN user_id END) AS view_stage,
		COUNT(DISTINCT CASE WHEN event_type='add_to_cart' THEN user_id END) AS cart_stage,
		COUNT(DISTINCT CASE WHEN event_type='checkout_start' THEN user_id END) AS checkout_stage,
		COUNT(DISTINCT CASE WHEN event_type='payment_info' THEN user_id END) AS payment_info_stage,
		COUNT(DISTINCT CASE WHEN event_type='purchase' THEN user_id END) AS purchase_stage
	FROM user_activities
)

SELECT * FROM sales_funnel

-- Let's display the conversion rates between stages

WITH sales_funnel AS(
	SELECT
		COUNT(DISTINCT CASE WHEN event_type='page_view' THEN user_id END) AS view_stage,
		COUNT(DISTINCT CASE WHEN event_type='add_to_cart' THEN user_id END) AS cart_stage,
		COUNT(DISTINCT CASE WHEN event_type='checkout_start' THEN user_id END) AS checkout_stage,
		COUNT(DISTINCT CASE WHEN event_type='payment_info' THEN user_id END) AS payment_info_stage,
		COUNT(DISTINCT CASE WHEN event_type='purchase' THEN user_id END) AS purchase_stage
	FROM user_activities
)

SELECT
	ROUND(cart_stage*100.0/view_stage,2) AS view_to_cart_conversion,
	ROUND(checkout_stage*100.0/cart_stage,2) AS cart_to_checkout_conversion,
	ROUND(payment_info_stage*100.0/cart_stage,2) AS checkout_to_payment_info_conversion,
	ROUND(purchase_stage*100.0/payment_info_stage,2) AS payment_info_to_purchase_conversion
FROM sales_funnel

-- Now let's display the same funnel metrics by traffic source

WITH sales_funnel_by_source AS(
	SELECT
		traffic_source,
		COUNT(DISTINCT CASE WHEN event_type='page_view' THEN user_id END) AS view_stage,
		COUNT(DISTINCT CASE WHEN event_type='add_to_cart' THEN user_id END) AS cart_stage,
		COUNT(DISTINCT CASE WHEN event_type='checkout_start' THEN user_id END) AS checkout_stage,
		COUNT(DISTINCT CASE WHEN event_type='payment_info' THEN user_id END) AS payment_info_stage,
		COUNT(DISTINCT CASE WHEN event_type='purchase' THEN user_id END) AS purchase_stage
	FROM user_activities
	GROUP BY traffic_source
)

SELECT * FROM sales_funnel_by_source

-- Let's also display the conversion rates grouped by traffic source

WITH sales_funnel_by_source AS(
	SELECT
		traffic_source,
		COUNT(DISTINCT CASE WHEN event_type='page_view' THEN user_id END) AS view_stage,
		COUNT(DISTINCT CASE WHEN event_type='add_to_cart' THEN user_id END) AS cart_stage,
		COUNT(DISTINCT CASE WHEN event_type='checkout_start' THEN user_id END) AS checkout_stage,
		COUNT(DISTINCT CASE WHEN event_type='payment_info' THEN user_id END) AS payment_info_stage,
		COUNT(DISTINCT CASE WHEN event_type='purchase' THEN user_id END) AS purchase_stage
	FROM user_activities
	GROUP BY traffic_source
)

SELECT
	traffic_source,
	ROUND(cart_stage*100.0/view_stage,2) AS view_to_cart_conversion,
	ROUND(checkout_stage*100.0/cart_stage,2) AS cart_to_checkout_conversion,
	ROUND(payment_info_stage*100.0/cart_stage,2) AS checkout_to_payment_info_conversion,
	ROUND(purchase_stage*100.0/payment_info_stage,2) AS payment_info_to_purchase_conversion
FROM sales_funnel_by_source

-- Let's display how effectively each traffic source is converting views to purchases


WITH sales_funnel_by_source AS(
	SELECT
		traffic_source,
		COUNT(DISTINCT CASE WHEN event_type='page_view' THEN user_id END) AS view_stage,
		COUNT(DISTINCT CASE WHEN event_type='add_to_cart' THEN user_id END) AS cart_stage,
		COUNT(DISTINCT CASE WHEN event_type='checkout_start' THEN user_id END) AS checkout_stage,
		COUNT(DISTINCT CASE WHEN event_type='payment_info' THEN user_id END) AS payment_info_stage,
		COUNT(DISTINCT CASE WHEN event_type='purchase' THEN user_id END) AS purchase_stage
	FROM user_activities
	GROUP BY traffic_source
)

SELECT
	traffic_source,
	ROUND(purchase_stage*100.0/view_stage,2) AS view_to_purchase_conversion
FROM sales_funnel_by_source
ORDER BY view_to_purchase_conversion DESC

-- Finally, let's look at the average order value by traffic source

WITH sales_funnel_revenue AS(
	SELECT
		traffic_source,
		COUNT(DISTINCT CASE WHEN event_type='page_view' THEN user_id END) AS total_views,
		COUNT(DISTINCT CASE WHEN event_type='purchase' THEN user_id END) AS total_unique_buyers,
		SUM(CASE WHEN event_type='purchase' THEN amount END) AS total_revenue,
		COUNT(CASE WHEN event_type='purchase' THEN 1 END) AS total_purchases
	FROM user_activities
	GROUP BY traffic_source
)

SELECT
	traffic_source,
	total_views,
	total_unique_buyers,
	total_revenue,
	total_purchases,
	ROUND(total_revenue*1.0/total_purchases,2) AS average_order_amount,
	ROUND(total_revenue*1.0/total_views,2) AS revenue_per_view
FROM sales_funnel_revenue