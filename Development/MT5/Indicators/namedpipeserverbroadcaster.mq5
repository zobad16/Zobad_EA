//+------------------------------------------------------------------+
//|                                   NamedPipeServerBroadcaster.mq5 |
//|                                      Copyright 2010, Investeo.pl |
//|                                                http:/Investeo.pl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Investeo.pl"
#property link      "http:/Investeo.pl"
#property version   "1.00"
#property script_show_inputs
#include <CNamedPipes.mqh>

input int account = 0;

CNamedPipe pipe;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   bool tickReceived;
   int i=0;

   if(pipe.Create(account)==true)
      while(GlobalVariableCheck("gvar0")==false)
        {
         if(pipe.Connect()==true)
            Print("Pipe connected");
            i=0;
         while(true)
           {
            do
              {
               tickReceived=pipe.ReadTick();
               if(tickReceived==false)
                 {
                  if(kernel32::GetLastError()==ERROR_BROKEN_PIPE)
                    {
                     Print("Client disconnected from pipe "+pipe.GetPipeName());
                     pipe.Disconnect();
                     break;
                    }
                  } else  {
                   i++; Print(IntegerToString(i)+" ticks received BY server.");
                  string bidask=DoubleToString(pipe.incoming.bid)+";"+DoubleToString(pipe.incoming.ask);
                  long currChart=ChartFirst(); int chart=0;
                  while(chart<100) // We have certainly no more than CHARTS_MAX open charts
                    {
                     EventChartCustom(currChart,6666,0,(double)account,bidask);
                     currChart=ChartNext(currChart); // We have received a new chart from the previous
                     if(currChart==0) break;         // Reached the end of the charts list
                     chart++;// Do not forget to increase the counter
                    }
                     if(GlobalVariableCheck("gvar0")==true || (kernel32::GetLastError()==ERROR_BROKEN_PIPE)) break;
              
                 }
              }
            while(tickReceived==true);
            if(i>0)
              {
               Print(IntegerToString(i)+"ticks received.");
               i=0;
              };
            if(GlobalVariableCheck("gvar0")==true || (kernel32::GetLastError()==ERROR_BROKEN_PIPE)) break;
            Sleep(100);
           }

        }


  pipe.Close(); 
  }
//+------------------------------------------------------------------+

//Print("Time from pipe "+TimeToString(pipe.incoming.time)+"bid : "+DoubleToString(pipe.incoming.bid)+" ask: "+DoubleToString(pipe.incoming.ask));
//long currChart=ChartFirst();


//string bidask = DoubleToString(pipe.incoming.bid)+";"+DoubleToString(pipe.incoming.ask);
/*
         while(i<CHARTS_MAX)                  // We have certainly no more than CHARTS_MAX open charts
         {
          EventChartCustom(currChart,5000,i,pipe.incoming.bid,bidask);
            currChart=ChartNext(currChart); // We have received a new chart from the previous
            if(currChart==0) break;         // Reached the end of the charts list
            i++;// Do not forget to increase the counter
         }
         */
//+------------------------------------------------------------------+
