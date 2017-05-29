//+------------------------------------------------------------------+
//|                                              MoneyManagement.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "zobad.mahmood@gmail.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MoneyManagement
{
   private:
            int    _ticket;
            double _prev_Atr;

   public:
            MoneyManagement();
            ~MoneyManagement();
            int    getTicket();
            int    getPrev_Atr();
            double CalculatePositionSize(int    type,    double value);
            double CalculateTP(int op,   int    tp_type, double points);
            double CalculateSL(int op,   int    sl_type, double points);
            int    PlaceOrder (int op,   double lot,     double tp, double sl);
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
double MoneyManagement:: CalculatePositionSize(int    type,    double value){return 0.0;}
double MoneyManagement:: CalculateTP(int op,   int    tp_type, double points){return 0.0;}
double MoneyManagement:: CalculateSL(int op,   int    sl_type, double points){return 0.0;}
int MoneyManagement::   PlaceOrder (int op,   double lot,     double tp, double sl){return 0;}
bool MoneyManagement::   TrailOrder(int type, int val){return false;}
bool MoneyManagement::  isOrderOpen(){return false;}
bool MoneyManagement::  JumpToBreakeven(double when, double by){return false;}