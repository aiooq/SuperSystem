//+------------------------------------------------------------------+
//|                                                 NewsTemplate.mq5 |
//|                                         Copyright 2023, SnowBars |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, SnowBars"
#property link      "https://www.mql5.com"
#property version   "1.17"
//+------------------------------------------------------------------+
#include "News.mqh"
//+------------------------------------------------------------------+
input string InpCurrencies = "USD,EUR";   // Currencies
input uint InpSecondsBeforeNews = 86400;  // Seconds before the news
input uint InpSecondsAfterNews = 86400;   // Seconds after the news
input string InpImportance = "0,1,2,3";   // Importance
input string InpImpact = "0,1,2";         // Impact
input string InpName = "";                // Name
//+------------------------------------------------------------------+
CNews news;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetMillisecondTimer(1000);

   news.Init(InpCurrencies,
             InpSecondsBeforeNews,
             InpSecondsAfterNews,
             InpImportance,
             InpImpact,
             InpName);

   OnTick();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   Comment("");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   news.Tick();

   if(news.IsUpdated() &&
      (MQLInfoInteger(MQL_VISUAL_MODE) || !MQLInfoInteger(MQL_TESTER)))
     {
      Comment(news.GetDescription());
      ChartRedraw();
     }
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   news.Timer();
  }
//+------------------------------------------------------------------+
