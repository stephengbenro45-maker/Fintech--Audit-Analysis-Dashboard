      select * from fact_transactions
            limit 10;


			select * from dim_users;


       select * from fact_loans;



	   SELECT 
    COUNT(user_id) AS total_users,
    COUNT(DISTINCT region) AS total_regions_covered
    FROM dim_users;

     note   (1500 total users and 5 regions covered)
         




       SELECT 
    region, 
    COUNT(user_id) AS user_count,
    ROUND(COUNT(user_id) * 100.0 / (SELECT COUNT(*) 
	FROM dim_users), 2) AS population_pct
      FROM dim_users
          GROUP BY 1
          ORDER BY 2 DESC;




     SELECT 
    user_id, 
    full_name, 
    LENGTH(user_id) AS actual_length
     FROM dim_users;

	 

      UPDATE dim_users
    SET user_id = LPAD(user_id, 10, '0')
     WHERE LENGTH(user_id) < 10;


        SELECT 
    user_id, 
    full_name, 
    LENGTH(user_id) AS actual_length
     FROM dim_users
        WHERE LENGTH(user_id) != 10;
		

		  
   UPDATE dim_users
SET region = INITCAP(LOWER(region));
     




     SELECT 
    t.tx_id, 
    t.user_id AS transaction_user_id
     FROM fact_transactions t
       LEFT JOIN dim_users u ON t.user_id = u.user_id
       WHERE u.user_id IS NULL;

	note   (all transaction are assigned to a user)



	   SELECT 
    tx_id, 
    COUNT(*)
     FROM fact_transactions
      GROUP BY 1
       HAVING COUNT(*) > 1;


	 note  (no duplicated transaction no update required)



     select 
	     user_id,
		 region 
		 from dim_users
		 where region is null;
		 
    note  (no update required all users have region) 
		  


              SELECT 
    region, 
    SUM(principal) AS total_loan_amount,
    SUM(CASE WHEN UPPER(status) = 'LATE' THEN 1 ELSE 0 END) 
	AS late_count,
    SUM(CASE WHEN UPPER(status) = 'DEFAULTED' THEN 1 ELSE 0 END) 
	AS defaulted_count
        FROM dim_users AS u
       JOIN fact_loans AS l ON u.user_id = l.user_id
         GROUP BY 1
       ORDER BY total_loan_amount DESC;
	   


	   select 
	      max(amount),
		  min(amount)
		  from fact_transactions;


         
		
		
		                  SELECT 
					    kyc_level,
						 round(avg(amount),2) as avg_transaction_amount,
						  count(tx_Id) as total_transaction
						 from dim_users as u
						  join fact_transactions as t
						  on u.user_id = t.user_id
						  group by 1
						  order by avg_transaction_amount desc;


     select  
	 kyc_level,
	     count(u.user_id) as user_count
		  from dim_users as u
		  group by 1
		  order by 2 desc;
		  
		 
      
            SELECT 
					    kyc_level,
						  avg(amount) as avg_transaction_amount,
						  count(tx_Id) as total_transaction
						 from dim_users as u
						  join fact_transactions as t
						  on u.user_id = t.user_id
						  where kyc_level = 'Tier 1'
						  group by 1;
          
		  
		  
		  WITH ceiling_audit AS (
                     SELECT 
                        u.full_name,
                         u.kyc_level,
                        t.amount,
                        t.tx_timestamp,
       COUNT(*) OVER(PARTITION BY u.user_id) as total_ceiling_hits,
        ROUND(AVG(t.amount) OVER(PARTITION BY u.user_id), 2) as avg_ceiling_spend
    FROM dim_users u
    JOIN fact_transactions t ON u.user_id = t.user_id
    WHERE u.kyc_level = 'Tier 1' 
      AND t.amount BETWEEN 48000 AND 50000
)
        SELECT * 
           FROM ceiling_audit
              WHERE total_ceiling_hits >= 3
                ORDER BY total_ceiling_hits DESC, full_name, tx_timestamp;


						 

    SELECT 
	   kyc_level,
    u.full_name, 
    SUM(t.amount) AS total_volume 
         FROM dim_users u 
           JOIN fact_transactions t ON u.user_id = t.user_id 
             GROUP BY 1,2
                ORDER BY 3 DESC 
                  LIMIT 10;



             WITH top_whale AS (
    SELECT 
        u.user_id,
        u.full_name,
        u.kyc_level,
        t.amount,
        COUNT(t.tx_id) OVER() as total_lifetime_tx,
        CASE WHEN t.amount BETWEEN 48000 AND 50000 THEN 1 ELSE 0 END as is_ceiling_hit
    FROM dim_users u
    JOIN fact_transactions t ON u.user_id = t.user_id
    WHERE u.full_name = 'Customer_52' 
      )
        SELECT 
    full_name,
    kyc_level,
    total_lifetime_tx,
    SUM(is_ceiling_hit) as total_ceiling_hits,
    ROUND(AVG(amount), 2) as avg_tx_size,
    ROUND((SUM(is_ceiling_hit)::numeric / total_lifetime_tx) * 100, 2)
	AS frustration_percentage
