//+------------------------------------------------------------------+
//|                                           ForexProEA_6_4_Fan.mq5 |
//|                                                     Forex Pro EA |
//|                      https://www.facebook.com/groups/forexproea/ |
//+------------------------------------------------------------------+
#property copyright "Forex Pro EA"
#property link      "https://www.facebook.com/groups/forexproea/"
#property version   "1.00"

// Khai báo thư viện ve biểu tượng trên biểu đồ
#include <ChartObjects\ChartObjectsArrows.mqh>

// Khai báo sử dụng chỉ báo chung với biểu đồ chính
#property indicator_chart_window
// Tổng số bộ đệm
#property indicator_buffers 10
// Chỉ định tổng số đường hiển thị
#property indicator_plots   9

//-------------------------------------------------------------- 
// Thông tin thiết lập cho đường trung bình SMA 1,2,3,4,5,6,7,8
//--------------------------------------------------------------
#property indicator_label1  "SMA1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "SMA2"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "SMA3"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSteelBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "SMA4"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrMediumOrchid
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

#property indicator_label5  "SMA5"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrLimeGreen
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

#property indicator_label6  "SMA6"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrBrown
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1

#property indicator_label7  "SMA7"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrDarkGray
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1

#property indicator_label8  "SMA8"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrBlueViolet
#property indicator_style8  STYLE_SOLID
#property indicator_width8  1

//--------------------------------------------------------------
// Chỉ báo tín hiệu BUY/SELL, khi có tín hiệu, giá trị được gán là SMA6
#property indicator_label9  "Signal"
// Chỉ định vẽ đường thẳng có màu
#property indicator_type9   DRAW_COLOR_ARROW
// Màu được định nghĩa theo một danh sách, đánh số từ 0, 1, 2, ...
#property indicator_color9  clrBlue, clrRed
#property indicator_width9  5
//--------------------------------------------------------------

//--------------------------------------------------------------
// Tham số đầu vào (input)
//--------------------------------------------------------------
input group "=== Thông số các đường trung bình SMA ==="
input int InpMAPeriod1 = 4;         // Giai đoạn nến của đường SMA 1
input int InpMAPeriod2 = 8;         // Giai đoạn nến của đường SMA 2
input int InpMAPeriod3 = 12;        // Giai đoạn nến của đường SMA 3
input int InpMAPeriod4 = 16;        // Giai đoạn nến của đường SMA 4
input int InpMAPeriod5 = 20;        // Giai đoạn nến của đường SMA 5
input int InpMAPeriod6 = 24;        // Giai đoạn nến của đường SMA 6
input int InpMAPeriod7 = 28;        // Giai đoạn nến của đường SMA 7
input int InpMAPeriod8 = 34;        // Giai đoạn nến của đường SMA 8

input group "=== Thiết lập hiển thị ==="
input int InpMAShift = 0;           // Dịch chuyển SMA theo khoảng nến nhất định (shift)
input bool InpChangeColorOfCandle = false;  // Thay đổi màu của nến theo màu nền

input group "=== Xử lý khi SMA quạt ra (lên/xuống) ==="
input bool InpDrawSymbol = false;           // Vẽ biểu tượng BUY/SELL khi SMA quạt ra
input bool InpShowAlert = false;            // Hiển thị thông báo (alert)
input bool InpSendNotification = false;     // Gởi thông báo tới thiết bị (notification)

//--------------------------------------------------------------



// Bộ đệm dùng lưu giá trị của SMA 1,2,3,4,5,6,7,8
double m_dataBuffer1[], m_dataBuffer2[], m_dataBuffer3[],
       m_dataBuffer4[], m_dataBuffer5[], m_dataBuffer6[],
       m_dataBuffer7[], m_dataBuffer8[], 
       // Bộ đệm của đường tín hiệu BUY/SELL
       m_dataBuffer9[],
       // Bộ đệm này được dùng để hiển thị màu của chỉ báo tín hiệu
       m_dataBufferColor[];
