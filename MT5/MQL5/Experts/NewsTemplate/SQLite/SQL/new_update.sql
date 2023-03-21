SELECT (
           SELECT IFNULL(MAX(id), 0) 
             FROM event_change
       )
<>      (
           SELECT IFNULL(MAX(id), 0) 
             FROM n.event_change
       );