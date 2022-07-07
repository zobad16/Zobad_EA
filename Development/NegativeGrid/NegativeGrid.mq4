//+------------------------------------------------------------------+
//|                                                 NegativeGrid.mq4 |
//|                                               Algo Tradeup, 2020 |
//|                                          https://algotradeup.com |
//+------------------------------------------------------------------+
#property copyright "Algo Tradeup, 2020"
#property link      "https://algotradeup.com"
#property version   "1.00"
#property strict

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>

CDialog Dialog;
CButton MannualEntryBtn [3];
CButton CloseAllBtn;
CButton CloseBuysBtn;
CButton CloseSellsBtn;
CButton TitleBtn;
CLabel  Labels[4];
CLabel  LabelsValues[4];

enum OrderDirection{
   LONG = 1,   //Long
   SHORT = -1  //Short
};
enum Type_Strategy{
   OPEN_NOW = 1 //Open Now
};
enum Signal{
   NONE = -99,
   BUY  = 1,
   SELL = 2
};
datetime Expiry=D'2021.10.19 00:00';
bool exp_deliverd = false;
input int                        magic_num=10; //Magic Number
input string                     Trade_Symbol; //Trade Symbol
input string                     EA_Setting="===== EA Setting =====";
input bool                       Negative_Grid_Enable=true;
input double                     Lot_Size=0.01;// Lot Size
input OrderDirection             Direction         = LONG;
input Type_Strategy              Strategy_Type=OPEN_NOW;//Strategy Type
input string                     Comment_Order="NEGATIVE_GRID";//Comment Order
input double                     TP_Point=100;//TP Point
input double                     TP_Money=100;//TP $Money
input bool                       UsePNLStop = true;   //Use TP$/SL$
input double                     Grid_Risk_Money=100;//Grid Risk $Money
input double                     Distance_Point=50;//Grid Leg Threshold(Points)
input int                        Grid_Max_Legs=10;//Grid Max Legs 
input double                     Grid_Multiplier=1.25;//Grid Multiplier
//input bool                       Grid_Hide_all_TP_SL=true;//Grid Hide all TP/SL 

int Slippage = 33; 
double l_lots = 0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   if(Trade_Symbol == ""){
      Print("INIT failed. Reason incorrect symbol name");
      return (INIT_FAILED);
   }
   EventSetTimer(1);
   Dialog.Create(ChartID(),"                                      ALGOTRADEUP",0,5,5,400,200);
   string dialogNumber=Dialog.Name();
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,clrGold);
   ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,clrWhite);
   
