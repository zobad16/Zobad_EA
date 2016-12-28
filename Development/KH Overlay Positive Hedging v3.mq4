//+------------------------------------------------------------------+
//|                                 KH OverLay Positive Hedge v1.mq4 |
//|                                            © 2012.05.10 KingHigh |
//+------------------------------------------------------------------+
//|       Derived from work done by Meet Joe Black, Maidin, Zainudin |                                           |
//|       Found on site: Forex Is Biz FX Solutions                   |
//+------------------------------------------------------------------+
#property copyright "Meet Joe Black, Maidin, Zainudin"
#property link      "zdntaib@yahoo.com"

#define BUY1SELL2           1
#define SELL1BUY2           2

extern string  Basic_Setting = "----------------- Basic Setting -----------------";
extern double  Lot = 0.1;
extern int     LevelDistance = 100;
extern bool    UseTakeProfitByPip = TRUE;
extern int     TakeProfit = 80;
extern bool    UseTakeProfitByUSD = FALSE;
extern double  TakeProfitInUSD = 100.0;
extern int     MaximumLevel = 5;
extern int     TradeMgmtRetry = 5;
extern string  Pair_Setting = "----------------- Pairs Setting -----------------";
extern string  Pair1 = "GBPUSD";
extern string  Pair2 = "EURUSD";
extern string  Note1 = "Buy1Sell2: Buy Pair1 Sell Pair2";
extern string  Note2 = "Sell1Buy2: Sell Pair1 Buy Pair2";
extern bool    Buy1Sell2 = TRUE;
extern bool    Sell1Buy2 = FALSE;
extern string  ADR_Setting = "------------------ ADR Setting ------------------";
extern int     ADR_Day = 365;
extern bool    UseManual_ADR_Ratio = TRUE;
extern double  ADR_Ratio = 0.8;
extern int     MagicNo = 90000;
int UniqueMagic;


int init( ) 
{
   return ( 0 );
}
int deinit( ) 
{
   Comment( "" );
   return ( 0 );
}

