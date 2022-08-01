//+------------------------------------------------------------------+
//|                                           ForexProEA_6_5_BasicExtIndicator.mq5 |
//|                                                     Forex Pro EA |
//|                      https://www.facebook.com/groups/forexproea/ |
//+------------------------------------------------------------------+
#property copyright "Forex Pro EA"
#property link      "https://www.facebook.com/groups/forexproea/"
#property version   "1.00"

// Khai báo sử dụng chỉ báo chung với biểu đồ chính
#property indicator_chart_window
// Tổng số bộ đệm
#property indicator_buffers 1
// Chỉ định tổng số đường hiển thị
#property indicator_plots   1

//--------------------------------------------------------------
//--- Thông tin thiết lập cho đường trung bình SMA
#property indicator_label1  "SMA"
#property indicator_type1   DRAW_LINE
#property indicator_width1  1
#property indicator_color1  clrSteelBlue 
#property indicator_style1  STYLE_SOLID
//--------------------------------------------------------------

//--------------------------------------------------------------
// Tham số đầu vào (input)
//--------------------------------------------------------------
input int                   InpMAPeriod = 20;               // Giai đoạn nến của đường trung bình SMA
input ENUM_APPLIED_PRICE    InpAppliedPrice = PRICE_CLOSE;  // Áp dụng loại giá
input int InpMAShift = 0;                                   // Dịch chuyển hiển thị theo khoảng nến nhất định (shift)
//--------------------------------------------------------------

// Khai báo bộ đệm hiển thị
double m_smaBuffer[];
int m_smaHandler;

//+------------------------------------------------------------------+
//| Sự kiện khởi tạo
//+------------------------------------------------------------------+
int OnInit()
{
    // Thiết lập mapping bộ đệm của biến lưu trữ với bộ đệm hiển thị lên biểu đồ
    SetIndexBuffer(0, m_smaBuffer, INDICATOR_DATA);
    
    // Thiết lập hiển thị chính xác số thập phân
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
    
    // Di chuyển SMA theo khoảng nến nhất định (shift)
    PlotIndexSetInteger(0, PLOT_SHIFT, InpMAShift);
    
    // Với những vị trí không có giá trị, thiết lập giá trị 0.0
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    
    m_smaHandler = iMA(NULL, 0, InpMAPeriod, InpMAShift, MODE_SMA, InpAppliedPrice);
    
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Sự kiện được gọi mỗi khi có tín hiệu từ server
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
    // Tính toán các giá trị cho chỉ báo tín hiệu BUY/SELL
    int calculated = BarsCalculated(m_smaHandler);
    if(calculated < rates_total)
    {
        Print("Không tính toán được dữ liệu của SMA (", calculated,". Lỗi: ", GetLastError());
        return(0);
    }
    
    int copyCount;

    // Thời điểm khởi đầu -> Copy hết dữ liệu
    if(prev_calculated > rates_total || prev_calculated <= 0)
    {
        // Đọc dữ liệu bỏ qua số lượng phần tử (giai đoạn) của SMA
        copyCount = rates_total - InpMAPeriod;
        for(int idx = 0; idx < rates_total && !IsStopped(); idx++)
            m_smaBuffer[idx] = 0.0;
    }
    // Từ lần thứ 2 trở đi, chỉ copy dữ liệu cần thiết
    else
    {
        copyCount = rates_total - prev_calculated;
        if(prev_calculated > 0)
            copyCount++;
    }
    
    if(IsStopped())
        return(0);

    // Đọc dữ liệu từ chỉ báo bên ngoài SMA
    if(CopyBuffer(m_smaHandler, 0, 0, copyCount, m_smaBuffer) <= 0)
    {
        Print("Không đọc được dữ liệu của SMA. Lỗi: ", GetLastError());
        return(0);
    }
    
    // Theo luồng xử lý của chỉ báo, 
    // giá trị trả về sẽ được truyền vào tham số prev_calculated cho lần gọi hàm tiếp theo
    return rates_total;
}