//---
   TitleBtn.Create(0,"Title",0,5,6,0,0)                              ;
   TitleBtn.Text("Martingale")                                            ;
   TitleBtn.FontSize(12)                                          ;                                    
   TitleBtn.Height(35)                                            ;
   TitleBtn.Width(200)                                            ;
   TitleBtn.Color(clrWhite)                                       ;
   TitleBtn.ColorBackground(clrDarkTurquoise)                             ;
   TitleBtn.ColorBorder(clrBlack)                                 ;
   TitleBtn.Disable()                                             ;
   CloseAllBtn.Create(0,"CloseAll",0,5,120,0,0)                      ;
   CloseAllBtn.Text("Close All")                                     ;
   CloseAllBtn.FontSize(10)                                          ;                                    
   CloseAllBtn.Height(40)                                            ;
   CloseAllBtn.Width(200)                                            ;
   CloseAllBtn.Color(clrBlack)                                       ;
   CloseAllBtn.ColorBackground(clrWhite)                             ;
   CloseAllBtn.ColorBorder(clrBlack)                                 ;
   CloseAllBtn.Pressed(false);
   MannualEntryBtn[0].Create(0,"OpenBuy",0,5,40,0,0)                ;
   MannualEntryBtn[0].Text("Open Buy")                                ;
   MannualEntryBtn[0].FontSize(10)                                    ;                                    
   MannualEntryBtn[0].Height(40)                                      ;
   MannualEntryBtn[0].Width(100)                                      ;
   MannualEntryBtn[0].Color(clrWhite)                                 ;
   MannualEntryBtn[0].ColorBackground(clrBlue)                        ;
   MannualEntryBtn[0].ColorBorder(clrBlack)                           ;
   MannualEntryBtn[0].Pressed(false);
   CloseBuysBtn.Create(0,"CloseBuys",0,5,80,0,0)                      ;
   CloseBuysBtn.Text("Close Buys")                                     ;
   CloseBuysBtn.FontSize(10)                                          ;                                    
   CloseBuysBtn.Height(40)                                            ;
   CloseBuysBtn.Width(100)                                            ;
   CloseBuysBtn.Color(clrWhite)                                       ;
   CloseBuysBtn.ColorBackground(clrBlue)                               ;
   CloseBuysBtn.ColorBorder(clrBlack)                                 ;
   CloseBuysBtn.Pressed(false);
   MannualEntryBtn[1].Create(0,"OpenSell",0,105,40,0,0)                      ;
   MannualEntryBtn[1].Text("Open Sells")                                     ;
   MannualEntryBtn[1].FontSize(10)                                          ;                                    
   MannualEntryBtn[1].Height(40)                                            ;
   MannualEntryBtn[1].Width(100)                                            ;
   MannualEntryBtn[1].Color(clrWhite)                                       ;
   MannualEntryBtn[1].ColorBackground(clrRed)                               ;
   MannualEntryBtn[1].ColorBorder(clrBlack)                                 ;
   MannualEntryBtn[1].Pressed(false);
   //reset = false                                                     ; 
   CloseSellsBtn.Create(0,"CloseSells",0,105,80,0,0)                      ;
   CloseSellsBtn.Text("Close Sells")                                     ;
   CloseSellsBtn.FontSize(10)                                          ;                                    
   CloseSellsBtn.Height(40)                                            ;
   CloseSellsBtn.Width(100)                                            ;
   CloseSellsBtn.Color(clrWhite)                                       ;
   CloseSellsBtn.ColorBackground(clrRed)                               ;
   CloseSellsBtn.ColorBorder(clrBlack)                                 ;
   CloseSellsBtn.Pressed(false);
   
   Dialog.Add(TitleBtn);
   Dialog.Add(CloseAllBtn);
   Dialog.Add(MannualEntryBtn[0]);
   Dialog.Add(CloseBuysBtn);
   Dialog.Add(CloseSellsBtn);
   Dialog.Add(MannualEntryBtn[1]);
   
   Labels[0].Create(0,"LegsLbl",0,230,5,30,0);
   Labels[0].Text("LEGS #: ");
   Labels[0].FontSize(10);
   Dialog.Add(Labels[0]);
   LabelsValues[0].Create(0,"LegsValue",0,320,5,30,0);
   LabelsValues[0].Text("0");
   LabelsValues[0].FontSize(10);
   Dialog.Add(LabelsValues[0]);
   Labels[1].Create(0,"PointsLbl",0,230,25,30,0);
   Labels[1].Text("Next Entry:");
   Labels[1].FontSize(10);
   Dialog.Add(Labels[1]);
   LabelsValues[1].Create(0,"-",0,320,25,30,0);
   LabelsValues[1].Text("0.00");
   LabelsValues[1].FontSize(10);
   Dialog.Add(LabelsValues[1]);
   Labels[2].Create(0,"DirectionLbl",0,230,45,30,0);
   Labels[2].Text("Direction:");
   Labels[2].FontSize(10);
   Dialog.Add(Labels[2]);
   LabelsValues[2].Create(0,"DirectionValue",0,320,45,30,0);
   LabelsValues[2].Text("-");
   LabelsValues[2].FontSize(10);
   Dialog.Add(LabelsValues[2]);
   Labels[3].Create(0,"PnlLbl",0,230,65,30,0);
   Labels[3].Text("PNL$  : ");
   Labels[3].FontSize(10);
   Dialog.Add(Labels[3]);
   LabelsValues[3].Create(0,"PNLValue",0,320,65,30,0);
   LabelsValues[3].Text("0.0");
   LabelsValues[3].FontSize(10);
   Dialog.Add(LabelsValues[3]);
   /*
   Labels[3].Create(0,"PointsLbl",0,230,65,30,0);
   Labels[3].Text("Next Entry:");
   Labels[3].FontSize(10);
   Dialog.Add(Labels[3]);
   LabelsValues[3].Create(0,"PointsValue",0,320,65,30,0);
   LabelsValues[3].Text("-");
   LabelsValues[3].FontSize(10);
   Dialog.Add(LabelsValues[3]);
   
   */
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
   Dialog.Destroy(reason);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int op = -99;
   if(Direction == LONG ) op = OP_BUY;
   else if(Direction == SHORT)op = OP_SELL;
   
   //first leg
   if(IsOrdersTotal(magic_num)<1){
      int entry = EntrySignal();
      if(entry == LONG ){
         SendOrder(OP_BUY, Trade_Symbol);
      }
         //PlaceOrder Long
      else if(entry == SHORT){
         SendOrder(OP_SELL, Trade_Symbol);
      }
         //PlaceOrder Short   
   }
   else
   {
      bool is_leg_entry = LegEntrySignal(op);
      Comment("Is Leg Entry: "+ (string)is_leg_entry);
      if(is_leg_entry)SendOrder(op,Trade_Symbol);
      ProfitMonitor();
   
   
   
   }
   
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---
   int legs = IsLegsTotal(magic_num,Trade_Symbol);
   double pnl = CalculateTotalProfit(magic_num);
   string dir ="";
   int op = -99;
   if(Direction == LONG){        
      dir = "Long";
      op = OP_BUY;
   }
   else if(Direction == SHORT){  
      dir = "Short";
      op = OP_SELL;
   }   
   
   LabelsValues[0].Text((string)legs);
   LabelsValues[1].Text((string)PointsSignal(op));
   LabelsValues[2].Text(dir);
   LabelsValues[3].Text((string)pnl);

}
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
   OnTick();
