//+------------------------------------------------------------------+
//|                                           ForexProEA_6_2_SMA.mq5 |
//|                                                     Forex Pro EA |
//|                      https://www.facebook.com/groups/forexproea/ |
//+------------------------------------------------------------------+
#property copyright "Forex Pro EA"
#property link      "https://www.facebook.com/groups/forexproea/"
#property version   "1.00"

// Khai báo sử dụng chỉ báo chung với biểu đồ chính
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

//--- Thông tin thiết lập cho đường trung bình SMA
#property indicator_label1  "SMA1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

input int InpMAPeriod = 20;         // Giai đoạn của đường SMA

// Bộ đệm dùng lưu giá trị của SMA
double m_dataBuffer[];

//+------------------------------------------------------------------+
//| Sự kiện khởi tạo
//+------------------------------------------------------------------+
int OnInit()
{
    // Thiết lập mapping bộ đệm của biến lưu trữ với bộ đệm hiển thị lên biểu đồ
    SetIndexBuffer(0, m_dataBuffer, INDICATOR_DATA);
    
    // Với những vị trí không có giá trị, thiết lập giá trị 0.0
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Sự kiện được gọi mỗi khi có tín hiệu từ server
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,        // Đây là vị trí bắt đầu trong mảng price[] có dữ liệu đúng
                const double &price[])  // Đây là bộ đệm giá được truyền vào từ bảng thiết lập 
  {
    int start;
    // Lần đầu tiên tính toán dữ liệu của chỉ báo
    // Lúc này, giá trị prev_calculated <= 0
    if(prev_calculated <= 0)
    {
        // Giá trị start cần bắt đầu tính toán (bỏ qua 1 khoảng nến đầu tiên)
        start = InpMAPeriod + begin;
        
        // Trong khoảng nến đầu tiên cần phải tính giá trung bình, 
        // nên giá trị của bộ đệm SMA sẽ thiết lập là 0
        for(int idx = 0; idx < start - 1; idx++)
            m_dataBuffer[idx] = 0.0;
            
        // Tính toán giá trị trung bình đầu tiên
        double firstPriceSum = 0;
        for(int idx = begin; idx < start; idx++)
            firstPriceSum += price[idx];

        // Tính trung bình cho giá trị SMA đầu tiên
        m_dataBuffer[start - 1] = firstPriceSum / InpMAPeriod;
    }
    // Từ lần thứ 2 trở đi
    // Giá trị prev_calculated > 0
    else
        start = prev_calculated - 1;
        
    // Công đoạn này tính các vị trí tiếp theo
    // Lưu ý: cách này không tính tổng lại các nến giống như giá trị SMA đầu tiên
    //        điều này sẽ tăng tốc độ xử lý, và việc tính toán hiệu quả hơn
    for(int idx = start; idx < rates_total && !IsStopped(); idx++)
        m_dataBuffer[idx] = m_dataBuffer[idx-1] + (price[idx] - price[idx - InpMAPeriod]) / InpMAPeriod;
        
    // Theo luồng xử lý của chỉ báo, 
    // giá trị trả về sẽ được truyền vào tham số prev_calculated cho lần gọi hàm tiếp theo
    return(rates_total);
}
//+------------------------------------------------------------------+