FROM top_whale
GROUP BY 1, 2, 3;
				     






					SELECT 
    region,
    total_loan_amount,
    late_count,
    ROUND(CAST(late_count AS NUMERIC) / total_loan_count * 100, 2) AS delinquency_rate
     FROM dim_users 
	 join 
        ORDER BY total_loan_amount DESC;






						  
             with user_money as ( 
						  select 
						     full_name,
							  region,
							  sum(amount) as money_spent
							  from dim_users as u
						  join fact_transactions  as t
						  on u.user_id = t.user_id
						   group by 1,2
						   ),
						   ranked_user as (
						   select 
						      full_name,
							  region,
							   money_spent,
							   row_number() over(partition by region
							   order by money_spent desc) as user_rank 
							   from user_money
							   ) 
							   select * from ranked_user
							   where user_rank <= 5
							   order by region,user_rank;





                     select 
				     region,
					 sum(principal) as total_loan_amount,
					 sum(case 
					          when status = 'Late' then 1 else 0 end)
							  as late_count
							  FROM dim_users AS u
                                 JOIN fact_loans AS l 
					               ON u.user_id = l.user_id
                                GROUP BY 1
								order by total_loan_amount desc;



                        select 
						    count(user_id) as new_user_count,
							DATE_TRUNC('month',signup_date) as months
							from dim_users
							group by 2
							order by 2;






			SELECT u.full_name, 
			SUM(t.amount) as total_amount,
			count(tx_id) as transaction_count
           FROM dim_users u
                 JOIN fact_transactions t 
                     ON u.user_id = t.user_id
                        GROUP BY 1
                          HAVING SUM(t.amount) > 500000
						  order by 2 desc;






               SELECT 
    u.region, 
    round(COUNT(t.tx_id),2)::FLOAT / COUNT(DISTINCT u.user_id)
	AS avg_transactions_per_user 
FROM dim_users u 
JOIN fact_transactions t ON u.user_id = t.user_id 
GROUP BY 1
ORDER BY 2 DESC;


                  



							SELECT 
    u.full_name, 
    SUM(DISTINCT l.principal) AS total_loans,
    SUM(DISTINCT t.amount) AS total_spent
    FROM dim_users u
      JOIN fact_loans l 
      ON u.user_id = l.user_id
     JOIN fact_transactions t 
      ON u.user_id = t.user_id
     GROUP BY 1
     order by 3
      limit 10;



           WITH high AS (
    SELECT
        full_name,
        SUM(amount) AS total_spent
    FROM dim_users AS u
    JOIN fact_transactions AS t ON u.user_id = t.user_id
    GROUP BY 1
    ORDER BY total_spent DESC 
    LIMIT 10
)
SELECT
    SUM(total_spent) AS top_10_total,
    (SELECT SUM(amount) FROM fact_transactions) 
	AS total_company_volume,
    ROUND(SUM(total_spent) / (SELECT SUM(amount) 
	FROM fact_transactions) * 100, 2) AS idan_percent
     FROM high;


			   


				 
                  SELECT 
      u.user_id,
       u.full_name,
      u.region
     FROM dim_users u
      LEFT JOIN fact_transactions t ON u.user_id = t.user_id
      LEFT JOIN fact_loans l ON u.user_id = l.user_id
     WHERE t.user_id IS NULL 
     AND l.user_id IS NULL;



	     
		 
		 select 
				   region,
				   count(u.user_id) as silent_users
				   FROM dim_users u
      LEFT JOIN fact_transactions t ON u.user_id = t.user_id
      LEFT JOIN fact_loans l ON u.user_id = l.user_id
     WHERE t.user_id IS NULL 
     AND l.user_id IS NULL
	    group by region
		 order by silent_users desc;



		 
		 
		 SELECT 
      region,
    COUNT(u.user_id) as silent_users,
    COUNT(u.user_id) * 2000 as potential_revenue
          FROM dim_users u
       LEFT JOIN fact_transactions t ON u.user_id = t.user_id
      LEFT JOIN fact_loans l ON u.user_id = l.user_id
     WHERE t.user_id IS NULL AND l.user_id IS NULL
      GROUP BY 1
     ORDER BY 3 DESC;







		     WITH active_early AS (
         SELECT DISTINCT user_id 
    FROM fact_transactions 
    WHERE tx_timestamp >= '2026-01-01'
	      and tx_timestamp < '2026-03-01'
    ),
      active_recent AS (
    SELECT DISTINCT user_id 
    FROM fact_transactions 
    WHERE tx_timestamp >= '2026-03-01'
     )
     SELECT 
    aearly.user_id,
    u.full_name
    FROM active_early AS aearly
    LEFT JOIN active_recent AS arecent ON aearly.user_id = arecent.user_id
     JOIN dim_users AS u ON aearly.user_id = u.user_id
     WHERE arecent.user_id IS NULL;  





              SELECT 
			       region,
			      channel,
				    sum(amount) as total_amount 
					from fact_transactions as t
					join dim_users as u
					 on t.user_id = u.user_id
					GROUP BY 1,2
					order by total_amount ;
					
	          

   
      select 
	      channel,
		    sum(amount) as total_revenue 
			 from fact_transactions 
			 group by 1




	 
			