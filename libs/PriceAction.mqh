
//+------------------------------------------------------------------+
// Lấy tỉ lệ % bóng phía trên so với chiều cao của cả nến
//+------------------------------------------------------------------+
double CandleTailUpPercent(int idx, AllSeriesInfo &priceInfo)
{
    double h = priceInfo.high(idx);
    double l = priceInfo.low(idx);
    double compare = priceInfo.close(idx);
    
    if(IsCandleDown(idx, priceInfo))
    {
        compare = priceInfo.open(idx);
    }
    
    if(h - l > 0)
        return (h - compare) * 100 / (h - l);
    return 0;
}

//+------------------------------------------------------------------+
// Lấy tỉ lệ % bóng phía dưới so với chiều cao của cả nến
//+------------------------------------------------------------------+
double CandleTailDownPercent(int idx, AllSeriesInfo &priceInfo)
{
    double h = priceInfo.high(idx);
    double l = priceInfo.low(idx);
    double compare = priceInfo.open(idx);
    
    if(IsCandleDown(idx, priceInfo))
    {
        compare = priceInfo.close(idx);
    }
    
    if(h - l > 0)
        return (compare - l) * 100 / (h - l);
    return 0;
}

//+------------------------------------------------------------------+
// Lấy tỉ lệ % thân nến so với chiều cao của cả nến
//+------------------------------------------------------------------+
double CandleBodyPercent(int idx, AllSeriesInfo &priceInfo)
{  
    double h = priceInfo.high(idx);
    double l = priceInfo.low(idx);
    
    if(h - l > 0)
    {
        return (MathAbs(priceInfo.close(idx) - priceInfo.open(idx)) * 100) / (h - l);
    }
    return 0;
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến búa không
// Căn cứ:
// . Tính tỉ lệ bóng nến trên dưới: [bóng dưới] lớn hơn nhiều so với [bóng trên]
// . Tính tỉ lệ thân nến
//+------------------------------------------------------------------+
bool IsHammerBar(int idx, AllSeriesInfo &priceInfo)
{
    return (CandleBodyPercent(idx, priceInfo) <= 35 && CandleBodyPercent(idx, priceInfo) >= 10
            && CandleTailDownPercent(idx, priceInfo) >= 55
            && CandleTailUpPercent(idx, priceInfo) <= 5);
}

//+------------------------------------------------------------------+
// Kiểm tra nến có phải nến búa ngược không
// Căn cứ:
// . Tính tỉ lệ bóng nến trên dưới: [bóng dưới] nhỏ hơn nhiều so với [bóng trên]
// . Tính tỉ lệ thân nến
//+------------------------------------------------------------------+
bool IsReverseHammerBar(int idx, AllSeriesInfo &priceInfo)
{
    return (CandleBodyPercent(idx, priceInfo) <= 35 && CandleBodyPercent(idx, priceInfo) >= 10
            && CandleTailUpPercent(idx, priceInfo) >= 55
            && CandleTailDownPercent(idx, priceInfo) <= 5);
}
