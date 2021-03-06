//+------------------------------------------------------------------+
//|                                                Statistic Arb.mq4 |
//|                                                    Zobad Mahmood |
//|                                          zobad.mahmood@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "zobad.mahmood@gmail.com"
#property version   "1.00"
#property strict

//--- input parameters

enum Take_Profit_Type{
   
   FIXED=0,
   VOLATILITY=1,
   MID_BB=2
};
/*enum SL{
   Volatility=0,
   Fixed=1
};*/
input int              Magic_Number = 1;
input bool             Double_Order = true;
extern string          order1="-------Order_1--------";
input double           LotSize=1.0;
input Take_Profit_Type TP_Type= VOLATILITY;
input Take_Profit_Type SL_Type= VOLATILITY;
input double           TP_Volatility_Factor=2.0;
input double           SL_Volatility_Factor=1.0;
input double           TP_Fixed=25.0;
input double           SL_Fixed=12.0;

extern string          order2="-------Order_2--------";
input double           LotSize2=1.0;
input Take_Profit_Type TP_Type2= VOLATILITY;
input Take_Profit_Type SL_Type2= VOLATILITY;
input double           TP_Volatility_Factor2=3.0;
input double           SL_Volatility_Factor2=1.5;
input double           TP_Fixed2=25.0;
input double           SL_Fixed2=12.0;

input ENUM_TIMEFRAMES  BB_Chart_Timeframe= PERIOD_M15;
input int              BB_Period=14;
input int              ATR_Period=14;
input ENUM_TIMEFRAMES  ATR_Charts_Period = PERIOD_M30;
input int              Slippage=33; 
input double           Risk_Management; 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
double MyPoint;
double Mid_Price=0.0;

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

bool Sell_Alert()
{
   double bb_high=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,1);
   double bb_high2=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,2);
     
      //If bar touches or crosses the upper band
      if(Open[2]>bb_high2 && Close[2]<bb_high2 )
      { 
         if(Close[1]> Close[2] && Close[1]<bb_high)
         {
          Print("Sell Alert");    
                
         return true;                 
         }
      }          //If comming from top and touches MidBand Sell alert      
     
  
   return false;
}
bool Buy_Alert()
{
   double bb_low=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,1);
   double bb_low2=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,2);
      if(Open[2]<bb_low2 && Close[2]>bb_low2)
      {  
         if(Close[1]< Close[2])
         {
            Print("Buy Order Alert");      
            return true;
         }
      }           


   return false;
} 

bool Pattern_Brake()
{
   if(Close[1] < Open[1] && Close[2]>Open[2] && Close[3]> Open[3]){return true;}
   else if(Close[1]<Open[1]&&Close[2]>Open[2] && Close[3]< Open[3]){return true;}
   else if(Close[1] > Open[1] && Close[2] < Open[2] && Close[3] < Open[3]){return true;}
   else if(Close[1] > Open[1] && Close[2] < Open[2] && Close[3] > Open[3]){return true;}
   return false;
}

bool Place_Buy_Order()
{

   double sl=0.0,tp=0.0;
   int ticket= OrderSend(_Symbol,OP_BUY,LotSize,Ask,Slippage,0,0,"Buy",Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);   Print("ATR Reading: ",atr);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*_Point;
   Print("Minimum Broker SL: ",minSL);
   
   if(Ticket_Check(ticket)==true)
   {
      if(SL_Type==0)
      {
         sl=SL_Fixed*_Point*10;
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
         tp=TP_Fixed*_Point*10;
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
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0);
         Print("Mid Band: ",B_Mid_B);
         Print("Mid Band Pip: ",B_Mid_B*_Point*10);         
         tp= Ask + B_Mid_B*_Point*10;
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
      
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
   
   }
     if(Bid-sl<minSL)
   {  
      double toAdd= minSL;      
      sl= Ask- toAdd;      
      Print("SL below Minimum Broker SL. Aplying minimum SL!");
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
   }
   return false;
}
bool Place_Buy_Order2()
{

   double sl=0.0,tp=0.0;
   int ticket= OrderSend(_Symbol,OP_BUY,LotSize2,Ask,Slippage,0,0,"Buy",Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);   Print("ATR Reading: ",atr);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*_Point;
   Print("Minimum Broker SL: ",minSL);
   
   if(Ticket_Check(ticket)==true)
   {
      if(SL_Type2==0)
      {
         sl=SL_Fixed2*_Point*10;
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
         tp=TP_Fixed2*_Point*10;
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
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0);
         Print("Mid Band: ",B_Mid_B);
         Print("Mid Band Pip: ",B_Mid_B*_Point*10);         
         tp= Ask + B_Mid_B*_Point*10;
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
      
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
   
   }
     if(Bid-sl<minSL)
   {  
      double toAdd= minSL;      
      sl= Ask- toAdd;      
      Print("SL below Minimum Broker SL. Aplying minimum SL!");
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
   }
   return false;
}

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

