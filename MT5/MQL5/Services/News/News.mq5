//+------------------------------------------------------------------+
//|                                                         News.mq5 |
//|                                         Copyright 2023, SnowBars |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property service
#property copyright "Copyright 2023, SnowBars"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
#resource "\\SQL\\create_db.sql" as string sql_create_db;
//+------------------------------------------------------------------+
#include "SQLite\CSQLite.1.21.mqh"
//+------------------------------------------------------------------+
input datetime InpDateFrom = D'01.01.2021'; // Date From
//+------------------------------------------------------------------+
//--- структура под хранение событий календаря с вещественными значениями
struct AdjustedCalendarValue
  {
   ulong                               id;                    // ID значения
   ulong                               event_id;              // ID события
   datetime                            time;                  // время и дата события
   datetime                            period;                // отчетный период события
   int                                 revision;              // ревизия публикуемого индикатора по отношению к отчетному периоду
   double                              actual_value;          // актуальное значение показателя
   double                              prev_value;            // предыдущее значение показателя
   double                              revised_prev_value;    // пересмотренное предыдущее значение показателя
   double                              forecast_value;        // прогнозное значение показателя
   ENUM_CALENDAR_EVENT_IMPACT          impact_type;           // потенциальное влияние на курс валюты
  };
//+------------------------------------------------------------------+
CSQLite m_db;
//+------------------------------------------------------------------+
string sql_insert_country = "INSERT OR IGNORE INTO country VALUES (%lld,'%s','%s','%s','%s','%s');";
string sql_insert_event = "INSERT OR IGNORE INTO event VALUES (%lld,%d,%d,%d,%d,%lld,%d,%d,%d,%d,'%s','%s','%s');";
string sql_insert_value = "INSERT OR %s INTO value VALUES (%lld,%lld,%d,%d,%d,%s,%s,%s,%s,%d);";
string sql_insert_change = "INSERT OR IGNORE INTO event_change VALUES (%lld,%d);";
//+------------------------------------------------------------------+
//| Service program start function                                   |
//+------------------------------------------------------------------+
void OnStart()
  {
   m_db.SetName("news.db");
   if(!m_db.Execute(sql_create_db))
     {
      Print("Error: DataBase is not create!");
      return;
     }

//---
   if(!CountriesToDataBase())
      if(_LastError>0)
         Print("Error: ",_LastError);

   while(!IsStopped())
     {
      CheckCalendar();

      Sleep(1000);
     }
  }
//+------------------------------------------------------------------+
bool CountriesToDataBase()
  {
   MqlCalendarCountry countries[];
   int total = CalendarCountries(countries);
   string query;

   m_db.TransactionBegin();

   for(int i=0; i<total; i++)
     {
      query = StringFormat(sql_insert_country,
                           countries[i].id,
                           countries[i].name,
                           countries[i].code,
                           countries[i].currency,
                           countries[i].currency_symbol,
                           countries[i].url_name);

      if(!m_db.Execute(query))
         return false;
     }

   m_db.TransactionEnd(true);

   for(int i=0; i<total; i++)
     {
      if(!EventsToDataBase(countries[i]))
         return false;
     }

   return true;
  }
//+------------------------------------------------------------------+
bool EventsToDataBase(MqlCalendarCountry &country)
  {
   MqlCalendarEvent events[];
   int total = CalendarEventByCountry(country.code,events);
   string query;

   m_db.TransactionBegin();

   for(int i=0; i<total; i++)
     {
      StringReplace(events[i].name,"'","\"");
      query = StringFormat(sql_insert_event,
                           events[i].id,
                           events[i].type,
                           events[i].sector,
                           events[i].frequency,
                           events[i].time_mode,
                           events[i].country_id,
                           events[i].unit,
                           events[i].importance,
                           events[i].multiplier,
                           events[i].digits,
                           events[i].source_url,
                           events[i].event_code,
                           events[i].name);

      if(!m_db.Execute(query))
         return false;
     }

   m_db.TransactionEnd(true);

   for(int i=0; i<total; i++)
     {
      MqlCalendarValue values[];
      if(!CalendarValueHistoryByEvent(events[i].id,values,InpDateFrom))
         continue;

      if(!ValuesToDataBase(values))
         return false;
     }

   return true;
  }
//+------------------------------------------------------------------+
bool ValuesToDataBase(MqlCalendarValue &values[], bool replace=false)
  {
   int total = ArraySize(values);
   string query;

   m_db.TransactionBegin();

   for(int i=0; i<total; i++)
     {
      query = StringFormat(sql_insert_value,
                           replace?"REPLACE":"IGNORE",
                           values[i].id,
                           values[i].event_id,
                           values[i].time,
                           values[i].period,
                           values[i].revision,
                           values[i].HasActualValue()?DoubleToString(values[i].GetActualValue()):"null",
                           values[i].HasPreviousValue()?DoubleToString(values[i].GetPreviousValue()):"null",
                           values[i].HasRevisedValue()?DoubleToString(values[i].GetRevisedValue()):"null",
                           values[i].HasForecastValue()?DoubleToString(values[i].GetForecastValue()):"null",
                           values[i].impact_type);

      if(!m_db.Execute(query))
         return false;
     }

   return m_db.TransactionEnd(true);
  }
//+------------------------------------------------------------------+
void CheckCalendar()
  {
//--- идентификатор изменения базы Календаря
   static ulong calendar_change_id=m_db.GetLong("SELECT IFNULL(MAX(id),0) FROM event_change;");
//--- массив значений событий
   MqlCalendarValue values[];
//--- у нас есть последнее известное значение идентификатора изменения Календаря (change_id)
   ulong old_change_id=calendar_change_id;
//--- проверим - не появились ли новые события Календаря
   if(CalendarValueLast(calendar_change_id,values)>0)
     {
      PrintFormat("%s: Получены новые события Календаря: %d",
                  __FUNCTION__,ArraySize(values));
      //--- выведем в Журнал информацию из массива values
      ArrayPrint(values);
      //--- выведем в Журнал значения предыдущего и нового идентификатора Календаря
      PrintFormat("%s: Предыдущий change_id=%d, новый change_id=%d",
                  __FUNCTION__,old_change_id,calendar_change_id);

      string query = StringFormat(sql_insert_change,calendar_change_id,ArraySize(values));
      m_db.Execute(query);

      ValuesToDataBase(values,true);
     }
  }
//+------------------------------------------------------------------+
