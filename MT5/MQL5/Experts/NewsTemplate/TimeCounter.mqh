//+------------------------------------------------------------------+
//|                                                  TimeCounter.mqh |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
//| Счётчик времени                                                  |
//+------------------------------------------------------------------+
class CTimeCounter
  {
private:
   ulong             m_pause_micro;
   ulong             m_time_count,m_count;
   //---
public:
                     CTimeCounter(void);
                     CTimeCounter(const uint pause_msec);
                    ~CTimeCounter(void);
   //--- Установка временного интервала
   void              SetPause(const uint pause_msec);
   //--- Обнуление счётчика
   void              SetZero(void) { m_count=GetMicrosecondCount(); }
   //--- Проверяет прохождение указанного временного интервала 
   bool              Check(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTimeCounter::CTimeCounter(void)
  {
   m_pause_micro=1000000;
   m_count=GetMicrosecondCount();
  }
//+------------------------------------------------------------------+  
CTimeCounter::CTimeCounter(const uint pause_msec)
  {
   m_pause_micro=pause_msec*1000;
   m_count=GetMicrosecondCount();
  }  
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTimeCounter::~CTimeCounter(void)
  {
  }
//+------------------------------------------------------------------+
//| Установка шага и временного интервала                            |
//+------------------------------------------------------------------+  
void CTimeCounter::SetPause(const uint pause_msec)
  {
   m_pause_micro=pause_msec*1000;
  }
//+------------------------------------------------------------------+
//| Проверяет прохождение указанного временного интервала            |
//+------------------------------------------------------------------+
bool CTimeCounter::Check(void)
  {
   m_time_count=GetMicrosecondCount();

   if((m_time_count-m_count)<m_pause_micro) return(false);

   m_count=m_time_count;
   return(true);
  }
//+------------------------------------------------------------------+
