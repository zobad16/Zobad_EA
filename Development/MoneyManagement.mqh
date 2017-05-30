//+------------------------------------------------------------------+
//|                                              MoneyManagement.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "zobad.mahmood@gmail.com"
#property version   "1.00"
#property strict
#include "Indicators.mqh"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MoneyManagement
{
   private:
            int    _ticket;
            double _prev_Atr;
            Indicators *i;
            enum position_Type
            {
               _AUTO   = 1,
               _MANUAL = 0,
            };

   public:
            MoneyManagement();
            ~MoneyManagement();
            int    getTicket();
            int    getPrev_Atr();
            double CalculatePositionSize(int    type,    int    lot,  double rvalue);
            double CalculateTP(int op,   int    tp_type, double value);
            double CalculateSL(int op,   int    sl_type, double value);
            int    PlaceOrder (int op,   double lot,     double tp,   double sl);
            bool   TrailOrder(int type, int val);
            bool   isOrderOpen();
            bool   JumpToBreakeven(double when, double by);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MoneyManagement::MoneyManagement()
  {
   _ticket   = 0;
   _prev_Atr = 0.0;
   i= new Indicators();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MoneyManagement::~MoneyManagement()
  {
  }
//+------------------------------------------------------------------+
int MoneyManagement::getTicket()
{
   return 0;
}
int MoneyManagement:: getPrev_Atr(){return 0;}
double MoneyManagement:: CalculatePositionSize(int lot_type, int lot, double risk)
{
   double lots = lot;
   double minlot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxlot = MarketInfo(Symbol(),MODE_MAXLOT);
   double leverage = AccountLeverage();
   double lotsize = MarketInfo(Symbol(), MODE_LOTSIZE);
   double stoplevel= MarketInfo(Symbol(), MODE_STOPLEVEL);
   double MinLots =0.01;
   double MaximalLots =50.0;
  //------------------------------------------------------//
   if(lot_type == _AUTO)
   {      
      lots = NormalizeDouble(AccountBalance()*risk/100/1000.0, 1);
      if(lots < minlot) lots = minlot;
      if (lots > MaximalLots) lots = MaximalLots;
      if (AccountFreeMargin() < Ask * lots * lotsize / leverage)
         Print("Error:No money. Lots = ", lots, " , Free Margin = ", AccountFreeMargin());
   }   
   else lots=NormalizeDouble(lot,Digits);
   return lots;   
}
double MoneyManagement:: CalculateTP(int op,   int    tp_type, double value)
{
   double tp=0.0;
   double atr= i.iAtr(0);
   double point=MarketInfo(Symbol(),MODE_POINT);
   int digit= (int)MarketInfo(Symbol(),MODE_DIGITS);
   double mid=i.iBB(0,MODE_MAIN);//iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
   //--------------------------------------------
   if(op == OP_BUY)
   {
    switch(tp_type)
      {
        case 0:
         tp=Ask+(value*point);
         Print("Case 0 fix: Tp[",tp,"]");
         break;
        case 1:
         tp=Ask+(atr*point);
         Print("Case 1 atr: Tp[",tp,"]");
         break;
        case 2:
         Print("Mid Band: ",mid);
         tp=mid;
         Print("Case 3: mid Tp[",tp,"]");
         break;
        default :
         Print("Error in Tp Type. [",tp_type,"]");
         break;
      }
   }
   else if (op == OP_SELL)
   {
   switch(tp_type)
     {
         case 0:
            tp=Bid -(value*point);
            Print("Case 0: fix Tp[",tp,"]");
            break;
         case 1:
            tp=Bid -(atr*value);
            Print("Case 1: atr Tp[",tp,"]");
            break;
         case 2:
            tp=mid;
            Print("Case 1: mid Tp[",tp,"]");
            break;
     }   
   }
   return tp;
}
double MoneyManagement:: CalculateSL(int op,   int    sl_type, double value)
{
   double sl =0.0;
   double atr= i.iAtr(0);
   double point=MarketInfo(Symbol(),MODE_POINT);
   int digit= (int)MarketInfo(Symbol(),MODE_DIGITS);
   double minsl=MarketInfo(Symbol(),MODE_STOPLEVEL);
   double min_sl=NormalizeDouble(minsl*point,Digits);/*minsl*_point;*/
   if(op == OP_BUY)
   {
       switch(sl_type)
         {
            case 0:
               sl=Bid -(value*point);
               Print("Stop Loss [",sl,"]");
               break;
            case 1:
               sl=Bid -(atr*value);
               Print("Stop Loss [",sl,"]");
               break;
             default :
               Print("Error in SL Type. [",sl_type,"]");
               break;
          }
       if(Bid-sl>=min_sl)
           {
            sl=NormalizeDouble(sl,digit);
            Print("Stop Loss [",sl,"]");
           }
      if(Bid-sl<min_sl)
           {
            double toAdd=min_sl+(55*point);
            sl=Bid-toAdd;
            sl=NormalizeDouble(sl,digit);
            Print("Stop Loss [",sl,"]");
           }
   
   }
   else if(op==OP_SELL)
    {  
      switch(sl_type)
           {
             case 0:
                  sl=Bid+(value*point);
                  Print("Stop Loss [",sl,"]");
                  break;
             case 1:
                  sl=Bid+(atr*value);
                  Print("Stop Loss [",sl,"]");
                  break;
           }       
         if(sl-Ask>=minsl )
           {
            sl=NormalizeDouble(sl,digit);
            Print("Stop Loss [",sl,"]");
            }
         if(sl-Ask<minsl)
           {
            double toAdd=min_sl+(7.0 *point);
            sl=Ask+toAdd;
            sl=NormalizeDouble(sl,digit);
            Print("Stop Loss [",sl,"]");
           }
    }
    return sl;
}
int MoneyManagement::   PlaceOrder (int op,   double lot,     double tp, double sl)
{
   return 0;
}
bool MoneyManagement::   TrailOrder(int type, int val){return false;}
bool MoneyManagement::  isOrderOpen(){return false;}
bool MoneyManagement::  JumpToBreakeven(double when, double by){return false;}