//+------------------------------------------------------------------+
//|                                                  TOMAS_RD_v1.mq4 |
//|                        |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Tomas RD"
#property link      "https://www.mql5.com"
#property version   "1.01"
#property strict
int MagicNumber=1;
extern int magic=3059823;
extern double lotes=0.01;
extern bool UseRisk = FALSE;
extern double Risk = 0.1; 
extern double stop_loss=30;
extern double take_profit =30;
extern double multiply=2.5;
extern string INDICATOR_PARAMETER1 ="=========Candle==========";
extern int SHIFT_CANDLE=1;
 double lots=0.01;
 int TP=20;
 int SL=20;


extern string INDICATOR_PARAMETER2 ="=========Volumes==========";
extern int SHIFT_VOLUME=1;
double Scale,stop_loss_v,take_profit_v;
int LOTS,x,f,g,h,k,y,z,jumlahbuy,jumlahbuylimit,jumlahselllimit,jumlahsell,jumlahbuystop,jumlahsellstop;
double BUY[99], SELL[99], BUYLIMIT[99], SELLLIMIT[99], BUYSTOP[99], SELLSTOP[99],BATAS;
int prec=0;
int a=0;
double pt,i,minlot,stoplevel;
color  FontColorUp1 = Red;  
color  FontColorDn1 = White; 
color  FontColor = Blue;
color  FontColorUp2 = Yellow;  
color  FontColorDn2 = Lime; 
color  FontUP = Lime;  
color  Font = White; 
color  FontDOWN = Red; 

int lastTicket=0;
input double SL_total=300;
bool MM_closed = false;
datetime  closeTime =0;
input int StopPeriod = 6;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
  switch(Digits)
  {
    case 1:
       Scale = 0.1;
       break;
    case 2:
       Scale = 0.01;
       break;
    case 3:
       Scale = 0.01;
       break;
    case 4:
       Scale = 0.0001;
       break;
    case 5:
       Scale = 0.0001;
       break;
  }
  
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
    ObjectDelete("Market_Price_Label1"); 
    ObjectDelete("Market_Price_Label2"); 
    ObjectDelete("Market_Price_Label3"); 
    ObjectDelete("Market_Price_Label4"); 
    ObjectDelete("Market_Price_Label5"); 
    ObjectDelete("Market_Price_Label6"); 
    ObjectDelete("Market_Price_Label7"); 
    ObjectDelete("Market_Price_Label8"); 
    ObjectDelete("Market_Price_Label9"); 
    ObjectDelete("Market_Price_Label10"); 
    ObjectDelete("Market_Price_Label11"); 
    ObjectDelete("Market_Price_Label12"); 
    ObjectDelete("Market_Price_Label13"); 
    ObjectDelete("Market_Price_Label14"); 
    ObjectDelete("Market_Price_Label15"); 
    ObjectDelete("Market_Price_Label16"); 
    ObjectDelete("Market_Price_Label17"); 
    ObjectDelete("Market_Price_Label18"); 
    ObjectDelete("Market_Price_Label19"); 
    ObjectDelete("Market_Price_Label20"); 
    ObjectDelete("Market_Price_Label21"); 
    ObjectDelete("Market_Price_Label22"); 
    ObjectDelete("Market_Price_Label23"); 
    ObjectDelete("Market_Price_Label24"); 
    ObjectDelete("Market_Price_Label25"); 
    ObjectDelete("Market_Price_Label26"); 
    ObjectDelete("Market_Price_Label27"); 
    ObjectDelete("Market_Price_Label28"); 
    ObjectDelete("Market_Price_Label29"); 
    ObjectDelete("Market_Price_Label30"); 
    ObjectDelete("Market_Price_Label31"); 
    ObjectDelete("Market_Price_Label32"); 
    ObjectDelete("Market_Price_Label33"); 
    ObjectDelete("Market_Price_Label34"); 
    ObjectDelete("Market_Price_Label35"); 
    ObjectDelete("Market_Price_Label36"); 
    ObjectDelete("Market_Price_Label37"); 
    ObjectDelete("Market_Price_Label38"); 
    ObjectDelete("Market_Price_Label39"); 
    ObjectDelete("Market_Price_Label40"); 
    ObjectDelete("Market_Price_Label41"); 
    ObjectDelete("Market_Price_Label42"); 
    ObjectDelete("Market_Price_Label43"); 
    ObjectDelete("Market_Price_Label44"); 
    ObjectDelete("Market_Price_Label45"); 
    ObjectDelete("Market_Price_Label46"); 
    ObjectDelete("Market_Price_Label47"); 
    ObjectDelete("Market_Price_Label48"); 
    ObjectDelete("Market_Price_Label49"); 
    ObjectDelete("Market_Price_Label50");
