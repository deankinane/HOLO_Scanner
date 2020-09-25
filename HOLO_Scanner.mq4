//+------------------------------------------------------------------+
//|                                                 HOLO_Scanner.mq4 |
//|                                            Copyright 2020, Aeson |
//|                               https://www.forexfactory.com/aeson |
//+------------------------------------------------------------------+

#property copyright "Copyright 2020, Aeson"
#property link      "https://www.forexfactory.com/aeson"
#define VERSION "1.00"
#property version VERSION
#property strict

extern string Pairs = "AUDJPY,AUDCHF,AUDCAD,CADCHF,AUDUSD,AUDNZD,EURAUD,CHFJPY,CADJPY,EURGBP,EURCHF,EURCAD,EURNZD,EURJPY,GBPCHF,GBPCAD,GBPAUD,GBPUSD,GBPNZD,GBPJPY,NZDJPY,NZDCGF,NZDCAD,USDCHF,USDCAD,NZDUSD,USDJPY";
extern string BrokerSuffix = "-g";
extern ENUM_TIMEFRAMES EntryPeriod = PERIOD_M15;
extern int ScanFrequency = 5;
extern bool ShowAlerts = true;
extern string ChartTemplateName = "HOLO";
extern int ButtonsStartX = 120;
extern int ButtonsStartY = 120;

string PairList[];
string Alerts[];
string Signals[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   ScanFrequency = ScanFrequency < 1 ? 1 : ScanFrequency;
   
   EventSetTimer(ScanFrequency);
   StringSplit(Pairs, StringGetCharacter(",",0), PairList);
   SetChartBlank();
   OnTimer();
   
   DrawLabels();
   DrawTimeFrameButtons();
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
   DeleteAllButtons();
   DeleteLabels();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
   int offsetX = ButtonsStartX;
   int offsetY= ButtonsStartY;
   
   for(int i=0; i<ArraySize(PairList); i++) {
      CheckForSignal(PairList[i]+BrokerSuffix);
      DrawPairButton(PairList[i], offsetX, offsetY);
      
      offsetX += 110;;
      
      if ((i+1)%5 == 0) {
         offsetX = ButtonsStartX;
         offsetY += 40;
      }
   }
   
  }
//+------------------------------------------------------------------+

void CheckForSignal(string symbol) {

   ArrayFree(Signals);
   
   int barShift = iBarShift(symbol, PERIOD_H1, iTime(symbol, PERIOD_D1, 0)) + 1;

   int highOpen = iHighest(symbol, PERIOD_H1, MODE_OPEN, barShift);
   double OpenHigh = iOpen(symbol, PERIOD_H1, highOpen);

   int lowOpen = iLowest(symbol, PERIOD_H1, MODE_OPEN, barShift);
   double OpenLow = iOpen(symbol, PERIOD_H1, lowOpen);

   double DailyHigh = iHigh(symbol, PERIOD_D1, 0);

   int dayLow = iLowest(symbol, PERIOD_H1, MODE_LOW, barShift);
   double DailyLow = iLow(symbol, PERIOD_D1, 0);
  
   
   if (iOpen(symbol, EntryPeriod, 0) > OpenHigh && iHigh(symbol, PERIOD_H1, 0) < DailyHigh) {
      ShowAlert(symbol, (string)iOpen(symbol, EntryPeriod, 0), "SHORT");
      ArrayResize(Signals, ArraySize(Signals) + 1);
      Signals[ArraySize(Signals)-1] = symbol;
   }
   
   if (iOpen(symbol, EntryPeriod, 0) < OpenLow && iLow(symbol, PERIOD_H1, 0) > DailyLow) {
      ShowAlert(symbol, (string)iOpen(symbol, EntryPeriod, 0), "LONG");
      ArrayResize(Signals, ArraySize(Signals) + 1);
      Signals[ArraySize(Signals)-1] = symbol;
   }
   
}

void ShowAlert(string symbol, datetime time, string message) {
   
   if (!ShowAlerts) return;

   string id = symbol+(string)time+message;
   if(ArraySearch(Alerts, id) < 0) {
      ArrayResize(Alerts, ArraySize(Alerts)+1);
      Alerts[ArraySize(Alerts)-1] = id;
      Alert(symbol + "  -  ", time + "  -  ", message);
   }
}

int ArraySearch(string& array[], string value) {
   for (int i=0; i<ArraySize(array); i++) {
      if (array[i] == value) return i;
   }
   
   return -1;
}

void DrawPairButton(string symbol, int x, int y) {
   bool signal = ArraySearch(Signals, symbol + BrokerSuffix) > -1;
   CreateButton(symbol, symbol, x, y, 100, 30, signal ? clrSpringGreen : C'236,233,216');
}

