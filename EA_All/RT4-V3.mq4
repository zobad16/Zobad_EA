//+------------------------------------------------------------------+
//|                                                       RT4-V3.mq4 |
//|                                                    Zobad Mahmood |
//|                                          zobad.mahmood@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "zobad.mahmood@gmail.com"
#property version   "3.0"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#define FAIL 0
#define BUY  1
#define SELL 2

enum Take_Profit_Type{
   
   FIXED=0,
   VOLATILITY=1,
   MID_BB=2
};
enum Strategy_Type
{
   BREAKOUT=0,
   BREAKIN=1,   
   BANDTOUCH=2,   
};
input int              Magic_Number = 1;                 //Magic Number

extern string          order1="-------Order_1--------";  //Order 1 Settings
bool                   order1Open=false;
extern string          Strat_Name="Break Out";           //Strategy Name
input bool             useStrategy1=true;                //Use Strategy
input double           LotSize=1.0;                      //Lot Size
input Take_Profit_Type TP_Type= VOLATILITY;              //Take Profit Type
input Take_Profit_Type SL_Type= VOLATILITY;              //Stop Loss Type
input double           TP_Volatility_Factor=2.0;         //Take Profit Volatility Factor
input double           SL_Volatility_Factor=1.0;         //Stop Loss Volatility Factor
input double           TP_Fixed=25.0;                    //Take Profit Fixed(Pips)
input double           SL_Fixed=12.0;                    //Stop Loss Fixed(Pips)

extern string          order2="-------Order_2--------"; //Order 2 Settings   
bool                   order2Open= false;
extern string          Strat_Name2="Break In";          //Strategy Name
input bool             useStrategy2=true;                //Use Strategy
input double           LotSize2=1.0;                    //Lot Size
input Take_Profit_Type TP_Type2= VOLATILITY;            //Take Profit Type
input Take_Profit_Type SL_Type2= VOLATILITY;            //Stop Loss Type
input double           TP_Volatility_Factor2=3.0;       //Take Profit Volatility Factor
input double           SL_Volatility_Factor2=1.5;       //Stop Loss Volatility Factor
input double           TP_Fixed2=25.0;                  //Take Profit Fixed(Pips)
input double           SL_Fixed2=12.0;                  //Stop Loss Fixed(Pips)

extern string          order3="-------Order_3--------"; //Order 3 Settings
bool                   order3Open=false;   
extern string          Strat_Name3="Band Touch";        //Strategy Name
input bool             useStrategy3=true;                //Use Strategy
input double           LotSize3=1.0;                    //Lot Size
input Take_Profit_Type TP_Type3= VOLATILITY;            //Take Profit Type
input Take_Profit_Type SL_Type3= VOLATILITY;            //Stop Loss Type
input double           TP_Volatility_Factor3=3.0;       //Take Profit Volatility Factor
input double           SL_Volatility_Factor3=1.5;       //Stop Loss Volatility Factor
input double           TP_Fixed3=25.0;                  //Take Profit Fixed(Pips)
input double           SL_Fixed3=12.0;                  //Stop Loss Fixed(Pips)

extern string          bb_Set="--Bollinger Band Settings--"; //Bollinger Band Settings
input ENUM_TIMEFRAMES  BB_Chart_Timeframe= PERIOD_M15;  //Bollinger Band Chart Time 
input int              BB_Period=14;                    //Bollinger Band Period

extern string          atr_Set="--ATR Settings--";     //Order 3 Settings
input int              ATR_Period=14;                   //ATR Period 
input ENUM_TIMEFRAMES  ATR_Charts_Period = PERIOD_M30;  //ATR Chart Time
input int              Slippage=33;                     //Slippage
input double           Risk_Management;                 //Risk Management 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
double MyPoint;
double Mid_Price=0.0;

