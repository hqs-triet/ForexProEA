#include  "ExpertWrapper.mqh"
#include  <trade/PositionInfo.mqh>
#include <trade/trade.mqh>
//+------------------------------------------------------------------+
// Lấy tổng số lệnh đã được gởi tới sàn giao dịch
//+------------------------------------------------------------------+
int GetActivePositions(string symbol, int magicNumber, 
                        bool isSellPos, bool isBuyPos,
                        string commentContain = "")
{
    int posCounter=0;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        string checkingSymbol = PositionGetSymbol(i);
        int ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            int tradeType = PositionGetInteger(POSITION_TYPE);
            bool isBuy = tradeType == POSITION_TYPE_BUY;
            bool isSell = !isBuy;
            
            if(symbol == checkingSymbol 
               && PositionGetInteger(POSITION_MAGIC) == magicNumber)
            {
                if(commentContain != "")
                {
                    string comment = PositionGetString(POSITION_COMMENT);
                    if(StringFind(comment, commentContain) < 0)
                        continue;
                }
                
                if((isSell && isSellPos) || (isBuy && isBuyPos))
                    posCounter++;
            }
     }
     
    }
    return posCounter;
}

//+------------------------------------------------------------------+
// Lấy số lượng lệnh chờ theo tham số chỉ định
//+------------------------------------------------------------------+
int GetPendingOrdersByType(string symbol, int magicNumber, 
                            ENUM_ORDER_TYPE orderType, 
                            string commentContain = "")
{
    int counter = 0;
    uint total = OrdersTotal();
    for(int idx = total - 1; idx >= 0; idx--)
    {
        ulong ticket = OrderGetTicket(idx);
        if(OrderSelect(ticket))
        {
            int tradeType = OrderGetInteger(ORDER_TYPE);
            
            if(OrderGetString(ORDER_SYMBOL) == symbol 
                && OrderGetInteger(ORDER_MAGIC) == magicNumber
                && tradeType == orderType)
            {
                if(commentContain != "")
                {
                    string comment = OrderGetString(ORDER_COMMENT);
                    if(StringFind(comment, commentContain) >= 0)
                        counter++;
                }
                else
                {
                    counter++;
                }
            }
        }
    }
    return counter;
}

