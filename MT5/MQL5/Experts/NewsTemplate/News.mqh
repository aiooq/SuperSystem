//+------------------------------------------------------------------+
//|                                                      Program.mqh |
//|                                         Copyright 2023, SnowBars |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, SnowBars"
#property link      "https://www.mql5.com"
#property version   "1.16"
//+------------------------------------------------------------------+
#resource "\\SQLite\\SQL\\select.sql" as string sql_select;
#resource "\\SQLite\\SQL\\insert.sql" as string sql_insert;
#resource "\\SQLite\\SQL\\create_db.sql" as string sql_create_db;
#resource "\\SQLite\\SQL\\sync_db.sql" as string sql_sync_db;
#resource "\\SQLite\\SQL\\new_update.sql" as string sql_new_update;
//+------------------------------------------------------------------+
#include "SQLite\CSQLite.1.21.mqh"
#include "TimeCounter.mqh"
//+------------------------------------------------------------------+
struct struct_news_values
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
   string                              country_code;
   string                              currency;
   string                              name;
   string                              event_code;
   int                                 importance;
   int                                 seconds;
   //bool                                cheking;
  };
//+------------------------------------------------------------------+
class CNews
  {
private:
   CSQLite           m_db;

   CTimeCounter      m_timer_D1;

   bool              m_is_tester,
                     m_is_updated;

   int               m_total;

   uint              m_seconds_for_values,
                     m_seconds_before_news,
                     m_seconds_after_news;

   string            m_currencies,
                     m_importance,
                     m_impact_type,
                     m_name,
                     m_description;

public:
                     CNews();
                    ~CNews();

   struct_news_values data[];

   bool              Init(
      string currencies = "USD,EUR",
      uint seconds_before_news = 86400,
      uint seconds_after_news = 86400,
      const string importance = "0,1,2",
      const string impact_type = "0,1,2",
      const string name = "");

   void              Tick();
   void              Timer();
   string            GetDescription() { return m_description; }

   bool              IsUpdated();
   int               Total() { return m_total; }

private:
   void              TimerForRealTime();
   void              TimerForTester();
   bool              GetByParameters();
   bool              Filling();
   bool              Updating();
   void              Removing();
   bool              SetDescription();

  };
//+------------------------------------------------------------------+
CNews::CNews()
  {
   m_total = 0;
   m_timer_D1.SetPause(PeriodSeconds(PERIOD_D1)*1000);
   m_seconds_for_values = PeriodSeconds(PERIOD_D1)*2;

   m_db.SetName("news.db");
   m_db.Execute("ATTACH DATABASE ':memory:' AS n;");
   if(m_db.Execute(sql_create_db))
      Print("DataBase in memory for news: Created!");
   else
      Print("DataBase in memory for news: Error!");

   m_is_tester = MQLInfoInteger(MQL_OPTIMIZATION) ||
                 MQLInfoInteger(MQL_VISUAL_MODE) ||
                 MQLInfoInteger(MQL_FRAME_MODE) ||
                 MQLInfoInteger(MQL_FORWARD) ||
                 MQLInfoInteger(MQL_TESTER);
  }
//+------------------------------------------------------------------+
CNews::~CNews()
  {
  }
//+------------------------------------------------------------------+
bool CNews::Init(
   string currencies = "USD,EUR",
   uint seconds_before_news = 86400,
   uint seconds_after_news = 86400,
   const string importance = "0,1,2",
   const string impact_type = "0,1,2",
   const string name = "")
  {
   currencies = StringFormat("'%s'",currencies);
   StringReplace(currencies,",","','");

   if(seconds_before_news > 86400)
      seconds_before_news = 86400;

   if(seconds_after_news > 86400)
      seconds_after_news = 86400;

   m_currencies = currencies;
   m_seconds_before_news = seconds_before_news;
   m_seconds_after_news = seconds_after_news;
   m_importance = importance;
   m_impact_type = impact_type;
   m_name = name;

   return GetByParameters() && Filling();
  }
