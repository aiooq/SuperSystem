//+------------------------------------------------------------------+
//|                               Copyright © 2021, Daniel Kurmyshev |
//|                           https://www.mql5.com/ru/users/snowbars |
//+------------------------------------------------------------------+
class CSQLite
  {
public:
                     CSQLite(void);
                    ~CSQLite(void) { Finalize(); DatabaseClose(m_handle); }

   bool              Create(string name_db, string main_table_name, string sql_create_db, bool in_memory = false);

   bool              Open(uint flags = 0);
   void              Close(void);

   bool              Execute(const string query, bool error_log = true);
   bool              TableExists(const string name);

   int               Prepare(const string query);
   void              Finalize(void);

   bool              TransactionBegin(void);
   bool              TransactionEnd(bool success);
   bool              TransactionExecute(const string query);

   void              Vacuum(void);
   void              WAL(void);
   void              BUSY(int timeout = 1000);

   void              SetName(const string name, const bool correcting_as_url = false);
   string            Name(void) { return(m_name); }
   string            Query(void) { return(m_query); }

   void              SetFlags(const uint flags) { m_flags = flags; }
   void              AddFlags(const uint flags) { m_flags |= flags; }

   bool              ExistFlag(ENUM_DATABASE_OPEN_FLAGS flag) { return((flag & m_flags) > 0); }

   string            GetColumnName(const string query, int column = 0);

   int               GetInt(const string query, int column = 0);
   long              GetLong(const string query, int column = 0);
   double            GetDouble(const string query, int column = 0);
   string            GetString(const string query, int column = 0);

   int               GetValues(const string query, long &values[], int column = 0);
   int               GetValues(const string query, double &values[], int column = 0);
   int               GetValues(const string query, string &values[], int column = 0);

   template<typename T>
   int               GetValuesIndi(const string query, T &values[], int column = 0, int bar_start = 0);
   //int               GetValuesIndi(const string query, color &values[], int column = 0, int bar_start = 0);

   template<typename T>
   bool              GetItems(const string query,T &arr[]);

   static void       FileNameCorrectionAsURL(string &name);

   void              DataBaseToFile(void);
   void              DataBaseFromFile(ulong skip_rows = 0, string skip_comments = NULL);

   string            GetStruct(void);
   int               GetTables(string &tables[]);

private:

   bool
   is_transaction_active;

   int
   m_handle,
   m_handle_query;

   uint
   m_flags;

   string
   m_name,
   m_query;

   bool              TransactionRollback(void);
   bool              TransactionCommit(void);
  };
//+------------------------------------------------------------------+
CSQLite::CSQLite(void)
  {
   m_name = MQLInfoString(MQL_PROGRAM_NAME);

   m_handle = NULL;
   m_handle_query = NULL;

   is_transaction_active = false;

   m_flags = DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON;
  }
//+------------------------------------------------------------------+
static void CSQLite::FileNameCorrectionAsURL(string &name)
  {
   StringReplace(name, "«", "%22");
//StringReplace(name,"/","%2F");
   StringReplace(name, ":", "%3A");
   StringReplace(name, "?", "%3F");
   StringReplace(name, "<", "%3C");
   StringReplace(name, ">", "%3E");
   StringReplace(name, "|", "%7C");
   StringReplace(name, "\\", "%5C");
   StringReplace(name, "*", "%2A");
   StringReplace(name, "\"", "%22"); // исправить перед компиляцией...
  }
//+------------------------------------------------------------------+
// В следующей версии библиотеки заложить в основу создание базы с таблицей log по умолчанию...
//+------------------------------------------------------------------+
bool CSQLite::Create(string name_db, string main_table_name, string sql_for_create_db, bool in_memory = false)
  {
   if(name_db != m_name)
      SetName(name_db);

   if(in_memory)
      m_flags |= DATABASE_OPEN_MEMORY;

   if(!TableExists(main_table_name))
      if(!Execute(sql_for_create_db, false))
         return(false);

   return(true);
  }
//+------------------------------------------------------------------+
void CSQLite::SetName(const string name, const bool correcting_as_url = false)
  {
   m_name = name;
   if(correcting_as_url)
      FileNameCorrectionAsURL(m_name);
  }
//+------------------------------------------------------------------+
bool CSQLite::Open(const uint flags = 0)
  {
   if(flags > 0)
      m_flags = flags;

   m_handle = DatabaseOpen(m_name, m_flags);

   if(m_handle == INVALID_HANDLE)
     {
      Print("DB: ", m_name, " open failed with code ", GetLastError());
      m_handle = NULL;
      return(false);
     }

   WAL();
   BUSY(1000);

   return(true);
  }