int m_symbolId;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    // Thiết lập mapping bộ đệm của biến lưu trữ với bộ đệm hiển thị lên biểu đồ
    SetIndexBuffer(0, m_dataBuffer1, INDICATOR_DATA);
    SetIndexBuffer(1, m_dataBuffer2, INDICATOR_DATA);
    SetIndexBuffer(2, m_dataBuffer3, INDICATOR_DATA);
    SetIndexBuffer(3, m_dataBuffer4, INDICATOR_DATA);
    SetIndexBuffer(4, m_dataBuffer5, INDICATOR_DATA);
    SetIndexBuffer(5, m_dataBuffer6, INDICATOR_DATA);
    SetIndexBuffer(6, m_dataBuffer7, INDICATOR_DATA);
    SetIndexBuffer(7, m_dataBuffer8, INDICATOR_DATA);
    SetIndexBuffer(8, m_dataBuffer9, INDICATOR_DATA);
    // Chỉ định bộ đệm hiển thị màu kèm theo cho SMA
    SetIndexBuffer(9, m_dataBufferColor, INDICATOR_COLOR_INDEX);
    
    // Thiết lập hiển thị chính xác số thập phân
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
    
    // Thiết lập kiểu vẽ của đường chỉ báo tín hiệu BUY/SELL
    // Giá trị code 159 theo font Wingdings là kiểu vẽ vòng tròn
    PlotIndexSetInteger(8, PLOT_ARROW, 159);
    
    // Di chuyển SMA theo khoảng nến nhất định (shift)
    PlotIndexSetInteger(0, PLOT_SHIFT, InpMAShift);
    PlotIndexSetInteger(1, PLOT_SHIFT, InpMAShift);
    PlotIndexSetInteger(2, PLOT_SHIFT, InpMAShift);
    PlotIndexSetInteger(3, PLOT_SHIFT, InpMAShift);
    PlotIndexSetInteger(4, PLOT_SHIFT, InpMAShift);
    PlotIndexSetInteger(5, PLOT_SHIFT, InpMAShift);
    PlotIndexSetInteger(6, PLOT_SHIFT, InpMAShift);
    PlotIndexSetInteger(7, PLOT_SHIFT, InpMAShift);
    PlotIndexSetInteger(8, PLOT_SHIFT, InpMAShift);
    
    // Với những vị trí không có giá trị, thiết lập giá trị 0.0
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(6, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(7, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(8, PLOT_EMPTY_VALUE, 0.0);
    
    // Thiết lập màu của nến theo màu nền của biểu đồ
    // Lúc này, người dùng sẽ tập trung vào các SMA mà không quan tâm tới nến
    if(InpChangeColorOfCandle)
    {
        long bgColor = ChartGetInteger(0, CHART_COLOR_BACKGROUND);
        ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, bgColor);
        ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, bgColor);
        ChartSetInteger(0, CHART_COLOR_CHART_DOWN, bgColor);
        ChartSetInteger(0, CHART_COLOR_CHART_UP, bgColor);
        ChartSetInteger(0, CHART_COLOR_CHART_LINE, bgColor);
    }
    
    // Khởi tạo id cho việc vẽ biểu tượng BUY/SELL
    m_symbolId = 0;

    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,            // Đây là vị trí bắt đầu trong mảng price[] có dữ liệu đúng
                const double &price[])      // Đây là bộ đệm giá được truyền vào từ bảng thiết lập
{
    // Tính toán trung bình cộng tương ứng với từng SMA 1,2,3,4,5,6,7,8
    CalculateSMA(rates_total, prev_calculated, begin, price, m_dataBuffer1, InpMAPeriod1);
    CalculateSMA(rates_total, prev_calculated, begin, price, m_dataBuffer2, InpMAPeriod2);
    CalculateSMA(rates_total, prev_calculated, begin, price, m_dataBuffer3, InpMAPeriod3);
    CalculateSMA(rates_total, prev_calculated, begin, price, m_dataBuffer4, InpMAPeriod4);
    CalculateSMA(rates_total, prev_calculated, begin, price, m_dataBuffer5, InpMAPeriod5);
    CalculateSMA(rates_total, prev_calculated, begin, price, m_dataBuffer6, InpMAPeriod6);
    CalculateSMA(rates_total, prev_calculated, begin, price, m_dataBuffer7, InpMAPeriod7);
    CalculateSMA(rates_total, prev_calculated, begin, price, m_dataBuffer8, InpMAPeriod8);
    
    // ----------------------------------------------------
    // Tính toán các giá trị cho chỉ báo tín hiệu BUY/SELL
    if(prev_calculated == 0)
    {
        for(int idx = 1; idx < rates_total - 1; idx++)
        {
            if(IsFanDown(idx) || IsFanUp(idx))
            {
                m_dataBuffer9[idx] = m_dataBuffer7[idx];
            }
            else
                m_dataBuffer9[idx] = 0;
            
            if(IsFanDown(idx))
                m_dataBufferColor[idx] = 1;
            if(IsFanUp(idx))
                m_dataBufferColor[idx] = 0;
        }
    }
    else
    {
        m_dataBuffer9[rates_total - 1] = 0;
        for(int idx = prev_calculated - 1; idx < rates_total - 1 && !IsStopped(); idx++)
        {
            if(IsFanDown(idx) || IsFanUp(idx))
                m_dataBuffer9[idx] = m_dataBuffer7[idx];
            else
                m_dataBuffer9[idx] = 0;
            
            if(IsFanDown(idx))
                m_dataBufferColor[idx] = 1;
            if(IsFanUp(idx))
                m_dataBufferColor[idx] = 0;
        }
    }
    // ----------------------------------------------------
    
    // Qua nến mới
    if(rates_total - prev_calculated > 0)
    {
        int idx = rates_total - 2;
        if(IsFanUp(idx))
        {
            if(InpDrawSymbol)
                DrawSymbolBuy(m_dataBuffer6[rates_total - 2]);
                
            string msg = "All SMAs fanned up! \nBUY LIMIT at " + DoubleToString(m_dataBuffer6[rates_total - 2]);
            if(InpShowAlert)
                Alert(msg);
            if(InpSendNotification)
                SendNotification(msg);

            m_dataBuffer9[rates_total - 2] = m_dataBuffer7[rates_total - 2];
            
        }
        if(IsFanDown(idx))
        {
            if(InpDrawSymbol)
                DrawSymbolSell(m_dataBuffer6[rates_total - 2]);
                
            string msg = "All SMAs fanned down! \nSELL LIMIT at " + DoubleToString(m_dataBuffer6[rates_total - 2]);
            if(InpShowAlert)
                Alert(msg);
            if(InpSendNotification)
                SendNotification(msg);

            m_dataBuffer9[rates_total - 2] = m_dataBuffer7[rates_total - 2];
        }
    }
    return rates_total;
}

