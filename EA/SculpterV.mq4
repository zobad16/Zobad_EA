//+------------------------------------------------------------------+
//|                                                    Ladder_v2.mq4 |
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
   VOLATILITY=0,
   FIXED=1
};

input int             ATR_Period=20;
input ENUM_TIMEFRAMES ATR_Charts_Period = PERIOD_M5;
input Take_Profit     TP_Type=FIXED;
input Take_Profit     SL_Type=VOLATILITY;
input bool            SCULPTER= true;
input bool            VOLATILITY_Range=false;
input double          VOLATILITY_Range_High=30;
input double          VOLATILITY_Range_Low=20;      
input int             VOLATILITY_TP_Factor=3;
input int             VOLATILITY_SL_Factor=2;
input double          TP_Fixed=50.0;
input double          SL_Fixed=20.0;
input double          LotSize=1.0;
input int             Slippage=33;
input int             Magic_Number=5555;

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
      
      if(BuyAlert()==true && IsNewBar())
      {
         //if(Place_Buy_Order()==false)
         //first change
         double atr=iATR(0,0,ATR_Period,0);
         if(VOLATILITY_Range==true && atr>= (VOLATILITY_Range_Low*MyPoint) || atr<=(VOLATILITY_Range_High*MyPoint))
         {
            Print("ATR MET");
            if(SCULPTER==false)
            {
              Print("Sculpter False");
              bool order=Place_Buy_Order();
              if(!order){Print("Order Failed");}
            }
            else
            {
               bool order= Place_Sell_Order();
               if(order==false){Print("Buy Failed");}
            }
         }
         else if( VOLATILITY_Range == false)
         {
            if(SCULPTER== false )
            {
              Print("Sculpter False");
              bool orders=Place_Buy_Order();
              if(orders){Print("Order Failed");}
            }
            else
            {
               bool order= Place_Sell_Order();
               if(order==false){Print("Buy Failed");}
            }
               
         }
      }
      else if(SellAlert()==true && IsNewBar())
      {
         double atr=iATR(0,0,ATR_Period,0);
         if(VOLATILITY_Range && atr>= (VOLATILITY_Range_Low*MyPoint) || atr<=(VOLATILITY_Range_High*MyPoint))
         {
         Print("Atr met");
            if(SCULPTER)
            {
              bool order=Place_Buy_Order();
              if(!order){Print("Order Failed");}
            }
            else
            {
              Print("Sculpter False");
              bool order=Place_Sell_Order();
              if(!order){Print("Order Failed");}
            }
            
         }
         else if(VOLATILITY_Range==false)
            {
               if(SCULPTER)
               {
                 bool order=Place_Buy_Order();
                 if(!order){Print("Order Failed");}
               }
               else
               {
                 Print("Sculpter False");
                 bool order=Place_Sell_Order();
                 if(!order){Print("Order Failed");}
               }
               
            }
      }
    
   }
    
        else if(IsNewBar()&&TotalOpenOrder()!=0 ){ int ticket; double lots;
           bool orderS=OrderSelect(0,SELECT_BY_POS,MODE_TRADES );
           if(orderS)
            {
               ticket = OrderTicket(); lots= OrderLots();
               //Print("Ticket: "+ticket+" Lots: "+lots+"Order Type: "+OrderType());
               if(OrderType()==0){Buy_Watch(ticket, lots); Sleep(15000);}
               else if(OrderType()== 1){Sell_Watch(ticket,lots);Sleep(15000);}
            }
            else if(!orderS){Print("Order Select Failed"); }
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
        sl=atr*VOLATILITY_SL_Factor;
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
        tp=atr* VOLATILITY_TP_Factor;
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
        sl=atr*VOLATILITY_SL_Factor;
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
        tp=atr* VOLATILITY_TP_Factor;
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
      RefreshRates();
      if(Close[1] < Open[1] && Close[2] < Open[2]&& Close[3] < Open[3])
      {
         Print("Buy watch!");         
         //RefreshRates();
         bool close=OrderClose(ticket, lots, Bid, Slippage);
         if(!close){Print("Order Close Failed!");}
         
      }
      //if(reached tp || reached sl){break;}
   
   
   
}
void Sell_Watch(int ticket, double lots)
{
   //Logic//
   //loop if 3 buy candles [if(close[1] > open[1] && close[2] > open[2]&& close[3] > open[3])]
   //Break
   //Close order[OrderClose ( ticket, lots(amount of lots to be closed), double price(close price), slippage, color)]
      RefreshRates();
      if(Close[1] > Open[1] && Close[2] > Open[2] && Close[3] > Open[3])
      {
         Print("Sell Watch!");
         //RefreshRates();
         bool close=OrderClose(ticket, lots, Ask, Slippage);
         if(!close){Print("Order Close Failed!");}
         
      }
      //if(reached tp || reached sl){break;}
   
   
      
   
}