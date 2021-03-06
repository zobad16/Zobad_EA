//+------------------------------------------------------------------+
//|                                             White_Soldier_V3.mq4 |
//|                                                    Zobad Mahmood |
//|                                             https://www.mql5.com |
//| Changes: Added functionality for detecting and stoping on loosing|
//| TrendS                                                           |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "https://www.mql5.com"
#property version   "3.00"
#property strict
//--- input parameters
enum Take_Profit{
   atr=0,
   fixed=1
};
input int      ATR_Period=20;
input ENUM_TIMEFRAMES ATR_Charts_Period = PERIOD_M5;
input Take_Profit TP_Type=fixed;
input Take_Profit SL_Type=fixed;
input int      ATR_TP_Factor=4;
input int      ATR_SL_Factor=2;
input double   TP_Fixed=50.0;
input double   SL_Fixed=20.0;
input double   LotSize=1.0;
input int      Slippage=33;
input int      Magic_Number=5555;

double MyPoint;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   MyPoint=MyPoint();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(TotalOpenOrder()==0)
   {
      if(BuyAlert()==true)
      {
         //if(Place_Buy_Order()==false)
         //first change
         bool order= Place_Buy_Order();
         
         if(order==false)
         {Print("Buy Failed"); }
         
         ///New Bit
         else if(order)
         {
           int ticket; double lots;
           bool orderS=OrderSelect(OrdersTotal()-1,SELECT_BY_POS,MODE_TRADES );
           if(orderS)
            {
               ticket = OrderTicket(); lots= OrderLots();
               Print("Ticket: "+ticket+" Lots: "+lots);
               Buy_Watch(ticket, lots);
            }
            else{Print("Order Select Failed");}
         }
         ///End      
      }
      else if(SellAlert()==true)
      {
        bool order=Place_Sell_Order();
        if(!order){Print("Order Failed");}
        else if(order)
         {
           int ticket; double lots;
         bool orderS=OrderSelect(OrdersTotal()-1,SELECT_BY_POS,MODE_TRADES );
         if(orderS)
         {
            ticket = OrderTicket(); lots= OrderLots();
             Print("Ticket: "+ticket+" Lots: "+lots);
            Sell_Watch(ticket, lots);
         }
         }
      }
   }
      
  }
//+------------------------------------------------------------------+
bool Place_Buy_Order()
{
   double sl,tp;
   
   int ticket= OrderSend(_Symbol,OP_BUY,LotSize,Ask,Slippage,0,0,"Buy",Magic_Number);
   double atr=iATR(0,0,ATR_Period,0);   Print("ATR Reading: ",atr);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*MyPoint;
   minSL=Ask-minSL;
   Print("Minimum SL: ",minSL);
   if(TicketCheck(ticket)==true)
   {
      if(SL_Type==1)
      {
         sl=SL_Fixed*MyPoint;
         sl=Ask-sl;
      }
      if(SL_Type==0)
      {
        // sl=NormalizeDouble(ATR_TP_Factor,Digits);
        sl=atr*ATR_SL_Factor;
        sl= Ask-sl;
      }
      if(TP_Type==1)
      {
         tp=TP_Fixed*MyPoint;
         tp= Ask+tp;
      }
      if(TP_Type==0)
      {
        // tp=NormalizeDouble(ATR_SL_Factor,Digits);
        tp=atr* ATR_TP_Factor;
        tp=Ask+tp;
      }        
   }
   Alert("SL: ",sl);
   Alert("TP:",tp);
   if(sl>minSL)
   {
      double toAdd= sl-minSL;      
      sl= sl - toAdd- 1*MyPoint;
      Print("Added to SL: ",toAdd); 
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
   
   }
     if(sl<minSL)
   {   
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
   }
   return false;
   
}
bool Place_Sell_Order()
{
   double sl,tp;
   int ticket= OrderSend(_Symbol,OP_SELL,LotSize,Bid,Slippage,0,0,"Buy",Magic_Number);
   double atr=iATR(0,0,ATR_Period,0);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*MyPoint;
   minSL=Bid+minSL;
   Print("ATR Reading: ",atr);
   Print("Bid Reading: ",Bid);
   Print("Minimum SL: ",minSL);
   if(TicketCheck(ticket)==true)
   {
      if(SL_Type==1)
      {
         sl=SL_Fixed*MyPoint;
         sl=Bid+sl;
      }
      if(SL_Type==0)
      {
        // sl=NormalizeDouble(ATR_TP_Factor,Digits);
        sl=atr*ATR_SL_Factor;
        sl= Bid+sl;
      }
      if(TP_Type==1)
      {
         tp=TP_Fixed*MyPoint;
         tp= Bid-tp;
      }
      if(TP_Type==0)
      {
        // tp=NormalizeDouble(ATR_SL_Factor,Digits);
        tp=atr* ATR_TP_Factor;
        tp=Bid-tp;
      }
      
      Alert("SL: ",sl);
   Alert("TP:",tp);
   if(sl<=minSL)
   {
      double toAdd= minSL-sl;      
      sl= sl + toAdd ;
      //sl=+ 1*MyPoint;
      Print("Added to SL: ",toAdd); 
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
   
   }
    if(sl>minSL)
   {
     Print("Minimum SL: ",minSL); 
     if(Set_Order_Limit(ticket, sl,tp)){return true;}
   }
   
   else
   {
      return false;
   }
   }
   return false;
}

