#property description "This is demo EA for lessons on learning group."
#property copyright "ForexProEA"
#property link "https://www.facebook.com/groups/forexproea/"
#property version   "5.20"

// Mã số định danh cho EA (để phân biệt với các EA khác)
#define MAGIC_NUMBER 10000511

#include <trade/trade.mqh>
#include <expert/expertbase.mqh>
#include  "..\libs\ExpertWrapper.mqh"

#include  "..\libs\Common.mqh"
#include  "..\libs\PriceAction.mqh"


// ===================================================================
// Tham số đầu vào của EA [start]
// ===================================================================
input double InpFixedLot = 0.01;                    // Khối lượng vào lệnh
input string InpCommentPlus = "weg";                // Ghi chú thêm vào mỗi lệnh
input ENUM_TIMEFRAMES InpWedge_Tf = PERIOD_CURRENT; // Khung thời gian
#include  "..\libs\Algorithm\Wedge.mqh"
// ===================================================================
// Tham số đầu vào của EA [ end ]
// ===================================================================


// ===================================================================
// Khai báo các đối tượng cục bộ [start]
// ===================================================================
// Sử dụng đối tượng để thao tác mở lệnh trong EA
CTrade        m_trader;
// Đối tượng truy xuất thông tin giá
AllSeriesInfo m_infoCurrency, m_infoCurrencyWedge;

// Thông tin chung
string m_symbolCurrency;    // Cặp tiền tệ đang trade
ENUM_TIMEFRAMES m_tf;       // Khung thời gian đang trade
int m_prevCalculated;       // Lưu số lượng nến trước đó, dùng để tính số lượng nến phát sinh
int m_limit;                // Lưu số lượng nến phát sinh động

CWedge *m_wedge;
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
    
    m_infoCurrencyWedge.init(m_symbolCurrency, InpWedge_Tf);
    m_wedge = new CWedge();
    m_wedge.Init(m_symbolCurrency, InpWedge_Tf, m_trader, m_infoCurrencyWedge, InpCommentPlus, MAGIC_NUMBER);
    m_wedge.Vol(InpFixedLot);
    
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
     
    m_wedge.Process(m_limit);
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
