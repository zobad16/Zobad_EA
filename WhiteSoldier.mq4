//+------------------------------------------------------------------+
//|                                                      FirstEA.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property description "White Soldier and Black Crows Strategy"
//--- input parameters
//double         atr= iAtr(NULL,0,20,0);

input int      AtrPeriod=14;
input ENUM_TIMEFRAMES ATR_Charts_Period = PERIOD_M5;
enum Take_Profit{
   atr=0,
   fixed=1
};
input Take_Profit TP_Type=atr;
input int         ATR_SL_Factor=1;
input int         ATR_TP_Factor=1;
input double      TP_fixed=5.00;
input double      SL_fixed=5.00;
input double      LotSize=0.1;
input int         Slippage=0;
input int         MagicNumber=5555;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
double MyPoint;
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
//---White Soldier Strategy

//       Alert(atr+"");
     if(TotalOpenOrder()==0){
     
      if(Close[1]>Open[1]&& Close[2]>Open[2]&&Close[3]>Open[3])
      {
         Print("Buy Order Request");
         double atr= iATR(NULL,ATR_Charts_Period,14,0);
         if(TP_Type==0){
        // int ticket=OrderSend(_Symbol,OP_BUY,LotSize,Ask,Slippage,Ask -( atr * ATR_SL_Factor)*MyPoint,Ask+(atr*ATR_TP_Factor)*MyPoint,"Buy",MagicNumber);}
         
         int ticket=OrderSend(_Symbol,OP_BUY,LotSize,Ask,Slippage,0,Ask+(atr*ATR_TP_Factor)*MyPoint,"Buy",MagicNumber);}
         else
         {
         //OrderSend(Symbol(),OP_BUY,LotSize,Ask,Slippage,Ask -( atr * SL_fixed)*MyPoint,Ask+TP_fixed*MyPoint,"Buy",MagicNumber);
            OrderSend(Symbol(),OP_BUY,LotSize,Ask,Slippage,0,Ask+TP_fixed*MyPoint,"Buy",MagicNumber);
         }
      }
      if(Close[1]<Open[1]&& Close[2]<Open[2]&&Close[3]<Open[3])
      {
         Print("Sell Order Request");
         double atr= iATR(NULL,ATR_Charts_Period,20,0);
         if(TP_Type==0){
         //int ticket=OrderSend(_Symbol,OP_SELL,LotSize,Ask,Slippage,Ask -( atr * ATR_SL_Factor)*MyPoint,Ask+(atr*ATR_TP_Factor)*MyPoint,"Buy",MagicNumber);}
         int ticket=OrderSend(_Symbol,OP_SELL,LotSize,Bid,Slippage,0,Bid+(atr*ATR_TP_Factor)*MyPoint,"Buy",MagicNumber);}
         
         else
         {
         //OrderSend(_Symbol,OP_SELL,LotSize,Ask,Slippage,Ask -( atr * SL_fixed)*MyPoint,Ask+TP_fixed*MyPoint,"Buy",MagicNumber);
         
         OrderSend(_Symbol,OP_SELL,LotSize,Bid,Slippage,0,Bid+TP_fixed*MyPoint,"Sell",MagicNumber);
         
         }

      }
      
       // Check Buy Entry
      //if(BuyAlert() == true)
      //   {
      //      OpenBuy();
      //   }
      
      // Check Sell Entry
     // else if(SellAlert() == true)
       //  {
           // OpenSell();
         //}
     }
  }
 
 // Returns the number of total open orders for this Symbol and MagicNumber 
 int TotalOpenOrder()
 {
   int total_order=0;
   for(int order=0; order<OrdersTotal();order++){
      if(OrderSelect(order,SELECT_BY_POS,MODE_TRADES)==false)break;
      if(OrderMagicNumber()==MagicNumber && OrderSymbol()==_Symbol)
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
  // Get My Points   
double MyPoint()
{
   double CalcPoint = 0;
   
   if(_Digits == 2 || _Digits == 3) CalcPoint = 0.01;
   else if(_Digits == 4 || _Digits == 5) CalcPoint = 0.0001;
   
   return(CalcPoint);
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
 
 
// Open Buy Order
void OpenBuy()
{
   // Open Buy Order
    //int ticket=OrderSend(_Symbol,OP_BUY,LotSize,Ask,Slippage,0,0,"Buy",MagicNumber);
    //TicketCheck(ticket);
    // Modify Buy Order 
   if(TP_Type==0)
   {
     //bool res = OrderModify(ticket,OrderOpenPrice(),Ask -( atr * ATR_SL_Factor*MyPoint),Ask+(atr*ATR_TP_Factor*MyPoint),0);
     //OrderModifyCheck(res);     
     double sl=Ask -( atr * ATR_SL_Factor)*_Point;
     double tp=Ask+(atr*ATR_TP_Factor)*_Point;
     //Ask -( atr * ATR_Factor)*MyPoint,Ask+(atr*ATR_Factor)*MyPoint
     int ticket=OrderSend(_Symbol,OP_BUY,LotSize,Ask,Slippage,Ask -( atr * ATR_SL_Factor)*MyPoint,Ask+(atr*ATR_TP_Factor)*MyPoint,"Buy",MagicNumber);
     TicketCheck(ticket);
    
   }     
   
   else if(TP_Type==1)
   {
     //bool res = OrderModify(ticket,OrderOpenPrice(),Ask -( atr * SL_fixed*MyPoint),Ask+(atr*TP_fixed*MyPoint),0);
     //OrderModifyCheck(res);
     
     double sl=Ask -( atr * SL_fixed)*_Point;
     double tp=Ask+(atr*TP_fixed)*_Point;
     int ticket=OrderSend(_Symbol,OP_BUY,LotSize,Ask,Slippage,Ask -( atr * SL_fixed)*MyPoint,Ask+TP_fixed*MyPoint,"Buy",MagicNumber);
     TicketCheck(ticket);
   
   }     
   
                 
   // Modify Buy Order
  // bool res = OrderModify(ticket,OrderOpenPrice(),Ask-StopLoss*MyPoint,Ask+TakeProfit*MyPoint,0);
  // OrderModifyChech(res);
}
void TicketCheck(int ticket)
{
    if(ticket<0){
         
         Print("OrderSend failed with error #"+GetLastError());
      }
      else
      {
         Print("OrderSend placed successfully");
      } 
}
void OrderModifyCheck(int res)
{
    if(!res)
      {
         Print("Error in OrderModify. Error code=",GetLastError());
      }
      else
      {
         Print("Order modified successfully.");
      }
}

// Open Sell Order
void OpenSell()
{
   //Open Sell Order
 //  int ticket = OrderSend(_Symbol,OP_SELL,LotSize,Bid,Slippage,0,0,"SELL",MagicNumber);
  // TicketCheck(ticket);  
                 
   // Modify Sell Order
   //bool res = OrderModify(ticket,OrderOpenPrice(),Bid+StopLoss*MyPoint,Bid-TakeProfit*MyPoint,0);
   //OrderModifyChech(res);
   if(TP_Type==0)
   {
     double sl=Bid+( atr * ATR_SL_Factor)*_Point;
     double tp=Bid-(atr*ATR_TP_Factor)*_Point;
    // bool res = OrderModify(ticket,OrderOpenPrice(),sl,tp,0);
     //OrderModifyCheck(res);
      int ticket = OrderSend(_Symbol,OP_SELL,LotSize,Bid,Slippage,sl,tp,"SELL",MagicNumber);
      TicketCheck(ticket);  
   //  bool res = OrderModify(ticket,OrderOpenPrice(),Ask -( atr * ATR_Factor)*MyPoint,Ask+(atr*ATR_Factor)*MyPoint,0);
   //  OrderModifyCheck(res);     
   }     
   
   else if(TP_Type==1)
   {
      //bool res = OrderModify(ticket,OrderOpenPrice(),Bid+( atr * SL_fixed*MyPoint),Bid-(atr*TP_fixed*MyPoint),0);
      //OrderModifyCheck(res); 
      double sl=Bid+( atr * SL_fixed)*_Point;
      double tp=Bid-(atr*TP_fixed)*_Point;
      int ticket = OrderSend(_Symbol,OP_SELL,LotSize,Bid,Slippage,sl,tp,"SELL",MagicNumber);
      TicketCheck(ticket);  
    // bool res = OrderModify(ticket,OrderOpenPrice(),Ask -( atr * ATR_Factor)*MyPoint,Ask+(atr*TP_fixed)*MyPoint,0);
    // OrderModifyCheck(res);
   }   
         
}
  
//+------------------------------------------------------------------+


