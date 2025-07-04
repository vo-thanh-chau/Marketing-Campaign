-- PHÂN TÍCH HIỆU QUẢ CHIẾN DỊCH MARKETING VÀ HÀNH VI KHÁCH HÀNG

-- Khách hàng đã tương tác nhưng chưa mua hàng
-- > Xác định khách hàng tiềm năng, cần áp dụng hình thức khuyến mãi để chuyển đổi thành doanh số
SELECT DISTINCT i.customer_id
FROM Interactions i
LEFT JOIN Sales s ON i.customer_id = s.customer_id AND i.campaign_id = s.campaign_id
WHERE s.customer_id IS NULL;

-- ROI theo từng chiến dịch
-- > Hỗ trợ phân bổ ngân sách hợp lý hơn trong các chiến dịch tương lai
-- -> Đánh giá hiệu suất của phòng Marketing hoặc các Agency
SELECT 
    c.campaign_id,
    c.name,
    c.budget,
    COALESCE(SUM(s.price_usd), 0) AS revenue,
    ROUND((COALESCE(SUM(s.price_usd), 0) - c.budget) / c.budget * 100, 2) AS roi_pct
FROM Campaigns c
LEFT JOIN Sales s ON c.campaign_id = s.campaign_id
GROUP BY c.campaign_id, c.name, c.budget;

-- Sản phẩm được ưa chuộng theo độ tuổi khách hàng
-- > Giúp doanh nghiệp thiết kế chiến dịch quảng bá phù hợp cho từng độ tuổi
SELECT 
    c.age,
    s.product,
    COUNT(*) AS times_bought
FROM Sales s
JOIN Customers c ON s.customer_id = c.customer_id
GROUP BY c.age, s.product
ORDER BY c.age, times_bought DESC;

-- Kênh Influencer hiệu quả nhất theo từng loại chiến dịch
SELECT
  c.name,
  i.platform,
  SUM(s.price_usd) AS revenue
FROM Influencers i
JOIN Campaigns c ON i.campaign_id = c.campaign_id
JOIN Sales s ON s.campaign_id = c.campaign_id
GROUP BY c.name, i.platform
ORDER BY c.name, revenue DESC;

-- 	Tìm top sản phẩm "mồi" – thường được mua đầu tiên
-- > Xác định đâu là sản phẩm để dẫn khách tới hệ sinh thái
WITH FirstPurchase AS (
  SELECT 
    customer_id, 
    MIN(purchase_date) AS first_date
  FROM Sales
  GROUP BY customer_id
),
FirstProduct AS (
  SELECT s.customer_id, s.product
  FROM Sales s
  JOIN FirstPurchase fp ON s.customer_id = fp.customer_id AND s.purchase_date = fp.first_date
)
SELECT product, COUNT(*) AS first_purchases
FROM FirstProduct
GROUP BY product
ORDER BY first_purchases DESC
LIMIT 5;

-- Tỉ lệ khách tương tác nhưng không mua hàng theo chiến dịch?
-- > Đâu là chiến dịch kém chất lượng: nhiều tương tác nhưng thiếu chuyển đổi?
SELECT 
    c.campaign_id,
    COUNT(DISTINCT i.customer_id) AS total_interacted,
    COUNT(DISTINCT s.customer_id) AS total_bought,
    (1 - COUNT(DISTINCT s.customer_id) / COUNT(DISTINCT i.customer_id)) AS bounce_rate
FROM Campaigns c
JOIN Interactions i ON c.campaign_id = i.campaign_id
LEFT JOIN Sales s ON s.customer_id = i.customer_id AND s.campaign_id = c.campaign_id
GROUP BY c.campaign_id
HAVING total_interacted >= 10;
