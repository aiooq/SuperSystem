INSERT OR IGNORE INTO n.country SELECT *
                                  FROM country
                                 WHERE currency IN ('ALL',%s);

INSERT OR IGNORE INTO n.event SELECT *
                                FROM event
                               WHERE country_id IN (
                                         SELECT id
                                           FROM n.country
                                     ) AND importance IN (%s) AND
					(name = '%s' OR '%s' = '');

INSERT OR IGNORE INTO n.value SELECT *
                                FROM value
                               WHERE event_id IN (
                                         SELECT id
                                           FROM n.event
                                     ) AND impact_type IN (%s)
AND 
                                     time >= %d - %d AND 
                                     time <= %d + %d;

DELETE FROM n.value
      WHERE time < %d - %d OR 
            time > %d + %d;

INSERT OR IGNORE INTO n.event_change SELECT *
                                       FROM event_change;