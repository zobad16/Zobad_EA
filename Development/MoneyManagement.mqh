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
            int    _ticket                                                              ;
            double _prev_Atr                                                            ;
            Indicators *i                                                               ;
            bool Trail(double sl)                                                       ;
            bool Trail_Volatility(double prevatr, double trailV)                        ;
            bool JumpToBreakeven(int tickt, double sl)                                  ;
            enum position_Type
            {
               _AUTO   = 1,
               _MANUAL = 0,
            };

   public:
            MoneyManagement()                                                           ;
            ~MoneyManagement()                                                          ;
            int    getTicket()                                                          ;
            int    getPrev_Atr()                                                        ;
            double CalculatePositionSize(int    type,    double    lot,  double rvalue) ;
            double CalculateTP(int op,   int    tp_type, double value)                  ;
            double CalculateSL(int op,double op_Price,   int    sl_type, double value)  ;
            bool   PlaceOrder (int op,   double lot,     double tp, double sl,int Magic_Number ,int comment);
            bool   PlaceOrder(int op , double lot, int tpType, double tpval,int slType,double slval,int Magic_Number, int comment);
            bool   TrailOrder(int type, double val, int magic)                          ;
            bool   isOrderOpen()                                                        ;
            bool   JumpToBreakeven(int magic,string comment,double when, double by)     ;
            bool   ModifyCheck(bool res)                                                ;
            bool   Ticket_Check(int ticket)                                             ;
            bool   isConsequtive(int code , int magic)                                  ;
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MoneyManagement::MoneyManagement()
  {
   _ticket   = 0               ;
   _prev_Atr = 0.0             ;
   i         = new Indicators();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MoneyManagement::~MoneyManagement()
  {
   delete(i)                   ;
  }
//+------------------------------------------------------------------+
int MoneyManagement::getTicket()
{
   return 0                    ;
}
int MoneyManagement:: getPrev_Atr(){return 0;}
double MoneyManagement:: CalculatePositionSize(int lot_type, double lot, double risk)
{
   double lots        = lot                                      ; 
   double minlot      = MarketInfo(Symbol(), MODE_MINLOT)        ;
   double maxlot      = MarketInfo(Symbol(),MODE_MAXLOT)         ; 
   double leverage    = AccountLeverage()                        ;
   double lotsize     = MarketInfo(Symbol(), MODE_LOTSIZE)       ;
   double stoplevel   = MarketInfo(Symbol(), MODE_STOPLEVEL)     ;
   double MinLots     = 0.01                                     ;
   double MaximalLots = 50.0                                     ;
  //------------------------------------------------------//
   if(lot_type == _AUTO)
   {      
      lots = NormalizeDouble(AccountBalance()*risk/100/1000.0, 1);
      if (lots < minlot)        lots = minlot                    ;
      if (lots > MaximalLots)   lots = MaximalLots               ;
      if (AccountFreeMargin() < Ask * lots * lotsize / leverage  )
         Print("Error:No money. Lots = ", lots, " , Free Margin = ", AccountFreeMargin());
   }   
   else   lots = NormalizeDouble(lot,Digits)                     ;
   return lots                                                   ;   
}

double MoneyManagement:: CalculateTP(int op,   int    tp_type, double value)
{
   double tp    = 0.0                                            ;
   double atr   = i.iAtr(0)                                      ;
   double point = MarketInfo(Symbol(),MODE_POINT)                ;
   int    digit = (int)MarketInfo(Symbol(),MODE_DIGITS)          ;
   double mid   = i.iBB(0,MODE_MAIN)                             ;//iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
   RefreshRates()                                                ;
   //--------------------------------------------
   if(op == OP_BUY)
   {
      switch(tp_type)
        {
          case 0:
             tp = Ask+(value*point)                             ;
             Print("Case 0 fix: Tp[",tp,"]")                    ;
             break                                              ;
          case 1:
             tp = Ask+(atr*value)                               ;
             Print("Case 1 atr: Tp[",tp,"]")                    ;
             break                                              ;
          case 2:
             Print("Mid Band: ",mid)                            ;
             tp = mid                                           ;
             Print("Case 3: mid Tp[",tp,"]")                    ;
             break                                              ;
          default :
             Print("Error in Tp Type. [",tp_type,"]")           ;
             break                                              ;
        }
   }
   else if (op == OP_SELL)
   {
      switch(tp_type)
        {
          case 0:
             tp = Bid -(value*point)                            ;
             Print("Case 0: fix Tp[",tp,"]")                    ;
             break                                              ;
          case 1:
             tp = Bid -(atr*value)                              ;
             Print("Case 1: atr Tp[",tp,"]")                    ;
             break                                              ;
          case 2:
             tp = mid                                           ;
             Print("Case 1: mid Tp[",tp,"]")                    ;
             break                                              ;
        }   
   }
   return tp                                                    ;
}

double MoneyManagement:: CalculateSL(int op, double openPrice  ,int    sl_type, double value)
{
   double sl    = 0.0                                           ;
   double atr   = i.iAtr(0)                                     ;
   double point = MarketInfo(Symbol(),MODE_POINT)               ;
   int    digit = (int)MarketInfo(Symbol(),MODE_DIGITS)         ;
   double minsl = MarketInfo(Symbol(),MODE_STOPLEVEL)           ;
   minsl        = NormalizeDouble(minsl*point,Digits)           ;
   RefreshRates()                                               ;
   //--------------------------------------------
   if(op == OP_BUY)
   {
       switch(sl_type)
         {
            case 0:
               sl = Bid -(value*point)                          ;
               Print("Case Fix:Stop Loss [",sl,"]")             ;
               break                                            ;
            case 1:
               sl = Bid -(atr*value)                            ;
               Print("Case Volatility:Stop Loss [",sl,"]")      ;
               break                                            ;
             default :
               Print("Error in SL Type. [",sl_type,"]")         ;
               break                                            ;
          }
       if(openPrice-sl>=minsl)
           {
            sl = NormalizeDouble(sl,digit)                      ;
            Print("Stop Loss [",sl,"]")                         ;
           }
      if(openPrice-sl<minsl)
           {
            double toAdd = minsl+(55*point)                     ;
            sl           = openPrice-toAdd                      ; 
            sl           = NormalizeDouble(sl,digit)            ;
            Print("Small Stop Loss [",sl,"]")                   ;
           }   
   }
   else if(op==OP_SELL)
    {  
      switch(sl_type)
           {
             case 0:
                  sl = Bid+(value*point)                        ;
                  Print("Case Fix:Stop Loss [",sl,"]")          ;
                  break                                         ;
             case 1:
                  sl=Bid+(atr*value)                            ;
                  Print("Case Volatility:Stop Loss [",sl,"]")   ;
                  break                                         ;
           }       
         if(sl-openPrice>=minsl )
           {
            sl          = NormalizeDouble(sl,digit)             ;
            Print("Stop Loss [",sl,"]")                         ;
            }
         else if(sl-openPrice<minsl)
           {
            double toAdd = minsl+(7.0 *point)                   ;
            sl           = openPrice+toAdd                      ;
            sl           = NormalizeDouble(sl,digit)            ;
            Print("Small Stop Loss [",sl,"]")                   ;
           }
    }
    return sl                                                   ;
}
bool MoneyManagement::   PlaceOrder (int op,   double lot,     double tp, double sl,int mg ,int comment)
{
   int ticket   = 0                                                             ;
   int Slippage = 33                                                            ;
   //--------------------------------------------
    if(op == OP_BUY)
      ticket=OrderSend(_Symbol,OP_BUY,lot,Ask,Slippage,0,0,(string)comment,mg)  ;
   else if(op==OP_SELL)
      ticket =OrderSend(_Symbol,OP_SELL,lot,Bid,Slippage,0,0,(string)comment,mg);
   if(Ticket_Check(ticket)==true)
   {
      bool res=OrderModify(ticket,OrderOpenPrice(),sl,tp,comment)               ;
      if(ModifyCheck(res))return true                                           ;
   }
   return false                                                                 ;
}
bool  MoneyManagement::PlaceOrder(int op , double lot, int tpType, double tpval,int slType,double slval,int mg, int comment)
{
   int ticket   = 0                                                             ;
   int Slippage = 33                                                            ;
   //--------------------------------------------
    if(op == OP_BUY)
      ticket=OrderSend(_Symbol,OP_BUY,lot,Ask,Slippage,0,0,(string)comment,mg)  ;
   else if(op==OP_SELL)
     ticket = OrderSend(_Symbol,OP_SELL,lot,Bid,Slippage,0,0,(string)comment,mg);
   if(Ticket_Check(ticket)==true)
   {
      double tp = 0.0, sl = 0.0                                                 ;
      if(OrderSelect(ticket, SELECT_BY_TICKET,MODE_TRADES)>0){
         double op_price =OrderOpenPrice()                                      ;
         tp = CalculateTP(op,tpType,tpval)                                      ;
         sl = CalculateSL(op,op_price,slType,slval)                             ;
         bool res=OrderModify(ticket,OrderOpenPrice(),sl,tp,comment)            ;
         if(ModifyCheck(res))return true                                        ;
      }
   }
   return false                                                                 ;
}
bool MoneyManagement::ModifyCheck(bool res)
  {
   if(!res)
     {
      Print("Error in OrderModify. Error code=",GetLastError())                 ;
      return false                                                              ;
     }
   else
     {
      Print("Order modified successfully.")                                     ;
      return true                                                               ;
     }
  }
bool MoneyManagement::Ticket_Check(int ticket)
  {
   if(ticket<0)
     {
      Print("OrderSend failed with error #",GetLastError())                    ;
      return false                                                             ;
     }
   else
     {
      Print("OrderSend placed successfully")                                   ;
      return true                                                              ;
     }
   return false                                                                ;
  }
bool MoneyManagement::   Trail(double sl)
{
   Print("Trailing....")                                                       ;
   bool tckt = OrderModify(OrderTicket(), OrderOpenPrice(),sl,OrderTakeProfit(),0,clrNONE);
   if(!tckt)
      {
         Print("Error Trail Modify: Error No[",GetLastError(),"]")             ; 
         return false                                                          ;
      }
   return true                                                                 ;
}
bool MoneyManagement::   TrailOrder(int type, double val, int magic_Number){
   double point    = MarketInfo(Symbol(),MODE_POINT)                           ;
   int    min_stop =(int) MarketInfo(Symbol(),MODE_STOPLEVEL)                  ;
   //--------------------------------------------
    for(int ii=0; ii<OrdersTotal(); ii++)
        {
         if(OrderSelect(ii,SELECT_BY_POS,MODE_TRADES)==true)
           {
            if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_Number)
              {
                 if(OrderProfit()>0)
                 {
                     if(OrderType()==OP_BUY)
                     {                     
                        if(OrderStopLoss()>OrderOpenPrice())
                        {
                           if(Bid-OrderStopLoss()>=val*point)
                           {
                              double trailStop=val-val*0.25                    ;
                              double stop=NormalizeDouble(Bid-trailStop *point,(int)MarketInfo(Symbol(),MODE_DIGITS));
                              Print("Trail by points[",trailStop,"]")          ;
                              Trail(stop)                                      ;
                           }
                        }
                        else if(Bid-OrderOpenPrice()>=val *point
                              && OrderStopLoss()<OrderOpenPrice())
                        {
                           double trailStop=val-val*0.25                       ;
                           double stop=NormalizeDouble(Bid-trailStop *point,(int)MarketInfo(Symbol(),MODE_DIGITS))   ;
                           Print("Trail by points[",trailStop,"]")             ;
                           Trail(stop)                                         ;
                        }                       
                      }
                      else if(OrderType()==OP_SELL)
                      {
                        if(OrderStopLoss()<OrderOpenPrice())
                        {
                           if(OrderStopLoss()-Ask>=val*point)
                           {
                              double trailStop=val-val*0.25                    ;
                              double stop=NormalizeDouble(Ask+trailStop *point,(int)MarketInfo(Symbol(),MODE_DIGITS)) ;
                              Print("Trail by points[",trailStop,"]")          ;
                              Trail(stop)                                      ;
                           }
                        }
                        else if(( OrderOpenPrice()-Ask>=val *point && 
                                 OrderStopLoss()>OrderOpenPrice()) || OrderStopLoss()==0)
                        {
                            double trailStop = val-val*0.25                    ;
                            double stop      = NormalizeDouble(Ask+trailStop *point,(int)MarketInfo(Symbol(),MODE_DIGITS))   ;
                            Print("Trail by points[",trailStop,"]")            ;
                            Trail(stop)                                        ;
                        }
                     }
                 }
                     else
                        return false                                           ;
                    
              }
          }
         }
   return false;
}
bool MoneyManagement::Trail_Volatility(double prevatr, double trailV)
{
   double stop =NormalizeDouble(prevatr + (trailV*Point),Digits)               ;
   Print("Stop[",stop,"]")                                                     ;   
   int total = OrdersTotal()                                                   ;
   for(int ii = 0; ii < total; ii++)
   {
      if(OrderSelect(ii, SELECT_BY_POS, MODE_TRADES) == true)
      {
         if(OrderType()==OP_BUY)
         {
            if(Bid - OrderOpenPrice() > stop)
            {
              if(OrderStopLoss() < Bid - stop)
              {
                 Trail(Bid-prevatr)                                            ;
              }
            }
         }
         if(OrderType()==OP_SELL)
         {
            if((OrderOpenPrice()-Ask)> (stop))
            {
               if((OrderStopLoss()>(Ask+stop))||(OrderStopLoss()==0))
               {
                  Trail(Ask+prevatr)                                          ;
               }
            }      
         }
      }
   }
   return false                                                               ;
}
bool MoneyManagement::  isOrderOpen(){return false;}
bool MoneyManagement::  JumpToBreakeven(int magic,string comment,double when, double by)
{   
   double point = MarketInfo(Symbol(), MODE_POINT)                            ;
   int digit = (int)MarketInfo(Symbol(),MODE_DIGITS)                          ;
   for (int ii= 0; ii< OrdersTotal(); ii++)
   {
      if(OrderSelect(ii, SELECT_BY_POS, MODE_TRADES) == true)
         {     
            if( OrderSymbol() == Symbol() && OrderMagicNumber() == magic)
               {
                  if(StringFind(OrderComment(), comment,0)!= -1)
                     {
                        if(OrderType() == OP_BUY) 
                           {   
                           //if stoploss below open price then ignore
                           //else if 
                              if(OrderStopLoss()< OrderOpenPrice())
                              {                        
                                 if( Bid-OrderOpenPrice() >= when *point)
                                    {
                                       Print("Buy Jump to Breakeven")         ;
                                       double sl= NormalizeDouble(OrderOpenPrice()+ by *point,digit);
                                       JumpToBreakeven(OrderTicket(), sl)     ;
                                    }
                              }                              
                           }   
                         else if(OrderType() == OP_SELL) 
                           {
                              if(OrderStopLoss()> OrderOpenPrice())
                              {
                                 if( OrderOpenPrice() - Ask >= when *point)
                                    {
                                       Print("Sell Jump to Breakeven")        ;
                                       double sl= NormalizeDouble(OrderOpenPrice() - by *point,digit);
                                       JumpToBreakeven(OrderTicket(),sl)      ;
                                    }
                              }
                                                 
                            } 
                     }           
                }
         }
   }
   return false;
}
bool MoneyManagement::JumpToBreakeven(int tickt, double sl)
{
   bool tckt= OrderModify(tickt, OrderOpenPrice(),sl,OrderTakeProfit(),0,clrNONE);
   if(!tckt)
      {
         Print("Error Trail Modify: Error No[",GetLastError(),"]")              ; 
         return false                                                           ;
      }
   return true                                                                  ;

}
bool MoneyManagement::isConsequtive(int code,int magic)
{
   int total = OrdersHistoryTotal() ;
   string ccode = (string)code      ;
   Print("Total Orders[",total,"]") ;
   if(OrderSelect(total -1, SELECT_BY_POS, MODE_HISTORY)>0)
   {
      if(OrderSymbol()==Symbol() && OrderMagicNumber()== magic)
      {
         Print("Order Selected");
         Print("Code[",ccode,"] ");
         if(StringFind(OrderComment(),ccode,0)!= -1)
         {
            Print("Code[",(string)code,"] Order Comment[",OrderComment(),"]");
            return true;
         }
         else return false;
      }
   }
   return false;
}