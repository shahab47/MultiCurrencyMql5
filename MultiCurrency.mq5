   #property link          "Shahab47"
   #property description   "Multi Symbol EA SuperTrend"
   #property strict
  
   //#include <StdLibErr.mqh>
   #include <Trade/Trade.mqh >
   CTrade trade;
   
   //INPUTS
   input string          TradeSymbols         = "AUDCAD|AUDJPY|AUDNZD|AUDUSD|EURUSD";                                         //Symbol(s) or ALL or CURRENT
   input string          TimeTrade            = "0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23";    //Trade Times ALL or Seperate Time With |
   input int             Periods              = 10;
   input double          Multiplier           = 3.0;
   input ENUM_TIMEFRAMES timeFrameTrigger;
   input ENUM_TIMEFRAMES timeFrameTrend;
   input bool            BBW                  =true;                                    //Active BBW 
   input int             highBBW              = 123;
   input int             lowBBW               = 76;
   input bool            CCI                  =true;                                    //Active CCI
   input int             CCIPeriod            =240;
   input double          MaxCciBuy            = -100;                                   //Max CCI Robot Buy : EX if -100 upper -100 dont trade
   input double          MinCciSell           = 100;                                    //Min CCI Robot Sell : EX if 100 under 100 dont trade
   
   
   //GENERAL GLOBALS   
   string   AllSymbolsString           = "XAUUSDb|AUDCADb|AUDJPYb|AUDNZDb|AUDUSDb|CADJPYb|EURAUDb|EURCADb|EURGBPb|EURJPYb|EURNZDb|EURUSDb|GBPAUDb|GBPCADb|GBPJPYb|GBPNZDb|GBPUSDb|NZDCADb|NZDJPYb|NZDUSDb|USDCADb|USDJPYb";
   string   AllTimeString              = "0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23";
   int      NumberOfTradeableSymbols; 
   int      NumberOfTradeableTime;             
   string   SymbolArray[];
   string   TimeArray[];                        
   int      TicksReceivedCount         = 0;
   
   
   //INDICATOR HANDLES
   int handle_SuperTrend[]; 
   int handle_BBW[];
   int handle_CCI[];
   //Place additional indicator handles here as required 

   //OPEN TRADE ARRAYS
   ulong    OpenTradeOrderTicket[];    //To store 'order' ticket for trades
   //Place additional trade arrays here as required to assist with open trade management
   
   int OnInit()
   {
      if(TradeSymbols == "CURRENT")  //Override TradeSymbols input variable and use the current chart symbol only
      {
         NumberOfTradeableSymbols = 1;
         
         ArrayResize(SymbolArray, 1);
         SymbolArray[0] = Symbol(); 

         Print("EA will process ", SymbolArray[0], " only");
      }
      else
      {  
         string TradeSymbolsToUse = "";
         
         if(TradeSymbols == "ALL")
            TradeSymbolsToUse = AllSymbolsString;
         else
            TradeSymbolsToUse = TradeSymbols;
         
         //CONVERT TradeSymbolsToUse TO THE STRING ARRAY SymbolArray
         NumberOfTradeableSymbols = StringSplit(TradeSymbolsToUse, '|', SymbolArray);
         Print("EA will process: ", TradeSymbolsToUse);
      } 
      
      //----------------------------
      
         string TradeTimeToUse = "";
         if(TimeTrade != "ALL"){
                  TradeTimeToUse    = TimeTrade;
                  NumberOfTradeableTime = StringSplit(TradeTimeToUse, '|', TimeArray);
                  Print("EA Time Range: ", TradeTimeToUse);
            }
        
        //----------------------
      //RESIZE OPEN TRADE ARRAYS (based on how many symbols are being traded)
      
      ResizeCoreArrays();
      
      //RESIZE INDICATOR HANDLE ARRAYS
      ResizeIndicatorHandleArrays();
      Print("All arrays sized to accomodate ", NumberOfTradeableSymbols, " symbols");
      
      //INITIALIZE ARAYS
      for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
         OpenTradeOrderTicket[SymbolLoop] = 0;
      
      //INSTANTIATE INDICATOR HANDLES
      if(!SetUpIndicatorHandles())return(INIT_FAILED);
      //
      return(INIT_SUCCEEDED);     
   }
   
   void OnDeinit(const int reason)
   {
      Comment("\n\rMulti-Symbol EA Stopped");
   }

   void OnTick()
   {
      TicksReceivedCount++;
      string indicatorMetrics = "";
      
      bool conditionTimeRange = true;
      
      if(TimeTrade != "ALL"){
         
         for(int TimeLoop=0;TimeLoop<NumberOfTradeableTime;TimeLoop++)
              {
               string currentTimeforCheck = TimeArray[TimeLoop];
               MqlDateTime mdt;
               TimeCurrent(mdt);
               if(currentTimeforCheck == mdt.hour)
                 {
                  conditionTimeRange = true;
                  Print("Current Time for Check = ",currentTimeforCheck,"mdt.hour = ",mdt.hour);
                  break;
                 }else conditionTimeRange = false;
                 
              }
              
      }
      
      //LOOP THROUGH EACH SYMBOL TO CHECK FOR ENTRIES AND EXITS, AND THEN OPEN/CLOSE TRADES AS APPROPRIATE
      for(int SymbolLoop = 0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
      {
         string currentSymbol = SymbolArray[SymbolLoop];
         bool newbarTrigger = IsNewBar(currentSymbol,timeFrameTrigger);
         if(newbarTrigger)
           {
               //Print("Found New Bar .... ");
               string CurrentIndicatorValues; //passed by ref below
            
               //GET OPEN SIGNAL (BOLLINGER BANDS SIMPLY USED AS AN EXAMPLE)
               if(conditionTimeRange == true)
                 {
                     string OpenSignalStatus = GetSTrendOpenSignalStatus(SymbolLoop, CurrentIndicatorValues);      
                     StringConcatenate(indicatorMetrics, indicatorMetrics, SymbolArray[SymbolLoop], "  |  ", CurrentIndicatorValues, "  |  OPEN_STATUS=", OpenSignalStatus, "  |  ");
                 }
               
               
               //GET CLOSE SIGNAL (BOLLINGER BANDS SIMPLY USED AS AN EXAMPLE)
               //string CloseSignalStatus = GetSTrendCloseSignalStatus(SymbolLoop);
               //StringConcatenate(indicatorMetrics, indicatorMetrics, "CLOSE_STATUS=", CloseSignalStatus, "\n\r");
               GetSTrendCloseSignalStatus(SymbolLoop);
               
               //PROCESS TRADE OPENS
               //if((OpenSignalStatus == "LONG" || OpenSignalStatus == "SHORT") && OpenTradeOrderTicket[SymbolLoop] == 0)
                  //ProcessTradeOpen(SymbolLoop, OpenSignalStatus);
               
               //PROCESS TRADE CLOSURES
               //else if((CloseSignalStatus == "CLOSE_LONG" || CloseSignalStatus == "CLOSE_SHORT") && OpenTradeOrderTicket[SymbolLoop] != 0)
                  //ProcessTradeClose(SymbolLoop, CloseSignalStatus);
           }
         
      }
      
      //OUTPUT INFORMATION AND METRICS TO THE CHART (No point wasting time on this code if in the Strategy Tester)
      if(!MQLInfoInteger(MQL_TESTER))
         OutputStatusToChart(indicatorMetrics);   
   }
   
   void ResizeCoreArrays()
   {
      ArrayResize(OpenTradeOrderTicket, NumberOfTradeableSymbols);
      //Add other trade arrays here as required
   }
 
   void ResizeIndicatorHandleArrays()
   {
      //Indicator Handles
      //h
      //ArrayResize(handle_BollingerBands, NumberOfTradeableSymbols);
      ArrayResize(handle_SuperTrend,NumberOfTradeableSymbols);
      ArrayResize(handle_BBW,NumberOfTradeableSymbols);
      ArrayResize(handle_CCI,NumberOfTradeableSymbols);
      //Add other indicators here as required by your EA
   }
   
   //SET UP REQUIRED INDICATOR HANDLES (arrays because of multi-symbol capability in EA)
   bool SetUpIndicatorHandles()
   {  
      //Supertrend 
      for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
      {
         //Reset any previous error codes so that only gets set if problem setting up indicator handle
         ResetLastError();
         //h
         //handle_BollingerBands[SymbolLoop] = iBands(SymbolArray[SymbolLoop], Period(), BBandsPeriods, 0, BBandsDeviations, PRICE_CLOSE);
         handle_SuperTrend[SymbolLoop]= iCustom(SymbolArray[SymbolLoop],timeFrameTrigger,"Supertrend.ex5",Periods,Multiplier);
         if(handle_SuperTrend[SymbolLoop] == INVALID_HANDLE) messageINVALID("SuperTrend",SymbolArray[SymbolLoop]);
         
        if(BBW)
          {
            handle_BBW[SymbolLoop]= iCustom(SymbolArray[SymbolLoop],timeFrameTrigger,"bbandwidth.ex5",20,0,2);
            if(handle_BBW[SymbolLoop] == INVALID_HANDLE) messageINVALID("BBW",SymbolArray[SymbolLoop]);
          }
          
        if(CCI)
          {
           handle_CCI[SymbolLoop]= iCustom(SymbolArray[SymbolLoop],timeFrameTrigger,"CCI Color.ex5",CCIPeriod,100,-100);
           if(handle_CCI[SymbolLoop] == INVALID_HANDLE) messageINVALID("CCI",SymbolArray[SymbolLoop]);
          }
         
         
         
         
         
         Print("Handle for Supertrend / ", SymbolArray[SymbolLoop], " / ", EnumToString(Period()), " successfully created");
      }
      
      //All completed without errors so return true
      return true;
   }
   
   string GetSTrendOpenSignalStatus(int SymbolLoop, string& signalDiagnosticMetrics)
   {
      string CurrentSymbol = SymbolArray[SymbolLoop];
      
      //Need to copy values from indicator buffers to local buffers
      int    numValuesNeededST = 3;
      
      double valueSt[];

      bool fillSuccessNowCandleSt = tlamCopyBuffer(handle_SuperTrend[SymbolLoop], 0, valueSt, numValuesNeededST, CurrentSymbol, "SuperTrendValue");
      if(fillSuccessNowCandleSt    == false)                   return("FILL_ERROR");     //No need to log error here. Already done from tlamCopyBuffer() function
      
      
      
  
      double TwoPreClose = iClose(CurrentSymbol, Period(), 2);
      double TwoPreSt = valueSt[2];
      double onePreClose = iClose(CurrentSymbol, Period(), 1);
      double onePreSt = valueSt[1];
      
      long digits = SymbolInfoInteger(CurrentSymbol,SYMBOL_DIGITS);
      double newSL = NormalizeDouble(valueSt[1],digits);  
      //SET METRICS FOR BBANDS WHICH GET RETURNED TO CALLING FUNCTION BY REF FOR OUTPUT TO CHART
      //StringConcatenate(signalDiagnosticMetrics, "ST 0 =", DoubleToString(valueSt[0], (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)), "  |  ST 1=", DoubleToString(valueSt[1], (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)), "  |  CLOSE=" + DoubleToString(CurrentClose, (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS)));
     
      
      //INSERT YOUR OWN ENTRY LOGIC HERE
      //e.g.
      
      
      
      if(TwoPreClose>TwoPreSt && onePreClose<onePreSt){
         string resultOC = OtherCondition(CurrentSymbol,SymbolLoop);
         if(resultOC == "OCSell" || resultOC == "Trade")trade.Sell(0.01,CurrentSymbol,SYMBOL_ASK,newSL);
         //Print("TwoPreSt = ",TwoPreSt," TwoPreClose = ",TwoPreClose," onePreSt = ",onePreSt," onePreClose = ",onePreClose);
         return("SHORT");   
      }else if(TwoPreClose<TwoPreSt && onePreClose>onePreSt)
         {
            string resultOC = OtherCondition(CurrentSymbol,SymbolLoop);
            if(resultOC == "OCBuy"|| resultOC == "Trade")trade.Buy(0.01,CurrentSymbol,SYMBOL_ASK,newSL);
            //Print("TwoPreSt = ",TwoPreSt," TwoPreClose = ",TwoPreClose," onePreSt = ",onePreSt," onePreClose = ",onePreClose);
            return("LONG");
       }else return("NO_TRADE");
        
        
                  
   }
   
   void GetSTrendCloseSignalStatus(int SymbolLoop)
   {
      string CurrentSymbol = SymbolArray[SymbolLoop];
      
      
      
      //Need to copy values from indicator buffers to local buffers
      int    numValuesNeeded = 3;
      double valueSt[];
      
      
      bool fillSuccessNowCandleSt = tlamCopyBuffer(handle_SuperTrend[SymbolLoop], 0, valueSt, numValuesNeeded, CurrentSymbol, "SuperTrendValue");
      
         
      
      if(PositionSelect(CurrentSymbol)&& fillSuccessNowCandleSt != false)
        {
         long digits = SymbolInfoInteger(CurrentSymbol,SYMBOL_DIGITS);
         double newSL = NormalizeDouble(valueSt[1],digits);
         
         //newSL = NormalizeDouble(newSL,_Digits); 
         double aSK = (SymbolInfoDouble(CurrentSymbol,SYMBOL_ASK));
         //aSK = NormalizeDouble(aSK,_Digits);
         double bID = (SymbolInfoDouble(CurrentSymbol,SYMBOL_BID));
         //bID = NormalizeDouble(bID,_Digits);
         //tpForBuy =NormalizeDouble(tpForBuy,_Digits);
         double posSL = PositionGetDouble(POSITION_SL);
         //posSL =NormalizeDouble(posSL,_Digits);
         //FOR CHECK IN BUY POSITION SL<BID AND IN SELL POSITION SL>
         double askPriceModify = SymbolInfoDouble(CurrentSymbol,SYMBOL_ASK);
         double bidPriceModify = SymbolInfoDouble(CurrentSymbol,SYMBOL_BID);
         //inja fasele e ro az gheymat bid taeen kardim be darsad ke vaghti gheymat stop loss ma farghe chandani nadsht ba stoploss ghabli kari anjam nade ....
         double distanceFromBid = bID*0.002;
         double distanceFromAsk = aSK*0.002;
         double spreadinmodify = askPriceModify - bidPriceModify;
         bool chkBuyPosition = PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
         bool chkSellPostion = PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL;
         //Print("PositionSelect(symbol) = ",PositionSelect(CurrentSymbol)," symbol = ",CurrentSymbol," BidPriceModify = ",bidPriceModify," bID - distanceFromBid = ",bID - distanceFromBid," New sl = ",newSL," oldSl = ",posSL," BUY = ",chkBuyPosition," Sell = ",chkSellPostion);
         if(chkBuyPosition)
           {
            if(newSL>posSL && newSL<bidPriceModify)
               {
            
               double tpForBuy = aSK+(aSK-newSL);      
               
               Print("i Want to modify Buy Position ",CurrentSymbol," in SL = ",newSL," And TP = ",tpForBuy," Ask Price is = ",askPriceModify," Bid Price is = ",bidPriceModify," Spread is = ",spreadinmodify," bidPriceModify - distanceFromBid = ",bidPriceModify - distanceFromBid);
               trade.PositionModify(CurrentSymbol,newSL,0);
               
              }
           }else if(chkSellPostion)
                   {
                     if(newSL<posSL && newSL>askPriceModify )
                      {
                     
                        //Print("i Want to modify Sell Position ",CurrentSymbol," in SL = ",newSL," And TP = ",tpForSell," Ask Price is = ",askPriceModify," Bid Price is = ",bidPriceModify," askPriceModify + distanceFromAsk = ",askPriceModify + distanceFromAsk);
                        trade.PositionModify(CurrentSymbol,newSL,0);
                       }
                   }
        }
      
   }
   
   bool tlamCopyBuffer(int ind_handle,            // handle of the indicator 
                       int buffer_num,            // for indicators with multiple buffers
                       double &localArray[],      // local array 
                       int numBarsRequired,       // number of values to copy 
                       string symbolDescription,  
                       string indDesc)
   {
      
      
      
      int availableBars;
      bool success = false;
      int failureCount = 0;
      
      //Sometimes a delay in prices coming through can cause failure, so allow 3 attempts
      while(!success)
      {
         availableBars = BarsCalculated(ind_handle);
         //Print("I AM IN ");
         if(availableBars < numBarsRequired)
         {
            failureCount++;
            
            if(failureCount >= 3)
            {
               Print("Failed to calculate sufficient bars in tlamCopyBuffer() after ", failureCount, " attempts (", symbolDescription, "/", indDesc, " - Required=", numBarsRequired, " Available=", availableBars, ")");
               return(false);
            }
            
            Print("Attempt ", failureCount, ": Insufficient bars calculated for ", symbolDescription, "/", indDesc, "(Required=", numBarsRequired, " Available=", availableBars, ")");
            
            //Sleep for 0.1s to allow time for price data to become usable
            Sleep(100);
         }
         else
         {
            success = true;
            
            if(failureCount > 0) //only write success message if previous failures registered
               Print("Succeeded on attempt ", failureCount+1);
         }
      }
       
      ResetLastError(); 
      
      int numAvailableBars = CopyBuffer(ind_handle, buffer_num, 0, numBarsRequired, localArray);
      
      if(numAvailableBars != numBarsRequired) 
      { 
         Print("Failed to copy data from indicator with error code ", GetLastError(), ". Bars required = ", numBarsRequired, " but bars copied = ", numAvailableBars);
         return(false); 
      } 
      
      //Ensure that elements indexed like in a timeseries (with index 0 being the current, 1 being one bar back in time etc.)
      ArraySetAsSeries(localArray, true);
      
      return(true); 
   }
   
   void ProcessTradeOpen(int SymbolLoop, string TradeDirection)
   {
      string CurrentSymbol = SymbolArray[SymbolLoop];
      
      //INSERT YOUR PRE-CHECKS HERE
      
      //SETUP MqlTradeRequest orderRequest and MqlTradeResult orderResult HERE 
      //Ensure that CurrentSymbol is used as the symbol 
      
      //bool success = OrderSend(orderRequest, orderResult);
      
      //CHECK FOR ERRORS AND HANDLE EXCEPTIONS HERE
      
      //SET TRADE ARRAY TO PREVENT FUTURE TRADES BEING OPENED UNTIL THIS IS CLOSED
      //OpenTradeOrderTicket[SymbolLoop] = orderResult.order;
   }
   
   void ProcessTradeClose(int SymbolLoop, string CloseDirection)
   {
      string CurrentSymbol = SymbolArray[SymbolLoop];
      
      //INCLUSE PRE-CLOSURE CHECKS HERE
      
      //SETUP CTrade tradeObject HERE
         
      //bool bCloseCheck = tradeObject.PositionClose(OpenTradeOrderTicket[SymbolLoop], 0); 
      
      //CHECK FOR ERRORS AND HANDLE EXCEPTIONS HERE
      
      //IF SUCCESSFUL SET TRADE ARRAY TO 0 TO ALLOW FUTURE TRADES TO BE OPENED
      //OpenTradeOrderTicket[SymbolLoop] = 0;
   }
   
   void OutputStatusToChart(string additionalMetrics)
   {      
      //GET GMT OFFSET OF MT5 SERVER
      double offsetInHours = (TimeCurrent() - TimeGMT()) / 3600.0;
 
      //SYMBOLS BEING TRADED
      string symbolsText = "SYMBOLS BEING TRADED: ";
      for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
         StringConcatenate(symbolsText, symbolsText, " ", SymbolArray[SymbolLoop]);
      
      Comment("\n\rMT5 SERVER TIME: ", TimeCurrent(), " (OPERATING AT UTC/GMT", StringFormat("%+.1f", offsetInHours), ")\n\r\n\r",
               Symbol(), " TICKS RECEIVED: ", TicksReceivedCount, "\n\r\n\r",
               symbolsText,
               "\n\r\n\r", additionalMetrics);
   }
   
   bool IsNewBar(string currentSymbol,ENUM_TIMEFRAMES timeframe)
   {
      static datetime lastBar;
      return lastBar != (lastBar = iTime(currentSymbol, timeframe, 0)
      );
   }
   /*
   void FindMul(string symbolGlobal)
  {

   long digits = SymbolInfoInteger(symbolGlobal,SYMBOL_DIGITS);
   double mul;
   switch(digits)
     {
      case  1:
         mul = 1;
         break;
      case  2:
         mul = 0.1;
         break;
      case  3:
         mul = 0.01;
         break;
      case  4:
         mul = 0.001;
         break;
      case  5:
         mul = 0.0001;
         break;
      default:
         mul = 0.00001;
         break;
     }
   mulGlobal = mul;
  }*/
  
  
  bool messageINVALID(string handle,string symbol){
      string outputMessage = "";
               
      if(GetLastError() == 4302)
         outputMessage = "Symbol needs to be added to the MarketWatch";
      else
         StringConcatenate(outputMessage, "(error code ", GetLastError(), ")");
   
      MessageBox("Failed to create handle of the ",handle," indicator for " + symbol + "/" + EnumToString(Period()) + "\n\r\n\r" + 
                  outputMessage +
                  "\n\r\n\rEA will now terminate.");
                   
      //Don't proceed
      return false;
  }
  
  string OtherCondition(string CurrentSymbol,int SymbolLoop){
      string rsOC;
      bool BBWConditon =false;
      if(BBW){
         int    numValuesNeededBBW = 1;
         double valueBBW[];
         bool fillSuccessNowCandleStBBW = tlamCopyBuffer(handle_BBW[SymbolLoop], 0, valueBBW, numValuesNeededBBW, CurrentSymbol, "BBWValue");
         if(fillSuccessNowCandleStBBW == false) return("FILL_ERROR");
         if(lowBBW<valueBBW[0]&&valueBBW[0]<highBBW)
           {
            BBWConditon =true;
           }
      }
      
      bool CCIConditonBuy = false;
      bool CCIConditonSell = false;
      
      if(CCI){
         int    numValuesNeededCCI = 3;
         double valueCCI[];
         bool fillSuccessNowCandleStCCI = tlamCopyBuffer(handle_CCI[SymbolLoop], 0, valueCCI, numValuesNeededCCI, CurrentSymbol, "CCIValue");
         if(fillSuccessNowCandleStCCI == false) return("FILL_ERROR");
         
         
         if(valueCCI[0]<MaxCciBuy)
           {
            Print("CCIConditon Buy - valueCCI[0] = ",valueCCI[0], " MaxCciBuy = ",MaxCciBuy);
            CCIConditonBuy =true;
            
           }else if(valueCCI[0]>MinCciSell)
                   {
                     Print("CCIConditon Sell - valueCCI[0] = ",valueCCI[0], " MinCciSell = ",MinCciSell);
                    CCIConditonSell =true;
                   }
      }
      
       
      // return("OCSell");
      // return("OCBuy"); 
      
      if(rsOC == NULL && BBW==false && BBWConditon ==false && CCI == false){
         rsOC = "Trade";
      }
      if(rsOC == NULL && BBW==true && BBWConditon ==true && CCI == false){
         rsOC = "Trade";
      }
      
      if(rsOC == NULL && BBW==true   && BBWConditon ==false ){
         rsOC ="NoTrade";
      }
      
      if(rsOC == NULL && BBW==false  && CCI == true && CCIConditonBuy ==true){
         rsOC = "OCBuy";
      }
      
      if(rsOC == NULL && BBW==false  && CCI == true && CCIConditonSell ==true){
         rsOC = "OCSell";
      }
      
      if(rsOC == NULL && BBW==true && BBWConditon ==true  && CCI == true && CCIConditonBuy ==true){
         rsOC = "OCBuy";
      }
      
      if(rsOC == NULL && BBW==true && BBWConditon ==true  && CCI == true && CCIConditonSell ==true){
         rsOC = "OCSell";
      }
      
      
      Print(rsOC);
      return rsOC;
  }