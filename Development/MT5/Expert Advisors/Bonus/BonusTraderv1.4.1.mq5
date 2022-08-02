//+------------------------------------------------------------------+
//|                                                        Bonus.mq5 |
//|                                     Copyright 2022, Quantech Sol.|
//|                                          https://quantechsol.com |
//|                                     MA-Crossover
//+------------------------------------------------------------------+
#property copyright "Contact us : Whatsapp: +905469442173"
#property link      "https://quantechsol.com"
#property version   "1.00"
#property strict
#include <Trade\Trade.mqh>
#include <Trade\TerminalInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
CEdit   InputParams[3];
CDialog Dialog;
CButton MannualEntryBtn [5];
CButton CloseAllBtn;
CButton CloseBuysBtn;
CButton CloseSellsBtn;
CButton TitleBtn;
CButton SaveBtn;
CLabel  Labels[8];
CLabel  LabelsInputs[8];
CLabel  LabelsValues[8];
color DialogColor= C'16,21,43';
string FontName = "Segoe UI";
color FirstComboBoxColor= C'27,33,59';
color FirstComboBoxBorderColor= C'18,69,99';
color HedgeBtnColor= C'255,136,0';
color HedgeBtnTextColor=clrBlack;
CSymbolInfo    m_symbol;
CPositionInfo  m_position;
CTrade trade;
CTerminalInfo  TerminalInfo;
enum BBM
{
   DIRECTIONAL=0,
   REVERSAL=1




};
enum E_SST
{
   Directional=0,
   Reversal=1,
   Open_Now=2,
   MA_Directional=3,
   MA_Reversal=4,
   Mannual=5,
};
enum E_Grid_Direction
{

Grid_Long=0,//Long
Grid_Short=1,//Short
Grid_Both=2,//Both
Grid_Both_Solo=3//Both solo
};
enum E_SCREEN_SIZE{
   Small = 0, //COMPACT
   Big = 1,   //LARGE 
};

input E_SCREEN_SIZE ScreenSize = Big; 
input string               GridSet="------------ Settings -------------------";
input int                  magic_num=46598; //Magic Number
 bool                 Positive_Grid=true;//Positive Grid
input E_Grid_Direction     Grid_Direction=Grid_Both_Solo;//Grid Direction
 E_SST                Strategy_Type=Mannual;//Strategy Type
double                     Lot_Size=0.5;// Lot Size
input int                  Grid_Max_Leg=3;//Grid Max Leg
input double               Grid_Leg_Threshold=2500;//Grid Leg Threshold
input double               Grid_Lot_Multiplier=1.50;//Grid Multiplier
bool                 Grid_Hide_TP_SL=false;//Grid Hide TP/SL
input bool                 UsePointStop = false;//Use Average SL
double               TP_Point=25000;//TP Point
input double               SL_Point=25000;//SL Point
 double               TP_Money=700;//TP Money
 double               SL_Money=2000;//SL Money
input bool                 UseEquityTrail=false;//Use Equity trail
input double               EquityTrailStart= 500;//Equity Trail Start point
input double               Width=200;//Equity trail width
input string               Trade_Comment="Bonus";
input bool UseHedgeNLegs = false; //Use hedge legs after n legs
input int  NLegsHedge    = 3;     //N Leg Hedge 

 string               Bollinger_Bands_Setting="=====  Bollinger Bands =====";
 int                  BB_Period=20;// Bollinger Bands Period
 double               BB_deviation=2;// Bollinger Bands deviation
 int                  BB_Shift=0;// Bollinger Shift
 ENUM_APPLIED_PRICE   BB_Applied_Price=PRICE_CLOSE;// Bollinger Applied Price
 string  MA_Setting="=====  Moving Average =====";
 int     MovingPeriod       = 50;      // Moving Average period
 int     MovingShift        = 0;       // Moving Average shift
 ENUM_MA_METHOD MA_Method   = MODE_EMA; //Moving Average Method
 ENUM_APPLIED_PRICE  MA_Applied_Price=PRICE_CLOSE;// MA Applied Price
datetime Expiry=D'2022.10.10 00:00';
bool exp_deliverd = false;
double TPB,TPS;
int C_B_N=-1;
int C_S_N=-1;
double GB_N[1000];
double GBL_N[1000];
double GS_N[1000];
double GSL_N[1000];

int C_B_P=-1;
int C_S_P=-1;
double GB_P[1000];
double GBL_P[1000];
double GS_P[1000];
double GSL_P[1000];
double OPB=0;
double Count_B=0;
double OPS=0;
double Count_S=0;
double FTPB=0;
double FTPS=0;
int Handler_BB;
double UPBB1[];
double DNBB1[];
bool reset;
int ExtHandle = 0;
bool useAcl = false;
int Allowed_Acc = 100111;
int Allowed_Acc2 = 1406484;
int Allowed_Acc3 = 100113;
//int Allowed_Acc2 = 14;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   if(useAcl){
      long curr_acc = AccountInfoInteger(ACCOUNT_LOGIN);
      if(curr_acc != Allowed_Acc && curr_acc != Allowed_Acc2 &&curr_acc != Allowed_Acc3 ){
         Alert("AMG Trade not allowed on this account");
         return (INIT_FAILED);
      }
   }
   if(CheckExpiry())
   {
      Alert("EA expired. Please contact the developer");
      exp_deliverd=true;
      return (INIT_FAILED);
      
   }
   ExtHandle=iMA(_Symbol,_Period,MovingPeriod,MovingShift,MA_Method,MA_Applied_Price);
   if(ExtHandle==INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }
   trade.SetExpertMagicNumber(magic_num);
   Handler_BB=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price);
   
   if(ScreenSize == Big)CreateBigScreen();
   else if(ScreenSize == Small)CreateSmallScreen();
   
   
   EventSetMillisecondTimer(300);
   
   
   
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   Dialog.Destroy(reason);
   EventKillTimer();
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer(){
   if(!TerminalInfo.IsTradeAllowed() || exp_deliverd)
      return;
   int legs = Orders();
   int blegs= OrdersTT(POSITION_TYPE_BUY);
   int slegs= OrdersTT(POSITION_TYPE_SELL);
   double pnl = GetPnl();
   double bpnl= GetPnl(POSITION_TYPE_BUY);
   double spnl= GetPnl(POSITION_TYPE_SELL);
   string dir = "";
    int op = -99;
   if(Grid_Direction == Grid_Long){ 
      op= POSITION_TYPE_BUY;        
      dir = "Long";
   }   
   else if(Grid_Direction == Grid_Short){
      dir = "Short";
      op = POSITION_TYPE_SELL;  
   }   
   else if(Grid_Direction == Grid_Both)  {
    dir = "Both";
   }
   LabelsValues[0].Text(DoubleToString(pnl,2));
   LabelsValues[1].Text(DoubleToString(bpnl,2));
   LabelsValues[2].Text(DoubleToString(spnl,2));
   LabelsValues[3].Text((string)blegs);
   LabelsValues[4].Text((string)slegs);
}