int OnInit()
  {
   MyPoint=MyPoint();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
  
double MyPoint()
  {
   double CalcPoint = 0;
   
   if(_Digits == 2 || _Digits == 3) CalcPoint = 0.01;
   else if(_Digits == 4 || _Digits == 5) CalcPoint = 0.0001;
   
   return(CalcPoint);
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

//+------------------------------------------------------------------+
//|   Entry Rule Check                                               |
//+------------------------------------------------------------------+

//Check for Breakout Pattern 

int Pattern1()
{
   if(order1Open)return FAIL;
   else if(Sell_Alert_1())return SELL;
   else if(Buy_Alert_1())return BUY;
   return FAIL;
}

//Check for Breakin Pattern 
int Pattern2()
{
   if(order2Open)return FAIL;
   else if(Sell_Alert_2())return SELL;
   else if(Buy_Alert_2())return BUY;
   return FAIL;
}

//Check for Touch Pattern 
int Pattern3()
{   
   if(order3Open) return FAIL;
   else if(Sell_Alert_3()) return SELL;
   else if(Buy_Alert_3())  return BUY;
   return FAIL;
}

//Breakout Pattern
bool Sell_Alert_1()
{
   double bb_high=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,1);
   double bb_high2=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,2); 
   if(Open[1]<bb_high && Close[1]>bb_high ) return true;
   return false;
}  

bool Buy_Alert_1()
{
   double bb_low=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,1);
   if(Open[1]>bb_low && Close[1]< bb_low)  return true;   
   return false;
}  

//Breakin Pattern
bool Sell_Alert_2()
{
   double bb_high=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,1);
   double bb_high2=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,2); 
   if(Open[2]>bb_high2 && Close[2]<bb_high2 )
   { 
     if(Close[1]> Close[2] && Close[1]<bb_high){Print("Sell Alert"); return true;}
   }             
   return false;
}  

bool Buy_Alert_2()
{
   double bb_low=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,1);
   double bb_low2=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,2);
   if(Open[2]<bb_low2 && Close[2]>bb_low2)
   {  
      if(Close[1]< Close[2] && Close[1]>bb_low){ Print("Buy Order Alert"); return true;}
   }
   return false;
} 
//
bool Sell_Alert_3()
{
   double bb_high=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,1);
   if(High[1]>=bb_high) return true;           
   return false;
}  

bool Buy_Alert_3()
{
   double bb_low=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,1);
   if(Low[1]<=bb_low)  return true;   
   return false;
}

//+------------------------------------------------------------------+
//|   Place Order Buy                                                |
//+------------------------------------------------------------------+

bool Place_Buy_Order()
{

   double sl=0.0,tp=0.0;
   int ticket= OrderSend(_Symbol,OP_BUY,LotSize,Ask,Slippage,0,0,Strat_Name,Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);   Print("ATR Reading: ",atr);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*_Point;
   Print("Minimum Broker SL: ",minSL);
   
   if(Ticket_Check(ticket)==true)
   {
      order1Open=true;
      if(SL_Type==0)
      {
         sl=SL_Fixed*pip_Calculate();
         sl=Ask-sl;
      }
      if(SL_Type==1)
      {        
        sl=atr*SL_Volatility_Factor;
        sl= Ask-sl;
      }
      if(TP_Type==0)
      {
         Print("Fixed TP");
         tp=TP_Fixed*pip_Calculate();
         tp= Ask+tp;
      }
      if(TP_Type==1)
      {
        tp=atr* TP_Volatility_Factor;
        tp=Ask+tp;
      }  
      if(TP_Type==2)
      {
         double B_Mid_B;
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
         Print("Mid Band: ",B_Mid_B);
         Print("Mid Band Pip: ",B_Mid_B*pip_Calculate());         
         tp= B_Mid_B;
         Print("Mid Band TP: ",tp);
      }      
   }
   Print("Ask: ",Ask);
   Print("Point: ",_Point);
   Print("Pip: ",_Point*10);
   Print("SL: ",sl);
   Print("TP:",tp);
   
   //(Buy)Trade option not performed if:
   //a) Bid-SL ≥ StopLevel (SL)
   //b) TP-Bid ≥ StopLevel (Tp) 
   Print("StopLoss Level: ",Bid-sl);
  if(Bid-sl>=minSL)
   {
      
      if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}
   
   }
     if(Bid-sl<minSL)
   {  
      double toAdd= minSL;      
      sl= Ask- toAdd;      
      Print("SL below Minimum Broker SL. Aplying minimum SL!");
      if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}
   }
   return false;
}
bool Place_Buy_Order2()
{

   double sl=0.0,tp=0.0;
   int ticket= OrderSend(_Symbol,OP_BUY,LotSize2,Ask,Slippage,0,0,Strat_Name2,Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);   Print("ATR Reading: ",atr);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*_Point;
   Print("Minimum Broker SL: ",minSL);
   
   if(Ticket_Check(ticket)==true)
   {
      order2Open=true;
      if(SL_Type2==0)
      {
         sl=SL_Fixed2*pip_Calculate();
         sl=Ask-sl;
      }
      if(SL_Type2==1)
      {        
        sl=atr*SL_Volatility_Factor2;
        sl= Ask-sl;
      }
      if(TP_Type2==0)
      {
         Print("Fixed TP");
         tp=TP_Fixed2*pip_Calculate();
         tp= Ask+tp;
      }
      if(TP_Type2==1)
      {
        tp=atr* TP_Volatility_Factor2;
        tp=Ask+tp;
      }  
      if(TP_Type2==2)
      {
         double B_Mid_B;
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
         Print("Mid Band: ",B_Mid_B);
         Print("Mid Band Pip: ",B_Mid_B*_Point*10);         
         tp= B_Mid_B;
         Print("Mid Band TP: ",tp);
      }      
   }
   Print("Ask: ",Ask);
   Print("Point: ",_Point);
   Print("Pip: ",_Point*10);
   Print("SL: ",sl);
   Print("TP:",tp);
   
   //(Buy)Trade option not performed if:
   //a) Bid-SL ≥ StopLevel (SL)
   //b) TP-Bid ≥ StopLevel (Tp) 
   Print("StopLoss Level: ",Bid-sl);
  if(Bid-sl>=minSL)
   {      
      if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}   
   }
   if(Bid-sl<minSL)
   {  
      double toAdd= minSL;      
      sl= Ask- toAdd;      
      Print("SL below Minimum Broker SL. Aplying minimum SL!");
      if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}
   }
   return false;
}

