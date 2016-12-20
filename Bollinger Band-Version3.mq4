//+------------------------------------------------------------------+
//|                                      Bollinger Band-Version1.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "https://www.mql5.com"
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
input int              Magic_Number=1;
input double           LotSize=1.0;
input Take_Profit_Type TP_Type= VOLATILITY;
input Take_Profit_Type SL_Type= VOLATILITY;
input double           TP_Volatility_Factor=1.5;
input double           SL_Volatility_Factor=0.75;
input double           TP_Fixed=25.0;
input double           SL_Fixed=12.0;
input ENUM_TIMEFRAMES  BB_Chart_Timeframe= PERIOD_M30;
input int              BB_Period=20;
input int              ATR_Period=14;
input ENUM_TIMEFRAMES  ATR_Charts_Period = PERIOD_M30;
input int              Slippage=33; 
input double           Risk_Management; 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
double MyPoint;
bool UBandTouch=false;
bool LBandTouch=false;
bool MidBandTouch=false;
double Mid_Price=0.0;
int loss=0, consecutive_loss=0, ignore=0,ignoreLong=0, C_loss=0, s_loss=0, l_loss=0,Cs_loss=0,Cl_loss=0;
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
   if(!UBandTouch)
   {
      //If bar touches or crosses the upper band
      if(High[0]>=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,0))
      {
         UBandTouch=true;
         Print("Up Band Signal Activated");
         //If the previous candles pattern breaks and the closing is bellow the upperband
         if(Pattern_Brake() && Close[0]< iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,0)&& Close[0]> iBands(NULL,BB_Chart_Timeframe,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0))
         {
            Print("Up band Sell");
            UBandTouch=false;
            return true;
         }            
         return false;
      }
      //If comming from top and touches MidBand Sell alert
      
   }
   else if(UBandTouch==true)
   {
      //If the previous candles pattern breaks and the closing is bellow the upperband
         if(Pattern_Brake() && Close[0]< iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,0)&& Close[0]> iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0))
         {
            Print("Up band Sell");
            UBandTouch=false;
            return true;
         }
         return false;
      //   UBandTouch =false;
         //If comming from top and touches MidBand Sell alert
   }
   else if(Low[0]<=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0))
      {
         double BB_Up=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,0);
         double BB_Mid=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0);
         if(Close[1]<BB_Up && Close[1]>BB_Mid && Close[2]<BB_Up && Close[2]>BB_Mid && Open[1]<BB_Up && Open[1]>BB_Mid && Open[2]<BB_Up&& Open[2]>BB_Mid
         &&Open[3]<BB_Up&& Open[3]>BB_Mid)
         {Mid_Price=BB_Mid;
          Print("Mid Band Price: ",BB_Mid);return true;}
          
      }
  
   return false;
}  
 
bool Buy_Alert()
{
   if(!LBandTouch)
   {
      //If bar touches or crosses the upper band
      if(Low[0]<=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,0))
      {
         LBandTouch=true;
         Print("Low Band Signal Activated");
         //If the previous candles pattern breaks and the closing is bellow the upperband
         if(Pattern_Brake() && Close[0]> iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,0)&& Close[0]< iBands(NULL,BB_Chart_Timeframe,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0))
         {
            Print("Low band Buy");
            LBandTouch=false;
            return true;
         }            
         return false;
      }
    
   }
   else if(LBandTouch==true)
   {
      //If the previous candles pattern breaks and the closing is bellow the upperband
         if(Pattern_Brake() && Close[0]> iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,0)&& Close[0]< iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0))
         {
            Print("Buy Alert. Broken Pattern");
            Print("Low band Buy");
            LBandTouch=false;
            return true;
         }
        return false;
   }
     //If comming from top and touches MidBand Sell alert
      else if(Low[0]<=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0))
      {
         Print("Mid Band Signal Activated");
         double BB_Down=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,0);
         double BB_Mid=iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0);
         if(Close[1]>BB_Down && Close[1]<BB_Mid && Close[2]<BB_Down && Close[2]<BB_Mid && Open[1]>BB_Down && Open[1]<BB_Mid && Open[2]>BB_Down&& Open[2]<BB_Mid
         &&Open[3]>BB_Down&& Open[3]<BB_Mid)
         {
          
          Mid_Price=BB_Mid;
          Print("Mid band Buy");
          Print("Mid Band Price: ",BB_Mid);return true;}
          
      }
   return false;
}   