void OnTick()
{
//---
   
   //if(!IsExpertEnabled()) return;
   if(!TerminalInfo.IsTradeAllowed())
      return;
   if(CheckExpiry()){
      if(!exp_deliverd){
         exp_deliverd = true;
         Alert("EA expired. Please contact the developer");
      }
      else
         return;
   }
int orders_total = Orders();
if(orders_total == 0){
   Refresh_Buy();
   Refresh_Sell();
   if(Strategy_Type == Mannual && Grid_Direction == Grid_Both_Solo){
      //do nothing
   }
   if(Strategy_Type==2 && (Grid_Direction==0||Grid_Direction==2) && OrdersTT(0)==0)
   {
      
      Refresh_Sell();
          bool buy = false;
          if(UsePointStop)buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),0,Trade_Comment);  
          else buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),0,0,Trade_Comment);
          if(buy){
            C_B_N=0;
            GB_N[C_B_N]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_N[C_B_N]=Lot_Size;
            C_B_P=0;
            GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_P[C_B_P]=Lot_Size;
            OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
            Count_B++;
            FTPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
          }  
     
     
     
     }
     
     if(Strategy_Type==2 && (Grid_Direction==1||Grid_Direction==2) && OrdersTT(1)==0)
    {
    
     
              Refresh_Buy();
        
            bool sell = false;
            if(UsePointStop) sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),0,Trade_Comment);    
            else sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,0,Trade_Comment);    
            if(sell){
               C_S_N=0;
               GS_N[C_S_N]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_N[C_S_N]=Lot_Size;
               C_S_P=0;
               GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_P[C_S_P]=Lot_Size;
               OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
               Count_S++;
               FTPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
            }
     }
     
     else if(Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal){
      int signal_ma = MA_Check();
      if(signal_ma == 1){
         Refresh_Sell();
         bool buy = false;
          if(UsePointStop)buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point(),Trade_Comment);  
          else buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),0,0,Trade_Comment);
          if(buy){
            C_B_N=0;
            GB_N[C_B_N]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_N[C_B_N]=Lot_Size;
            C_B_P=0;
            GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_P[C_B_P]=Lot_Size;
            OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
            Count_B++;
            FTPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
         }
      }
      else if(signal_ma == -1 ){
         Refresh_Buy();
         bool sell = false;
         if(UsePointStop) sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point(),Trade_Comment);    
         else sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,0,Trade_Comment);    
         if(sell){
               C_S_N=0;
               GS_N[C_S_N]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_N[C_S_N]=Lot_Size;
               C_S_P=0;
               GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_P[C_S_P]=Lot_Size;
               OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
               Count_S++;
               FTPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
         }
     }

   }
   
   }      
   else{
         CheckLoss();
         EquityTrail(UseEquityTrail,EquityTrailStart,Width);
         if(UseHedgeNLegs){
            HedgeLegsMonitor();
         }
      }

