SELECT v.*,
       c.code,
	 c.currency,
       e.name,
       e.event_code,
       (v.time - $time_now ) seconds,
       (v.time - $time_now ) < $seconds_before checking
  FROM country c,
       event e ON (c.code IN ($code) OR 
                   c.currency IN ($currency) ) AND
                  c.id = e.country_id,
       value v ON e.id = v.event_id
 WHERE (e.name LIKE '%' || '$name' || '%' OR 
        '' = '$name') AND 
       v.time > ($time_now - $seconds_after) AND 
       impact_type IN ($impact) 
 GROUP BY v.event_id
HAVING MIN(v.time);