int start( ) 
{
   int NewBuyTicket;
   int NewSellTicket;
   int LstBuyLevel;
   int LstSellLevel;
   int LstBuyTicket;
   int LstSellTicket;
   int BuyFloat;
   int SellFloat;
   double Sum1;
   double Sum2;
   int CloseStatus;
   string TrdMde1OnOff;
   string TrdMde2OnOff;
   string B1S2 = "Buy1Sell2";
   string S1B2 = "Sell1Buy2";
   UniqueMagic = MagicNo + 987;
   if( UseManual_ADR_Ratio == FALSE )
   {
      for ( int j = 1; j <= ADR_Day; j++ ) 
      {
         Sum1 += ( iHigh( Pair1, PERIOD_D1, j ) - iLow( Pair1, PERIOD_D1, j ) ) / MarketInfo( Pair1, MODE_POINT );
         Sum2 += ( iHigh( Pair2, PERIOD_D1, j ) - iLow( Pair2, PERIOD_D1, j ) ) / MarketInfo( Pair2, MODE_POINT );
      }
      double Adr1 = Sum1 / ADR_Day;
      double Adr2 = Sum2 / ADR_Day;
      double CalcAdrRatio = Adr2 / Adr1;
      ADR_Ratio = CalcAdrRatio;
   }
   double ScaledLots = NormalizeDouble( Lot * ADR_Ratio, 2 );
   double BaseLots   = NormalizeDouble( Lot, 2 );
   //
   // Check For No Open Trades in Buy1Sell2 Mode - Open initial Buy/Sell
   //
   if( Buy1Sell2 ) 
   {
      if( GetBuyOrderCount( Pair1, MagicNo ) <= 0 )
         SendBuy( B1S2, Pair1, ScaledLots, 1, MagicNo );
      if( GetBuyOrderCount( Pair1, MagicNo ) == 1 && GetSellOrderCount( Pair2, MagicNo ) <= 0 ) 
         SendSell( B1S2, Pair2, BaseLots, 1, MagicNo );
      if( GetFloatingPip( BUY1SELL2 ) <= ( -LevelDistance ) && GetBuyOrderCount( Pair1, MagicNo ) < MaximumLevel ) 
      {
         LstBuyTicket = GetLastBuyTicket( Pair1, MagicNo );
         LstBuyLevel = GetLastBuyLevelNbr( Pair1, LstBuyTicket, MagicNo );
         if( GetBuyOrderCount( Pair1, MagicNo ) <= LstBuyLevel ) 
            SendBuy( B1S2, Pair1, ScaledLots, LstBuyLevel + 1, MagicNo );
         if( GetBuyOrderCount( Pair1, MagicNo ) == LstBuyLevel + 1 && GetSellOrderCount( Pair2, MagicNo ) <= LstBuyLevel ) 
            SendSell( B1S2, Pair2, BaseLots, LstBuyLevel + 1, MagicNo );
      }
      if( UseTakeProfitByPip == TRUE && GetFloatingPip( BUY1SELL2 ) >= TakeProfit ) 
      {
         LstBuyTicket  = GetLastBuyTicket( Pair1, MagicNo );
         LstSellTicket = GetLastSellTicket( Pair2, MagicNo );
         if( LstBuyTicket > 0 && LstSellTicket > 0 ) 
            CloseLastBuy( LstBuyTicket, Pair1 );
      }
      if( UseTakeProfitByUSD == TRUE && GetFloatingUSD( BUY1SELL2 ) >= TakeProfitInUSD ) 
      {
         LstBuyTicket  = GetLastBuyTicket( Pair1, MagicNo );
         LstSellTicket = GetLastSellTicket( Pair2, MagicNo );
         if( LstBuyTicket > 0 && LstSellTicket > 0 ) 
            CloseLastBuy( LstBuyTicket, Pair1 );
      }
   }
   //
   // Check For No Open Trades in Sell1Buy2 Mode - Open initial Buy/Sell
   //
   if( Sell1Buy2 ) 
   {
      if( GetBuyOrderCount( Pair2, UniqueMagic ) <= 0 ) 
         SendBuy( S1B2, Pair2, BaseLots, 1, UniqueMagic );
      if( GetBuyOrderCount( Pair2, UniqueMagic ) == 1 && GetSellOrderCount( Pair1, UniqueMagic ) <= 0 ) 
         SendSell( S1B2, Pair1, ScaledLots, 1, UniqueMagic );
      if( GetFloatingPip( SELL1BUY2 ) <= ( -LevelDistance ) && GetBuyOrderCount( Pair2, UniqueMagic ) < MaximumLevel ) 
      {
         LstBuyTicket = GetLastBuyTicket( Pair2, UniqueMagic );
         LstBuyLevel  = GetLastBuyLevelNbr( Pair2, LstBuyTicket, UniqueMagic );
         if( GetBuyOrderCount( Pair2, UniqueMagic ) <= LstBuyLevel ) 
            SendBuy( S1B2, Pair2, BaseLots, LstBuyLevel + 1, UniqueMagic );
         if( GetBuyOrderCount( Pair2, UniqueMagic ) == LstBuyLevel + 1 && GetSellOrderCount( Pair1, UniqueMagic ) <= LstBuyLevel ) 
            SendSell( S1B2, Pair1, ScaledLots, LstBuyLevel + 1, UniqueMagic );
      }
      if( UseTakeProfitByPip == TRUE && GetFloatingPip( SELL1BUY2 ) >= TakeProfit ) 
      {
         LstBuyTicket = GetLastBuyTicket( Pair2, UniqueMagic );
         LstSellTicket = GetLastSellTicket( Pair1, UniqueMagic );
         if( LstBuyTicket > 0 && LstSellTicket > 0 ) 
            CloseLastBuy( LstBuyTicket, Pair2 );
      }
      if( UseTakeProfitByUSD == TRUE && GetFloatingUSD( SELL1BUY2 ) >= TakeProfitInUSD ) 
      {
         LstBuyTicket = GetLastBuyTicket( Pair2, UniqueMagic );
         LstSellTicket = GetLastSellTicket( Pair1, UniqueMagic );
         if( LstBuyTicket > 0 && LstSellTicket > 0 ) 
            CloseLastBuy( LstBuyTicket, Pair2 );
      }
   }
   if( Buy1Sell2 ) 
   {
      LstBuyTicket = GetLastBuyTicket( Pair1, MagicNo );
      LstBuyLevel = GetLastBuyLevelNbr( Pair1, LstBuyTicket, MagicNo );
      LstSellTicket = GetLastSellTicket( Pair2, MagicNo );
      LstSellLevel = GetLastSellLevelNbr( Pair2, LstSellTicket, MagicNo );
      if( LstBuyLevel > LstSellLevel ) 
      {
         BuyFloat = GetBuyFloat( LstBuyTicket, Pair1, MagicNo );
         if( BuyFloat > 0 )
            CloseLastBuy( LstBuyTicket, Pair1 );
         else 
            SendSell( B1S2, Pair2, BaseLots, LstBuyLevel, MagicNo );
      }
      if( LstSellLevel > LstBuyLevel ) 
      {
         SellFloat = GetSellFloat( LstSellTicket, Pair2, MagicNo );
         if( SellFloat > 0 ) 
            CloseLastSell( LstSellTicket, Pair2 );
         else 
            SendBuy( B1S2, Pair1, ScaledLots, LstSellLevel, MagicNo );
      }
   }
   if( Sell1Buy2 == TRUE ) 
   {
      LstBuyTicket = GetLastBuyTicket( Pair2, UniqueMagic );
      LstBuyLevel = GetLastBuyLevelNbr( Pair2, LstBuyTicket, UniqueMagic );
      LstSellTicket = GetLastSellTicket( Pair1, UniqueMagic );
      LstSellLevel = GetLastSellLevelNbr( Pair1, LstSellTicket, UniqueMagic );
      if( LstBuyLevel > LstSellLevel ) 
      {
         BuyFloat = GetBuyFloat( LstBuyTicket, Pair2, UniqueMagic );
         if( BuyFloat > 0 ) 
            CloseLastBuy( LstBuyTicket, Pair2 );
         else 
            SendSell( S1B2, Pair1, ScaledLots, LstBuyLevel, UniqueMagic );
      }
      if( LstSellLevel > LstBuyLevel ) 
      {
         SellFloat = GetSellFloat( LstSellTicket, Pair1, UniqueMagic );
         if( SellFloat > 0 ) 
            CloseLastSell( LstSellTicket, Pair1 );
         else 
            SendBuy( S1B2, Pair2, BaseLots, LstSellLevel, UniqueMagic );
      }
   }
   if( Buy1Sell2 == TRUE ) TrdMde1OnOff = "  ON"; else TrdMde1OnOff = "OFF";
   if( Sell1Buy2 == TRUE ) TrdMde2OnOff = "  ON"; else TrdMde2OnOff = "OFF";
   Comment( "\nAverage ADR ", Pair1, ": ", DoubleToStr( Adr1, 0 ), "  Average ADR ", Pair2, ": ", DoubleToStr( Adr2, 0 ), "   Ratio ADR: ", DoubleToStr( CalcAdrRatio, 2 ), 
      "\n", "Lot ", Pair1, ": ", ScaledLots, "   Lot ", Pair2, ": ", BaseLots, "  Take Profit: ", TakeProfit, "  Take Profit in USD: ", TakeProfitInUSD, "  Distance: ", LevelDistance, "  Maximum Level: ", MaximumLevel, 
      "\n\n", "Mode 1>  ", TrdMde1OnOff, "  Last Floating pip: ", GetFloatingPip( BUY1SELL2 ), "  Last Floating in USD: ", GetFloatingUSD( BUY1SELL2 ), "  Total Buy: ", GetTotalLotBuy( Pair1, MagicNo ), "  Total Sell: ", GetTotalLotSell( Pair2, MagicNo ), 
   "\n", "Mode 2>  ", TrdMde2OnOff, "  Last Floating pip: ", GetFloatingPip( SELL1BUY2 ), "  Last Floating in USD: ", GetFloatingUSD( SELL1BUY2 ), "  Total Buy: ", GetTotalLotBuy( Pair2, UniqueMagic ), "  Total Sell: ", GetTotalLotSell( Pair1, UniqueMagic ) );
   return ( 0 );
}

