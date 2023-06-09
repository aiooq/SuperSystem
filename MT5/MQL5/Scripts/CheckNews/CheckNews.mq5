//+------------------------------------------------------------------+
//|                                                    CheckNews.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs
//+------------------------------------------------------------------+
#resource "\\SQL\\select.sql" as string sql_select;
//+------------------------------------------------------------------+
#include "SQLite\CSQLite.1.21.mqh"
//+------------------------------------------------------------------+
input string InpCountryCode = "US,EU"; // Country codes
input string InpCurrencies = "USD,EUR"; // Currencies
input string InpNameNews = "";                  // Name of the news
input uint InpSecondsBeforeNews = 84600;        // Seconds before the news
input uint InpSecondsAfterNews = 84600;        // Seconds after the news
input string InpImpact = "0,1,2";               // Impact
//+------------------------------------------------------------------+
//--- структура под хранение событий календаря с вещественными значениями
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
   int                                 seconds;
   bool                                cheking;
  };
//+------------------------------------------------------------------+
CSQLite m_db;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   string CountryCode = StringFormat("'%s'",InpCountryCode);
   string Currencies = StringFormat("'%s'",InpCurrencies);
   
   StringReplace(CountryCode,",","','");
   StringReplace(Currencies,",","','");
  
   string query = sql_select;
   StringReplace(query,"$code",CountryCode);
   StringReplace(query,"$currency",Currencies);
   StringReplace(query,"$time_now",IntegerToString(TimeCurrent()));
   StringReplace(query,"$name",InpNameNews);
   StringReplace(query,"$seconds_before",IntegerToString(InpSecondsBeforeNews));
   StringReplace(query,"$seconds_after",IntegerToString(InpSecondsAfterNews));
   StringReplace(query,"$impact",InpImpact);
   
   m_db.SetName("news.db");
   
   struct_news_values values[];
   m_db.GetItems(query,values);

   int total = ArraySize(values);
   for(int i=0; i<total; i++)
     {
      if(values[i].cheking)
         Print(values[i].name,"|",values[i].cheking);
     }
  }
//+------------------------------------------------------------------+
