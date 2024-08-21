int delay=1000;
int start, TickCount;
int Size=0, PrevSize=0;
int cnt, TotalCounter = 0;
string cmt;
string nl="\n";

int OrdId[], PrevOrdId[];
string OrdSym[], PrevOrdSym[];
int OrdTyp[], PrevOrdTyp[];
double OrdLot[], PrevOrdLot[];
double OrdPrice[], PrevOrdPrice[];
double OrdSL[], PrevOrdSL[];
double OrdTP[], PrevOrdTP[];

string backend_url = "https://tudominio.com/api/operaciones";  // URL del backend

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   return(0);
}

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   return(0);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {

   while(!IsStopped()) {
      start = GetTickCount();
      cmt = start + nl + "Counter: " + TotalCounter;
      get_positions();
      if(compare_positions()) send_positions();
      Comment(cmt);
      TickCount = GetTickCount() - start;
      if(delay > TickCount) Sleep(delay - TickCount - 2);
   }
   Alert("end, TradeCopy EA stopped");
   Comment("");
   return(0);
}

void get_positions() {
   Size = OrdersTotal();
   if(Size != PrevSize) {
      ArrayResize(OrdId, Size);
      ArrayResize(OrdSym, Size);
      ArrayResize(OrdTyp, Size);
      ArrayResize(OrdLot, Size);
      ArrayResize(OrdPrice, Size);
      ArrayResize(OrdSL, Size);
      ArrayResize(OrdTP, Size);
   }

   for(int cnt = 0; cnt < Size; cnt++) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      OrdId[cnt] = OrderTicket();
      OrdSym[cnt] = OrderSymbol();
      OrdTyp[cnt] = OrderType();
      OrdLot[cnt] = OrderLots();
      OrdPrice[cnt] = OrderOpenPrice();
      OrdSL[cnt] = OrderStopLoss();
      OrdTP[cnt] = OrderTakeProfit();
   }
   cmt = cmt + nl + "Size: " + Size;
}

bool compare_positions() {
   if(PrevSize != Size) return(true);
   for(int i = 0; i < Size; i++) {
      if(PrevOrdSL[i] != OrdSL[i]) return(true);
      if(PrevOrdTP[i] != OrdTP[i]) return(true);
      if(PrevOrdPrice[i] != OrdPrice[i]) return(true);
      if(PrevOrdId[i] != OrdId[i]) return(true);
      if(PrevOrdSym[i] != OrdSym[i]) return(true);
      if(PrevOrdLot[i] != OrdLot[i]) return(true);
      if(PrevOrdTyp[i] != OrdTyp[i]) return(true);
   }
   return(false);
}

void send_positions() {

   string json = "{";
   json += "\"TotalCounter\": " + IntegerToString(TotalCounter) + ",";
   json += "\"positions\": [";

   for(int i = 0; i < Size; i++) {
      json += "{";
      json += "\"OrdId\": " + IntegerToString(OrdId[i]) + ",";
      json += "\"OrdSym\": \"" + OrdSym[i] + "\",";
      json += "\"OrdTyp\": " + IntegerToString(OrdTyp[i]) + ",";
      json += "\"OrdLot\": " + DoubleToString(OrdLot[i], 2) + ",";
      json += "\"OrdPrice\": " + DoubleToString(OrdPrice[i], 5) + ",";
      json += "\"OrdSL\": " + DoubleToString(OrdSL[i], 5) + ",";
      json += "\"OrdTP\": " + DoubleToString(OrdTP[i], 5);
      json += "}";
      if(i < Size - 1) json += ",";
   }

   json += "]}";

   int timeout = 5000;
   char post[], result[];
   StringToCharArray(json, post);
   int res = WebRequest("POST", backend_url, "", NULL, 0, post, strlen(json), result, timeout);

   if(res == -1) {
      Print("Error in WebRequest. Error Code: ", GetLastError());
   } else if(res == 200) {
      Print("Positions sent successfully.");
   } else {
      Print("Unexpected response. Code: ", res);
   }

   TotalCounter++;
}