//***********************************************************

   if(Positive_Grid)
   {
      int order = Orders();
      Count_B   = OrdersTTUpdated(POSITION_TYPE_BUY);
      Count_S   = OrdersTTUpdated(POSITION_TYPE_SELL);
      if( order!=0)
      {
         
         //Need to check legs
         if(Count_B<Grid_Max_Leg+1){
            double lots = 0.0;
            double lst_price =  LastOrderPrice(ORDER_TYPE_BUY,lots);
            if(SymbolInfoDouble(Symbol(),SYMBOL_ASK)>=(lst_price+Grid_Leg_Threshold*Point()))
            {
               Print("Total Orders: ["+order+"] Leg trigger-Buy["+IntegerToString(Count_B)+"] Starting Lot: "+DoubleToString(Lot_Size,2));
               if( (Grid_Direction==0||Grid_Direction==Grid_Both||Grid_Direction==Grid_Both_Solo)){
               //|| (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal || Strategy_Type == Mannual ))
               
                  double average_price_buy = Average_Open_Price(POSITION_TYPE_BUY);
                  
                  OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
                  double lot_size_G=NormalizeDouble(MathPow(Grid_Lot_Multiplier,C_B_P)*Lot_Size,2);
                  double lot_size_diff = NormalizeDouble(Lot_Size*MathPow(Grid_Lot_Multiplier,Count_B),2);
                  Print("Buy grid leg["+IntegerToString(Count_B)+"] lotg["+DoubleToString(lot_size_G)+"] lotdiff["+DoubleToString(lot_size_diff)+"]");
                  if(trade.Buy(lot_size_diff,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),0,0,Trade_Comment))
                  {
                     C_B_P++;
                     GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
                     GBL_P[C_B_P]=lot_size_G;
                     Print("AVG["+average_price_buy+"]OPB["+OPB+"] Count_B["+Count_B+"] SL_Point*point["+(SL_Point*Point())+"] point[]");
                     if(UsePointStop)Average_SL((average_price_buy)-SL_Point*Point() );
                  
                  }                  
               }
            }         
         }
         if(Count_S<Grid_Max_Leg+1)
         {
            double lst_price = LastOrderPrice(ORDER_TYPE_SELL);
            if( (Grid_Direction==1||Grid_Direction==Grid_Both||Grid_Direction==Grid_Both_Solo)){
            //|| (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal|| Strategy_Type == Mannual)){
               if(SymbolInfoDouble(Symbol(),SYMBOL_BID)<=(lst_price-Grid_Leg_Threshold*Point()))
               {
                  Print("Total Orders: ["+order+"] Leg trigger-Sell["+(Count_S)+"] Starting Lot: "+Lot_Size);
                  double average_price_sell = Average_Open_Price(POSITION_TYPE_SELL);
                  OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
                  double lot_size_G=NormalizeDouble(MathPow(Grid_Lot_Multiplier,C_S_P)*Lot_Size,2);            
                  double lot_size_diff = NormalizeDouble(Lot_Size*MathPow(Grid_Lot_Multiplier,Count_S),2);
                  Print("Sell grid leg["+(Count_S)+"] lotg["+DoubleToString(lot_size_G)+"] lotdiff["+DoubleToString(lot_size_diff)+"]");
                  
                  bool sell = trade.Sell(lot_size_diff,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,0,Trade_Comment);
                  if(sell){
                     C_S_P++;
                     GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
                     GSL_P[C_S_P]=lot_size_G;
                     Print("AVG["+DoubleToString(average_price_sell,Digits())+"] OPS["+IntegerToString(OPS)+"] Count_S["+IntegerToString(Count_S)+"] SL_Point*point["+(SL_Point*Point())+"] point[]");
                     if(UsePointStop)Average_SL((average_price_sell)+SL_Point*Point() );            
                  }
               }
            }               
         }
      }
      if(Grid_Direction == Grid_Both){
      int buy_legs = OrdersTT(POSITION_TYPE_BUY);
      int sell_legs = OrdersTT(POSITION_TYPE_SELL);
      if(buy_legs>0 && sell_legs == 0){
        Print("opening sell- Reason both");
        bool sell = false;
         if(UsePointStop) sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point(),Trade_Comment);    
         else sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,0,Trade_Comment);    
         
            if(sell){
               C_S_N=0;
               GS_N[C_S_N]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_N[C_S_N]=Lot_Size;
               C_S_P=0;
               GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL_P[C_S_P]=Lot_Size;
               OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
               Count_S++;
               FTPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
            }    
         
      }
      else if(buy_legs==0 && sell_legs > 0){
         Print("opening buy- Reason both");
         bool buy = false;
         if(UsePointStop)buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point(),Trade_Comment);  
          else buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),0,0,Trade_Comment);
          if(buy){
               C_B_N=0;
               GB_N[C_B_N]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
               GBL_N[C_B_N]=Lot_Size;
               C_B_P=0;
               GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
               GBL_P[C_B_P]=Lot_Size;
               OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
               Count_B++;
               FTPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
             } 
      }
   }
      /*if(Orders()!=0)
      {
         if(OrdersTT(ORDER_TYPE_SELL)<Grid_Max_Leg+1)
         {
            GB_P[C_S_P] = LastOrderPrice(ORDER_TYPE_SELL);
            if( (Grid_Direction==1||Grid_Direction==2)){
            //|| (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal|| Strategy_Type == Mannual)){
               if(SymbolInfoDouble(Symbol(),SYMBOL_BID)<=(GS_P[C_S_P]-Grid_Leg_Threshold*Point()))
               {
                  double average_price_sell = Average_Open_Price(POSITION_TYPE_SELL);
                  OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
                  Count_S++;
                  double lot_size_G=NormalizeDouble(MathPow(Grid_Lot_Multiplier,C_S_P)*Lot_Size,2);            
                  bool sell = trade.Sell(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,FTPS,Trade_Comment);
                  if(sell){
                     C_S_P++;
                     GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
                     GSL_P[C_S_P]=lot_size_G;
                     //Print("AVG["+average_price_sell+"] OPS["+OPS+"] Count_S["+Count_S+"] SL_Point*point["+(SL_Point*Point())+"] point[]");
                     Average_SL((average_price_sell)+SL_Point*Point() );            
                  }
                  else{
                     Count_S--;
                  }
               }
            }               
         }
       }*/
   }