//---

//---
   return(ret);
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
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "")
      return;
    if(sparam=="CloseAll") // Close all
    {
        MessageBox("Closing All Orders!")                           ;
        CloseAllPositions();
        CloseAllBtn.Pressed(false);
        
    }
    if(sparam=="OpenBuy") // Close Buys
    {
        MannualEntryBtn[0].Pressed(false);
        MessageBox("Opening Buy Order!")                           ;
        MannualEntry(OP_BUY);
        Print("Opened Buy Position");
    }
    if(sparam=="CloseBuys") // Close Buys
    {
        CloseBuysBtn.Pressed(false);
        MessageBox("Closing All Buy Orders!")                           ;
        CloseAllPositions(OP_BUY);
        Print("Close All Buy Orders event");
        
    }
    if(sparam=="OpenSell") // Close Buys
    {
        MannualEntryBtn[1].Pressed(false);
        MessageBox("Opening Sell Order!")                           ;
        MannualEntry(OP_SELL);
        Print("Opened Sell Position");
    }
    if(sparam=="CloseSells") // Close Sells
    {
        CloseSellsBtn.Pressed(false);
        MessageBox("Closing All sell Orders!")                           ;
        CloseAllPositions(OP_SELL);
        Print("Close All Sell Orders event");
        
    }
    
   }
    ChartRedraw();
  }

