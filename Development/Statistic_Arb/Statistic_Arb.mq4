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

input int              Magic_Number = 1;                 //Magic Number
input bool             Double_Order = true;              //Place Double Orders
extern string          order1="-------Order_1--------";  //Order 1
input double           LotSize=1.0;                      //Lot Size
input Take_Profit_Type TP_Type= VOLATILITY;              //Type of Take-Profit
input Take_Profit_Type SL_Type= VOLATILITY;              //Type of Stop-Loss
input double           TP_Volatility_Factor=2.0;         //Take Profit Volatility Factor
input double           SL_Volatility_Factor=1.0;         //Stop-Loss Volatility Factor
input double           TP_Fixed=25.0;                    //Take-Profit Fixed Pips
input double           SL_Fixed=12.0;                    //Stop-Loss Fixed Pips

extern string          order2="-------Order_2--------";  //Order 2
input double           LotSize2=1.0;                     //Lot Size
input Take_Profit_Type TP_Type2= VOLATILITY;             //Type of Take-Profit
input Take_Profit_Type SL_Type2= VOLATILITY;             //Type of Stop-Loss
input double           TP_Volatility_Factor2=3.0;        //Take Profit Volatility Factor
input double           SL_Volatility_Factor2=1.5;        //Stop-Loss Volatility Factor
input double           TP_Fixed2=25.0;                   //Take-Profit Fixed Pips
input double           SL_Fixed2=12.0;                   //Stop-Loss Fixed Pips

input ENUM_TIMEFRAMES  BB_Chart_Timeframe= PERIOD_M15;   //Bollinger Band Chart Timeframe
input int              BB_Period=14;                     //Bollinger Band Period
input int              ATR_Period=14;                    //Atr Period
input ENUM_TIMEFRAMES  ATR_Charts_Period = PERIOD_M30;   //Atr Chart Period
input int              Slippage=33;                      //Slippage
input string           Rsk_Mng="------Risk Management-----------";//Risk Management
input bool             Risk_Management_Flag=false;       //Risk Management
input double           Percentage_Balance;               //Percentage Balance
input string           Correlation_Menu="------Correlation------";
input string           Main_Symbol="XAUUSD";             //Main Currency Pair
input string           Symbol1="GBPUSD";                 //Symbol Pair 1
input string           Symbol2;                          //Symbol Pair 2
input string           Symbol3;                          //Symbol Pair 3
input string           Symbol4;                          //Symbol Pair 4
input ENUM_TIMEFRAMES  timeframe=PERIOD_M30;             //Time Frame
input int              period=10;                       //Period
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
      }         
  
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

   Print("Pip: ",_Point*10);
   Print("SL: ",sl);
   Print("TP:",tp);
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
   Print("Point: ",_Point);
   Print("Pip: ",_Point*10);
   Print("SL: ",sl);
   Print("TP:",tp);
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
double Correlation_Calculation(string symbol1)
{
  int bars= 500;
  if(bars>=period) bars= period -1;
  double X[], Y[];
  double totalX=0.00,totalY=0.00,xsqr=0.00,ysqr=0.00, sigmaXY=0.00,answer=0.00,answer2=0.00,answer3=0.00;
  double x,y;
  
  for(int i=0; i<= period;i++)
  {
   X[i]= iClose(Main_Symbol, timeframe,i);
   Y[i]=iClose(Main_Symbol, timeframe,i);
   y=iClose(symbol1,timeframe,i);
   x=iClose(Main_Symbol, timeframe,i);
   totalY=+y;   
   ysqr+=MathPow(y,2);   
   totalX+=x;
   xsqr+=MathPow(x,2);
   sigmaXY= x*y;
   /*int sizeX=ArraySize(x);
   int sizeY=ArraySize(y);
   ArrayResize(x,sizeX);
   ArrayResize(y,sizeY);*/
  }
  
  //sigmaXY= totalX*totalY;
  /*answer=period*xsqr-MathPow(totalX,2);
  answer2= period* ysqr - MathPow(totalY,2);
  double answer4= answer*answer2;
  Print("SigmaXY"+sigmaXY+"-totalX"+totalX+"*totalY:"+totalY);
  answer3= (period * sigmaXY- totalX*totalY)/MathSqrt(answer4);
  */
  
  return answer3;
  
}
double Pearson_Correlation()
{
   
   return 0;
}
bool isSymbol(string symbol)
{

   return false;
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
      Print("First Symbol Correlation"+Correlation_Calculation(Symbol1));
//---
  /*if(TotalOpenOrder()==0)
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
   
  }*/
  }
//+------------------------------------------------------------------+