int SendBuy( string Mode, string Pair, double Lots, int Level, int Magic ) 
{
   string CommentStr = Mode + " - Level " + Level;
   for( int i = TradeMgmtRetry; i > 0; i-- )
   {
      RefreshRates();
      double Price = NormalizeDouble( MarketInfo( Pair, MODE_ASK ), MarketInfo( Pair, MODE_DIGITS ) );
      int Ticket = OrderSend( Pair, OP_BUY, Lots, Price, 5, 0, 0, CommentStr, Magic, 0, Blue );
      if( Ticket > 0 ) 
      {
         if( OrderSelect( Ticket, SELECT_BY_TICKET, MODE_TRADES ) ) 
            Print( "BUY order #", OrderTicket( ), " opened at ", OrderOpenPrice( ), " :", TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS) );
         return( Ticket );
      }
      Sleep( 3000 );
   }
   string AlertMsg = "#1: Error opening BUY order; Error Code: "+GetLastError( )+": "+ErrorDescription( GetLastError( ) )+" :"+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS); 
   FailureAlert( AlertMsg );
   return( Ticket );
}

int SendSell( string Mode, string Pair, double Lots, int Level, int Magic )
{ 
   string CommentStr = Mode + " - Level " + Level;
   for( int i = TradeMgmtRetry; i > 0; i-- )
   {
      RefreshRates( );
      double Price = NormalizeDouble( MarketInfo( Pair, MODE_BID ), MarketInfo( Pair, MODE_DIGITS ) );
      int Ticket = OrderSend( Pair, OP_SELL, Lots, Price, 5, 0, 0, CommentStr, Magic, 0, Red );
      if( Ticket > 0 ) 
      {
         if( OrderSelect( Ticket, SELECT_BY_TICKET, MODE_TRADES ) ) 
            Print( "SELL order #", OrderTicket( ), " opened at ", OrderOpenPrice( ), " :", TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS) );
         return( Ticket );
      }
      Sleep( 3000 );
   } 
   string AlertMsg = "#2: Error opening SELL order; Error Code: "+GetLastError( )+": "+ErrorDescription( GetLastError( ) )+" :"+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS); 
   FailureAlert( AlertMsg );
   return( Ticket );
}

