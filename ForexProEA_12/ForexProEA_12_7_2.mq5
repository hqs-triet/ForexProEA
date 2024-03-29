#property description "Chiến thuật MoMo"
#property copyright "ForexProEA"
#property link "https://www.facebook.com/groups/forexproea/"
#property version   "12.72"

// Mã số định danh cho EA (để phân biệt với các EA khác)
#define MAGIC_NUMBER 10001272

#include <trade/trade.mqh>
#include <expert/expertbase.mqh>
#include  "..\libs\ExpertWrapper.mqh"
#include  "..\libs\Common.mqh"

// ===================================================================
// Tham số đầu vào của EA [start]
// ===================================================================
input string InpCommentPlus = "MoMo";  // Ghi chú thêm vào mỗi lệnh
input ENUM_TIMEFRAMES InpMoMoTF = PERIOD_M5;    // Khung thời gian giao dịch chỉ định
//#include  "..\libs\Algorithm\MoMo.mqh"
#include  "..\libs\Algorithm\MoMo_V1.mqh"

// ===================================================================
// Tham số đầu vào của EA [ end ]
// ===================================================================


// ===================================================================
// Khai báo các đối tượng cục bộ [start]
// ===================================================================
// Sử dụng đối tượng để thao tác mở lệnh trong EA
CTrade        m_trader;
// Đối tượng truy xuất thông tin giá
AllSeriesInfo m_infoCurrencyMoMoAlgo;

// Thông tin chung
string m_symbolCurrency;    // Cặp tiền tệ đang trade
ENUM_TIMEFRAMES m_tf;       // Khung thời gian đang trade
int m_prevCalculated;       // Lưu số lượng nến trước đó, dùng để tính số lượng nến phát sinh
int m_limit;                // Lưu số lượng nến phát sinh động

CMoMo *m_momo;

// ===================================================================
// Khai báo các đối tượng cục bộ [ end ]
// ===================================================================


//+------------------------------------------------------------------+
// Khởi tạo các thông số cho chiến thuật
//+------------------------------------------------------------------+
int Init(string symbol, ENUM_TIMEFRAMES tf)
{
    // Lưu các tham số khởi tạo
    m_symbolCurrency = symbol;
    m_tf = tf;
    
    // Khởi tạo đối tượng thao tác mở lệnh
    m_trader.SetExpertMagicNumber(MAGIC_NUMBER); // Số định danh
    m_trader.SetMarginMode();
    m_trader.SetTypeFillingBySymbol(m_symbolCurrency);
    
    // Khởi tạo thông tin cho đối tượng MoMo
    m_infoCurrencyMoMoAlgo.init(m_symbolCurrency, InpMoMoTF);
    m_momo = new CMoMo();
    m_momo.Init(m_symbolCurrency, InpMoMoTF, m_trader, m_infoCurrencyMoMoAlgo, InpCommentPlus, MAGIC_NUMBER);

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
// Xử lý chính của chiến thuật
//+------------------------------------------------------------------+
void Process()
{
    // Xử lý các tác vụ chung
    ProcessCommon();
    
    // ===================================================================
    // Xử lý chính giao dịch [start]
    // ===================================================================
    
    if(m_momo.RequireRealtime() || m_limit > 0)
        m_momo.Process(m_limit);
    
    // ===================================================================
    // Xử lý chính giao dịch [ end ]
    // ===================================================================
}
//+------------------------------------------------------------------+
// Xử lý chung của chiến thuật mỗi khi sự kiện tick xuất hiện
//+------------------------------------------------------------------+
void ProcessCommon()
{
    // Tính toán số lượng nến phát sinh
    int bars = Bars(m_symbolCurrency, m_tf);
    m_limit = bars - m_prevCalculated;
    m_prevCalculated = bars;
}

//+------------------------------------------------------------------+
//| Khởi tạo ban đầu
//+------------------------------------------------------------------+
int OnInit()
{
    // Khởi tạo chung
    return Init(Symbol(), Period());
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Sự kiện chính
//+------------------------------------------------------------------+
void OnTick()
{
    Process();
}