//+------------------------------------------------------------------+
void CSQLite::Close(void)
  {
   if(ExistFlag(DATABASE_OPEN_MEMORY))
      return;

   DatabaseClose(m_handle);
   m_handle = NULL;
  }
//+------------------------------------------------------------------+
bool CSQLite::Execute(const string query, bool error_log = true)
  {
   if(m_handle == NULL)
      Open();

   if(query=="" || query==NULL)
      return false;

   m_query = query;

   if(!DatabaseExecute(m_handle, query))
     {
      if(!is_transaction_active ||
         ERR_DATABASE_INVALID_HANDLE == GetLastError())
         Close();

      if(ERR_DATABASE_BUSY == GetLastError())
        {
         Sleep(100);
         return(Execute(query));
        }

      if(error_log)
        {
         Print("+------------------------------------------------------------------+");
         Print("handle: ", m_handle);
         Print(m_query);
        }
      Print("DB: ", m_name, " execute failed with code ", GetLastError());
      return(false);
     }

   return(true);
  }
//+------------------------------------------------------------------+
void CSQLite::Vacuum(void)
  {
   Execute("VACUUM;");
  }
//+------------------------------------------------------------------+
void CSQLite::WAL(void)
  {
   Execute("PRAGMA journal_mode = WAL;");
  }
//+------------------------------------------------------------------+
void CSQLite::BUSY(int timeout = 1000)
  {
   Execute(StringFormat("PRAGMA busy_timeout = %d;", timeout));
  }
//+------------------------------------------------------------------+
bool CSQLite::TableExists(const string name)
  {
   if(m_handle == NULL)
      if(!Open())
         return(false);

   if(!DatabaseTableExists(m_handle, name))
      return(false);

   return(true);
  }
//+------------------------------------------------------------------+
template<typename T>
bool CSQLite::GetItems(const string query,T &arr[])
  {
   int handle_query = Prepare(query);
   if(handle_query == INVALID_HANDLE)
      return false;

   ArrayFree(arr);
   T item;
   for(int i = 0; DatabaseReadBind(handle_query, item); i++)
     {
      ArrayResize(arr, i + 1, 10);
      arr[i] = item;
     }

   Finalize();
   return true;
  }
//+------------------------------------------------------------------+
int CSQLite::Prepare(const string query)
  {
   if(m_handle == NULL)
      Open();

   m_query = query;

   m_handle_query = DatabasePrepare(m_handle, query);
   if(m_handle_query == INVALID_HANDLE)
     {
      if(!is_transaction_active)
         Close();

      if(ERR_DATABASE_BUSY == GetLastError() ||
         ERR_DATABASE_INVALID_HANDLE == GetLastError())
        {
         Sleep(1000);
         return(Prepare(query));
        }

      Print("+------------------------------------------------------------------+");
      Print("handle: ", m_handle);
      Print(m_query);
      Print("DB: ", m_name, " Prepare query failed with code ", GetLastError());
      return(INVALID_HANDLE);
     }

   return(m_handle_query);
  }
//+------------------------------------------------------------------+
void CSQLite::Finalize(void)
  {
   DatabaseFinalize(m_handle_query);
   m_handle_query = NULL;
  }
//+------------------------------------------------------------------+
bool CSQLite::TransactionExecute(const string query)
  {
   if(!TransactionBegin())
      return(false);

   return(TransactionEnd(Execute(query)));
  }
//+------------------------------------------------------------------+
bool CSQLite::TransactionBegin(void)
  {
   if(m_handle == NULL)
      Open();

   if(!DatabaseTransactionBegin(m_handle))
     {
      Close();

      if(ERR_DATABASE_BUSY == GetLastError() ||
         ERR_DATABASE_INVALID_HANDLE == GetLastError())
        {
         Sleep(1000);
         return(TransactionBegin());
        }

      Print("+------------------------------------------------------------------+");
      Print("handle: ", m_handle);
      Print(m_query);
      Print("DB: ", m_name, " TransactionBegin failed with code ", GetLastError());
      return(false);
     }

   is_transaction_active = true;

   return(true);
  }
//+------------------------------------------------------------------+
bool CSQLite::TransactionEnd(bool success)
  {
   if(!is_transaction_active)
      return(false);

   if(success)
      success = TransactionCommit();
   else
      success = TransactionRollback();

   is_transaction_active = false;

   return(success);
  }