int GetLastBuyLevelNbr( string Pair, int Ticket, int Magic ) 
{
   string CommentStr;
   int LstLevel;
   if( OrderSelect( Ticket, SELECT_BY_TICKET ) == TRUE ) 
   {
      if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic ) 
      {
         CommentStr = OrderComment( );
         LstLevel = StrToInteger( StringSubstr( CommentStr, 18 ) );
      }
   }
   return ( LstLevel );
}

int GetLastSellLevelNbr( string Pair, int Ticket, int Magic ) 
{
   string CommentStr;
   int LstLevel;
   if( OrderSelect( Ticket, SELECT_BY_TICKET ) == TRUE ) 
   {
      if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic ) 
      {
         CommentStr = OrderComment( );
         LstLevel = StrToInteger( StringSubstr( CommentStr, 18 ) );
      }
   }
   return ( LstLevel );
}

int GetLastBuyTicket( string Pair, int Magic ) 
{
   int CurLstTicket;
   int LstTicket = 0;
   for ( int i = OrdersTotal( ) - 1; i >= 0; i-- ) 
   {
      OrderSelect( i, SELECT_BY_POS, MODE_TRADES );
      if( OrderSymbol( ) != Pair || OrderMagicNumber( ) != Magic ) continue;
      if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic && OrderType( ) == OP_BUY ) 
      {
         CurLstTicket = OrderTicket( );
         if( CurLstTicket > LstTicket ) LstTicket = CurLstTicket;
      }
   }
   return ( LstTicket );
}