bool Place_Buy_Order3()
{

   double sl=0.0,tp=0.0;
   int ticket= OrderSend(_Symbol,OP_BUY,LotSize3,Ask,Slippage,0,0,Strat_Name3,Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);   Print("ATR Reading: ",atr);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*_Point;
   Print("Minimum Broker SL: ",minSL);
   
   if(Ticket_Check(ticket)==true)
   {
      order3Open=true;
      if(SL_Type2==0)
      {
         sl=SL_Fixed2*pip_Calculate();
         sl=Ask-sl;
      }
      if(SL_Type2==1)
      {        
        sl=atr*SL_Volatility_Factor2;
        sl= Ask-sl;
      }
      if(TP_Type2==0)
      {
         Print("Fixed TP");
         tp=TP_Fixed2*pip_Calculate();
         tp= Ask+tp;
      }
      if(TP_Type2==1)
      {
        tp=atr* TP_Volatility_Factor2;
        tp=Ask+tp;
      }  
      if(TP_Type2==2)
      {
         double B_Mid_B;
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
         Print("Mid Band: ",B_Mid_B);
         Print("Mid Band Pip: ",B_Mid_B*_Point*10);         
         tp= B_Mid_B;
         Print("Mid Band TP: ",tp);
      }      
   }
   Print("Ask: ",Ask);
   Print("Point: ",_Point);
   Print("Pip: ",_Point*10);
   Print("SL: ",sl);
   Print("TP:",tp);
   
   //(Buy)Trade option not performed if:
   //a) Bid-SL ≥ StopLevel (SL)
   //b) TP-Bid ≥ StopLevel (Tp) 
   Print("StopLoss Level: ",Bid-sl);
  if(Bid-sl>=minSL)
   {      
      if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}   
   }
   if(Bid-sl<minSL)
   {  
      double toAdd= minSL;      
      sl= Ask- toAdd;      
      Print("SL below Minimum Broker SL. Aplying minimum SL!");
      if(Set_Order_Limit(Blue,ticket, sl,tp)){return true;}
   }
   return false;
}

//+------------------------------------------------------------------+
//|   Place Order Sell                                               |
//+------------------------------------------------------------------+

