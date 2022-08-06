//+--------------------------------------------------------------------------+
//|                                           ForexProEA_6_6_MultipleSMA.mq5 |
//|                                                             Forex Pro EA |
//|                              https://www.facebook.com/groups/forexproea/ |
//+--------------------------------------------------------------------------+
#property copyright "Forex Pro EA"
#property link      "https://www.facebook.com/groups/forexproea/"
#property version   "1.00"
#property description "Resistance and support zone"

#include "..\\libs\\Common.mqh"
#include "..\\libs\\Graph.mqh"
#include <Generic\ArrayList.mqh>
// Khai báo sử dụng chỉ báo chung với biểu đồ chính
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots 0

// -----------------------------------------------
// Chỉ báo tín hiệu 
#property indicator_label1  "Resistance"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_width1  5

#property indicator_label2  "Support"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  5

#resource "\\Indicators\\Examples\\ZigZagColor.ex5"
//--------------------------------------------------------------
// Tham số đầu vào (input)
//--------------------------------------------------------------
input int InpZone = 300;                    // Zone (in points)
input int InpLookbackPoint = 10;            // Look back top/bottom points
input color InpResColor = clrDarkGoldenrod; // Color of resistance zone
input color InpSupColor = clrDarkSeaGreen;  // Color of support zone
input color InpTurningColor = clrPurple;    // Color of turning res <-> sup
input color InpSingleColor = clrNONE;       // Color of single top/bottom point
//input color InpSingleColor = clrDarkSlateGray;       // Color of single top/bottom point
//--------------------------------------------------------------
//const int MAX_POINT = 10;

double m_resBuffer[], m_supBuffer[],
       m_zigzagTopBuffer[], m_zigzagBottomBuffer[];
int m_zigzagHandler;

