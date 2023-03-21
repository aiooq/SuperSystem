INSERT OR REPLACE INTO n.value SELECT v.*
                                 FROM value v
                                      LEFT JOIN
                                      n.value nv ON v.id = nv.id
                                WHERE v.time >= %d - %d AND 
                                      v.time <= %d + %d AND 
                                      (v.actual_value <> nv.actual_value OR 
                                       v.prev_value <> IFNULL(nv.prev_value, 0) OR 
                                       v.revised_prev_value <> nv.revised_prev_value OR 
                                       v.forecast_value <> nv.forecast_value);