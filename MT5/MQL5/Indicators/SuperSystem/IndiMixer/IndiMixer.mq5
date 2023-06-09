//+------------------------------------------------------------------+
//|                                                    IndiMixer.mq5 |
//|                                         Copyright 2023, SnowBars |
//|                           https://www.mql5.com/ru/users/snowbars |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, SnowBars"
#property link      "https://www.mql5.com/ru/users/snowbars"
#property version   "1.00"
#property description "IndiMixer"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0
//+------------------------------------------------------------------+
#resource "SQL/select_indicators.sql" as string sql_select_indicators
////+------------------------------------------------------------------+
#include <!Custom\SQLite\CSQLite.1.21.mqh>
#include <!Custom\Web\JAson.mqh>
#include <Indicators\Indicators.mqh>
//+------------------------------------------------------------------+
input uint InpIndicatorsId = 1;
//+------------------------------------------------------------------+
CSQLite m_db;
CIndicators m_indicators;
int subwins[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//m_db.Create(path_to_db_strategy, "indicators", sql_create_db_StrategyFactory, false);
   m_db.SetName("SuperSystem/core.1.21.db");
   m_db.SetFlags(DATABASE_OPEN_READONLY);

//--- indicator buffers mapping
   string query = StringFormat(sql_select_indicators,InpIndicatorsId);
   if(!SetConfig(m_db.GetString(query)))
      return INIT_FAILED;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ChartSetSymbolPeriod(0,_Symbol,PERIOD_CURRENT);
   for(int i=m_indicators.Total()-1; i>=0; i--)
     {
      CIndicator *indi = m_indicators.At(i);
      indi.DeleteFromChart(0,subwins[i]);
     }
   ChartSetSymbolPeriod(0,_Symbol,PERIOD_CURRENT);  
   ChartRedraw();  
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+
bool SetConfig(string config)
  {
   CJAVal jin;
   jin.Deserialize(config);
   int total = ArraySize(jin.m_e);
   if(total <= 0)
      return false;

   m_indicators.Clear();

   int subwin = 0;
   ArrayResize(subwins,total);

   for(int i=0; i<total; i++)
     {
      int id = i+1;
      string symbol = _Symbol;//jin.m_e[i][1].ToStr()==""?NULL:jin.m_e[i][1].ToStr();
      ENUM_TIMEFRAMES tf = PERIOD_CURRENT;//(ENUM_TIMEFRAMES)jin.m_e[i][2].ToInt();
      ENUM_INDICATOR type = (ENUM_INDICATOR)jin.m_e[i][0].ToInt();
      bool to_subwin = jin.m_e[i][1].ToBool();

      CJAVal jp = jin.m_e[i][2];
      int count_params = ArraySize(jp.m_e);
      MqlParam params[];
      ArrayResize(params,count_params);

      for(int p = 0; p < count_params; p++)
        {
         params[p].type = (ENUM_DATATYPE)jp[p][0].ToInt();
         switch(params[p].type)
           {
            case TYPE_INT:
               params[p].integer_value = jp[p][1].ToInt();
               break;
            case TYPE_DOUBLE:
               params[p].double_value = jp[p][1].ToDbl();
               break;
            case TYPE_STRING:
               params[p].string_value = jp[p][1].ToStr();
               break;
            default:
               return false;
           }
        }

      CIndicator *indi = m_indicators.Create(symbol,tf,type,count_params,params);

      if(indi == NULL)
        {
         Print("Ошибка создания индикатора! #",i);
         ArrayPrint(params);
         continue;
        }

      //Print(indi.Symbol());
      //Print(indi.Period());
      ArrayPrint(params);

      if(to_subwin)
         subwin++;
      subwins[i]=to_subwin?subwin:0;
      indi.AddToChart(0,subwins[i]);
     }

   m_indicators.Refresh();
   ChartRedraw();

   return true;
  }
//+------------------------------------------------------------------+
