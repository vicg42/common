#ifndef WMAIN_H
#define WMAIN_H

#include <QWidget>
#include <QtNetwork>
#include <QtGui>


#define C_BOARD_IF                 0 //Интерфейс обмена с платой
#define C_BOARD_VCH_COUNT_MAX      4

#define C_PKT_TYPE_CFG             0xA

//--- CFG ---
#define C_CFGPKT_HEADER_SIZE       3
#define C_CFGPKT_DATA_ALIGN        sizeof(uint16_t)
//C_CFGPKT_WR_BIT/ Bit Map:
#define C_CFGPKT_WR                0
#define C_CFGPKT_RD                1
//HEADER(0)/ Bit map:
#define C_CFGPKT_TYPE_BIT          0 //Тип пакета
#define C_CFGPKT_TYPE_MASK         0xF
#define C_CFGPKT_FIFO_BIT          6 //Тип адресации 1 - FIFO/0 - Регистр(авто инкрементация адреса)
#define C_CFGPKT_WR_BIT            7 //Тип пакета - запись/чтение
#define C_CFGPKT_DADR_L_BIT        8 //Адрес модуля в проекте FPGA
#define C_CFGPKT_DADR_MASK         0xFF
//HEADER(1)/ Bit map:
#define C_CFGPKT_RADR_L_BIT        0 //Адрес начального регистра
#define C_CFGPKT_RADR_MASK         0xFFFF
//HEADER(2)/ Bit map:
#define C_CFGPKT_DLEN_L_BIT        0 //Кол-во данных для записи/чтения
#define C_CFGPKT_DLEN_MASK         0xFFFF
//cfg device map:
#define C_CFGDEV_SWT               0
#define C_CFGDEV_ETH               1
#define C_CFGDEV_FG                2
#define C_CFGDEV_TMR               3
#define C_CFGDEV_HDD               5
#define C_CFGDEV_TESTING           6


//--- FG ---
#define C_FR_REG_CTRL                     0
#define C_FR_REG_DATA_L                   1
#define C_FR_REG_DATA_M                   2
#define C_FR_REG_MEM_CTRL                 3 //(15..8)(7..0) - trn_mem_rd;trn_mem_wr
#define C_FR_REG_TST0                     4

#define C_FG_REG_CTRL_VCH_L_BIT           0 //Номер видео канала
#define C_FG_REG_CTRL_VCH_MASK            0xF
#define C_FG_REG_CTRL_PRM_L_BIT           4 //Номер парамера
#define C_FG_REG_CTRL_PRM_MASK            0x7
#define C_FG_REG_CTRL_SET_BIT             7
#define C_FG_REG_CTRL_SET_IDLE_BIT        8
#define C_FG_REG_CTRL_RAMCOE_ADR_BIT      9
#define C_FG_REG_CTRL_RAMCOE_DATA_BIT     10
#define C_FG_REG_CTRL_RAMCOE_L_BIT        11 //Номер RAMCOE
#define C_FG_REG_CTRL_RAMCOE_MASK         0x7

#define C_FG_PRM_MEM_ADR_WR               0 //Базовый адрес буфера записи видео
#define C_FG_PRM_MEM_ADR_RD               1 //Базовый адрес буфера чтения видео
#define C_FG_PRM_FR_ZONE_SKIP             2
#define C_FG_PRM_FR_ZONE_ACTIVE           3
#define C_FG_PRM_FR_OPTIONS               4


#define C_UDEV_REQ_WRITE                  1
#define C_UDEV_REQ_READ                   0

struct TUDevWR {
  struct TReq {
    uint8_t *data;
    uint64_t size;
  }tx,rx;
  uint8_t dir; //1/0 - wr/rd request
};

struct TUDev {
  struct TEth {
    QUdpSocket *udpSocket;
    QHostAddress ip;
    qint16 port;
  }eth;
};

struct TVCH_prm {
  struct TVFr_size {
    struct TXY {
      uint16_t x;
      uint16_t y;
    }activ, skip;
  }fr_size;
};

struct TFG_prm {
  TVCH_prm  vch[C_BOARD_VCH_COUNT_MAX];
  uint8_t  vch_count;
};


class MainWindow : public QWidget
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = 0);
    ~MainWindow();

private:

    TUDev  udev;
    TFG_prm  fg;

    QLineEdit *eline_eth_ip;
    QLineEdit *eline_eth_port;
    QPushButton *btn_eth;

    QPushButton *btn_img_open;
    QCheckBox *chbox_img;

    QPushButton *btn_usr_set;

    QTextEdit *etext_log;

    QLabel *lbimage;

    bool imgToboard(QImage *img);

    bool board_init(void);
    int16_t get_firmware(void);
    bool set_vch_prm(uint8_t vch, TVCH_prm  val);
    bool cfg_write(uint16_t cfgdev, uint16_t sreg,
                   uint8_t tpkt, uint8_t *data, uint16_t dlen, uint8_t fifo);

    bool cfg_read(uint16_t cfgdev, uint16_t sreg,
                   uint8_t tpkt, uint8_t *data, uint16_t dlen, uint8_t fifo);

    bool dev_write(TUDevWR rq);


private slots:

    void cfg_txd();
    void eth_rxd();
    void eth_on_off();
    void img_open();

};

#endif // WMAIN_H