CChartObjectTrend *m_lineTop[], *m_lineBottom[], *m_line[];
CChartObjectRectangle *m_recTop[], *m_recBottom[], *m_rec[];
//+------------------------------------------------------------------+
//| Sự kiện khởi tạo
//+------------------------------------------------------------------+
int OnInit()
{
    InitSeries(m_zigzagTopBuffer);
    InitSeries(m_zigzagBottomBuffer);
    InitSeries(m_resBuffer);
    InitSeries(m_supBuffer);
    
    // Thiết lập hiển thị chính xác số thập phân
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
    
    // Thiết lập bộ đệm cho chỉ báo tín hiệu
    SetIndexBuffer(2, m_resBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(3, m_supBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(0, m_zigzagTopBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(1, m_zigzagBottomBuffer, INDICATOR_CALCULATIONS);
    
    // Với những vị trí không có giá trị, thiết lập giá trị 0.0
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
    
    // Thiết lập kiểu vẽ của đường chỉ báo tín hiệu BUY/SELL
    // Giá trị code 159 theo font Wingdings là kiểu vẽ vòng tròn
    PlotIndexSetInteger(0, PLOT_ARROW, 159);
    PlotIndexSetInteger(1, PLOT_ARROW, 159);
    
    
    m_zigzagHandler = iCustom(NULL, 0, "::Indicators\\Examples\\ZigZagColor",
                              12,5,3);
    
    if(m_zigzagHandler <= 0)
    {
        Print("Cannot initalize zigzag");
        return INIT_FAILED;
    }
    
    ArrayResize(m_lineBottom, InpLookbackPoint);
    ArrayResize(m_lineTop, InpLookbackPoint);
    ArrayResize(m_recBottom, InpLookbackPoint);
    ArrayResize(m_recTop, InpLookbackPoint);
    
    ArrayResize(m_line, InpLookbackPoint * 2);
    ArrayResize(m_rec, InpLookbackPoint * 2);
    
    for(int idx = 0; idx < InpLookbackPoint * 2; idx++)
    {
        if(m_line[idx] != NULL) m_line[idx].Delete();
        if(m_rec[idx] != NULL) m_rec[idx].Delete();
        m_line[idx] = NULL;
        m_rec[idx] = NULL;
        
        if(ObjectFind(0, "line_" + (string)idx) >= 0)
            ObjectDelete(0, "line_" + (string)idx);
        if(ObjectFind(0, "rec_" + (string)idx) >= 0)
            ObjectDelete(0, "rec_" + (string)idx);
    }
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Sự kiện được gọi mỗi khi có tín hiệu từ server                            |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    // ----------------------------------------------------
    // Tính toán các giá trị cho chỉ báo zigzag
    int calculated = BarsCalculated(m_zigzagHandler);
    if(calculated < rates_total)
    {
        //Print("Not all data of zigzag is calculated (", calculated," bars). Error ", GetLastError());
        return(0);
    }
    
    int to_copy;
    // Thời điểm khởi đầu -> Copy hết dữ liệu
    if(prev_calculated > rates_total || prev_calculated <= 0)
    {
        to_copy = rates_total;
    }
    // Từ lần thứ 2 trở đi
    else
    {
        to_copy = rates_total - prev_calculated;
        if(prev_calculated > 0)
            to_copy++;
    }
    
    if(to_copy == 0)
        return rates_total;
    

    // Zigzag
    if(IsStopped()) // checking for stop flag
        return(0);
    if(CopyBuffer(m_zigzagHandler, 0, 0, to_copy, m_zigzagTopBuffer) <= 0)
    {
        Print("Getting zigzag top is failed! Error ", GetLastError());
        return(0);
    }
    if(CopyBuffer(m_zigzagHandler, 1, 0, to_copy, m_zigzagBottomBuffer) <= 0)
    {
        Print("Getting zigzag bottom is failed! Error ", GetLastError());
        return(0);
    }
    
    CArrayList<int> points;
    int idxFindTop = 4;
    int idxFindBottom = 4;
    for(int idx = 0; idx < InpLookbackPoint; idx++)
    {
        idxFindTop = GetFirstPoint(m_zigzagTopBuffer, idxFindTop + 1);
        idxFindBottom = GetFirstPoint(m_zigzagBottomBuffer, idxFindBottom + 1);
        points.Add(idxFindTop);
        points.Add(idxFindBottom);
    }
    points.Sort();
    CArrayList<int> excludePoints;
    double zone = PointsToPriceShift(_Symbol, InpZone);
    
    datetime time1 = NULL;
    
    for(int idx = points.Count() - 1; idx > 0; idx--)
    {
        bool currPointTop = false, currPointBottom = false;
        bool drawRec = false;
        int posCandle;
        points.TryGetValue(idx, posCandle);
        if(excludePoints.IndexOf(posCandle) >= 0)
            continue;
        if(time1 > time[rates_total - posCandle - 1] || time1 == NULL)
        {
            time1 = time[rates_total - posCandle - 1];
            time1 -= PeriodSeconds(PERIOD_CURRENT)*5;
        }
        datetime time2 = time[rates_total - 1];
        double maxPrice = -1, minPrice = -1;
        time2 += PeriodSeconds(PERIOD_CURRENT)*5;
        
        double price = m_zigzagTopBuffer[posCandle];
        if(price == 0)
            price = m_zigzagBottomBuffer[posCandle];
        
        if(maxPrice == -1 || maxPrice < price)
            maxPrice = price;
        if(minPrice == -1 || minPrice > price)
            minPrice = price;
            
        if(m_zigzagTopBuffer[posCandle] > 0)
            currPointTop = true;
        if(m_zigzagBottomBuffer[posCandle] > 0)
            currPointBottom = true;
            
        bool foundPointTop = false, foundPointBottom = false;
        for(int idxCheck = idx - 1; idxCheck >= 0; idxCheck--)
        {
            int posCandle1;
            points.TryGetValue(idxCheck, posCandle1);
            
            double price1 = m_zigzagTopBuffer[posCandle1];
            if(price1 == 0)
                price1 = m_zigzagBottomBuffer[posCandle1];
            
            double delta = MathAbs(price - price1);
            if(delta <= zone)
            {
                if(maxPrice == -1 || maxPrice < price1)
                    maxPrice = price1;
                if(minPrice == -1 || minPrice > price1)
                    minPrice = price1;
                if(excludePoints.IndexOf(posCandle1) < 0)
                {
                    if(m_zigzagTopBuffer[posCandle1] > 0)
                        foundPointTop = true;
                    if(m_zigzagBottomBuffer[posCandle1] > 0)
                        foundPointBottom = true;
                    excludePoints.Add(posCandle1);
                    drawRec = true;
                }
            }
        }
        if(drawRec)
        {
            color clr = clrDarkSeaGreen;
            // Turning
            if((currPointTop && foundPointBottom) || (currPointBottom && foundPointTop))
                clr = InpTurningColor;
            // Resistance
            else if(currPointTop && foundPointTop)
                clr = InpResColor;
            // Support
            else if(currPointBottom && foundPointBottom)
                clr = InpSupColor;
                
            DrawRec(m_rec[idx], "rec_" + (string)idx, 
                    time1, maxPrice,
                    time2, minPrice,
                    clr);
        }
        else
        {
            if(excludePoints.IndexOf(posCandle) < 0)
            {
                double price2 = 0;
                if(m_zigzagTopBuffer[posCandle] > 0)
                {
                    price2 = open[rates_total - posCandle - 1];
                    if(close[rates_total - posCandle - 1] > open[rates_total - posCandle - 1])
                        price2 = close[rates_total - posCandle - 1];
                    if(high[rates_total - posCandle - 2] > price2)
                        price2 = high[rates_total - posCandle - 2];
                    if(high[rates_total - posCandle] > price2)
                        price2 = high[rates_total - posCandle];
                }
                if(m_zigzagBottomBuffer[posCandle] > 0)
                {
                    price2 = open[rates_total - posCandle - 1];
                    if(close[rates_total - posCandle - 1] < open[rates_total - posCandle - 1])
                        price2 = close[rates_total - posCandle - 1];
                    if(low[rates_total - posCandle - 2] < price2)
                        price2 = low[rates_total - posCandle - 2];
                    if(low[rates_total - posCandle] < price2)
                        price2 = low[rates_total - posCandle];
                }
                
                // ------------------------------------------------
                // Check overlap
                bool isOverlap = false;
                for(int idxOverlap = 0; idxOverlap < ArraySize(m_rec); idxOverlap++)
                {
                    if(ObjectFind(0, "rec_" + (string)idxOverlap) >= 0)
                    {
                        
                        double anchorPriceH = ObjectGetDouble(0, "rec_" + (string)idxOverlap, OBJPROP_PRICE, 0);
                        double anchorPriceL = ObjectGetDouble(0, "rec_" + (string)idxOverlap, OBJPROP_PRICE, 1);
                        if(anchorPriceH < anchorPriceL)
                        {
                            double temp = anchorPriceH;
                            anchorPriceH = anchorPriceL;
                            anchorPriceL = temp;
                        }
                        //Print("0=" + anchorPrice1 + "; 1=" + anchorPrice2);
                        if(anchorPriceH >= price && anchorPriceL <= price)
                            isOverlap = true;
                        if(anchorPriceH >= price2 && anchorPriceL <= price2)
                            isOverlap = true;
                        if((anchorPriceH < price && anchorPriceL > price2) 
                           ||(anchorPriceH < price2 && anchorPriceL > price))
                           isOverlap = true;
                    }
                    if(isOverlap)
                        break;
                }
                
                // ------------------------------------------------
                if(!isOverlap)
                    DrawRec(m_rec[idx], "rec_" + (string)idx, 
                                    time1, price,
                                    time2, price2, InpSingleColor);
                //else
                //{
                //    // Xóa rec không sử dụng
                //    if(ObjectFind(0, "rec_" + (string)idx) >= 0)
                //    {
                //        ObjectDelete(0, "rec_" + (string)idx);
                //        m_rec[idx] = NULL;
                //    }
                //}
            }
            else
            {
                // Xóa rec không sử dụng
                if(ObjectFind(0, "rec_" + (string)idx) >= 0)
                {
                    ObjectDelete(0, "rec_" + (string)idx);
                    m_rec[idx] = NULL;
                }
            }
        }
    }
    
    return rates_total;
}