bool Set_Order_Limit(int ticket, double sl, double tp)
{
   bool res=OrderModify(ticket,OrderOpenPrice(),sl,tp,0);
   if(ModifyCheck(res)){return true;}
   else{return false;}
}

bool ModifyCheck(bool res)
{
    if(!res)
      {
         Print("Error in OrderModify. Error code=",GetLastError());
         return false;
      }
      else
      {
         Print("Order modified successfully.");
         return true;
      }
}

bool TicketCheck(int ticket)
{
   if(ticket<0)
   {         
      Print("OrderSend failed with error #"+GetLastError());
      return false;
   }
      else
      {
         Print("OrderSend placed successfully");
         return true;
      }
   return false;
}
 // Returns the number of total open orders for this Symbol and MagicNumber 
int TotalOpenOrder()
{
  int total_order=0;
  for(int order=0; order<OrdersTotal();order++){
     if(OrderSelect(order,SELECT_BY_POS,MODE_TRADES)==false)break;
     if(OrderMagicNumber()==Magic_Number && OrderSymbol()==_Symbol)
     {
        total_order++;
     }
  }  
  return(total_order);
}
  
  //Checks if there is a new bar
bool IsNewBar()
{
  static datetime RegBarTime=0;
  datetime ThisBarTime=Time[0];
  
  if(ThisBarTime==RegBarTime)
  {
     return false;
  }
  else
  {
     RegBarTime=ThisBarTime;
     return true;
  }
}

bool BuyAlert()
{
   if(Close[1] > Open[1] && Close[2] > Open[2] && Close[3] > Open[3])
   {
      return(true);
   }
   else
   {
      return(false);
   }
}


// Sell Logic
bool SellAlert()
{
   if(Close[1] < Open[1] && Close[2] < Open[2] && Close[3] < Open[3])
   {
      return(true);
   }
   else
   {
      return(false);
   }
   
}
 double MyPoint()
{
   double CalcPoint = 0;
   
   if(_Digits == 2 || _Digits == 3) CalcPoint = 0.01;
   else if(_Digits == 4 || _Digits == 5) CalcPoint = 0.0001;
   
   return(CalcPoint);
}
void Buy_Watch(int ticket, double lots)
{
   //Logic//
   //loop if 3 sell candles while (true) [if(close[1] < open[1] && close[2] < open[2]&& close[3] < open[3])]
   //RefreshRates()
   //Close order [OrderClose(ticket, lots(amount of lots to be closed), Bid(bid price), slippage)]
   //break
   while(true)
   {
      if(Close[1] < Open[1] && Close[2] < Open[2]&& Close[3] < Open[3])
      {
         RefreshRates();
         bool close=OrderClose(ticket, lots, Bid, Slippage);
         if(!close){Print("Order Close Failed!");}
         else{break;}
      }
      //if(reached tp || reached sl){break;}
   
   
   }
}
void Sell_Watch(int ticket, double lots)
{
   //Logic//
   //loop if 3 buy candles [if(close[1] > open[1] && close[2] > open[2]&& close[3] > open[3])]
   //Break
   //Close order[OrderClose ( ticket, lots(amount of lots to be closed), double price(close price), slippage, color)]
   while(true)
   {
      if(Close[1] > Open[1] && Close[2] > Open[2] && Close[3] > Open[3])
      {
         RefreshRates();
         bool close=OrderClose(ticket, lots, Ask, Slippage);
         if(!close){Print("Order Close Failed!");}
         else{break;}
      }
      //if(reached tp || reached sl){break;}
   
   
   }   
   
}