//+------------------------------------------------------------------+
// Đóng hết các lệnh chờ theo tham số chỉ định
//+------------------------------------------------------------------+
void ClosePendingOrders(CTrade &trader, string symbol, int magicNumber, ENUM_ORDER_TYPE orderType, string commentContain = "")
{
    uint total = OrdersTotal();
    for(int idx = total - 1; idx >= 0; idx--)
    {
        ulong ticket = OrderGetTicket(idx);
        if(OrderSelect(ticket))
        {
            int tradeType = OrderGetInteger(ORDER_TYPE);
            int castOrderType = (int)orderType;
            if(OrderGetString(ORDER_SYMBOL) == symbol 
                && OrderGetInteger(ORDER_MAGIC) == magicNumber
                && tradeType == castOrderType)
            {
                if(commentContain != "")
                {
                    string comment = OrderGetString(ORDER_COMMENT);
                    if(StringFind(comment, commentContain) >= 0)
                        trader.OrderDelete(ticket);
                }
                else
                {
                    trader.OrderDelete(ticket);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
// Chuyển đổi số points sang giá thực (của cặp tiền tệ đang sử dụng)
//+------------------------------------------------------------------+
double PointsToPriceShift(string symbol, double points)
{
    CSymbolInfo objSymbol;
    objSymbol.Name(symbol);
    return (objSymbol.Point() * points);

}

//+------------------------------------------------------------------+
// Chuyển số giá thực (của cặp tiền tệ đang sử dụng) sang số points
//+------------------------------------------------------------------+
int PriceShiftToPoints(string symbol, double priceShift)
{
    CSymbolInfo objSymbol;
    objSymbol.Name(symbol);
    return (int)(priceShift / objSymbol.Point());
}

//+------------------------------------------------------------------+
// Tính toán ra khối lượng giao dịch dựa vào:
// . Tỉ lệ % vốn
// . Số points stop loss
//+------------------------------------------------------------------+
double PointsToLots(string symbol, double percentBalance, int points)
{
    CSymbolInfo objSymbol;
    objSymbol.Name(symbol);
    double balance      = AccountInfoDouble(ACCOUNT_BALANCE);
    double moneyrisk    = balance * percentBalance / 100;
    double spread       = objSymbol.Spread();
    double point        = objSymbol.Point();
    double ticksize     = objSymbol.TickSize();
    double tickvalue    = objSymbol.TickValue();
    double tickvaluefix = 0;
    if(ticksize != 0)
        tickvaluefix = tickvalue * point / ticksize; // A fix for an extremely rare occasion when a change in ticksize leads to a change in tickvalue
    
    double lots = 0;
    if(((points + spread)*tickvaluefix) != 0)
        lots = moneyrisk / ((points + spread)*tickvaluefix);
    lots = NormalizeDouble(lots, 2);
    
    return (lots);
}

//+------------------------------------------------------------------+
// Tính toán ra số tiền tương ứng với:
// . Số points stop loss
// . Khối lượng (volume)
//+------------------------------------------------------------------+
double PointsToMoney(string symbol, int points, double lot)
{
    CSymbolInfo objSymbol;
    objSymbol.Name(symbol);
    double moneyrisk    = 0;
    double spread       = objSymbol.Spread();
    double point        = objSymbol.Point();
    double ticksize     = objSymbol.TickSize();
    double tickvalue    = objSymbol.TickValue();
    double tickvaluefix = 0;
    if(ticksize != 0)
        tickvaluefix = tickvalue * point / ticksize; // A fix for an extremely rare occasion when a change in ticksize leads to a change in tickvalue
    
    if(((points + spread)*tickvaluefix) != 0)
        //lots = moneyrisk / ((points + spread)*tickvaluefix);
        moneyrisk = lot * ((points + spread)*tickvaluefix);
        
    moneyrisk = NormalizeDouble(moneyrisk, 2);
    return (moneyrisk);
}

//+------------------------------------------------------------------+
// Di chuyển SL về điểm vào lệnh khi profit đạt tới tỉ lệ nhất định so với SL
//+------------------------------------------------------------------+
void MoveSLToEntryByProfitVsSL(string symbol, int magicNumber, double tsRatioVsSL, CTrade &trader,
                             int stepPoints, bool forSell, bool forBuy, string commentContain = "")
{
    for(int i=PositionsTotal()-1; i>=0; i--)
    {   
        string CounterSymbol = PositionGetSymbol(i);
        int ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(symbol == CounterSymbol 
                && PositionGetInteger(POSITION_MAGIC) == magicNumber)
            {
                string comment = PositionGetString(POSITION_COMMENT);
                if(commentContain != "")
                {
                    if(StringFind(comment, commentContain) < 0)
                        continue;
                }
                
                string comments[];
                Split(comment, ";", comments);
                //int slOriginalPoints = StringToDouble(comments[1]);
                
                double sl = PositionGetDouble(POSITION_SL);
                double tp = PositionGetDouble(POSITION_TP);
                double price = PositionGetDouble(POSITION_PRICE_OPEN);
                
                int tradeType = PositionGetInteger(POSITION_TYPE);
                bool isBuy = tradeType == POSITION_TYPE_BUY;
                bool isSell = !isBuy;
                
                //if(MathAbs(price-sl) < PointsToPriceShift(m_Symbol, slOriginalPoints/2))
                //    continue;
                    
                int trailingStopPoints = tsRatioVsSL * PriceShiftToPoints(symbol, MathAbs(sl-price));
                if(isSell && forSell)
                {
                    if(sl <= price)
                        continue;
                    AdjustTrailingStopByTicket(symbol, magicNumber, trader, ticket, trailingStopPoints, stepPoints, commentContain);
                }
                
                if(isBuy && forBuy)
                {
                    if(sl >= price)
                        continue;
                    AdjustTrailingStopByTicket(symbol, magicNumber, trader, ticket, trailingStopPoints, stepPoints, commentContain);
                }
            }
        }
    }
}

void TrailingStopByComment(string symbol, int magicNumber, CTrade &trader,
                             int stepPoints, bool forSell, bool forBuy, string commentContain)
{
    if(commentContain == "")
        return;
    for(int i=PositionsTotal()-1; i>=0; i--)
    {   
        string CounterSymbol = PositionGetSymbol(i);
        int ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(symbol == CounterSymbol 
                && PositionGetInteger(POSITION_MAGIC) == magicNumber)
            {
                string comment = PositionGetString(POSITION_COMMENT);
                if(commentContain != "")
                {
                    if(StringFind(comment, commentContain) < 0)
                        continue;
                }
                
                string comments[];
                Split(comment, ";", comments);
                
                int tradeType = PositionGetInteger(POSITION_TYPE);
                bool isBuy = tradeType == POSITION_TYPE_BUY;
                bool isSell = !isBuy;
                
                int trailingStopPoints = comments[2];
                if(isSell && forSell)
                {
                    AdjustTrailingStopByTicket(symbol, magicNumber, trader, ticket, trailingStopPoints, stepPoints, commentContain);
                }
                
                if(isBuy && forBuy)
                {
                    AdjustTrailingStopByTicket(symbol, magicNumber, trader, ticket, trailingStopPoints, stepPoints, commentContain);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
// Điều chỉnh SL 
//+------------------------------------------------------------------+
void AdjustTrailingStopByTicket(string symbol, int magicNumber, CTrade &trader, int posTicket, int trailingStopPoints, int stepPoints, string commentContain = "")
{
    for(int i=PositionsTotal()-1; i>=0; i--)
    {   
        string CounterSymbol = PositionGetSymbol(i);
        int ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(symbol == CounterSymbol 
                && PositionGetInteger(POSITION_MAGIC) == magicNumber
                && (ticket == 0 || ticket == posTicket)
                )
            {
                if(commentContain != "")
                {
                    string comment = PositionGetString(POSITION_COMMENT);
                    if(StringFind(comment, commentContain) < 0)
                        continue;
                }
                
                double sl = PositionGetDouble(POSITION_SL);
                double tp = PositionGetDouble(POSITION_TP);
                
                double price = PositionGetDouble(POSITION_PRICE_OPEN);
                int tradeType = PositionGetInteger(POSITION_TYPE);
                bool isBuy = tradeType == POSITION_TYPE_BUY;
                bool isSell = !isBuy;
                double newSL = 0;
                bool modSucess = false;
                MqlTick Latest_Price; 
                SymbolInfoTick(symbol, Latest_Price);
                    
                if(isSell)
                {
                    if(Latest_Price.ask < price
                        && price - Latest_Price.ask > PointsToPriceShift(symbol, trailingStopPoints))
                    {   
                        if(sl - Latest_Price.ask > PointsToPriceShift(symbol, trailingStopPoints))
                        {
                            newSL = Latest_Price.ask + PointsToPriceShift(symbol, trailingStopPoints);
                            
                            if(sl - newSL > PointsToPriceShift(symbol, stepPoints))
                            {
                                if(trader.PositionModify(ticket, newSL - PointsToPriceShift(symbol, stepPoints), tp))
                                {
                                    modSucess = true;
                                }
                            }
                        }
                    }
                }
                
                if(isBuy)
                {
                    if(Latest_Price.bid > price 
                        && Latest_Price.bid - price > PointsToPriceShift(symbol, trailingStopPoints))
                    {
                        if(Latest_Price.bid - sl > PointsToPriceShift(symbol, trailingStopPoints))
                        {
                            newSL = Latest_Price.bid - PointsToPriceShift(symbol, trailingStopPoints);
                            if(newSL - sl > PointsToPriceShift(symbol, stepPoints))
                            {
                                if(trader.PositionModify(ticket, newSL + PointsToPriceShift(symbol, stepPoints), tp))
                                {
                                    modSucess = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
// Tách chuỗi thành mảng
//+------------------------------------------------------------------+
int Split(string s, string separator, string &outResult[])
{
    ushort u_sep;                  // The code of the separator character
    //--- Get the separator code
    u_sep=StringGetCharacter(separator, 0);
    //--- Split the string to substrings
    int k = StringSplit(s, u_sep, outResult);
    return k;
}

//+------------------------------------------------------------------+
// Lấy đỉnh đầu tiên của zigzag tính từ index chỉ định
//+------------------------------------------------------------------+
int GetFirstPoint(double &zigZagBuff[], int fromIdx = 1)
{
    for(int i=fromIdx;;i++)
    {
        if(zigZagBuff[i] > 0)
            return i;
    }
}

//+------------------------------------------------------------------+
// Tính giá trị trung bình của một số nến trước đó
//+------------------------------------------------------------------+
int CalculateCandleAverage(AllSeriesInfo &priceInfo, int periods, int idxStart, bool skipSatSun = true)
{
    double sum=0;
    int len = periods;
    for(int i = 0; i < len; i++)
    {
        if(skipSatSun)
        {
            MqlDateTime structCurrentTime;
            if(TimeToStruct(priceInfo.time(i+idxStart), structCurrentTime))
            {
               if(structCurrentTime.day_of_week == 0
                  || structCurrentTime.day_of_week == 6)
                {
                    len++;
                    continue;
                }
            }
        }
        double high = priceInfo.high(i + idxStart);
        double low = priceInfo.low(i + idxStart);
        sum += MathAbs(PriceShiftToPoints(priceInfo.symbol_info().Name(), (high-low)/2 ));
    }
    double avg = sum/periods;
    return avg;
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải là nến tăng hay không
//+------------------------------------------------------------------+
bool IsCandleUp(int idx, AllSeriesInfo &priceInfo)
{
    if(priceInfo.open(idx) < priceInfo.close(idx))
        return true;
    return false;
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải là nến giảm hay không
//+------------------------------------------------------------------+
bool IsCandleDown(int idx, AllSeriesInfo &priceInfo)
{
    if(priceInfo.open(idx) > priceInfo.close(idx))
        return true;
    return false;
}

//+------------------------------------------------------------------+
// Đếm số lượng % nến cắt qua EMA
//+------------------------------------------------------------------+
double GetPercentEMACrossInsideCandle(AllSeriesInfo &priceInfo, double &emaBuffer[], 
                                      int periods, int shiftCandelIdx = 0)
{
    double count = 0;
    for(int idx=1; idx <= periods; idx++)
    {
        if(IsCandleDown(idx, priceInfo))
        {
            if(priceInfo.open(idx + shiftCandelIdx) > emaBuffer[idx + shiftCandelIdx]
                && priceInfo.close(idx + shiftCandelIdx) < emaBuffer[idx + shiftCandelIdx])
                count++;
        }
        else if(IsCandleUp(idx, priceInfo))
        {
            if(priceInfo.close(idx + shiftCandelIdx) > emaBuffer[idx + shiftCandelIdx]
                && priceInfo.open(idx + shiftCandelIdx) < emaBuffer[idx + shiftCandelIdx])
                count++;
        }
    }
    double result = (count * 100)/ periods;
    return result;
}


//+------------------------------------------------------------------+
// Kiểm tra chuỗi có phải là số nguyên dương không
//+------------------------------------------------------------------+
bool IsInteger(string value)
{
    if(value == "")
        return false;
        
    for(int idx = 0; idx < StringLen(value); idx++)
    {
        if(StringSubstr(value, idx, 1) != "0"
            && StringSubstr(value, idx, 1) != "1"
            && StringSubstr(value, idx, 1) != "2"
            && StringSubstr(value, idx, 1) != "3"
            && StringSubstr(value, idx, 1) != "4"
            && StringSubstr(value, idx, 1) != "5"
            && StringSubstr(value, idx, 1) != "6"
            && StringSubstr(value, idx, 1) != "7"
            && StringSubstr(value, idx, 1) != "8"
            && StringSubstr(value, idx, 1) != "9")
            return false;
        
    }
    return true;
}


//+------------------------------------------------------------------+
// Kiểm tra chuỗi có phải là giá trị thời gian đúng mẫu không (24 giờ))
// HH:mm:ss
//+------------------------------------------------------------------+
bool IsValidTime(string value)
{
    if(StringLen(value) == 8)
    {
        string sHours = StringSubstr(value, 0, 2);
        string sMinutes = StringSubstr(value, 3, 2);
        string sSeconds = StringSubstr(value, 6, 2);
        if(IsInteger(sHours) && IsInteger(sMinutes) && IsInteger(sSeconds))
        {
            int hours = StringToInteger(sHours);
            int minutes = StringToInteger(sMinutes);
            int seconds = StringToInteger(sSeconds);
            if(hours >= 0 && hours <= 23
               && minutes >= 0 && minutes <= 59
               && seconds >= 0 && seconds <= 59)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
// Kiểm tra thị trường hiện tại có phải khung thời gian giao dịch không
//+------------------------------------------------------------------+
bool IsTradingTime(string timeStart, string timeEnd)
  {
    
    datetime currentTime = TimeCurrent();

    if(IsValidTime(timeStart) && IsValidTime(timeEnd))
    {
        datetime inpStartTime = StringToTime(timeStart);
        datetime inpEndTime = StringToTime(timeEnd);

        if(inpStartTime < inpEndTime)
        {
            if(currentTime >= inpStartTime && currentTime <= inpEndTime)
            {
                return true;
            }
        }
        else 
            if(inpStartTime > inpEndTime)
            {
                if(currentTime >= inpStartTime || currentTime <= inpEndTime)
                {
                    return true;
                }
            }
    }
    return false;
}
//+------------------------------------------------------------------+
// Chèn ký tự vào bên trái chuỗi chỉ định
//+------------------------------------------------------------------+
string PaddingLeft(int value, int number, string sChar)
{
    if(number == 2)
        if(value < 10)
            return "0" + value;
    if(number == 3)
    {
        if(value < 10)
            return "00" + value;
        if(value < 100)
            return "0" + value;
    }
    if(number == 4)
    {
        if(value < 10)
            return "000" + value;
        if(value < 100)
            return "00" + value;
        if(value < 1000)
            return "0" + value;
    }
    if(number == 5)
    {
        if(value < 10)
            return "0000" + value;
        if(value < 100)
            return "000" + value;
        if(value < 1000)
            return "00" + value;
        if(value < 10000)
            return "0" + value;
    }
    return value;
}

//+------------------------------------------------------------------+
// Đóng hết các lệnh SELL theo điều kiện chỉ định
//+------------------------------------------------------------------+
void CloseAllSellPositions(CTrade &trader, string symbol, int magicNumber, int minProfitPoints = 0, string commentContain = "") 
{

    for(int i=PositionsTotal()-1; i>=0; i--)
    {   
        string CounterSymbol=PositionGetSymbol(i);
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(symbol==CounterSymbol 
                && PositionGetInteger(POSITION_MAGIC) == magicNumber
                && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                if(minProfitPoints > 0)
                {
                    MqlTick Latest_Price; 
                    SymbolInfoTick(symbol,Latest_Price);  // Assign current prices to structure
                    double price = PositionGetDouble(POSITION_PRICE_OPEN);
                    
                    int profit = PriceShiftToPoints(CounterSymbol, price - Latest_Price.ask);
                    if(profit < minProfitPoints)
                        continue;
                }
                
                if(minProfitPoints < 0)
                {
                    MqlTick Latest_Price; 
                    SymbolInfoTick(symbol,Latest_Price);  // Assign current prices to structure
                    double price = PositionGetDouble(POSITION_PRICE_OPEN);
                    
                    int profit = PriceShiftToPoints(CounterSymbol, price - Latest_Price.ask);
                    if(profit > minProfitPoints)
                        continue;
                }
                
                if(commentContain != "")
                {
                    string comment = PositionGetString(POSITION_COMMENT);
                    if(StringFind(comment, commentContain) >= 0)
                    {
                        Print("Manualy, to close order (SELL): " + ticket);
                        trader.PositionClose(ticket);
                    }
                }
                else
                {
                    Print("Manualy, to close order (SELL): " + ticket);
                    trader.PositionClose(ticket);
                }
            }
        }
        else
        {
            Print("CloseAllSellPositions() -> Cannot select ticket: " + ticket);
        }
    }
}
//+------------------------------------------------------------------+
// Đóng hết các lệnh BUY theo điều kiện chỉ định
//+------------------------------------------------------------------+
void CloseAllBuyPositions(CTrade &trader, string symbol, int magicNumber, int minProfitPoints = 0, string commentContain = "") 
{

    for(int i=PositionsTotal()-1; i>=0; i--)
    {
        string CounterSymbol=PositionGetSymbol(i);
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(symbol==CounterSymbol 
                && PositionGetInteger(POSITION_MAGIC) == magicNumber
                && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
                if(minProfitPoints > 0)
                {
                    MqlTick Latest_Price; 
                    SymbolInfoTick(symbol,Latest_Price);  // Assign current prices to structure
                    double price = PositionGetDouble(POSITION_PRICE_OPEN);
                    
                    int profit = PriceShiftToPoints(CounterSymbol, Latest_Price.bid - price);
                    if(profit < minProfitPoints)
                        continue;
                }
                if(minProfitPoints < 0)
                {
                    MqlTick Latest_Price; 
                    SymbolInfoTick(symbol,Latest_Price);  // Assign current prices to structure
                    double price = PositionGetDouble(POSITION_PRICE_OPEN);
                    
                    int profit = PriceShiftToPoints(CounterSymbol, Latest_Price.bid - price);
                    if(profit >= minProfitPoints)
                        continue;
                }
                
                if(commentContain != "")
                {
                    string comment = PositionGetString(POSITION_COMMENT);
                    if(StringFind(comment, commentContain) >= 0)
                    {
                        Print("Manualy, to close order (BUY): " + ticket);
                        trader.PositionClose(ticket);
                    }
                }
                else
                {
                    Print("Manualy, to close order (BUY): " + ticket);
                    trader.PositionClose(ticket);
                }
            }
        }
        else
        {
            Print("CloseAllBuyPositions() -> Cannot select ticket: " + ticket);
        }
    }
}
//+------------------------------------------------------------------+
// Tính hệ số a của đường thằng y = ax + b theo (x1,y1) và (x2,y2)
//+------------------------------------------------------------------+
double GetConsA(double x1CandleIdx, double y1CandlePrice, double x2CandleIdx, double y2CandlePrice)
{
    if(x1CandleIdx - x2CandleIdx == 0)
        return 0;
    double consA = (y1CandlePrice - y2CandlePrice) / (x1CandleIdx - x2CandleIdx);
    return consA;
}
//+------------------------------------------------------------------+
// Tính hệ số b của đường thằng y = ax + b theo (x1,y1) và (x2,y2)
//+------------------------------------------------------------------+
double GetConsB(double x1CandleIdx, double y1CandlePrice, double x2CandleIdx, double y2CandlePrice)
{
    if(x1CandleIdx - x2CandleIdx == 0)
        return 0;
    double consA = (y1CandlePrice - y2CandlePrice) / (x1CandleIdx - x2CandleIdx);
    double consB = y1CandlePrice - consA * x1CandleIdx;
    return consB;
}
//+------------------------------------------------------------------+
// Tính tỉ lệ % số nến nằm dưới đường thằng y = ax + b
//+------------------------------------------------------------------+
double GetPercentCandlesBelowLine(AllSeriesInfo &priceInfo, int periods, double a, double b, bool useClosePrice = true, int shiftCandelIdx = 0)
{
    double count = 0;
    for(int idx=1; idx <= periods; idx++)
    {
        double y = a * (idx+shiftCandelIdx) + b;
        double value = priceInfo.high(idx + shiftCandelIdx);
        if(useClosePrice)
            value = priceInfo.close(idx + shiftCandelIdx);
            
        if(value <= y)
            count++;
    }
    double result = (count * 100)/ periods;
    return result;
}

//+------------------------------------------------------------------+
// Tính tỉ lệ % số nến nằm trên đường thằng y = ax + b
//+------------------------------------------------------------------+
double GetPercentCandlesAboveLine(AllSeriesInfo &priceInfo, int periods, double a, double b, bool useClosePrice = true, int shiftCandelIdx = 0)
{
    double count = 0;
    for(int idx=1; idx <= periods; idx++)
    {
        double y = a * (idx+shiftCandelIdx) + b;
        double value = priceInfo.low(idx + shiftCandelIdx);
        if(useClosePrice)
            value = priceInfo.close(idx + shiftCandelIdx);
            
        if(value >= y)
            count++;
    }
    double result = (count * 100)/ periods;
    return result;
}