//+------------------------------------------------------------------+
void CNews::Tick()
  {
   Timer();
  }
//+------------------------------------------------------------------+
void CNews::Timer()
  {
   static datetime time_last = 0;
   if(time_last==TimeCurrent())
      return;

   if(m_is_tester)
      TimerForTester();
   else
      TimerForRealTime();

   Removing();

   time_last = TimeCurrent();
  }
//+------------------------------------------------------------------+
void CNews::TimerForTester()
  {
   static MqlDateTime s_dt;

   MqlDateTime dt;
   datetime time_current = TimeCurrent(dt);

   if(dt.day!=s_dt.day)
      if(!GetByParameters())
         Print("GetByParameters:Error!");

   //if((dt.min!=s_dt.min && dt.min % 5 == 0) ||
   //   (StructToTime(dt)-300>StructToTime(s_dt)))
      if(!Filling())
         Print("Filling:Error!");

   s_dt = dt;
  }
//+------------------------------------------------------------------+
void CNews::TimerForRealTime()
  {
   if(m_timer_D1.Check())
      if(!GetByParameters())
         Print("GetByParameters:Error!");

   if(!m_db.GetInt(sql_new_update))
      return;

//if(Updating())
   if(!Filling())
      Print("Filling:Error!");
  }
//+------------------------------------------------------------------+
bool CNews::GetByParameters()
  {
//Print("GetByParameters");
   datetime time_current = TimeCurrent();

   string query = StringFormat(sql_sync_db,
                               m_currencies,
                               m_importance,
                               m_name,
                               m_name,
                               m_impact_type,
                               time_current,
                               m_seconds_for_values,
                               time_current,
                               m_seconds_for_values,
                               time_current,
                               m_seconds_for_values,
                               time_current,
                               m_seconds_for_values);

   return m_db.Execute(query) && Filling();
  }
//+------------------------------------------------------------------+
bool CNews::Updating()
  {
//Print("Updating");
   datetime time_current = TimeCurrent();

   string query = StringFormat(sql_insert,
                               time_current,
                               m_seconds_for_values,
                               time_current,
                               m_seconds_for_values);

   return m_db.Execute(query);
  }
//+------------------------------------------------------------------+
bool CNews::Filling()
  {
//Print("Filling");
   datetime time_current = TimeCurrent();

   string query = StringFormat(sql_select,
                               time_current,
                               time_current,
                               m_seconds_before_news,
                               time_current,
                               m_seconds_after_news);

   return m_db.GetItems(query,data) && SetDescription();
  }
//+------------------------------------------------------------------+
bool CNews::SetDescription()
  {
   m_total = ArraySize(data);
   string desc = StringFormat("Size: %d\n",m_total);

   //datetime time_current = TimeCurrent();
   //StringAdd(desc,StringFormat("time current: %s\n",
   //                            TimeToString(time_current)));

   for(int i=0; i<m_total; i++)
     {
      StringAdd(desc,
                StringFormat("[%d]: %s\t time: %s \t desc: %s\n",
                             i,
                             i<10?" ":"",
                             TimeToString(data[i].time),
                             data[i].name));
     }

   if(m_description == desc)
      return true;

   m_description = desc;
   m_is_updated = true;
   return true;
  }
//+------------------------------------------------------------------+
bool CNews::IsUpdated()
  {
   if(m_is_updated)
     {
      m_is_updated = false;
      return true;
     }
   else
      return false;
  }
//+------------------------------------------------------------------+
void CNews::Removing()
  {
   datetime time_current = TimeCurrent();
   bool removed = false;

   for(int i=0; i<m_total; i++)
     {
      if(data[i].time + m_seconds_after_news > time_current)
         continue;

      removed = ArrayRemove(data,i,1);
      if(removed)
        {
         m_total--;
         i--;
        }
     }

   if(removed)
      SetDescription();
  }
//+------------------------------------------------------------------+