//+==================================================================+
//| FUNCTIONS: Lot                                                   |
//+==================================================================+
double AveragePrice(int op)
{
   double orderOpenPrice = 0.0;
   double net_lots = 0.0;
   double net_price=0.0;
   double weighted_average_price =0.0;
   
   for(int i =OrdersTotal()-1; i>=0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderSymbol() == Trade_Symbol && OrderType() == op && OrderMagicNumber() == magic_num)
         {
            net_lots+= OrderLots();
            net_price += OrderLots() * OrderOpenPrice();     
            //Print("Lots buy : ", OrderLots(), "   OrderOpenPrice : ", OrderOpenPrice(),"lotsize[",lotsize,"] adjprice[",adj_price,"]");       
         }
      }
   }
   if(net_lots > 0)
   {
      return weighted_average_price = net_price/net_lots;
   }
   return weighted_average_price;
}
bool SendOrder(int op, string symbol)
{
   double price = 0.0;
   RefreshRates();
   double new_lot = CalculateLotsSize();    
   double tp =0.0, sl = 0.0;
   double avg_price = AveragePrice(op);
   
   if(op == OP_BUY){
      price = MarketInfo(symbol,MODE_ASK);
      if(avg_price == 0)avg_price = price;
      tp = avg_price + (TP_Point*MarketInfo(symbol,MODE_POINT));
      
   }   
   if(op == OP_SELL){
      price = MarketInfo(symbol,MODE_BID);
      if(avg_price == 0)avg_price = price;
      tp = avg_price  - (TP_Point*MarketInfo(symbol,MODE_POINT));      
   }   
   Print("AvgPrice:{"+(string)avg_price+"} TP: {"+(string)tp+"} SL{"+(string)sl+"}");
   int ticket= OrderSend(symbol,op,NormalizeDouble(new_lot,2),price,Slippage,0,0,Comment_Order,magic_num);
   ModifyOrder(op);
   TicketCheck(ticket);
   
   return false;
}
void ModifyOrder(int op){
   double tp =0.0, sl = 0.0;
   double avg_price = AveragePrice(op);
   double price = 0.0;
  
   for(int i=0; i<OrdersTotal(); i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0)
         {
            if(OrderMagicNumber()==magic_num && OrderSymbol()== Trade_Symbol && OrderType() == op)
             {
               if(avg_price == 0)avg_price = OrderOpenPrice();
                if(op == OP_BUY)
                  tp = avg_price + (TP_Point*MarketInfo(Trade_Symbol,MODE_POINT));   
               if(op == OP_SELL)
                  tp = avg_price  - (TP_Point*MarketInfo(Trade_Symbol,MODE_POINT));   
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),0,tp,0,clrGreen))
                  Print("Error in OrderModify. Error code=",GetLastError()); 
               else 
                  Print("Order modified successfully."); 
              }                               
          }
      }

      
}
bool TicketCheck(int ticket)
{
   if(ticket<0)
   {         
      Print("OrderSend failed with error #",GetLastError());
      return false;
   }
      else
      {
         Print("OrderSend placed successfully");
         return true;
      }
   return false;
}
double CalculateLotsSize()
{
   int legs = IsLegsTotal(magic_num,Trade_Symbol);
   if(legs == 0) 
      return Lot_Size;  
   double lot_size_G=NormalizeDouble(MathPow(Grid_Multiplier,legs)*Lot_Size,2);
   return lot_size_G;
}
int IsLegsTotal(int mg, string symbol)
  {
   int count =0;
   int total = OrdersTotal();
   for(int i=0;i<total;i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0)
        {
         if(OrderMagicNumber()==mg && OrderSymbol()== symbol)
           {
            count+=1;
           }
        }
     }
   return count;
  }  
 double LastOrderPrice(int op)
{
   datetime time =D'01.01.2020';
      double k = 0.0;
      for(int i=0; i<OrdersTotal(); i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0)
         {
            if(OrderMagicNumber()==magic_num && OrderSymbol()== Trade_Symbol && OrderType() == op)
             {
               if(OrderOpenTime()>= time)
               {
                  time =(datetime) OrderOpenTime();
                  k = OrderOpenPrice();
                  l_lots = OrderLots();
               }  
             }
         }

      }
      return k;
   

}   
//+------------------------------------------------------------------+
void CloseAllPositions(){
   CloseAllOrders(magic_num);
}
void CloseAllPositions(int op){
   CloseAllOrders(magic_num,op);
}
void MannualEntry(int op){}