int GetLastSellTicket( string Pair, int Magic ) 
{
   int CurLstTicket;
   int LstTicket = 0;
   for ( int i = OrdersTotal( ) - 1; i >= 0; i-- ) 
   {
      OrderSelect( i, SELECT_BY_POS, MODE_TRADES );
      if( OrderSymbol( ) != Pair || OrderMagicNumber( ) != Magic ) continue;
      if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic && OrderType( ) == OP_SELL ) 
      {
         CurLstTicket = OrderTicket( );
         if( CurLstTicket > LstTicket ) LstTicket = CurLstTicket;
      }
   }
   return ( LstTicket );
}

int GetBuyOrderCount( string Pair, int Magic ) 
{
   int Count = 0;
   for ( int i = OrdersTotal( ); i >= 0; i-- ) 
   {
      if( OrderSelect( i, SELECT_BY_POS ) == TRUE ) 
      {
         if( OrderSymbol( ) != Pair || OrderMagicNumber( ) != Magic ) continue;
         if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic && OrderType( ) == OP_BUY ) Count++;
      }
   }
   return ( Count );
}

int GetSellOrderCount( string Pair, int Magic ) 
{
   int Count = 0;
   for ( int i = OrdersTotal( ); i >= 0; i-- ) 
   {
      if( OrderSelect( i, SELECT_BY_POS ) == TRUE ) 
      {
         if( OrderSymbol( ) != Pair || OrderMagicNumber( ) != Magic ) continue;
         if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic && OrderType( ) == OP_SELL ) Count++;
      }
   }
   return ( Count );
}

int GetFloatingPip( int Mode ) 
{
   int TotalFloat;
   int BuyFloat;
   int SellFloat;
   int Ticket;
   if( Mode == 1 ) 
   {
      Ticket = GetLastBuyTicket( Pair1, MagicNo );
      BuyFloat = GetBuyFloat( Ticket, Pair1, MagicNo );
      Ticket = GetLastSellTicket( Pair2, MagicNo );
      SellFloat = GetSellFloat( Ticket, Pair2, MagicNo );
      TotalFloat = BuyFloat + SellFloat;
   }
   if( Mode == 2 ) 
   {
      Ticket = GetLastBuyTicket( Pair2, UniqueMagic );
      BuyFloat = GetBuyFloat( Ticket, Pair2, UniqueMagic );
      Ticket = GetLastSellTicket( Pair1, UniqueMagic );
      SellFloat = GetSellFloat( Ticket, Pair1, UniqueMagic );
      TotalFloat = BuyFloat + SellFloat;
   }
   return ( TotalFloat );
}

double GetFloatingUSD( int Mode ) 
{
   double TotalFloat;
   double BuyFloat;
   double SellFloat;
   int Ticket;
   if( Mode == 1 ) 
   {
      Ticket = GetLastBuyTicket( Pair1, MagicNo );
      BuyFloat = GetBuyFloatUSD( Ticket, Pair1, MagicNo );
      Ticket = GetLastSellTicket( Pair2, MagicNo );
      SellFloat = GetSellFloatUSD( Ticket, Pair2, MagicNo );
      TotalFloat = BuyFloat + SellFloat;
   }
   if( Mode == 2 ) 
   {
      Ticket = GetLastBuyTicket( Pair2, UniqueMagic );
      BuyFloat = GetBuyFloatUSD( Ticket, Pair2, UniqueMagic );
      Ticket = GetLastSellTicket( Pair1, UniqueMagic );
      SellFloat = GetSellFloatUSD( Ticket, Pair1, UniqueMagic );
      TotalFloat = BuyFloat + SellFloat;
   }
   return ( TotalFloat );
}

