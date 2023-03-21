SELECT v.*,
       c.code,
       c.currency,
       e.name,
       e.event_code,
	 e.importance,
       (v.time - %d) seconds
  FROM n.value v,
       n.event e ON v.time <= (%d + %d) AND
		    v.time >= (%d - %d) AND 
		    e.id = v.event_id,
       n.country c ON c.id = e.country_id
ORDER BY v.time