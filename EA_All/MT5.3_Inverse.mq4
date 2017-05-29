//+------------------------------------------------------------------+
//|                                                MT5.3_Inverse.mq4 |
//|                                                    Zobad Mahmood |
//|                                          zobad.mahmood@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "zobad.mahmood@gmail.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
enum Strategy_Type
{
   BREAK   =  1, //Break Entry
   POINT   =  0, //Point Based Entry
   INVERSE = -1, //Inverse Entry   
};
enum Profit_type
{
   VOLAT    = 1, //Volatility
   MID_BAND = 2 ,//Middle Band 
   FIXED    = 3 // Bottom Band
};
enum Stop_Type
{
   FIX = 1,        //Top Band 
   VOLATILITY = 2, // Volatility
};

//------------------------------------------------------------------------
input int           magic = 999;                                     //Magic Number
input double        lot =0.1;                                        //Lot Size             
input Strategy_Type use_Strategy=1;                                  //Choose Entry Strategy
input double        point_entry= 100.0;                              //Point Entry::Points for entry
input Profit_type   TP_Type= VOLAT;                                  //TP::Type
input Stop_Type     SL_Type=VOLATILITY;                              //SL::Type
input double        tp;                                              //TP::Factor Volatility/Points(Fixed)
input double        sl;                                              //SL::Factor Volatility/Points(Fixed)
input bool          use_trail=false;                                 //Trail::Use Trail
input int           trail_point=100;                                 //Trail::

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
//---
   
  }
//+------------------------------------------------------------------+