int GetBuyFloat( int Ticket, string Pair, int Magic ) 
{
   int Pips;
   if( Ticket != 0 ) {
      if( OrderSelect( Ticket, SELECT_BY_TICKET ) == TRUE ) 
      {
         if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic ) 
            Pips = ( MarketInfo( Pair, MODE_BID ) - OrderOpenPrice( ) ) / MarketInfo( Pair, MODE_POINT );
      } 
      else 
      {
         string AlertMsg = "#3: GetBuyFloat - Select Buy Open Order no "+ Ticket+ ": "+ "  Error Code: "+ GetLastError( )+ ": "+ ErrorDescription( GetLastError( ) );
         FailureAlert( AlertMsg );
      }
   }
   return ( Pips );
}

int GetSellFloat( int Ticket, string Pair, int Magic ) 
{
   int Pips;
   if( Ticket != 0 ) {
      if( OrderSelect( Ticket, SELECT_BY_TICKET ) == TRUE ) 
      {
         if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic ) 
            Pips = ( OrderOpenPrice( ) - MarketInfo( Pair, MODE_ASK ) ) / MarketInfo( Pair, MODE_POINT );
      } 
      else 
      {
         string AlertMsg = "#4: GetSellFloat - Select Sell Open Order no "+ Ticket+ ": Error Code: "+ GetLastError( )+ ": "+ ErrorDescription( GetLastError( ) );
         FailureAlert( AlertMsg );
      }
   }
   return ( Pips );
}

double GetBuyFloatUSD( int Ticket, string Pair, int Magic ) 
{
   double Dlrs;
   if( Ticket != 0 ) {
      if( OrderSelect( Ticket, SELECT_BY_TICKET ) == TRUE ) 
      {
         if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic ) Dlrs = OrderProfit( ) + OrderSwap( ) + OrderCommission( );
      } 
      else 
      {
         string AlertMsg = "#5: GetBuyFloatUSD- Select Buy Open Order no "+ Ticket+ ": Error Code: "+ GetLastError( )+ ": "+ ErrorDescription( GetLastError( ) );
         FailureAlert( AlertMsg );
      }
   }
   return ( Dlrs );
}

double GetSellFloatUSD( int Ticket, string Pair, int Magic ) 
{
   double Dlrs;
   if( Ticket != 0 ) 
   {
      if( OrderSelect( Ticket, SELECT_BY_TICKET ) == TRUE ) 
      {
         if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic ) Dlrs = OrderProfit( ) + OrderSwap( ) + OrderCommission( );
      } 
      else 
      {
         string AlertMsg = "#6: GetSellFloatUSD- Select Sell Open Order no "+ Ticket+ ": Error Code: "+ GetLastError( )+ ": "+ ErrorDescription( GetLastError( ) );
         Print( AlertMsg );
         FailureAlert( AlertMsg );
      }
   }
   return ( Dlrs );
}

double GetTotalLotBuy( string Pair, int Magic ) 
{
   double Lots = 0;
   for ( int i = OrdersTotal( ); i >= 0; i-- ) {
      if( OrderSelect( i, SELECT_BY_POS ) == TRUE ) {
         if( OrderSymbol( ) != Pair || OrderMagicNumber( ) != Magic ) continue;
         if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic && OrderType( ) == OP_BUY ) Lots += OrderLots( );
      }
   }
   return ( Lots );
}

double GetTotalLotSell( string Pair, int Magic ) 
{
   double Lots = 0;
   for ( int i = OrdersTotal( ); i >= 0; i-- ) {
      if( OrderSelect( i, SELECT_BY_POS ) == TRUE ) {
         if( OrderSymbol( ) != Pair || OrderMagicNumber( ) != Magic ) continue;
         if( OrderSymbol( ) == Pair && OrderMagicNumber( ) == Magic && OrderType( ) == OP_SELL ) Lots += OrderLots( );
      }
   }
   return ( Lots );
}