//*******************************************************************

   if(Strategy_Type!=2)
   {
      if(TP_Point!=0 && UsePointStop)
      {
         TPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
         TPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
   
   
      }
      else
      {
         TPB=0;
         TPS=0;
      }
      if(Orders()==0 && iVolume(NULL,PERIOD_CURRENT,0)<=1)
      {
         if(BB_Check()==1 && Orders()==0&&  (Grid_Direction==0||Grid_Direction==2) )
         {
            Refresh_Sell();
            double _ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            //   int BuyTicket=OrderSend(Symbol(),OP_BUY,Lot_Size,Ask,5,Ask-SL_Point*Point,TPB,Trade_Comment,magic_num,0,clrNONE);
            if(trade.Buy(Lot_Size,NULL,_ask,/*_ask-(SL_Point*Point())*/0,TPB,Trade_Comment)){
               C_B_N=0;
               GB_N[C_B_N]=_ask;
               GBL_N[C_B_N]=Lot_Size;
               C_B_P=0;
               GB_P[C_B_P]=_ask;
               GBL_P[C_B_P]=Lot_Size;
               OPB=_ask+OPB;
               Count_B++;
               FTPB=TPB;
            }
            
         }
   
         if(BB_Check()==-1 && Orders()==0&&  (Grid_Direction==1||Grid_Direction==2))
         {
            Refresh_Buy();
            double _bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
            // int SellTicket=OrderSend(Symbol(),OP_SELL,Lot_Size,Bid,5,Bid+SL_Point*Point,TPS,Trade_Comment,magic_num,0,clrNONE);
            if(trade.Sell(Lot_Size,NULL,_bid,/*_bid+(SL_Point*Point())*/0,TPS,Trade_Comment)){
               C_S_N=0;
               GS_N[C_S_N]=_bid;
               GSL_N[C_S_N]=Lot_Size;
               C_S_P=0;
               GS_P[C_S_P]=_bid;
               GSL_P[C_S_P]=Lot_Size;
               OPS=_bid+OPS;
               Count_S++;
               FTPS=TPS;
            }
            
         }
   
   
      }
      if(OrdersTT(0)==0)
      {
         OPB=0;
         Count_B=0;
   
      }
      if(OrdersTT(1)==0)
      {
         OPS=0;
         Count_S=0;
   
      }
   }
}
void HedgeLegsMonitor(){
   int b_legs=0, s_legs=0, bh_leg =0, sh_leg =0;
   double b_lots=0.0, s_lots =0.0, bh_lots =0.0, sh_lots =0;
   int total = CalculateCurrentOrders2(b_legs,b_lots,s_legs,s_lots,bh_leg,bh_lots,sh_leg,sh_lots);
   
   //Print("BUY["+IntegerToString(b_legs)+"] SELL["+IntegerToString(s_legs)+"] Total["+IntegerToString(total)+"]");
   if(b_legs >= NLegsHedge){
      if(sh_leg == 0){
         if(trade.Sell(b_lots,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,NULL,Trade_Comment+"-Hedge")){
            SetTpToZero(POSITION_TYPE_BUY);
         }
      }
      //Check if next buy hedge needs to be open
      if(sh_leg>=1){
         int rounded_legs = round((b_legs/NLegsHedge));
        // Alert("Locking buy- Rounded legs["+rounded_legs+"]");
        //Print("Locking buy- Rounded legs["+rounded_legs+"]Hedged Sells["+sh_leg+"]");
         if(rounded_legs > sh_leg){
            Print("Locking buy- Rounded legs["+rounded_legs+"] Hedged Sells["+sh_leg+"]");
            double new_lots = b_lots - sh_lots; 
            if(trade.Sell(new_lots,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,NULL,Trade_Comment+"-Hedge")){
               SetTpToZero(POSITION_TYPE_BUY);
            }
         }     
      }
      
   }
   if(s_legs >= NLegsHedge){
      if(bh_leg == 0){
         if(trade.Buy(s_lots,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,NULL,Trade_Comment+"-Hedge")){
            SetTpToZero(POSITION_TYPE_SELL);
         }
      }
      
      if(bh_leg>=1){
         int rounded_legs = round((s_legs/NLegsHedge));
         //Print("Locking sell- Rounded legs["+rounded_legs+"]Hedged Buys["+bh_leg+"]");
         if(rounded_legs > bh_leg){
            Print("Locking sell- Rounded legs["+rounded_legs+"]");
            double new_lots = b_lots - bh_lots; 
            if(trade.Sell(new_lots,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,NULL,Trade_Comment+"-Hedge")){
               SetTpToZero(POSITION_TYPE_SELL);
            }
         }     
      } 
   }

}
void SetTpToZero(int op){
   double  num=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE) == op)
            trade.PositionModify(PositionGetTicket(i),NULL,NULL);
      }
   }
}
double LotsCalculatePositiveGrid(int legs){
   double lot = Lot_Size;
   for(int i = 1; i<=legs; i++){
      lot = lot * Grid_Lot_Multiplier; 
   }
   return lot;
}
double PointsSignal(int op){
   int legs = Orders();
   //Print("Opened Legs: "+legs);
    double last_price = LastOrderPrice(op);
    double next_price = 0.0;
    MqlTick tick;
    if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return -99; }
    else
    {
      
       double _ask=tick.ask;
       double _bid=tick.bid;
         if(op == POSITION_TYPE_BUY){
            next_price = (last_price+ Grid_Leg_Threshold*Point());     
         }
         else if(op == POSITION_TYPE_SELL){
            if(_ask <= last_price- Grid_Leg_Threshold*Point()){
               next_price = (last_price- Grid_Leg_Threshold*Point());
            }
         }
        return next_price; 
     }    
   //return 0.0;
}
double Average_Open_Price2(int op)
{
   int count = 0;
   double sum = 0.0;
   double avg = 0.0;
   for(int i=PositionsTotal()-1; i>=0; i--){ // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==magic_num && m_position.PositionType() == (ENUM_POSITION_TYPE)op)
         {
            count ++;
            sum += m_position.PriceOpen();
         }   
   }
   avg = sum/count;
   return avg;           
}
double Average_Open_Price(int op){
   double avg = 0.0;
   double lot=0.0,sum_lots=0.0, price =0.0,weighted_price=0.0, sum_weighted_price=0.0;
   for(int i=PositionsTotal()-1; i>=0; i--){ // returns the number of current positions
      if(PositionGetTicket(i)) // selects the position by index for further access to its properties
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol()&& PositionGetInteger(POSITION_TYPE) == op && PositionGetString(POSITION_COMMENT) ==Trade_Comment )
         {
            lot = PositionGetDouble(POSITION_VOLUME);
            sum_lots += lot;
            price = PositionGetDouble(POSITION_PRICE_OPEN);
            weighted_price = lot*price;
            sum_weighted_price+= weighted_price;
            
         }   
   }
   avg = sum_weighted_price/sum_lots;
   return avg;
}
int MA_Check()
{
    if(Strategy_Type==MA_Directional || Strategy_Type == MA_Reversal){
      int signal = 0;
      double   ma[1];
      if(CopyBuffer(ExtHandle,0,0,1,ma)!=1)
        {
         Print("CopyBuffer from iMA failed, no data");
         return 0;
        }
      double open = iOpen(Symbol(),0,0);    
      int k=0;
      MqlTick tick;
      if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return -99; }
       double Ask=tick.ask;
       double Bid=tick.bid;
      if((Ask >= ma[0] && open < ma[0]) && Strategy_Type==MA_Directional  )signal = 1;
      else if((Bid <= ma[0] && open > ma[0])&& Strategy_Type==MA_Directional) signal = -1;
      if((Ask >= ma[0] && open < ma[0]) && Strategy_Type==MA_Reversal  )signal = -1;
      else if((Bid <=ma[0] && open > ma[0])&& Strategy_Type==MA_Reversal) signal = 1;
      return signal;   
    }
   else{
      return 0;
   }
   
   
   

}