bool Place_Sell_Order()
{
   double sl=0.0,tp=0.0;
   int ticket= OrderSend(_Symbol,OP_SELL,LotSize,Bid,Slippage,0,0,Strat_Name,Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*_Point;
   Print("Minimum Broker SL: ",minSL);
   Print("ATR Reading: ",atr);
   if(Ticket_Check(ticket)==true)
   {
      if(SL_Type==0)
      {
        sl=SL_Fixed*pip_Calculate();
        sl=Bid+sl;
      }
      if(SL_Type==1)
      {
        sl=atr*SL_Volatility_Factor;
        sl= Bid+sl;
      }
      if(TP_Type==0)
      {
        tp=TP_Fixed*pip_Calculate();
        tp= Bid-tp;
      }
      if(TP_Type==1)
      {
        
        tp=atr* TP_Volatility_Factor;
        tp=Bid-tp;
      }
      if(TP_Type==2)
      {
         double price=0.0;
         if(OrderSelect(ticket, SELECT_BY_TICKET)){
         price=OrderOpenPrice();}
         double B_Mid_B,B_Low_B, B_Up_B;
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
         B_Up_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,0);
         B_Low_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,0);
         Print("Price: ",price);
         //Print("Mid Band Pip: ",B_Mid_B*MyPoint);
         
         
         
         if(Mid_Price >0.0){tp= B_Low_B;         
         Print("Price: ",B_Mid_B + 5*_Point);
         Print("MidPrice: ",Mid_Price); Mid_Price=0.0;
         
          }
         else{
            tp= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
         Print("TP Mid Band: Sell. Mid Band TP: ",tp);
         
         }
      }      
      Print("Estm SL: ",sl);
   if(sl-Ask>=minSL)
   {
      
      if(Set_Order_Limit(Red,ticket, sl,tp)){return true;}
   
   }
    if(sl-Ask<minSL)
   {
      double toAdd= minSL;      
      sl= Ask + toAdd;
      Print("Below Min Broker SL");
      Print("SL Changed"); 
      if(Set_Order_Limit(Red,ticket, sl,tp)){return true;}
   }
   
   else
   {
      return false;
   }
   }
   return false;
}  
bool Place_Sell_Order2()
{
   double sl=0.0,tp=0.0;
   int ticket= OrderSend(_Symbol,OP_SELL,LotSize2,Bid,Slippage,0,0,Strat_Name2,Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*_Point;
   Print("Minimum Broker SL: ",minSL);
   Print("ATR Reading: ",atr);
   if(Ticket_Check(ticket)==true)
   {
      if(SL_Type2==0)
      {
        sl=SL_Fixed2*pip_Calculate();
        sl=Bid+sl;
      }
      if(SL_Type2==1)
      {
        sl=atr*SL_Volatility_Factor2;
        sl= Bid+sl;
      }
      if(TP_Type2==0)
      {
        tp=TP_Fixed2*pip_Calculate();
        tp= Bid-tp;
      }
      if(TP_Type2==1)
      {
        
        tp=atr* TP_Volatility_Factor2;
        tp=Bid-tp;
      }
      if(TP_Type2==2)
      {
         double price=0.0;
         if(OrderSelect(ticket, SELECT_BY_TICKET)){
         price=OrderOpenPrice();}
         double B_Mid_B,B_Low_B, B_Up_B;
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
         B_Up_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,0);
         B_Low_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,0);
         Print("Price: ",price);
         //Print("Mid Band Pip: ",B_Mid_B*MyPoint);             
         if(Mid_Price >0.0)
         {
            tp= B_Low_B;         
            Print("Price: ",B_Mid_B + 5*_Point);
            Print("MidPrice: ",Mid_Price); Mid_Price=0.0;         
         }
         else
         {
            tp= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
            Print("TP Mid Band: Sell. Mid Band TP: ",tp);         
         }
      }      
      Print("Estm SL: ",sl);
   if(sl-Ask>=minSL)
   {
      
      if(Set_Order_Limit(Red,ticket, sl,tp)){return true;}
   
   }
    if(sl-Ask<minSL)
   {
      double toAdd= minSL;      
      sl= Ask + toAdd;
      Print("Below Min Broker SL");
      Print("SL Changed"); 
      if(Set_Order_Limit(Red,ticket, sl,tp)){return true;}
   }
   
   else
   {
      return false;
   }
   }
   return false;
}  
bool Place_Sell_Order3()
{
   double sl=0.0,tp=0.0;
   int ticket= OrderSend(_Symbol,OP_SELL,LotSize3,Bid,Slippage,0,0,Strat_Name3,Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*_Point;
   Print("Minimum Broker SL: ",minSL);
   Print("ATR Reading: ",atr);
   if(Ticket_Check(ticket)==true)
   {
      if(SL_Type3==0)
      {
        sl=SL_Fixed3*pip_Calculate();
        sl=Bid+sl;
      }
      if(SL_Type3==1)
      {
        sl=atr*SL_Volatility_Factor3;
        sl= Bid+sl;
      }
      if(TP_Type3==0)
      {
        tp=TP_Fixed3*pip_Calculate();
        tp= Bid-tp;
      }
      if(TP_Type3==1)
      {
        
        tp=atr* TP_Volatility_Factor3;
        tp=Bid-tp;
      }
      if(TP_Type3==2)
      {
         double price=0.0;
         if(OrderSelect(ticket, SELECT_BY_TICKET)){
         price=OrderOpenPrice();}
         double B_Mid_B,B_Low_B=0.00;
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
         Print("Price: ",price);
         if(Mid_Price >0.0)
         {
          tp=B_Mid_B; 
         }
         else
         {
            tp= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
            Print("TP Mid Band: Sell. Mid Band TP: ",tp);         
         }
      }      
      Print("Estm SL: ",sl);
   if(sl-Ask>=minSL)
   {
      
      if(Set_Order_Limit(Red,ticket, sl,tp)){return true;}
   
   }
    if(sl-Ask<minSL)
   {
      double toAdd= minSL;      
      sl= Ask + toAdd;
      Print("Below Min Broker SL");
      Print("SL Changed"); 
      if(Set_Order_Limit(Red,ticket, sl,tp)){return true;}
   }
   
   else
   {
      return false;
   }
   }
   return false;
}  
//---------------------------



bool Ticket_Check(int ticket)
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

//+------------------------------------------------------------------+
//|   Modify Order                                                   |
//+------------------------------------------------------------------+

bool Set_Order_Limit(color c,int ticket,double sl, double tp)
{
   bool res=OrderModify(ticket,OrderOpenPrice(),sl,tp,c);
   if(ModifyCheck(res)){return true;}   
   return false;
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


bool Check_Market(string strat)
{
   for(int i=0;i<4;++i)
   {
      if(OrderSelect(i, SELECT_BY_POS))
         {
            if(StringFind(OrderComment(), strat,0)!=-1)return true;
         }
   }
   return false;
}
void Check_Market()
{
   if(Check_Market(Strat_Name))order1Open=true;
   if(Check_Market(Strat_Name2))order2Open=true;
   if(Check_Market(Strat_Name3))order3Open=true;
   else if(!Check_Market(Strat_Name2))order2Open=false;
   if(!Check_Market(Strat_Name))order1Open=false;
   if(!Check_Market(Strat_Name3))order3Open=false;
}

//+------------------------------------------------------------------+
//|   Calculate Pips                                                 |
//+------------------------------------------------------------------+
double pip_Calculate()
{
  //double pip=(((MarketInfo(Symbol(),MODE_TICKVALUE)*_Point)/MarketInfo(Symbol(),MODE_TICKSIZE))*LotSize);
  double pip= _Point*10;
  Print("Pips Calculate: "+pip);
  double pPoint=pip/10;
  Print("Pips point calculate: "+pPoint);
  return pip; 
}
 
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
   Check_Market();
      
      if(IsNewBar())
      {
        if(useStrategy1)
        {
         if(Pattern1()==BUY){ Place_Buy_Order();}
         else if(Pattern1()==SELL){Place_Sell_Order();}
        } 
        if(useStrategy2)
        {
         if(Pattern2()==BUY){ Place_Buy_Order2();}
         else if(Pattern2()==SELL){Place_Sell_Order2();}
        }         
        if(useStrategy3 )
        {
         if(Pattern3()==BUY){ Place_Buy_Order3();}
         else if(Pattern3()==SELL){Place_Sell_Order3();}
        }      
      }

  }
//+------------------------------------------------------------------+