bool CloseLastBuy( int Ticket, string Pair ) 
{
   if( OrderSelect( Ticket, SELECT_BY_TICKET ) == TRUE ) 
   {
      for( int i = TradeMgmtRetry; i > 0; i-- )
      {
         if( OrderClose( OrderTicket( ), OrderLots( ), NormalizeDouble( MarketInfo( Pair, MODE_BID ), 12 ), 5, MediumBlue ) )
         {
            Print( "The Last Buy ",Pair," order is closed: ", TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS) );
            return( TRUE );
         }
         Sleep(3000);
      }
      string AlertMsg = "#7: Error when close the Last "+Pair+" Buy order; Error Code: "+ GetLastError( )+ ": "+ ErrorDescription( GetLastError( ) )+ ": "+ TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS);
      Print( AlertMsg );
      FailureAlert( AlertMsg );
      return ( FALSE );
   }
   AlertMsg = "#8: Last "+Pair+" Buy order with Ticket "+Ticket+" was not found: "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS); 
   FailureAlert( AlertMsg );
}

bool CloseLastSell( int Ticket, string Pair ) 
{
   if( OrderSelect( Ticket, SELECT_BY_TICKET ) == TRUE ) 
   {
      for( int i = TradeMgmtRetry; i > 0; i-- )
      {
         if( OrderClose( OrderTicket( ), OrderLots( ), NormalizeDouble( MarketInfo( Pair, MODE_BID ), 12 ), 5, Pink ) )
         {
            Print( "The Last Sell ",Pair," order is closed: ", TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS) );
            return( TRUE );
         }
         Sleep(3000);
      }
      string AlertMsg = "#9: Error when closing the Last Sell "+Pair+" order; Error Code: "+ GetLastError( )+ ": "+ ErrorDescription( GetLastError( ) )+ ": "+ TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS); 
      Print( AlertMsg );
      FailureAlert( AlertMsg );
      return ( FALSE );
   }
   AlertMsg = "#10: Last "+Pair+"Buy order with Ticket "+Ticket+" was not found: "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS); 
   FailureAlert( AlertMsg );
}
void FailureAlert( string msg )
{
   Print( msg );
   // Email msg
   // Beep
   // SMS Msg
}
string ErrorDescription( int err ) 
{
   string ErrorType;
   switch ( err )    
   {
      case 0:
         ErrorType = "no error";
      case 1:
         ErrorType = "no error";
         break;
      case 2:
         ErrorType = "common error";
         break;
      case 3:
         ErrorType = "invalid trade parameters";
         break;
      case 4:
         ErrorType = "trade server is busy";
         break;
      case 5:
         ErrorType = "old version of the client terminal";
         break;
      case 6:
         ErrorType = "no connection with trade server";
         break;
      case 7:
         ErrorType = "not enough rights";
         break;
      case 8:
         ErrorType = "too frequent requests";
         break;
      case 9:
         ErrorType = "malfunctional trade operation";
         break;
      case 64:
         ErrorType = "account disabled";
         break;
      case 65:
         ErrorType = "invalid account";
         break;
      case 128:
         ErrorType = "trade timeout";
         break;
      case 129:
         ErrorType = "invalid price";
         break;
      case 130:
         ErrorType = "invalid stops";
         break;
      case 131:
         ErrorType = "invalid trade volume";
         break;
      case 132:
         ErrorType = "market is closed";
         break;
      case 133:
         ErrorType = "trade is disabled";
         break;
      case 134:
         ErrorType = "not enough money";
         break;
      case 135:
         ErrorType = "price changed";
         break;
      case 136:
         ErrorType = "off quotes";
         break;
      case 137:
         ErrorType = "broker is busy";
         break;
      case 138:
         ErrorType = "requote";
         break;
      case 139:
         ErrorType = "order is locked";
         break;
      case 140:
         ErrorType = "long positions only allowed";
         break;
      case 141:
         ErrorType = "too many requests";
         break;
      case 145:
         ErrorType = "modification denied because order too close to market";
         break;
      case 146:
         ErrorType = "trade context is busy";
         break;
      case 4000:
         ErrorType = "no error";
         break;
      case 4001:
         ErrorType = "wrong function pointer";
         break;
      case 4002:
         ErrorType = "array index is out of range";
         break;
      case 4003:
         ErrorType = "no memory for function call stack";
         break;
      case 4004:
         ErrorType = "recursive stack overflow";
         break;
      case 4005:
         ErrorType = "not enough stack for parameter";
         break;
      case 4006:
         ErrorType = "no memory for parameter string";
         break;
      case 4007:
         ErrorType = "no memory for temp string";
         break;
      case 4008:
         ErrorType = "not initialized string";
         break;
      case 4009:
         ErrorType = "not initialized string in array";
         break;
      case 4010:
         ErrorType = "no memory for array\' string";
         break;
      case 4011:
         ErrorType = "too long string";
         break;
      case 4012:
         ErrorType = "remainder from zero divide";
         break;
      case 4013:
         ErrorType = "zero divide";
         break;
      case 4014:
         ErrorType = "unknown command";
         break;
      case 4015:
         ErrorType = "wrong jump ( never generated error )";
         break;
      case 4016:
         ErrorType = "not initialized array";
         break;
      case 4017:
         ErrorType = "dll calls are not allowed";
         break;
      case 4018:
         ErrorType = "cannot load library";
         break;
      case 4019:
         ErrorType = "cannot call function";
         break;
      case 4020:
         ErrorType = "expert function calls are not allowed";
         break;
      case 4021:
         ErrorType = "not enough memory for temp string returned from function";
         break;
      case 4022:
         ErrorType = "system is busy ( never generated error )";
         break;
      case 4050:
         ErrorType = "invalid function parameters count";
         break;
      case 4051:
         ErrorType = "invalid function parameter value";
         break;
      case 4052:
         ErrorType = "string function internal error";
         break;
      case 4053:
         ErrorType = "some array error";
         break;
      case 4054:
         ErrorType = "incorrect series array using";
         break;
      case 4055:
         ErrorType = "custom indicator error";
         break;
      case 4056:
         ErrorType = "arrays are incompatible";
         break;
      case 4057:
         ErrorType = "global variables processing error";
         break;
      case 4058:
         ErrorType = "global variable not found";
         break;
      case 4059:
         ErrorType = "function is not allowed in testing mode";
         break;
      case 4060:
         ErrorType = "function is not confirmed";
         break;
      case 4061:
         ErrorType = "send mail error";
         break;
      case 4062:
         ErrorType = "string parameter expected";
         break;
      case 4063:
         ErrorType = "integer parameter expected";
         break;
      case 4064:
         ErrorType = "double parameter expected";
         break;
      case 4065:
         ErrorType = "array as parameter expected";
         break;
      case 4066:
         ErrorType = "requested history data in update state";
         break;
      case 4099:
         ErrorType = "end of file";
         break;
      case 4100:
         ErrorType = "some file error";
         break;
      case 4101:
         ErrorType = "wrong file name";
         break;
      case 4102:
         ErrorType = "too many opened files";
         break;
      case 4103:
         ErrorType = "cannot open file";
         break;
      case 4104:
         ErrorType = "incompatible access to a file";
         break;
      case 4105:
         ErrorType = "no order selected";
         break;
      case 4106:
         ErrorType = "unknown symbol";
         break;
      case 4107:
         ErrorType = "invalid price parameter for trade function";
         break;
      case 4108:
         ErrorType = "invalid ticket";
         break;
      case 4109:
         ErrorType = "trade is not allowed";
         break;
      case 4110:
         ErrorType = "longs are not allowed";
         break;
      case 4111:
         ErrorType = "shorts are not allowed";
         break;
      case 4200:
         ErrorType = "object is already exist";
         break;
      case 4201:
         ErrorType = "unknown object property";
         break;
      case 4202:
         ErrorType = "object is not exist";
         break;
      case 4203:
         ErrorType = "unknown object type";
         break;
      case 4204:
         ErrorType = "no object name";
         break;
      case 4205:
         ErrorType = "object coordinates error";
         break;
      case 4206:
         ErrorType = "no specified subwindow";
         break;
      default:
      ErrorType = "unknown error";   
   }
   return ( ErrorType );
}