//+------------------------------------------------------------------+
bool CSQLite::TransactionRollback(void)
  {
   return(DatabaseTransactionRollback(m_handle));
  }
//+------------------------------------------------------------------+
bool CSQLite::TransactionCommit(void)
  {
   return(DatabaseTransactionCommit(m_handle));
  }
//+------------------------------------------------------------------+
int CSQLite::GetInt(const string query, int column = 0)
  {
   int
   handle_query = Prepare(query);

   if(DatabaseColumnsCount(handle_query) <= column)
     {
      Finalize();
      return(INVALID_HANDLE);
     }

   int
   value = INVALID_HANDLE;

   if(DatabaseRead(handle_query))
      if(!DatabaseColumnInteger(handle_query, column, value))
         value = INVALID_HANDLE;

   Finalize();

   return(value);
  }
//+------------------------------------------------------------------+
long CSQLite::GetLong(const string query, int column = 0)
  {
   int
   handle_query = Prepare(query);

   if(DatabaseColumnsCount(handle_query) <= column)
     {
      Finalize();
      return(INVALID_HANDLE);
     }

   long
   value = INVALID_HANDLE;

   if(DatabaseRead(handle_query))
      if(!DatabaseColumnLong(handle_query, column, value))
         value = INVALID_HANDLE;

   Finalize();

   return(value);
  }
//+------------------------------------------------------------------+
double CSQLite::GetDouble(const string query, int column = 0)
  {
   int
   handle_query = Prepare(query);

   if(DatabaseColumnsCount(handle_query) <= column)
     {
      Finalize();
      return(INVALID_HANDLE);
     }

   double
   value = INVALID_HANDLE;

   if(DatabaseRead(handle_query))
      if(!DatabaseColumnDouble(handle_query, column, value))
         value = INVALID_HANDLE;

   Finalize();

   return(value);
  }
//+------------------------------------------------------------------+
string CSQLite::GetString(const string query, int column = 0)
  {
   int
   handle_query = Prepare(query);

   if(DatabaseColumnsCount(handle_query) <= column)
     {
      Finalize();
      return(NULL);
     }

   string
   value;

   if(DatabaseRead(handle_query))
      if(!DatabaseColumnText(handle_query, column, value))
         value = NULL;

   Finalize();

   return(value);
  }
//+------------------------------------------------------------------+
string CSQLite::GetColumnName(const string query, int column = 0)
  {
   int
   handle_query = Prepare(query);

   if(DatabaseColumnsCount(handle_query) <= column)
     {
      Finalize();
      return(NULL);
     }

   string
   value;

   if(DatabaseRead(handle_query))
      if(!DatabaseColumnName(handle_query, column, value))
         value = NULL;

   Finalize();

   return(value);
  }
//+------------------------------------------------------------------+
int CSQLite::GetValues(const string query, long &values[], int column = 0)
  {
   bool failed = false;

   int
   handle_query = Prepare(query);

   if(DatabaseColumnsCount(handle_query) <= column)
     {
      Finalize();
      return(INVALID_HANDLE);
     }

   ArrayFree(values);

   for(int i = 0; DatabaseRead(handle_query); i++)
     {
      ArrayResize(values, ArraySize(values) + 1, 100);
      if(!DatabaseColumnLong(handle_query, column, values[i]))
        {
         failed = true;
         break;
        }
     }

   Finalize();

   if(failed)
      return(INVALID_HANDLE);
   else
      return(ArraySize(values));
  }
//+------------------------------------------------------------------+
int CSQLite::GetValues(const string query, double &values[], int column = 0)
  {
   bool failed = false;

   int
   handle_query = Prepare(query);

   if(DatabaseColumnsCount(handle_query) <= column)
     {
      Finalize();
      return(INVALID_HANDLE);
     }

   ArrayFree(values);

   for(int i = 0; DatabaseRead(handle_query); i++)
     {
      ArrayResize(values, ArraySize(values) + 1, 100);
      if(!DatabaseColumnDouble(handle_query, column, values[i]))
        {
         failed = true;
         break;
        }
     }

   Finalize();

   if(failed)
      return(INVALID_HANDLE);
   else
      return(ArraySize(values));
  }