int EntrySignal(){
   if(Strategy_Type == OPEN_NOW){
      if(Direction == LONG)
         return BUY;
      else if(Direction == SHORT)
         return SHORT;
   }
   return NONE;
}
bool LegEntrySignal(int op){
   int legs = IsLegsTotal(magic_num,Trade_Symbol);
   //Print("Opened Legs: "+legs);
   if(legs <= Grid_Max_Legs){
      double last_price = LastOrderPrice(op);
      double _bid = MarketInfo(Trade_Symbol,MODE_BID);
      double _ask = MarketInfo(Trade_Symbol,MODE_ASK);
      if(op == OP_SELL){
         if(_bid >= last_price+ Distance_Point*Point()){
            return true;
         }     
      }
      else if(op == OP_BUY){
         if(_ask <= last_price- Distance_Point*Point()){
            return true;
         }
      }
   }
   return false;
}
double PointsSignal(int op){
   int legs = IsLegsTotal(magic_num,Trade_Symbol);
   //Print("Opened Legs: "+legs);
   if(legs <= Grid_Max_Legs){
      double last_price = LastOrderPrice(op);
      double _bid = MarketInfo(Trade_Symbol,MODE_BID);
      double _ask = MarketInfo(Trade_Symbol,MODE_ASK);
      
      if(op == OP_BUY)
         return (last_price- Distance_Point*Point());     
      else if(op == OP_SELL)
         return (last_price+ Distance_Point*Point());     
   }
   return 0.0;
}
bool CloseAllOrders(int Magic_Numbe)
{
   // int Slippage =33;
   Print("Still in Order Close All function");
   int total= OrdersTotal();
   for(int ii=total-1;ii>=0;ii--){
     if(OrderSelect(ii,SELECT_BY_POS)==true){
        while(IsTradeContextBusy()) Sleep(10);
        if(OrderMagicNumber()==Magic_Numbe){
            if(OrderType()==OP_BUY ){
                 if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),Slippage,clrAntiqueWhite))
                    Print("Order Send Failed with Error[",GetLastError(),"]");
                        //continue;
             }
            else if(OrderType()==OP_SELL){
                  if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),Slippage,clrAntiqueWhite))
                    Print("Order Send Failed with Error[",GetLastError(),"]");
                        //continue;
             }
            else if(OrderType()==OP_SELLSTOP||OrderType()==OP_BUYSTOP||OrderType()==OP_SELLLIMIT||OrderType()==OP_BUYLIMIT){
               if( !OrderDelete(OrderTicket(), CLR_NONE))Print("Order Send Failed with Error[",GetLastError(),"]");
            }
        }
     }
   }
   if(IsOrdersTotal(Magic_Numbe)==0){return true;}
   else{return false;}
}
//+------------------------------------------------------------------+
//|CloseAllOrders: Closes all orders and returns true if successful  |
//+------------------------------------------------------------------+
bool CloseAllOrders(int Magic_Numbe, int op)
{
   // int Slippage =33;
   Print("Still in Order Close All function");
   int total= OrdersTotal();
   for(int ii=total-1;ii>=0;ii--){
     if(OrderSelect(ii,SELECT_BY_POS)==true){
        while(IsTradeContextBusy()) Sleep(10);
        if(OrderMagicNumber()==Magic_Numbe && OrderType() == op){
            if(OrderType()==OP_BUY ){
                 if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),Slippage,clrAntiqueWhite))
                    Print("Order Send Failed with Error[",GetLastError(),"]");
                        //continue;
             }
            else if(OrderType()==OP_SELL){
                  if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),Slippage,clrAntiqueWhite))
                    Print("Order Send Failed with Error[",GetLastError(),"]");
                        //continue;
             }
            else if(OrderType()==OP_SELLSTOP||OrderType()==OP_BUYSTOP||OrderType()==OP_SELLLIMIT||OrderType()==OP_BUYLIMIT){
               if( !OrderDelete(OrderTicket(), CLR_NONE))Print("Order Send Failed with Error[",GetLastError(),"]");
            }
        }
     }
   }
   if(IsOrdersTotal(Magic_Numbe)==0){return true;}
   else{return false;}
}
void ProfitMonitor(){
   double pnl = CalculateTotalProfit(magic_num);
   if(UsePNLStop){
      if(pnl >= TP_Money){
         Print("TP$: "+(string)pnl+" reached. Closing positions");
         CloseAllPositions();
      }
      else if(pnl < Grid_Risk_Money*(-1)){
         Print("SL$: "+(string)pnl+" reached. Closing positions");
         CloseAllPositions();
      }
   
   }
}
//+------------------------------------------------------------------+
//|CalculateTotalProfit: Returns Equity Profit                       |
//+------------------------------------------------------------------+
double CalculateTotalProfit(int _magic)
{
   int total =OrdersTotal();
   double equity =0.0;
   
   for(int i=0;i<total;i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0)
        {
         //OrderMagicNumber==magic?equity+=OrderProfit()
         if(OrderMagicNumber()==_magic)
           {            
               equity +=OrderProfit();
               equity+=OrderCommission();
               equity+=OrderSwap();
           }
        }
     }
    // Print("Profit: [",equity,"]");
   return equity;
}
//+------------------------------------------------------------------+
//| IsOrdersTotal function: returns total open orders                |
//+------------------------------------------------------------------+
int IsOrdersTotal(int mg)
  {
   int count =0;
   int total = OrdersTotal();
   for(int i=0;i<total;i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0)
        {
         if(OrderMagicNumber()==mg /*&& OrderSymbol()== Symbol()*/)
           {
            count+=1;
           }
        }
     }
   return count;
  }
  