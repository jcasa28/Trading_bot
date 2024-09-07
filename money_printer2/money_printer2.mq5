//+------------------------------------------------------------------+
//|                                               money_printer2.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
CTrade trade;

double stopLossPips = 3000;
double takeProfitPips = 6000;
double RiskPercentage = 2;

double CalculateLotSize()
{
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = accountBalance * (RiskPercentage / 100.0);
    double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lotSize = riskAmount / (stopLossPips * pipValue);

    // Normalize lot size to the nearest allowable lot
    lotSize = NormalizeDouble(lotSize, 2);  // Assuming 2 decimal places for lot size

    // Ensure lot size is within broker's allowed range
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    if (lotSize < minLot)
        lotSize = minLot;
    else if (lotSize > maxLot)
        lotSize = maxLot;
    else
        lotSize = MathFloor(lotSize / lotStep) * lotStep;

    return lotSize;
}

void OnTick()
{
    double lotSize = CalculateLotSize();
    Print("lotSize: ", lotSize);

    double current_bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
    double current_ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);

    // Price array
    MqlRates PriceInfo[];
    ArraySetAsSeries(PriceInfo, true);

    // Arrays for Moving Averages
    double EMA9Array_H4[], MA18Array_H4[], MA200Array_H4[];
    double EMA9Array_H1[], MA18Array_H1[], MA200Array_H1[];
    double EMA9Array_M5[], MA18Array_M5[], MA200Array_M5[];
    double EMA9Array_M15[], MA18Array_M15[];

    // Calculate EMAs and MAs in different timeframes
    int ema_9_H4 = iMA(_Symbol, PERIOD_H4, 9, 0, MODE_EMA, PRICE_CLOSE);
    int ma_18_H4 = iMA(_Symbol, PERIOD_H4, 18, 0, MODE_SMA, PRICE_CLOSE);
    int ma_200_H4 = iMA(_Symbol, PERIOD_H4, 200, 0, MODE_SMA, PRICE_CLOSE);

    int ema_9_H1 = iMA(_Symbol, PERIOD_H1, 9, 0, MODE_EMA, PRICE_CLOSE);
    int ma_18_H1 = iMA(_Symbol, PERIOD_H1, 18, 0, MODE_SMA, PRICE_CLOSE);
    int ma_200_H1 = iMA(_Symbol, PERIOD_H1, 200, 0, MODE_SMA, PRICE_CLOSE);

    int ema_9_M5 = iMA(_Symbol, PERIOD_M5, 9, 0, MODE_EMA, PRICE_CLOSE);
    int ma_18_M5 = iMA(_Symbol, PERIOD_M5, 18, 0, MODE_SMA, PRICE_CLOSE);
    int ma_200_M5 = iMA(_Symbol, PERIOD_M5, 200, 0, MODE_SMA, PRICE_CLOSE);

    int ema_9_M15 = iMA(_Symbol, PERIOD_M15, 9, 0, MODE_EMA, PRICE_CLOSE);
    int ma_18_M15 = iMA(_Symbol, PERIOD_M15, 18, 0, MODE_SMA, PRICE_CLOSE);

    // Sort the arrays for MAs
    ArraySetAsSeries(EMA9Array_H4, true);
    ArraySetAsSeries(MA18Array_H4, true);
    ArraySetAsSeries(MA200Array_H4, true);
    ArraySetAsSeries(EMA9Array_H1, true);
    ArraySetAsSeries(MA18Array_H1, true);
    ArraySetAsSeries(MA200Array_H1, true);
    ArraySetAsSeries(EMA9Array_M5, true);
    ArraySetAsSeries(MA18Array_M5, true);
    ArraySetAsSeries(MA200Array_M5, true);
    ArraySetAsSeries(EMA9Array_M15, true);
    ArraySetAsSeries(MA18Array_M15, true);

    // Fill the arrays with price data
    CopyBuffer(ema_9_H4, 0, 0, 10, EMA9Array_H4);
    CopyBuffer(ma_18_H4, 0, 0, 10, MA18Array_H4);
    CopyBuffer(ma_200_H4, 0, 0, 10, MA200Array_H4);
    //h1
    CopyBuffer(ema_9_H1, 0, 0, 10, EMA9Array_H1);
    CopyBuffer(ma_18_H1, 0, 0, 10, MA18Array_H1);
    CopyBuffer(ma_200_H1, 0, 0, 10, MA200Array_H1);
    //m5
    CopyBuffer(ema_9_M5, 0, 0, 10, EMA9Array_M5);
    CopyBuffer(ma_18_M5, 0, 0, 10, MA18Array_M5);
    CopyBuffer(ma_200_M5, 0, 0, 10, MA200Array_M5);
    //m15
    CopyBuffer(ema_9_M15, 0, 0, 10, EMA9Array_M15);
    CopyBuffer(ma_18_M15, 0, 0, 10, MA18Array_M15);

    Print("BID: ", current_bid);
    Print("ASK: ", current_ask);
    Print("Total Positions: ", PositionsTotal());

    Print("EMA 9 H4: ", EMA9Array_H4[0]);
    Print("MA 18 H4: ", MA18Array_H4[0]);
    Print("MA 200 M5: ", MA200Array_M5[0]);

    // Checking for signals
    static bool canTrade = false;
    // Buy signal
   bool isBuySignal=(EMA9Array_H4[0] > MA18Array_H4[0] && MA18Array_H4[0] > MA200Array_H4[0] &&
                        EMA9Array_H1[0] > MA18Array_H1[0] && MA18Array_H1[0] > MA200Array_H1[0] &&
                        EMA9Array_M5[0] > MA18Array_M5[0] && MA18Array_M5[0] > MA200Array_M5[0]);

    // Sell signal
    bool isSellSignal = (EMA9Array_H4[0] < MA18Array_H4[0] && MA18Array_H4[0] < MA200Array_H4[0] &&
                         EMA9Array_H1[0] < MA18Array_H1[0] && MA18Array_H1[0] < MA200Array_H1[0] &&
                         EMA9Array_M5[0] < MA18Array_M5[0] && MA18Array_M5[0] < MA200Array_M5[0]);

    // Get current server time
    MqlDateTime stm;
    datetime currentTime = TimeCurrent(stm);

    // Extract the hour (server time)
    int currentHour = stm.hour;
    Print("Current Time: ", currentTime);
    Print("Current hour: ", currentHour);

    // Define the start and end of the London and New York sessions in server time (assumed GMT here)
    int londonSessionStart = 8;   // 8 AM GMT
    int londonSessionEnd = 16;    // 4 PM GMT
    int newYorkSessionStart = 13; // 1 PM GMT
    int newYorkSessionEnd = 21;   // 9 PM GMT

    // Allow trading only during London or New York sessions
    bool isLondonSession = (currentHour >= londonSessionStart && currentHour < londonSessionEnd);
    bool isNewYorkSession = (currentHour >= newYorkSessionStart && currentHour < newYorkSessionEnd);

    if (isLondonSession || isNewYorkSession)
    {
        double StopLossBuy = current_ask - (stopLossPips * _Point);
        double StopLossSell = current_bid + (stopLossPips * _Point);

        // Check if there are no open orders
        if (PositionsTotal() == 0 && canTrade)
        {
            // Buy condition
            if (isBuySignal)
            {
                double buyPrice = current_ask;
                double stopLossPrice = NormalizeDouble(StopLossBuy, _Digits);
                double takeProfitPrice = NormalizeDouble(buyPrice + takeProfitPips * _Point, _Digits);
                trade.Buy(lotSize, _Symbol, buyPrice, stopLossPrice, takeProfitPrice, "Buy Order Placed");
                Print("BUY ORDER");
                
                canTrade = false;
            }
            

            // Sell condition
            if (isSellSignal)
            {
                double sellPrice = current_bid;
                double stopLossPrice = NormalizeDouble(StopLossSell, _Digits);
                double takeProfitPrice = NormalizeDouble(sellPrice - takeProfitPips * _Point, _Digits);
                trade.Sell(lotSize, _Symbol, sellPrice, stopLossPrice, takeProfitPrice, "Sell Order Placed");
                Print("SELL ORDER");
                canTrade = false;
            }
        }
    }
    
   if (PositionsTotal() > 0 && EMA9Array_H1[0] < MA18Array_H1[0] && MA18Array_H1[0] < MA200Array_H1[0]) 
   {
       // Get the ticket of the first position
       ulong ticket = PositionGetTicket(0);
       
       // Select the position and check if it's a buy order
       if (PositionSelectByTicket(ticket)) 
       {
           long positionType = PositionGetInteger(POSITION_TYPE);
           
           // Only close the position if it's a buy order
           if (positionType == POSITION_TYPE_BUY) 
           {
               trade.PositionClose(ticket);
               Print("Closed Buy Position");
           }
       }
   }//close buy orders

   if (PositionsTotal() > 0 && EMA9Array_H1[0] > MA18Array_H1[0] && MA18Array_H1[0] > MA200Array_H1[0]) 
   {
    // Get the ticket of the first position
    ulong ticket = PositionGetTicket(0);
    
    // Select the position and check if it's a sell order
    if (PositionSelectByTicket(ticket)) 
    {
        long positionType = PositionGetInteger(POSITION_TYPE);
        
        // Only close the position if it's a sell order
        if (positionType == POSITION_TYPE_SELL) 
        {
            trade.PositionClose(ticket);
            Print("Closed Sell Position");
        }
      }
   }//close for sell orders

    
        if (PositionsTotal() == 0 && (isBuySignal == false && isSellSignal == false))
    {
        canTrade = true;  // Allow new trades only if a crossover occurs again
    }

    
}