//----
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  if( TimeCurrent()-closeTime<StopPeriod*3600)
  {
      return;
  }
  
  double localDD = CountDD();
//---
      if(localDD <-SL_total )
      {
        CloseAllOrders();
         MM_closed = true;
        closeTime= TimeCurrent();
        
      /*    while(    localDD<-SL_total)
         {
             Print("Local DD", localDD);
         }   */
    
        
      }
      
   
   
   if(lotesMarginFree()>=MarketInfo(NULL,MODE_MINLOT)){ 
   if (UseRisk == TRUE) lotes = (AccountFreeMargin()/10000) * Risk;  
      if(vol_ea()== 1)OpenMartingale();
   }
   
   modifyOrders();  
}

void CloseAllOrders()
{  
   int total = OrdersTotal();
   for(int j = total-1; j >=0; j--)
   {
      if(! OrderSelect(j,SELECT_BY_POS,MODE_TRADES)) continue;
      
      if(OrderMagicNumber()==magic && OrderSymbol()==Symbol() /*&&  OrderCloseTime() == 0 */)
      {
         if( OrderType()==OP_BUY)
         {
            if(OrderClose(OrderTicket(),OrderLots(),Bid,1000,clrBlue))
            {
                
            }
         }
         if( OrderType()==OP_SELL)
         {
            if(OrderClose(OrderTicket(),OrderLots(),Ask,1000,clrRed))
            {
                
            }
         }

      }
  }     
}

  
  
double  CountDD()
{

 double localDD = 0;
  
   for(int ii = OrdersTotal() - 1; ii >= 0; ii --)
     {
        if(OrderSelect(ii,SELECT_BY_POS,MODE_TRADES))
        {
            if(OrderSymbol()==Symbol() && OrderType()==OP_SELL && OrderMagicNumber()==magic)
            {
              localDD=OrderProfit()+localDD;
            }
            if(OrderSymbol()==Symbol() && OrderType()==OP_BUY && OrderMagicNumber()==magic)
            {
              localDD=OrderProfit()+localDD;
            }
        }
      } 
  
 return localDD;
}
//+------------------------------------------------------------------+


void SendOrder(string symbol,int type,double lot,double price_s,int slippage_v,double stop_loss_v,double take_profit_v,string comment,int magic_v,color color_v){
  int countTentative=3;
  int tentative=0;
  int ticket=0;             
  while(IsConnected() && ticket < 1 && tentative <= countTentative){
    RefreshRates();
    ticket = OrderSend(symbol,type,lot,price_s,slippage_v,stop_loss_v,take_profit_v,comment,magic_v,0,color_v);
    Sleep(1000);            
    tentative++;
                  
  }
  lastTicket = ticket;

}

void modifyOrders(){
   double tp,sl;
      for(int ii=OrdersTotal()-1; ii>=0; ii--)       //Cycle for all orders..
      {                                        //displayed in the terminal
         if(OrderSelect(ii,SELECT_BY_POS,MODE_OPEN))//If there is the next one
           { 
            if(OrderMagicNumber() == magic)
            {   
               if(OrderType()==OP_BUY){
                  sl=OrderOpenPrice()-stop_loss*Scale;
                  tp=OrderOpenPrice()+take_profit*Scale;
               }
               if(OrderType()==OP_SELL){
                  sl=OrderOpenPrice()+stop_loss*Scale;
                  tp=OrderOpenPrice()-take_profit*Scale;
               }
               if(OrderTakeProfit()==0 && OrderStopLoss()==0){
                  int p=OrderModify(OrderTicket(),OrderOpenPrice(),sl,tp,0);
               }
               
            }
          }
      }        
}