//Check if the bullish or bearish pattern has been broken
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
   minSL= minSL*MyPoint;
   minSL=Ask-minSL;
   Print("Minimum SL: ",minSL);
   if(Ticket_Check(ticket)==true)
   {
      if(SL_Type==1)
      {
         sl=SL_Fixed*MyPoint;
         sl=Ask-sl;
      }
      if(SL_Type==0)
      {
        // sl=NormalizeDouble(ATR_TP_Factor,Digits);
        sl=atr*SL_Volatility_Factor;
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
        tp=atr* TP_Volatility_Factor;
        tp=Ask+tp;
      }  
      if(TP_Type==2)
      {
         double B_Mid_B;
         B_Mid_B= iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,0);
         Print("Mid Band: ",B_Mid_B);
         Print("Mid Band Pip: ",B_Mid_B*MyPoint);         
         tp= Ask + B_Mid_B*MyPoint;
         Print("Mid Band TP: ",tp);
      }      
   }
   Print("SL: ",sl);
   Print("TP:",tp);
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
   minSL= minSL*MyPoint;
   minSL=Bid+minSL;
   Print("ATR Reading: ",atr);
   Print("Bid Reading: ",Bid);
   Print("Minimum SL: ",minSL);
   if(Ticket_Check(ticket)==true)
   {
      if(SL_Type==1)
      {
         sl=SL_Fixed*MyPoint;
         sl=Bid+sl;
      }
      if(SL_Type==0)
      {
        // sl=NormalizeDouble(ATR_TP_Factor,Digits);
        sl=atr*SL_Volatility_Factor;
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
      
      
   if(sl<=minSL)
   {
      double toAdd= minSL-sl;      
      sl= sl + toAdd;
      //sl=+ 1*MyPoint;
      Print("Added to SL: ",toAdd); 
      if(Set_Order_Limit(ticket, sl,tp)){return true;}
   
   }
    if(sl>minSL)
   {
     Print("Actual SL: ",sl); 
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
bool Set_Order_Limit()
{
   
   return false;
}  
void Loss_Count()
{
   int order= OrderSelect(0,SELECT_BY_POS,MODE_HISTORY);
   if(OrderType()==OP_BUY && OrderProfit()<0)loss++;C_loss++;
}
bool Previous_Order()
{
   bool order= OrderSelect(0,SELECT_BY_POS,MODE_HISTORY);
   if(order)
   {if(OrderType()==OP_BUY && OrderProfit()<0){s_loss++;}
   //if(OrderType()==OP_BUY && OrderProfit()>=0){s_loss=0;}
  // if(OrderType()==OP_SELL && OrderProfit()>=0){l_loss=0;}
   else if(OrderType()==OP_SELL && OrderProfit()<0){l_loss++;Print("Sell Skip Candle: ", l_loss);}
   }
   if(!order){Print("Order Select Error");}
   if(Cs_loss==1){ignore=5;}
   if(l_loss==1){ignoreLong=5;}
   if(l_loss==1){Cl_loss++;}
   if(s_loss==1){Cs_loss++;}
   if(Cs_loss>2&& Cs_loss<4){ignore=20;}
   if(Cl_loss>2&&Cl_loss<4){ignoreLong=20;}
   if(Cl_loss>4){ignoreLong*=5;}
   if(Cs_loss>4){ignore*=5;}
   
   return true;
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(TotalOpenOrder()==0)
   {
      
      if(IsNewBar())
      {
             
         if(Buy_Alert())
        {
          Print("Next ",ignore," short Candles will be  ignored");  
          if(ignore<1)
          
           {Place_Buy_Order();Previous_Order();}
           
           
           else if(ignore>=1){s_loss--;Cs_loss--;ignore--; Print("Short Candle Ignored");
          Print("Next ",ignore," short Candles will be  ignored");}
        }
        else if(Sell_Alert() )
         {   
            Print("Next ",ignoreLong," Long Candles will be  ignored");     
            if(ignoreLong<1)
            {
            Place_Sell_Order();
            Previous_Order();
            }
            else if(ignoreLong>=1)
            {
               ignoreLong--;Print("Long Candle Ignored");
         Print("Next ",ignoreLong," Long Candles will be  ignored");
            }
            
         }
         
         /* if(ignore>1&&Short==1){ignore--; Print("Short Candle Ignored");
          Print("Next ",ignore," short Candles will be  ignored");}
         else if(ignoreLong>1&&Long==1){ignoreLong--;Print("Long Candle Ignored");
         Print("Next ",ignoreLong," Long Candles will be  ignored");}
      }*/
      
      
   }
   
  }
  }
//+------------------------------------------------------------------+