bool Set_Order_Limit(int ticket,double sl, double tp)
{
   bool res=OrderModify(ticket,OrderOpenPrice(),sl,tp,0);
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
bool Place_Sell_Order()
{
   double sl=0.0,tp=0.0;
   int ticket= OrderSend(_Symbol,OP_SELL,LotSize,Bid,Slippage,0,0,"Sell",Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*_Point;
   Print("Minimum Broker SL: ",minSL);
   Print("ATR Reading: ",atr);
   if(Ticket_Check(ticket)==true)
   {
      if(SL_Type==0)
      {
        sl=SL_Fixed*_Point*10;
        sl=Bid+sl;
      }
      if(SL_Type==1)
      {
        sl=atr*SL_Volatility_Factor;
        sl= Bid+sl;
      }
      if(TP_Type==0)
      {
        tp=TP_Fixed*_Point*10;
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
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0);
         B_Up_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,0);
         B_Low_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,0);
         Print("Price: ",price);
         //Print("Mid Band Pip: ",B_Mid_B*MyPoint);
         
         
         
         if(Mid_Price >0.0){tp= B_Low_B;
         sl= B_Mid_B + 5*MyPoint;
         Print("Price: ",B_Mid_B + 5*_Point);
         Print("MidPrice: ",Mid_Price); Mid_Price=0.0;
         
          }
         else{
            tp= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0);
         Print("TP Mid Band: Sell. Mid Band TP: ",tp);
         
         }
      }      
      Print("Estm SL: ",sl);
   if(sl-Ask>=minSL)
   {
      
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
   
   }
    if(sl-Ask<minSL)
   {
      double toAdd= minSL;      
      sl= Ask + toAdd;
      Print("Below Min Broker SL");
      Print("SL Changed"); 
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
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
   int ticket= OrderSend(_Symbol,OP_SELL,LotSize2,Bid,Slippage,0,0,"Sell",Magic_Number);
   double atr=iATR(Symbol(),0,ATR_Period,0);
   double minSL= MarketInfo(Symbol(),MODE_STOPLEVEL);
   minSL= minSL*_Point;
   Print("Minimum Broker SL: ",minSL);
   Print("ATR Reading: ",atr);
   if(Ticket_Check(ticket)==true)
   {
      if(SL_Type2==0)
      {
        sl=SL_Fixed2*_Point*10;
        sl=Bid+sl;
      }
      if(SL_Type2==1)
      {
        sl=atr*SL_Volatility_Factor2;
        sl= Bid+sl;
      }
      if(TP_Type2==0)
      {
        tp=TP_Fixed2*_Point*10;
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
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0);
         B_Up_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,0);
         B_Low_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,0);
         Print("Price: ",price);
         //Print("Mid Band Pip: ",B_Mid_B*MyPoint);
         
         
         
         if(Mid_Price >0.0){tp= B_Low_B;
         sl= B_Mid_B + 5*MyPoint;
         Print("Price: ",B_Mid_B + 5*_Point);
         Print("MidPrice: ",Mid_Price); Mid_Price=0.0;
         
          }
         else{
            tp= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0);
         Print("TP Mid Band: Sell. Mid Band TP: ",tp);
         
         }
      }      
      Print("Estm SL: ",sl);
   if(sl-Ask>=minSL)
   {
      
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
   
   }
    if(sl-Ask<minSL)
   {
      double toAdd= minSL;      
      sl= Ask + toAdd;
      Print("Below Min Broker SL");
      Print("SL Changed"); 
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
   }
   
   else
   {
      return false;
   }
   }
   return false;
}  
 
/*void Second_Order_Alert()
{ 
   if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES)==true)
   {  
      datetime dat= OrderOpenTime();
     
     
      if((TimeCurrent()- OrderOpenTime()) <= (Period()+Period()))
      {
        Print("Time Current: "+TimeCurrent());
      Print("Period(): "+Period());
      
       dat= TimeCurrent()- OrderOpenTime();
      Print("Dat value: "+TimeToStr(dat,TIME_SECONDS));
      Print("Order Type: "+OrderType());
         if(OrderType()== OP_BUY)
         {
            if(Second_Buy_Alert())
               {
                 Place_Buy_Order2();                    
               }
         }
         else
         {
            if(Second_Sell_Alert())
            {
               Place_Sell_Order2();
            }
         }
      }
   }
   else{Print("Failed: OrderSelct()");}
}*/
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //Print("total orders: "+TotalOpenOrder());
   if(TotalOpenOrder()==0)
   {
      
      if(IsNewBar())
      {
             
        if((Buy_Alert())&& (Double_Order==true))
        {
          Place_Buy_Order();
          Place_Buy_Order2();                  
        }
        else if((Buy_Alert())&& (Double_Order==false))
        {
          Place_Buy_Order();
        } 
        
        
        else if((Sell_Alert())&& (Double_Order==true) )
         {               
           Place_Sell_Order();
           Place_Sell_Order2();           
         }
        else if((Sell_Alert())&& (Double_Order==false))
         {
            Place_Sell_Order();
         }              
      }
   
  }
 /* else if(TotalOpenOrder()==1)
  {
  // Print("Open Orders: "+TotalOpenOrder());
   Second_Order_Alert();
  }*/
  }
//+------------------------------------------------------------------+