bool CheckExpiry()
{
   MqlDateTime str1, str2;
   TimeToStruct(Expiry,str1);
   TimeToStruct(TimeCurrent(),str2);  
   if(str2.day >= str1.day && str2.mon >= str1.mon && str2.year >= str1.year)
      return true;
   else
      return false;   
}
  //+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   Dialog.OnEvent(id,lparam,dparam,sparam);
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "")
      return;
    if(sparam=="CloseAll") // Close all
    {
        //CloseAll(Magic);
        //CloseAllBtn.Pressed(false);
        MessageBox("Closing All Orders!")                           ;
        CloseAllPositions();
        //closeByAll();
        CloseAllBtn.Pressed(false);
        //WindowRedraw();
        reset = true;
        Refresh_Buy();
        Refresh_Sell();
    }
    if(sparam=="OpenBuy") // Close Buys
    {
        //CloseAll(Magic);
        MannualEntryBtn[0].Pressed(false);
        MessageBox("Opening Buy Order!")                           ;
        MannualEntry(ORDER_TYPE_BUY);
        //MannualEntry(OP_BUY);
        Print("Opened Buy Position");
        //WindowRedraw();
    }
    if(sparam=="CloseBuys") // Close Buys
    {
        //CloseAll(Magic);
        CloseBuysBtn.Pressed(false);
        MessageBox("Closing All Buy Orders!")                           ;
        CloseAllPositions(POSITION_TYPE_BUY);
        Print("Close All Buy Orders event");
        //WindowRedraw();
        reset = true;
        Refresh_Buy();
    }
    if(sparam=="OpenSell") // Close Buys
    {
        //CloseAll(Magic);
        MannualEntryBtn[1].Pressed(false);
        MessageBox("Opening Sell Order!")                           ;
        MannualEntry(ORDER_TYPE_SELL);
        //MannualEntry(OP_SELL);
        Print("Opened Sell Position");
        //WindowRedraw();
    }
    if(sparam=="CloseSells") // Close Sells
    {
        //CloseAll(Magic);
        CloseSellsBtn.Pressed(false);
        MessageBox("Closing All sell Orders!")                           ;
        CloseAllPositions(POSITION_TYPE_SELL);
        Print("Close All Sell Orders event");
        //WindowRedraw();
        reset = true;
        Refresh_Sell();
    }
    if(sparam =="ApplyBtn"){
      SetParameters();
      MessageBox("Applying parameters");
    }
    if(sparam == "OpenHedge"){      
      MessageBox("Opening hedge positions and stating auto mode");
      Strategy_Type = Open_Now;
      if(Grid_Direction == Grid_Long ||Grid_Direction==Grid_Both)
         MannualEntry(ORDER_TYPE_SELL);
      if(Grid_Direction == Grid_Short ||Grid_Direction==Grid_Both)
         MannualEntry(ORDER_TYPE_BUY);
      TitleBtn.Pressed(false);
    }
    if(sparam == "OpenManual"){      
      MessageBox("Opening hedge positions and starting manual mode");
      Strategy_Type = Mannual;
      if(Grid_Direction == Grid_Long ||Grid_Direction==Grid_Both)
         MannualEntry(ORDER_TYPE_SELL);
      if(Grid_Direction == Grid_Short ||Grid_Direction==Grid_Both)
         MannualEntry(ORDER_TYPE_BUY);
      MannualEntryBtn[2].Pressed(false);
    }
   }
    
   
}
void SetParameters()
{
   Lot_Size         = StringToDouble(InputParams[0].Text());
   TP_Money         = StringToDouble(InputParams[1].Text());
   SL_Money         = StringToDouble(InputParams[2].Text());
}
//+------------------------------------------------------------------+
int BB_Check()
{
   int k=0;
   MqlTick tick;
    if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return -99; }
    double Ask=tick.ask;
    double Bid=tick.bid;
    
   CopyBuffer(Handler_BB,1,0,1,UPBB1);
   CopyBuffer(Handler_BB,2,0,1,DNBB1);
//  double UPBB1=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price,MODE_UPPER,1);
//  double   DNBB1=iBands(NULL,0,BB_Period,BB_deviation,BB_Shift,BB_Applied_Price,MODE_LOWER,1);
   if(Ask>=UPBB1[0] && Strategy_Type==0)
      k=1;
   if(Ask>=UPBB1[0] && Strategy_Type==1)
      k=-1;
   if(iOpen(NULL,0,1)<=UPBB1[0] && iClose(NULL,0,1)>=UPBB1[0]  && Strategy_Type==0)
      k=1;
   if(iOpen(NULL,0,1)<=UPBB1[0]  && iClose(NULL,0,1)>=UPBB1[0]  && Strategy_Type==1)
      k=-1;
   if(Bid<=DNBB1[0] && Strategy_Type==0)
      k=-1;   
   if(Bid<=DNBB1[0] && Strategy_Type==1)
      k=1;     
   if(iOpen(NULL,0,1)>=DNBB1[0]  && iClose(NULL,0,1)<=DNBB1[0]  && Strategy_Type==0)
      k=-1;
   if(iOpen(NULL,0,1)>=DNBB1[0]  && iClose(NULL,0,1)<=DNBB1[0]  && Strategy_Type==1)
      k=1;
   return(k);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void close(int TT)
{

//---

   for(int i=0; i<PositionsTotal()+1; i++)
   {
      if(PositionGetTicket(i)){
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetInteger(POSITION_TYPE)==TT)
            trade.PositionClose(PositionGetTicket(i));
      }
      
   }
   if(TT == POSITION_TYPE_BUY)
      Refresh_Buy();
   else if(TT == POSITION_TYPE_SELL)
      Refresh_Sell();   

//---
}
void CloseAllPositions(void)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==magic_num)
            if(!trade.PositionClose(m_position.Ticket())){ // close a position by the specified m_symbol
               Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",m_position.Ticket(),", ",trade.ResultRetcodeDescription());
            }
            else{
               Refresh_Buy();
               Refresh_Sell();
            }   
  }
void CloseAllPositions(int op)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==magic_num && m_position.PositionType() == (ENUM_POSITION_TYPE)op)
            if(!trade.PositionClose(m_position.Ticket())){ // close a position by the specified m_symbol
               Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",m_position.Ticket(),", ",trade.ResultRetcodeDescription());
            }
            else{
               Refresh_Buy();
               Refresh_Sell();
            }   
  }  