void OpenMartingale(){
      int value=0;
      for(int ii=OrdersTotal()-1; ii>=0; ii--)       //Cycle for all orders..
      {                                        //displayed in the terminal
         if(OrderSelect(ii,SELECT_BY_POS,MODE_OPEN))//If there is the next one
           { 
            if(OrderMagicNumber() == magic && OrderSymbol()==Symbol())
            {   
               value++;
            }
          }
      }

      if(value==0){//no open orders
         for(int ii=OrdersHistoryTotal()-1; ii>=0; ii--)       //Cycle for all orders..
         {                                        //displayed in the terminal
            if(OrderSelect(ii,SELECT_BY_POS,MODE_HISTORY))//If there is the next one
              { 
               if(OrderMagicNumber() == magic && OrderSymbol()==Symbol())
               {   
                  value++;
                  if(OrderType()==OP_BUY){
                     if(OrderOpenPrice()>OrderClosePrice())
                     {
                        if(OrderProfit()<-SL_total || MM_closed == true)
                        {
                           MM_closed = false;
                           closeTime= TimeCurrent();
                           SendOrder(Symbol(),OP_SELL,lotes,Bid,3,0,0," martingale sell ",magic,Red);}
                           else
                           {
                               SendOrder(Symbol(),OP_SELL,OrderLots()*multiply,Bid,3,0,0," martingale sell ",magic,Red);
                           }                        
                     }
                     else
                     {
                        SendOrder(Symbol(),OP_BUY,lotes,Ask,3,0,0," martingale buy ",magic,Blue);
                     }
                  }
                  if(OrderType()==OP_SELL){
                     if(OrderOpenPrice()<OrderClosePrice())
                     {
                        if(OrderProfit()<-SL_total || MM_closed == true )
                        {
                            MM_closed = false;
                            closeTime= TimeCurrent();                        
                            SendOrder(Symbol(),OP_BUY,lotes,Ask,3,0,0," martingale buy ",magic,Blue);
                        }
                        else
                        {
                              SendOrder(Symbol(),OP_BUY,OrderLots()*multiply,Ask,3,0,0," martingale buy ",magic,Blue);
                        }
                    }
                     else
                     {
                        SendOrder(Symbol(),OP_SELL,lotes,Bid,3,0,0," martingale sell ",magic,Red);
                     }
                  }
                  break;                  
               }
             }
         }
       }
       
       if(value==0){
          if(Open[1]<Close[1])
          {
            SendOrder(Symbol(),OP_BUY,lotes,Ask,3,0,0," martingale buy ",magic,Blue);//1st order
          }  
          else
          {
            SendOrder(Symbol(),OP_SELL,lotes,Bid,3,0,0," martingale sell ",magic,Red);//1st order
          }
       }          
}



void OnChartEvent(const int id,         // Event identifier  
                  const long& lparam,   // Event parameter of long type
                  const double& dparam, // Event parameter of double type
                  const string& sparam) // Event parameter of string type
  {
  

   if(id==CHARTEVENT_OBJECT_CLICK){ 
        //printf("int(lparam) "+sparam);

        if(sparam=="sell_option"){
            stop_loss_v=Bid+stop_loss*Scale;
            take_profit_v=Bid-take_profit*Scale;         
         SendOrder(Symbol(),OP_SELL,lotes,Bid,3,stop_loss_v,take_profit_v," sell ",magic+1,Red);
        }

        if(sparam=="buy_option"){
            stop_loss_v=Ask-stop_loss*Scale;
            take_profit_v=Ask+take_profit*Scale;         
         SendOrder(Symbol(),OP_BUY,lotes,Ask,3,stop_loss_v,take_profit_v," buy ",magic+1,Blue);
        }
        if(sparam=="close_this_option"){
         closeOrdersSymbol();
        }
        if(sparam=="close_all_option"){
         closeOrdersAll();
        }                 
   }     
}     