//+------------------------------------------------------------------+
template<typename T>
int CSQLite::GetValuesIndi(const string query, T &values[], int column = 0, int start_pos = 0)
  {
   bool failed = false;

   int handle_query = Prepare(query);

   if(DatabaseColumnsCount(handle_query) <= column)
     {
      Finalize();
      return(INVALID_HANDLE);
     }

   uint size = ArraySize(values);
   for(uint i = start_pos; DatabaseRead(handle_query); i++)
     {
      /*if(i >= size)
        {
         printf("Warrning: Array[%d] out of range, i=%d",size,i);
         break;
        }*/

      ArrayResize(values,ArraySize(values)+1,10);

      if(typename(T) == "double")
        {
         if(!DatabaseColumnDouble(handle_query, column, values[i]))
           {
            failed = true;
            break;
           }
        }

      //if(typename(T) == "integer")
      //  {
      //   if(!DatabaseColumnDouble(handle_query, column, values[i]))
      //     {
      //      failed = true;
      //      break;
      //     }
      //  }
     }

   Finalize();

   if(failed)
      return(INVALID_HANDLE);
   else
      return(ArraySize(values));
  }
//+------------------------------------------------------------------+
int CSQLite::GetValues(const string query, string &values[], int column = 0)
  {
   bool failed = false;

   int
   handle_query = Prepare(query);

   if(DatabaseColumnsCount(handle_query) <= column)
     {
      Finalize();
      return(INVALID_HANDLE);
     }

   ArrayFree(values);

   for(int i = 0; DatabaseRead(handle_query); i++)
     {
      ArrayResize(values, ArraySize(values) + 1, 100);
      if(!DatabaseColumnText(handle_query, column, values[i]))
        {
         failed = true;
         break;
        }
     }

   Finalize();

   if(failed)
      return(INVALID_HANDLE);
   else
      return(ArraySize(values));
  }
//+------------------------------------------------------------------+
string CSQLite::GetStruct(void)
  {
   string query = "SELECT sql FROM sqlite_master";
   StringAdd(query, " WHERE tbl_name<>'sqlite_sequence' AND sql IS NOT NULL");
   StringAdd(query, " ORDER BY type DESC");

   string items[],
          result = "";

   int total = GetValues(query, items);
   for(int i = 0; i < total; i++)
      StringAdd(result, StringFormat("%s; ", items[i]));

   return result;
  }
//+------------------------------------------------------------------+
int CSQLite::GetTables(string &tables[])
  {
   string query = "SELECT name FROM sqlite_master WHERE tbl_name <> 'sqlite_sequence' AND type='table'";
   return GetValues(query, tables);
  }
//+------------------------------------------------------------------+
void CSQLite::DataBaseToFile(void)
  {
   uint flags = DATABASE_EXPORT_COMMON_FOLDER | DATABASE_EXPORT_QUOTED_STRINGS;

   long count_rows = 0;

   string tables[],
          file_name,
          separator = ";",
          query = "SELECT name FROM sqlite_master WHERE tbl_name <> 'sqlite_sequence' AND type='table'";

   int total = GetValues(query, tables);

   if(m_handle == NULL)
      Open();

   for(int i = 0; i < total; i++)
     {
      file_name = StringFormat("%s.%s", m_name, tables[i]);
      count_rows = DatabaseExport(m_handle, tables[i], file_name, flags, separator);
      Print(StringFormat("Export file: %s, rows: %lld", file_name, count_rows));

      if(count_rows < 0)
         Print("DB: ", m_name, ", Table: ", tables[i], ", Import failed with code ", GetLastError());
      else
         if(count_rows > 0)
            Print(StringFormat("Import file: %s, rows: %lld", file_name, count_rows));
     }

   Finalize();
  }
//+------------------------------------------------------------------+
void CSQLite::DataBaseFromFile(ulong skip_rows = 0, string skip_comments = NULL)
  {
   uint flags = DATABASE_EXPORT_COMMON_FOLDER | DATABASE_EXPORT_QUOTED_STRINGS;

   string tables[],
          file_name,
          separator = ";",
          query = "SELECT name FROM sqlite_master WHERE tbl_name <> 'sqlite_sequence' AND type='table'";

   int total = GetValues(query, tables);

   long count_rows = 0;

   if(m_handle == NULL)
      Open();

   for(int i = 0; i < total; i++)
     {
      file_name = StringFormat("%s.%s", m_name, tables[i]);
      count_rows = DatabaseImport(m_handle, tables[i], file_name, flags, separator, skip_rows, skip_comments);

      if(count_rows < 0)
         Print("DB: ", m_name, ", Table: ", tables[i], ", Import failed with code ", GetLastError());
      else
         if(count_rows > 0)
            Print(StringFormat("Import file: %s, rows: %lld", file_name, count_rows));
     }

   Finalize();
  }
//+------------------------------------------------------------------+