//+------------------------------------------------------------------+
// Kiểm tra tại vị trí chỉ định xem SMA có quạt lên không
//+------------------------------------------------------------------+
bool IsFanUp(int idx)
{
    if(m_dataBuffer1[idx] > m_dataBuffer2[idx] &&
       m_dataBuffer2[idx] > m_dataBuffer3[idx] &&
       m_dataBuffer3[idx] > m_dataBuffer4[idx] &&
       m_dataBuffer4[idx] > m_dataBuffer5[idx] &&
       m_dataBuffer5[idx] > m_dataBuffer6[idx] &&
       m_dataBuffer6[idx] > m_dataBuffer7[idx] &&
       m_dataBuffer7[idx] > m_dataBuffer8[idx] &&
       
       // Kiểm tra vị trí trước
       !(m_dataBuffer1[idx - 1] > m_dataBuffer2[idx - 1]  &&
         m_dataBuffer2[idx - 1] > m_dataBuffer3[idx - 1]  &&
         m_dataBuffer3[idx - 1] > m_dataBuffer4[idx - 1]  &&
         m_dataBuffer4[idx - 1] > m_dataBuffer5[idx - 1]  &&
         m_dataBuffer5[idx - 1] > m_dataBuffer6[idx - 1]  &&
         m_dataBuffer6[idx - 1] > m_dataBuffer7[idx - 1]  &&
         m_dataBuffer7[idx - 1] > m_dataBuffer8[idx - 1]) &&
         
       // So sánh vị trí trước so với vị trí hiện tại
       m_dataBuffer1[idx] >= m_dataBuffer1[idx - 1] &&
       m_dataBuffer2[idx] >= m_dataBuffer2[idx - 1] &&
       m_dataBuffer3[idx] >= m_dataBuffer3[idx - 1] &&
       m_dataBuffer4[idx] >= m_dataBuffer4[idx - 1] &&
       m_dataBuffer5[idx] >= m_dataBuffer5[idx - 1] &&
       m_dataBuffer6[idx] >= m_dataBuffer6[idx - 1] &&
       m_dataBuffer7[idx] >= m_dataBuffer7[idx - 1] &&
       m_dataBuffer8[idx] >= m_dataBuffer8[idx - 1] &&
       
       (m_dataBuffer7[idx - 1] <= m_dataBuffer8[idx - 1] ||
        m_dataBuffer6[idx - 1] <= m_dataBuffer7[idx - 1] ||
        m_dataBuffer5[idx - 1] <= m_dataBuffer6[idx - 1] ||
        m_dataBuffer4[idx - 1] <= m_dataBuffer5[idx - 1] ||
        m_dataBuffer3[idx - 1] <= m_dataBuffer4[idx - 1])
       )
    {
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
// Kiểm tra tại vị trí chỉ định xem SMA có quạt xuống không
//+------------------------------------------------------------------+
bool IsFanDown(int idx)
{
    if(m_dataBuffer1[idx] < m_dataBuffer2[idx] &&
       m_dataBuffer2[idx] < m_dataBuffer3[idx] &&
       m_dataBuffer3[idx] < m_dataBuffer4[idx] &&
       m_dataBuffer4[idx] < m_dataBuffer5[idx] &&
       m_dataBuffer5[idx] < m_dataBuffer6[idx] &&
       m_dataBuffer6[idx] < m_dataBuffer7[idx] &&
       m_dataBuffer7[idx] < m_dataBuffer8[idx] &&
       
       // Kiểm tra vị trí trước
       !(m_dataBuffer1[idx - 1] < m_dataBuffer2[idx - 1]  &&
         m_dataBuffer2[idx - 1] < m_dataBuffer3[idx - 1]  &&
         m_dataBuffer3[idx - 1] < m_dataBuffer4[idx - 1]  &&
         m_dataBuffer4[idx - 1] < m_dataBuffer5[idx - 1]  &&
         m_dataBuffer5[idx - 1] < m_dataBuffer6[idx - 1]  &&
         m_dataBuffer6[idx - 1] < m_dataBuffer7[idx - 1]  &&
         m_dataBuffer7[idx - 1] < m_dataBuffer8[idx - 1]) &&
       
       // So sánh vị trí trước với vị trí hiện tại
       m_dataBuffer1[idx] <= m_dataBuffer1[idx - 1] &&
       m_dataBuffer2[idx] <= m_dataBuffer2[idx - 1] &&
       m_dataBuffer3[idx] <= m_dataBuffer3[idx - 1] &&
       m_dataBuffer4[idx] <= m_dataBuffer4[idx - 1] &&
       m_dataBuffer5[idx] <= m_dataBuffer5[idx - 1] &&
       m_dataBuffer6[idx] <= m_dataBuffer6[idx - 1] &&
       m_dataBuffer7[idx] <= m_dataBuffer7[idx - 1] &&
       m_dataBuffer8[idx] <= m_dataBuffer8[idx - 1] &&
       
       (m_dataBuffer7[idx - 1] >= m_dataBuffer8[idx - 1] ||
        m_dataBuffer6[idx - 1] >= m_dataBuffer7[idx - 1] ||
        m_dataBuffer5[idx - 1] >= m_dataBuffer6[idx - 1] ||
        m_dataBuffer4[idx - 1] >= m_dataBuffer5[idx - 1] ||
        m_dataBuffer3[idx - 1] >= m_dataBuffer4[idx - 1])
       
       )
    {
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
// Tính toán trung bình cộng (SMA))
//+------------------------------------------------------------------+
void CalculateSMA(int rates_total, int prev_calculated, int begin, 
                   const double &price[],
                   double &dataBuffer[], int period)
{
    int start;
    // Lần đầu tiên tính toán dữ liệu của chỉ báo
    // Lúc này, giá trị prev_calculated <= 0
    if(prev_calculated <= 0)
    {
        // Giá trị start cần bắt đầu tính toán (bỏ qua 1 khoảng nến đầu tiên)
        start = period + begin;
        
        // Trong khoảng nến đầu tiên cần phải tính giá trung bình, 
        // nên giá trị của bộ đệm SMA sẽ thiết lập là 0
        for(int idx = 0; idx < start - 1; idx++)
            dataBuffer[idx] = 0.0;
            
        // Tính toán giá trị trung bình đầu tiên
        double firstPriceSum = 0;
        for(int idx = begin; idx < start; idx++)
            firstPriceSum += price[idx];

        // Tính trung bình cho giá trị SMA đầu tiên
        dataBuffer[start - 1] = firstPriceSum / period;
    }
    // Từ lần thứ 2 trở đi
    // Giá trị prev_calculated > 0
    else
        start = prev_calculated - 1;
        
    // Công đoạn này tính các vị trí tiếp theo
    // Lưu ý: cách này không tính tổng lại các nến giống như giá trị SMA đầu tiên
    //        điều này sẽ tăng tốc độ xử lý, và việc tính toán hiệu quả hơn
    for(int idx = start; idx < rates_total && !IsStopped(); idx++)
        dataBuffer[idx] = dataBuffer[idx-1] + (price[idx] - price[idx - period]) / period;
}

//+------------------------------------------------------------------+
// Vẽ biểu tượng SELL
//+------------------------------------------------------------------+
void DrawSymbolSell(double price)
{
    CChartObjectArrow *sym = new CChartObjectArrow();
    
    datetime date1 = TimeCurrent();
    // 217: up
    // 218: down
    // 82: sunshine
    // 181: star
    ++m_symbolId;
    char symCode = (char)218;
    sym.Create(0, "sym_" + IntegerToString(m_symbolId), 0, date1, price, symCode);
    sym.Color(clrWhite);
    sym.Selectable(true);
    sym.Anchor(ANCHOR_BOTTOM);
}
void DrawSymbolBuy(double price)
{
    CChartObjectArrow *sym = new CChartObjectArrow();
    
    datetime date1 = TimeCurrent();
    // 217: up
    // 218: down
    // 82: sunshine
    // 181: star
    ++m_symbolId;
    char symCode = (char)217;
    sym.Create(0, "sym_" + IntegerToString(m_symbolId), 0, date1, price, symCode);
    sym.Color(clrWhite);
    sym.Selectable(true);
    sym.Anchor(ANCHOR_TOP);
}