void closeOrdersSymbol(){
int p;
   for(int ii=OrdersTotal()-1; ii>=0; ii--)       //Cycle for all orders..
   {                                        //displayed in the terminal
      if(OrderSelect(ii,SELECT_BY_POS,MODE_OPEN))//If there is the next one
        { 
         if(OrderMagicNumber() == magic+1 && OrderSymbol()==Symbol())
         {   
            if(OrderType()==OP_BUY){
               p=OrderClose(OrderTicket(),OrderLots(),Bid,3,clrSkyBlue);
            }else{
               p=OrderClose(OrderTicket(),OrderLots(),Ask,3,clrPink);
            }                                
            
         }
       }
   }
}

void closeOrdersAll(){
int p;
   for(int ii=OrdersTotal()-1; ii>=0; ii--)       //Cycle for all orders..
   {                                        //displayed in the terminal
      if(OrderSelect(ii,SELECT_BY_POS,MODE_OPEN))//If there is the next one
        { 
         if(OrderMagicNumber() == magic+1)
         {   
            if(OrderType()==OP_BUY){
               p=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),3,clrSkyBlue);
            }else{
               p=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),3,clrPink);
            }                                
            
         }
       }
   }
}




double lotesMarginFree(){

   double MargRequired = MarketInfo ( Symbol ( ), MODE_MARGINREQUIRED ) ; // current price * 1000

   double Equity = AccountEquity ( ) ;
      
   return NormalizeDouble ( Equity / MargRequired, 1 ) ;  
   
}



int vol_ea()
  {

 
y=0; f=0; g=0; h=0; k=0; z=0; jumlahbuy=0; jumlahsell=0; jumlahbuylimit=0; jumlahselllimit=0; jumlahsellstop=0; jumlahbuystop=0;
   

 
 
   

 
  
//////////CANDLE///////
double OPEN_3  =iOpen(Symbol(),0,SHIFT_CANDLE);
double OPEN_2  =iOpen(Symbol(),0,SHIFT_CANDLE+2);
double OPEN_1  =iOpen(Symbol(),0,SHIFT_CANDLE+3);

double CLOSE_3  =iClose(Symbol(),0,SHIFT_CANDLE);
double CLOSE_2  =iClose(Symbol(),0,SHIFT_CANDLE+2);
double CLOSE_1  =iClose(Symbol(),0,SHIFT_CANDLE+3);

////CANDLE 1////
double BULLISH = CLOSE_3 > OPEN_3 ;
double BEARISH = CLOSE_3 < OPEN_3 ;                      

 /////////////VOLUME//////////
 
 double VOLUME_3 =  (double)iVolume(Symbol(),0,SHIFT_VOLUME);
 double VOLUME_2 =  (double)iVolume(Symbol(),0,SHIFT_VOLUME+1);
 double VOLUME_1 =  (double)iVolume(Symbol(),0,SHIFT_VOLUME+2);
 double VOLUME_0 =  (double)iVolume(Symbol(),0,SHIFT_VOLUME+3);
 double VOLUME_LALU = (double) iVolume(Symbol(),0,SHIFT_VOLUME+4);
 
 
double VOLUME_OP = ( (VOLUME_0 < VOLUME_1) && (VOLUME_1 < VOLUME_2) && (VOLUME_2 < VOLUME_3) ) ;                    
                     


   {
    
    if (iOpen(Symbol(),0,0) > iOpen(Symbol(),0,1)) FontColor = FontColorUp1;
    if (iOpen(Symbol(),0,0)<  iOpen(Symbol(),0,1)) FontColor = FontColorDn1;
    if (iClose(Symbol(),0,0) > iClose(Symbol(),0,1) ) FontColor = FontColorUp2;
    if (iClose(Symbol(),0,0) < iClose(Symbol(),0,1) ) FontColor = FontColorDn2;
    if (Ask>iOpen(Symbol(),0,0)) Font=FontUP;
    if (Bid>iOpen(Symbol(),0,0)) Font=FontUP;
    if (Ask<iOpen(Symbol(),0,0)) Font=FontDOWN;
    if (Bid<iOpen(Symbol(),0,0)) Font=FontDOWN;
   
   }

 
 

    
 //INSTANT//




if(jumlahbuy+jumlahsell==0)
{

    if (BEARISH==true && VOLUME_OP==true)
        {
            return(1);
         }                 
    if (BULLISH==true && VOLUME_OP==true)
        {
            return(1);
         } 
 
 }



   return(0);
  }


