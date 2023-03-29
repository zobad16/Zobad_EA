//+------------------------------------------------------------------+
//|                                                       Common.mq5 |
//|                                    Copyright 2023, Zobad Mahmood |
//|                                          zobad.mahmood@gmail.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2023, Zobad Mahmood"
#property link      "zobad.mahmood@gmail.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| My function                                                      |
//+------------------------------------------------------------------+
// int MyCalculator(int value,int value2) export
//   {
//    return(value+value2);
//   }
//+------------------------------------------------------------------+
bool CheckExpiry(datetime Expiry)
{
   MqlDateTime str1, str2;
   TimeToStruct(Expiry,str1);
   TimeToStruct(TimeCurrent(),str2);  
   if(str2.day >= str1.day && str2.mon >= str1.mon && str2.year >= str1.year)
      return true;
   else
      return false;   
}

double GetPnl(int   magic_num){
   double  num=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol())
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   return num;
}
double GetPnl(int   magic_num,double &buy ,double &sell){
   double  num=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol()){
               long pos_type = PositionGetInteger(POSITION_TYPE);
               double profit =PositionGetDouble(POSITION_PROFIT);
               double swap = PositionGetDouble(POSITION_SWAP);
               
               if(pos_type == POSITION_TYPE_BUY ){
                  buy+=profit+swap;
               }
               else if(pos_type == POSITION_TYPE_SELL){
                  sell += profit+swap;
               }
               num=num+profit+swap;
            }
      }
   }
   return num;
}
double Average_Open_Price(int magic_num, string symbol, int op, string Comment_Order){
   double avg = 0.0;
   double lot=0.0,sum_lots=0.0, price =0.0,weighted_price=0.0, sum_weighted_price=0.0;
   for(int i=PositionsTotal()-1; i>=0; i--){ // returns the number of current positions
      if(PositionGetTicket(i)) // selects the position by index for further access to its properties
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==symbol&& PositionGetInteger(POSITION_TYPE) == op && PositionGetString(POSITION_COMMENT) ==Comment_Order )
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
int DemoTotalOrders(){
   return 0;
}
int TotalOrders( int magic_num,  string symbol, string comment )
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
        // Print("Symbol: ",PositionGetString(POSITION_SYMBOL)," |Magic: ",PositionGetInteger(POSITION_MAGIC)," |Comment: ",PositionGetString(POSITION_COMMENT));
         if(PositionGetString(POSITION_SYMBOL)==symbol && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_COMMENT)==comment)
            k++;
      }

   }
   //Print("Magic: ",magic_num," |Symbol: ",symbol," | Total orders found::",k);
   return(k);


}
int TotalOrders( int magic_num, int op, string symbol, string comment )
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==symbol && PositionGetInteger(POSITION_TYPE)==op && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_COMMENT)==comment)
            k++;
      }

   }
   return(k);


}
int TotalOrders(int magic_num, string symbol,int &buy_count , int &sell_count, string comment )
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==symbol  && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_COMMENT)== comment){
            long op = PositionGetInteger(POSITION_TYPE);
            if(op == POSITION_TYPE_BUY){
               buy_count++;
            }
            if(op == POSITION_TYPE_SELL){
               sell_count++;
            }
            k++;
         }
            
      }

   }
   return(k);


}
int TotalOrders(int magic_num, string symbol, int &buy_count, double &lots_b , int &sell_count , double &lots_s, string comment)
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==symbol  && PositionGetInteger(POSITION_MAGIC)==magic_num) 
            if(PositionGetString(POSITION_COMMENT)==comment){
               long op = PositionGetInteger(POSITION_TYPE);
               if(op == POSITION_TYPE_BUY){
                  buy_count++;
                  lots_b+= PositionGetDouble(POSITION_VOLUME);
               }
               if(op == POSITION_TYPE_SELL){
                  sell_count++;
                  lots_s+= PositionGetDouble(POSITION_VOLUME);
               }
               k++;
            }
        }           
      }
   return(k);


}
double Round2Ticksize(string symbol, double price )
{
   double tick_size = SymbolInfoDouble( symbol, SYMBOL_TRADE_TICK_SIZE );
   return( round( price / tick_size ) * tick_size );
}