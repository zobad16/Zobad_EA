//+------------------------------------------------------------------+
//|                                                      FirstEA.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//--- input parameters
input int      TakeProfit=500;
input int      StopPrice=500;
input double   LotSize=0.1;
input int      Slippage=33;
input int      MagicNumber=5555;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
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
     if(TotalOpenOrder()==0){
      if(Close[1]>Open[1]&& Close[2]>Open[2]&&Close[3]>Open[3])
      {
        OrderSend(Symbol(),OP_BUY,LotSize,Ask,Slippage,Ask-StopLoss*_Point,Ask+StopLoss*_Point,"Buy",MagicNumber);
     
      }
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
//+------------------------------------------------------------------+
