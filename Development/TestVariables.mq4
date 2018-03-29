//+------------------------------------------------------------------+
//|                                                TestVariables.mq4 |
//|                                   Copyright 2017, QuantSoftware. |
//|                                    https://www.quantsoftware.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, QuantSoftware."
#property link      "https://www.quantsoftware.net"
#property version   "1.00"
#property strict


int i = 0;
int iRef =0;
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
   if(IsNewBar())
   {
   Increment();IncrementReference(iRef);
      //if(!i>10 && !iRef>10){Increment();IncrementReference(iRef);}
      //else{i =0; iRef=0;}
      
   }
   //if(i==10 || iRef ==10){i=0;iRef=0;}
   Clear(2);
   Comment("i[",i,"] iRef[",iRef,"]");
  }
//+------------------------------------------------------------------+
void Increment()
{
   i+=1;
}
void IncrementReference(int &count)
{
   count+=1;
}
int Clear(int c)
{
   if(i> c || iRef > c){i=0;iRef=0;}
   return 0;
}
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