void CloseAll()
{
   for(int i=0; i<PositionsTotal()+1; i++)
   {
      if(PositionGetTicket(i)){
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num )
            trade.PositionClose(PositionGetTicket(i));
      }
   }
   Refresh_Buy();
   Refresh_Sell();
}
bool closeByAll(const string symbol) {
   //m_position
   
   for(int i = PositionsTotal() - 1; i >= 0; --i) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == symbol) {
         ENUM_POSITION_TYPE type1 = m_position.PositionType();
         ulong ticket1 = m_position.Ticket();
         for(int j = i - 1; j >= 0; --j) {
            if(m_position.SelectByIndex(j) && m_position.Symbol() == symbol && m_position.PositionType() != type1) {
               if(trade.PositionCloseBy(ticket1, m_position.Ticket())) {
                  return closeByAll(symbol);
               }
               return false;
            }
         }
         break;
      }
   }
   return true;
}
bool closeByAll() {
   //m_position
   
   for(int i = PositionsTotal() - 1; i >= 0; --i) {
      if(m_position.SelectByIndex(i) && m_position.Magic()==magic_num) {
         ENUM_POSITION_TYPE type1 = m_position.PositionType();
         ulong ticket1 = m_position.Ticket();
         for(int j = i - 1; j >= 0; --j) {
            if(m_position.SelectByIndex(j) && m_position.Magic()==magic_num && m_position.PositionType() != type1) {
               if(trade.PositionCloseBy(ticket1, m_position.Ticket())) {
                  return closeByAll();
               }
               return false;
            }
         }
         break;
      }
   }
   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MannualEntry(int op)
{
   double tpb = 0.0, tps = 0.0, slb =0.0, sls =0.0;
   if(UsePointStop){
      tpb =0;
      //tpb = SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
      slb = SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point();
      tps =0;
      //tps = SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
      sls = SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point();
   }
   else{
      tpb = 0;
      slb = 0;
      tps = 0;
      sls = 0;
   }
   if(op == ORDER_TYPE_BUY){
      if(OrdersTT(ORDER_TYPE_BUY)==0 && (Grid_Direction==Grid_Long||Grid_Direction==Grid_Both||Grid_Direction==Grid_Both_Solo))
         if(trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),slb,tpb,Trade_Comment)){  
            C_B_N=0;
            GB_N[C_B_N]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_N[C_B_N]=Lot_Size;
            C_B_P=0;
            GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_P[C_B_P]=Lot_Size;
            OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
            Count_B++;
            FTPB=tpb;   
           // Alert("Placed mannual order-Buy");   
         }
   }
   
   else if(op == ORDER_TYPE_SELL ){
      if(OrdersTT(ORDER_TYPE_SELL)==0 && (Grid_Direction==Grid_Short||Grid_Direction==Grid_Both||Grid_Direction==Grid_Both_Solo))
         if(trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),sls,tps,Trade_Comment)){    
            C_S_N=0;
            GS_N[C_S_N]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            GSL_N[C_S_N]=Lot_Size;
            C_S_P=0;
            GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            GSL_P[C_S_P]=Lot_Size;
            OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
            Count_S++;
            FTPS=tps;
           // Alert("Placed mannual order-Sell");   
         }
   }
   
}
int Orders( )
{

//---
   int k=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_COMMENT)==Trade_Comment)
            k++;
      }

   }
   return(k);


}
//+------------------------------------------------------------------+
int OrdersTT( int TT)
{

//---
   int k=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==TT && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_COMMENT)== Trade_Comment)
            k++;
      }

   }
   return(k);


}
int OrdersTTUpdated( int TT)
{

//---
   int k=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol()==Symbol() && m_position.Magic()==magic_num && m_position.PositionType()==TT && PositionGetString(POSITION_COMMENT)== Trade_Comment )
            k++;
      }

   }
   return(k);


}
int CalculateCurrentOrders2(int &buy_c , int &sell_c )
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_COMMENT)== Trade_Comment){
            long op = PositionGetInteger(POSITION_TYPE);
            if(op == POSITION_TYPE_BUY){
               buy_c++;
            }
            if(op == POSITION_TYPE_SELL){
               sell_c++;
            }
            k++;
         }
            
      }

   }
   return(k);


}
int CalculateCurrentOrders2(int &buy_c, double &lots_b , int &sell_c , double &lots_s)
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_MAGIC)==magic_num) 
            if(PositionGetString(POSITION_COMMENT)==Trade_Comment){
               long op = PositionGetInteger(POSITION_TYPE);
               if(op == POSITION_TYPE_BUY){
                  buy_c++;
                  lots_b+= PositionGetDouble(POSITION_VOLUME);
               }
               if(op == POSITION_TYPE_SELL){
                  sell_c++;
                  lots_s+= PositionGetDouble(POSITION_VOLUME);
               }
               k++;
            }
        }           
      }
   return(k);


}
int CalculateCurrentOrders2(int &buy_c, double &lots_b , int &sell_c , double &lots_s, int &h_legs_b, double &h_lots_b,int &h_legs_s, double &h_lots_s)
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_MAGIC)==magic_num) 
            if(PositionGetString(POSITION_COMMENT) ==Trade_Comment ){
               long op = PositionGetInteger(POSITION_TYPE);
               if(op == POSITION_TYPE_BUY){
                  buy_c++;
                  lots_b+= PositionGetDouble(POSITION_VOLUME);
               }
               if(op == POSITION_TYPE_SELL){
                  sell_c++;
                  lots_s+= PositionGetDouble(POSITION_VOLUME);
               }
               k++;
            }
            if(PositionGetString(POSITION_COMMENT) == (Trade_Comment+"-Hedge")){
            long op = PositionGetInteger(POSITION_TYPE);
               if(op == POSITION_TYPE_BUY){
                  h_legs_b++;
                  h_lots_b+= PositionGetDouble(POSITION_VOLUME);
               }
               if(op == POSITION_TYPE_SELL){
                  h_legs_s++;
                  h_lots_s+= PositionGetDouble(POSITION_VOLUME);
               }
               k++;
            }
         }                     
      }
   return(k);


}
double LastOrderPrice(int op)
{
   datetime time =D'01.01.2020';
      double k = 0.0;
      for(int i=0; i<PositionsTotal(); i++)
      {
         if(PositionGetTicket(i))
         {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==op && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_COMMENT) ==Trade_Comment)
             {
               if(PositionGetInteger(POSITION_TIME)>= time)
               {
                  time =(datetime) PositionGetInteger(POSITION_TIME);
                  k = PositionGetDouble(POSITION_PRICE_OPEN);
               }  
             }
         }

      }
      return k;
   

}
double LastOrderPrice(int op, double &lots)
{
   datetime time =D'01.01.2020';
      double k = 0.0;
      for(int i=0; i<PositionsTotal(); i++)
      {
         if(PositionGetTicket(i))
         {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==op && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_COMMENT) ==Trade_Comment)
             {
               if(PositionGetInteger(POSITION_TIME)>= time)
               {
                  time =(datetime) PositionGetInteger(POSITION_TIME);
                  k = PositionGetDouble(POSITION_PRICE_OPEN);
                  lots = PositionGetDouble(POSITION_VOLUME);
               }  
             }
         }

      }
      return k;
   

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPnl(){
   double  num=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol())
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   return num;
}
double GetPnl(int op){
   double  num=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)== op && PositionGetString(POSITION_COMMENT) ==Trade_Comment)
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   return num;
}
void CheckLoss()
{
   double  num=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetString(POSITION_COMMENT) ==Trade_Comment)
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   if(num<SL_Money*(-1) || num>=TP_Money)
   {
      Refresh_Buy();
      Refresh_Sell();
      CloseAllPositions();
      C_B_P=-1;
      C_S_P=-1;
      C_B_N=-1;
      C_S_N=-1;
   }


}
//+------------------------------------------------------------------+
void Average_SL(double NSL )
{


   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetDouble(POSITION_SL)!=NSL )
         trade.PositionModify(PositionGetTicket(i),NSL,PositionGetDouble(POSITION_TP));
          //  int yy=OrderModify(OrderTicket(),OrderOpenPrice(),NSL,OrderTakeProfit(), 0, clrNONE);
      }
   }
}
double Round2Ticksize( double price )
{
   double tick_size = SymbolInfoDouble( _Symbol, SYMBOL_TRADE_TICK_SIZE );
   return( round( price / tick_size ) * tick_size );
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Refresh_Buy()
{
   ArrayFill(GB_N,0,1000,0);
   ArrayFill(GBL_N,0,1000,0);
   C_B_N=-1;
//*********
   ArrayFill(GB_P,0,1000,0);
   ArrayFill(GBL_P,0,1000,0);
   C_B_P=-1;


}
//+------------------------------------------------------------------+
void Refresh_Sell()
{
   ArrayFill(GS_P,0,1000,0);
   ArrayFill(GSL_P,0,1000,0);
   C_S_P=-1;
//**********************
   ArrayFill(GS_N,0,1000,0);
   ArrayFill(GSL_N,0,1000,0);
   C_S_N=-1;


}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool trail_flag = false;
double trail_equity =0.0;
void EquityTrail(bool use, double start, double width){
   if(!use)return;
   
   double pnl = GetPnl();
   
   //trail 
   if(trail_flag){
      if(pnl<=trail_equity){
         //Liquidate
         trail_flag = false;
         Alert("Liquidating positions- Equity trail- Profit["+DoubleToString(pnl,2)+"] trail["+DoubleToString(trail_equity,2)+"]");
         if(Grid_Direction == Grid_Long)
            CloseAllPositions(POSITION_TYPE_BUY);
         else if(Grid_Direction == Grid_Short)
            CloseAllPositions(POSITION_TYPE_SELL); 
         else if(Grid_Direction == Grid_Both)
            CloseAllPositions();  
         return;
      }
      else if((pnl-trail_equity)> width){
         trail_equity = pnl-width;
      }
   }
   else if(!trail_flag){
      if(pnl >= start){
         
         trail_flag = true;
         trail_equity = pnl-width;
         Print("Trail Started-"+Symbol()+"- Trailing at: "+DoubleToString(trail_equity,1));
         return;
      }
   }

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void CreateBigScreen(){
   Dialog.Create(ChartID(),"                             WWW.QUANTECHSOL.COM",0,5,5,720,350);
   string dialogNumber=Dialog.Name();
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,clrOrange);
   ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,clrWhite);
   
   ObjectDelete(ChartID(),dialogNumber+"Border");
   int width = 200, height = 35, fontsize = 10, width_big = 400;
   color border_color = clrBlack, font_color = clrWhite;
   int x2 = 0, y2 =0;
   CreateButton(Dialog,TitleBtn,"OpenHedge", "AUTO START", width,height,15,16,x2,y2,fontsize,font_color,clrBlue,border_color);
   CreateButton(Dialog,MannualEntryBtn[2],"OpenManual", "START MANUAL", width,height,215,16,x2,y2,fontsize,font_color,clrBlue,border_color);
   CreateButton(Dialog,MannualEntryBtn[0],"OpenBuy", "BUY", width,height,15,50,x2,y2,fontsize,font_color,clrBlue,border_color);   
   CreateButton(Dialog,CloseBuysBtn,"CloseBuys", "CLOSE BUYS", width,height,15,84,x2,y2,fontsize,font_color,clrBlue,border_color);   
   CreateButton(Dialog,MannualEntryBtn[1],"OpenSell", "SELL", width,height,215,50,x2,y2,fontsize,font_color,clrRed,border_color);  
   
   reset = false                                                     ; 
   CreateButton(Dialog,CloseSellsBtn,"CloseSells", "CLOSE SELLS", width,height,215,84,x2,y2,fontsize,font_color,clrRed,border_color);  
   CreateButton(Dialog,CloseAllBtn,"CloseAll", "CLOSE TRADES", width_big,height,15,118,x2,y2,fontsize,font_color,clrMaroon,border_color);  
   
   int lbl_fontsize = 9;
   color lbl_color1 = clrBlack, lbl_color2= clrDarkBlue,  lbl_color3 = clrSlateGray;
   CreateLabel(Dialog, LabelsInputs[0],"LotsLbl", "Lots: ",15,168,x2,y2,lbl_fontsize,lbl_color1);
   CreateLabel(Dialog, LabelsInputs[1],"ProfitLbl", "Profit$: ",15,195,x2,y2,lbl_fontsize,lbl_color1);
   CreateLabel(Dialog, LabelsInputs[2],"LossLbl", "Loss$: ",15,225,x2,y2,lbl_fontsize,lbl_color1);
      
   InputParams[0].Create(0,"LotsEdit",0,80,165,0,0)                    ;
   int e_height = 25, e_width = 330, e_fontsize = 10;
   SetEditProperties(Dialog,InputParams[0],""+(string)Lot_Size,e_height,e_width,e_fontsize);
   
   InputParams[1].Create(0,"ProfitEdit",0,80,195,0,0)                    ;
   SetEditProperties(Dialog,InputParams[1],""+(string)TP_Money,e_height,e_width,e_fontsize);
   
   InputParams[2].Create(0,"LossEdit",0,80,225,0,0)                    ;
   SetEditProperties(Dialog,InputParams[2],""+(string)SL_Money,e_height,e_width,e_fontsize);
   
   CreateButton(Dialog,SaveBtn,"ApplyBtn", "APPLY", width_big,height,15,254,x2,y2,fontsize,clrBlack,clrLime,border_color);  
 
   CreateLabel(Dialog, Labels[0],"NPnlLbl", "NET PNL$: ",530,35,x2,y2,lbl_fontsize,lbl_color2);
   CreateLabel(Dialog, LabelsValues[0],"NPNLValue", "0.0",620,35,x2,y2,lbl_fontsize,lbl_color2);
   CreateLabel(Dialog, Labels[1],"BPnlLbl", "BUY PNL$: ",530,55,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[1],"BPNLValue", "0.0",620,55,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, Labels[2],"SPnlLbl", "SELL PNL$: ",530,75,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[2],"SPNLValue", "0.0",620,75,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, Labels[3],"BLegsLbl", "BUY Legs: ",530,95,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[3],"BLegsValue", "0.0",620,95,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, Labels[4],"SLegsLbl", "SELL Legs: ",530,115,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[4],"SLegsValue", "0.0",620,115,x2,y2,lbl_fontsize,lbl_color3);
   
   
}
void CreateSmallScreen(){
   Dialog.Create(ChartID(),"                             WWW.QUANTECHSOL.COM",0,5,5,380,320);
   string dialogNumber=Dialog.Name();
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,clrOrange);
   ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,clrWhite);
   
   ObjectDelete(ChartID(),dialogNumber+"Border");
   //CreateButton(Dialog,TitleBtn,"OpenHedge", "AUTO START", 100,35,15,16,0,0,clrWhite,10);
   int width = 100, height = 35, fontsize = 9, width_big = 200;
   color border_color = clrBlack, font_color = clrWhite;
   int x2 = 0, y2 =0;
   CreateButton(Dialog,TitleBtn,"OpenHedge", "AUTO START", width,height,15,16,x2,y2,fontsize,font_color,clrBlue,border_color);
   CreateButton(Dialog,MannualEntryBtn[2],"OpenManual", "START MANUAL", width,height,115,16,x2,y2,fontsize,font_color,clrBlue,border_color);
   CreateButton(Dialog,MannualEntryBtn[0],"OpenBuy", "BUY", width,height,15,50,x2,y2,fontsize,font_color,clrBlue,border_color);   
   CreateButton(Dialog,CloseBuysBtn,"CloseBuys", "CLOSE BUYS", width,height,15,84,x2,y2,fontsize,font_color,clrBlue,border_color);   
   CreateButton(Dialog,MannualEntryBtn[1],"OpenSell", "SELL", width,height,115,50,x2,y2,fontsize,font_color,clrRed,border_color);  
   
   reset = false                                                     ; 
   CreateButton(Dialog,CloseSellsBtn,"CloseSells", "CLOSE SELLS", width,height,115,84,x2,y2,fontsize,font_color,clrRed,border_color);  
   CreateButton(Dialog,CloseAllBtn,"CloseAll", "CLOSE TRADES", width_big,height,15,118,x2,y2,fontsize,font_color,clrMaroon,border_color);  
   
   int lbl_fontsize = 9;
   color lbl_color1 = clrBlack, lbl_color2= clrDarkBlue,  lbl_color3 = clrSlateGray;
   CreateLabel(Dialog, LabelsInputs[0],"LotsLbl", "Lots: ",15,165,x2,y2,lbl_fontsize,lbl_color1);
   CreateLabel(Dialog, LabelsInputs[1],"ProfitLbl", "Profit$: ",15,190,x2,y2,lbl_fontsize,lbl_color1);
   CreateLabel(Dialog, LabelsInputs[2],"LossLbl", "Loss$: ",15,214,x2,y2,lbl_fontsize,lbl_color1);
      
   InputParams[0].Create(0,"LotsEdit",0,80,160,0,0)                    ;
   int e_height = 20, e_width = 110, e_fontsize = 10;
   SetEditProperties(Dialog,InputParams[0],""+(string)Lot_Size,e_height,e_width,e_fontsize);
   
   InputParams[1].Create(0,"ProfitEdit",0,80,185,0,0)                    ;
   SetEditProperties(Dialog,InputParams[1],""+(string)TP_Money,e_height,e_width,e_fontsize);
   
   InputParams[2].Create(0,"LossEdit",0,80,210,0,0)                    ;
   SetEditProperties(Dialog,InputParams[2],""+(string)SL_Money,e_height,e_width,e_fontsize);
   
   CreateButton(Dialog,SaveBtn,"ApplyBtn", "APPLY", width_big,height,15,238,x2,y2,fontsize,clrBlack,clrLime,border_color);  
 
   CreateLabel(Dialog, Labels[0],"NPnlLbl", "NET PNL$: ",230,22,x2,y2,lbl_fontsize,lbl_color2);
   CreateLabel(Dialog, LabelsValues[0],"NPNLValue", "0.0",300,22,x2,y2,lbl_fontsize,lbl_color2);
   CreateLabel(Dialog, Labels[1],"BPnlLbl", "BUY PNL$: ",230,45,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[1],"BPNLValue", "0.0",300,45,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, Labels[2],"SPnlLbl", "SELL PNL$: ",230,65,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[2],"SPNLValue", "0.0",300,65,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, Labels[3],"BLegsLbl", "BUY Legs: ",230,85,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[3],"BLegsValue", "0.0",300,85,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, Labels[4],"SLegsLbl", "SELL Legs: ",230,105,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[4],"SLegsValue", "0.0",300,105,x2,y2,lbl_fontsize,lbl_color3);   
}
void CreateButton(CDialog &dialog, CButton &button, string name, string text, int width, int height, int x_dim, int y_dim, int x2_dim, int y2_dim,  int font_size, color _color, color c_bg, color c_brdr ){
   button.Create(0,name,0,x_dim,y_dim,x2_dim,y2_dim);
   button.FontSize(font_size);
   button.Height(height);
   button.Width(width);
   button.Text(text);
   button.ColorBackground(c_bg)                               ;
   button.ColorBorder(c_brdr)                                 ;
   button.Color(_color);
   button.Pressed(false);
   dialog.Add(button);
}
void CreateLabel(CDialog &dialog, CLabel &lbl, string name, string text, int x_dim, int y_dim, int x2_dim, int y2_dim,  int font_size, color _color ){
   lbl.Create(0,name,0,x_dim,y_dim,x2_dim,y2_dim);
   lbl.FontSize(font_size);
   lbl.Text(text);
   lbl.Color(_color);
   dialog.Add(lbl);
   /*
   Labels[1].Create(0,"BPnlLbl",0,530,55,30,0);
   Labels[1].Text("BUY PNL$: ");
   Labels[1].FontSize(9);
   Labels[1].Color(clrSlateGray);
   Dialog.Add(Labels[1]);
   */
}
void SetEditProperties(CDialog &dialog,CEdit &_edit, string text, int height, int width, int fontsize ){
   _edit.Text(text);
   _edit.FontSize(fontsize);
   _edit.Width(width);
   _edit.Height(height);
   dialog.Add(_edit);
   

/*
   InputParams[0].Create(0,"LotsEdit",0,80,165,0,0)                    ;
   InputParams[0].Text(""+(string)Lot_Size)                                          ;
   InputParams[0].FontSize(10)                                          ;
   InputParams[0].Height(25)                                           ;
   InputParams[0].Width(330)                                           ;
   Dialog.Add(InputParams[0])                                          ;
*/
}
void SetPropertiesButton(CButton &button, string text, int width, int height,color _color, int font_size){
   button.Text(text);
   button.FontSize(font_size);
   button.Color(_color);

}