void CreateButton(string name, string label, int x, int y, int width, int height,
                  color bgColor = C'236,233,216', color textColor = clrBlack, int anchor = CORNER_LEFT_UPPER) {
   ObjectCreate(name, OBJ_BUTTON, 0, 0, 0);
   ObjectSet(name,OBJPROP_XDISTANCE,x+width);
   ObjectSet(name,OBJPROP_YDISTANCE,y);
   ObjectSet(name,OBJPROP_WIDTH,x);
   ObjectSet(name,OBJPROP_XSIZE,width);
   ObjectSet(name,OBJPROP_YSIZE,height);
   ObjectSet(name, OBJPROP_CORNER, anchor);
   ObjectSet(name, OBJPROP_BGCOLOR, bgColor);
   ObjectSet(name, OBJPROP_COLOR, textColor);
   ObjectSet(name, OBJPROP_ZORDER, 100);
   ObjectSetText(name, label, 12);
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {


   if(id==CHARTEVENT_OBJECT_CLICK) {
   
      if (sparam == btnAlerts) {
         ShowAlerts = !ShowAlerts;
         UpdateTimeFrameButtons();
         return;
      }
      
      if (sparam == btnM5) {
         EntryPeriod = PERIOD_M5;
         UpdateTimeFrameButtons();
         return;
      }
      
      if (sparam == btnM15) {
         EntryPeriod = PERIOD_M15;
         UpdateTimeFrameButtons();
         return;
      }
      
      if (ArraySearch(PairList, sparam) < 0) return;
      
      long chartid = ChartOpen(sparam+BrokerSuffix, EntryPeriod);
      
      if (StringLen(ChartTemplateName) > 0) {
         ChartApplyTemplate(chartid, ChartTemplateName);
      }
      
      ObjectSetInteger(0, sparam, OBJPROP_STATE, 0);
   }
  

}

void DeleteAllButtons() {
    for(int i=0; i<ArraySize(PairList); i++) {
      ObjectDelete(PairList[i]);
   }
}

void SetChartBlank() {
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrBlack);
   ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrBlack);
   ChartSetInteger(0, CHART_COLOR_ASK, clrBlack);
   ChartSetInteger(0, CHART_COLOR_BID, clrBlack);
   ChartSetInteger(0, CHART_COLOR_GRID, clrBlack);
   ChartSetInteger(0, CHART_MODE, CHART_LINE);
   ChartSetInteger(0, CHART_FOREGROUND, 0);
}

string lblAuthor = "lblAuthor";
string lblTitle = "lblTitle";
string lblPeriod = "lblPeriod";
string lblScanning = "lblScanning";
string btnM15 = "M15";
string btnM5 = "M5";
string btnAlerts = "btnAlerts";

void DrawLabels() {
   DrawLabel(lblTitle, "HOLO Scanner " + (string)VERSION, clrWhite, 16, 10, 10, "Arial Bold");
   DrawLabel(lblAuthor, "Created by Aeson  -  Inspired by TooSlow", clrWhiteSmoke, 8, 10, 35);
   
   DrawLabel(lblPeriod, "Entry Period", clrWhiteSmoke, 12, 10, 70, "Arial Bold");
   DrawLabel(lblScanning, "Scanning every " + (string)ScanFrequency + " seconds", clrWhiteSmoke, 10, 10, 92);
}

void DrawTimeFrameButtons() {
   string period = EnumToString(EntryPeriod);
   StringReplace(period, "PERIOD_", "");
   CreateButton(btnM5, "M5", 80, 69, 35, 20, period == "M5" ? clrSpringGreen : C'236,233,216');
   CreateButton(btnM15, "M15", 120, 69, 35, 20, period == "M15" ? clrSpringGreen : C'236,233,216');
   CreateButton(btnAlerts, "Alerts " + (ShowAlerts ? "on" : "off"), -70, 115, 80, 22, ShowAlerts ? clrSpringGreen : clrLightPink);
}

void UpdateTimeFrameButtons() {
   string period = EnumToString(EntryPeriod);
   StringReplace(period, "PERIOD_", "");
   
   ObjectSetInteger(0, btnM5, OBJPROP_STATE, 0);
   ObjectSetInteger(0, btnM15, OBJPROP_STATE, 0);
   ObjectSetInteger(0, btnAlerts, OBJPROP_STATE, 0);
   
   ObjectSetInteger(0, btnM5, OBJPROP_BGCOLOR, period == "M5" ? clrSpringGreen : C'236,233,216');
   ObjectSetInteger(0, btnM15, OBJPROP_BGCOLOR, period == "M15" ? clrSpringGreen : C'236,233,216');
   ObjectSetInteger(0, btnAlerts, OBJPROP_BGCOLOR, ShowAlerts ? clrSpringGreen : clrLightPink);
   ObjectSetText(btnAlerts, "Alerts " + (ShowAlerts ? "on" : "off"));
   
   OnTimer();
}

void DeleteLabels() {
   ObjectDelete(lblTitle);
   ObjectDelete(lblAuthor);
   ObjectDelete(lblPeriod);
   ObjectDelete(lblScanning);
   ObjectDelete(btnM15);
   ObjectDelete(btnM5);
   ObjectDelete(btnAlerts);
}

void DrawLabel(string name, string text, color colour, int size, int x, int y, string font = "", int anchor = CORNER_LEFT_UPPER) {
   ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(name,text,size,font == "" ? "Arial" : font,colour);
   ObjectSet(name,OBJPROP_XDISTANCE,x);
   ObjectSet(name,OBJPROP_YDISTANCE,y);
   ObjectSet(name, OBJPROP_CORNER, anchor);

   if (anchor == CORNER_RIGHT_UPPER) {
      ObjectSet(name, OBJPROP_ANCHOR, ANCHOR_RIGHT);
   }
}