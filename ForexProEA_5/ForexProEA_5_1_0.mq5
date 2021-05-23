#property description "This is demo EA for lessons on learning group."
#property copyright "ForexProEA"
#property link "https://www.facebook.com/groups/forexproea/"
#property version   "5.10"

// Mã số định danh cho EA (để phân biệt với các EA khác)
#define MAGIC_NUMBER 10000510

#include <trade/trade.mqh>
#include <expert/expertbase.mqh>
#include  "..\libs\ExpertWrapper.mqh"

#include  "..\libs\Common.mqh"
#include  "..\libs\PriceAction.mqh"
        
// ===================================================================
// Tham số đầu vào của EA [start]
// ===================================================================


// ===================================================================
// Tham số đầu vào của EA [ end ]
// ===================================================================


// ===================================================================
// Khai báo các đối tượng cục bộ [start]
// ===================================================================
// Sử dụng đối tượng để thao tác mở lệnh trong EA
CTrade        m_trader;
// Đối tượng truy xuất thông tin giá
AllSeriesInfo m_infoCurrency;

// Thông tin chung
string m_symbolCurrency;    // Cặp tiền tệ đang trade
ENUM_TIMEFRAMES m_tf;       // Khung thời gian đang trade
int m_prevCalculated;       // Lưu số lượng nến trước đó, dùng để tính số lượng nến phát sinh
int m_limit;                // Lưu số lượng nến phát sinh động



// ===================================================================
// Khai báo các đối tượng cục bộ [ end ]
// ===================================================================


//+------------------------------------------------------------------+
// Khởi tạo các thông số cho chiến thuật
//+------------------------------------------------------------------+
bool Init(string symbol, ENUM_TIMEFRAMES tf)
{
    // Lưu các tham số khởi tạo
    m_symbolCurrency = symbol;
    m_tf = tf;
    // Khởi tạo đối tượng thao tác mở lệnh
    m_trader.SetExpertMagicNumber(MAGIC_NUMBER); // Số định danh
    m_trader.SetMarginMode();
    m_trader.SetTypeFillingBySymbol(m_symbolCurrency);
    
    // Khởi tạo đối tượng thao tác giá
    m_infoCurrency.init(m_symbolCurrency, m_tf);
    
    // ===================================================================
    
    // For test only
    Print("ChartID=" + ChartID());
    
    return true;
}

//+------------------------------------------------------------------+
// Xử lý chính của chiến thuật
//+------------------------------------------------------------------+
void Process()
{
    // Xử lý các tác vụ chung
    ProcessCommon();
    
    // Đọc dữ liệu của các chỉ báo
    ReadIndicatorData();
    
    // Tiết kiệm CPU bằng cách chỉ xử lý khi có nến mới
    if(m_limit <= 0)
        return;

    // ===================================================================
    // Xử lý chính giao dịch [start]
    // ===================================================================
    if(IsHammerBar(1, m_infoCurrency))
        Print("Nến búa!");
        
    if(IsReverseHammerBar(1, m_infoCurrency))
        Print("Nến búa ngược!");
        
    if(IsPinBarSmall(1, m_infoCurrency))
        Print("Nến pinbar nhỏ!");
    if(IsBearishPinBar(1, m_infoCurrency))
        Print("Nến pinbar giảm mạnh!");
    if(IsBullishPinBar(1, m_infoCurrency))
        Print("Nến pinbar tăng mạnh!");
    
    if(IsPinBarBig(1, m_infoCurrency))
        Print("Nến pinbar lớn!");
    
    if(IsShootingStarBar(1, m_infoCurrency))
        Print("Nến sao băng!");
    
    if(IsInsideBar(1, m_infoCurrency))
        Print("Nến inside (lọt lòng)!");
    
    if(IsEngulfing(1, m_infoCurrency))
        Print("Nến nhấn chìm!");
    if(IsBearishEngulfing(1, m_infoCurrency))
        Print("Nến nhấn chìm giảm!");
    if(IsBullishEngulfing(1, m_infoCurrency))
        Print("Nến nhấn chìm tăng!");
    
    if(IsDojiCandle(1, m_infoCurrency))
        Print("Nến chuồng chuồng!");
    
    if(IsDoubleDojiCandle(1, m_infoCurrency))
        Print("Cặp chuồng chuồng!");
    
    if(IsTripleDojiCandle(1, m_infoCurrency))
        Print("3 anh em chuồng chuồng!");
        
    // ===================================================================
    // Xử lý chính giao dịch [ end ]
    // ===================================================================
}
//+------------------------------------------------------------------+
// Xử lý chung của chiến thuật mỗi khi sự kiện tick xuất hiện
//+------------------------------------------------------------------+
void ProcessCommon()
{
    // Cập nhật thông tin mới nhất của giá mỗi khi có tick
    m_infoCurrency.refresh();
    
    // Tính toán số lượng nến phát sinh
    int bars = Bars(m_symbolCurrency, m_tf);
    m_limit = bars - m_prevCalculated;
    m_prevCalculated = bars;
}

//+------------------------------------------------------------------+
// Đọc dữ liệu của các indicator
//+------------------------------------------------------------------+
void ReadIndicatorData()
{
    // Tính toán số lượng nến cần đọc
    int bars = Bars(m_symbolCurrency, m_tf);
    
}

//+------------------------------------------------------------------+
//| Khởi tạo ban đầu
//+------------------------------------------------------------------+
int OnInit()
{
    
    // Khởi tạo chung
    Init(Symbol(), Period());
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Sự kiện chính
//+------------------------------------------------------------------+
void OnTick()
{
    Process();
}
