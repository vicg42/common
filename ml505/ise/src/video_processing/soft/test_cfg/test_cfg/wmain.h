#ifndef WMAIN_H
#define WMAIN_H

#include <QWidget>
#include <QtNetwork>
#include <QtGui>


#define C_ETH_PKT_TYPE_CFG         0xA

//C_CFGPKT_WR_BIT/ Bit Map:
#define C_CFGPKT_WR                0
#define C_CFGPKT_RD                1
//HEADER(0)/ Bit map:
#define C_CFGPKT_TYPE_BIT          0 //Тип пакета
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

#define C_CFGDEV_SWT               0
#define C_CFGDEV_ETH               1
#define C_CFGDEV_VCTRL             2
#define C_CFGDEV_TMR               3
#define C_CFGDEV_HDD               5
#define C_CFGDEV_TESTING           6


struct TUDev{
    struct TEth{
        QUdpSocket *udpSocket;
        QHostAddress ip;
        qint16 port;
    }eth;
};

class MainWindow : public QWidget
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = 0);
    ~MainWindow();

private:

    TUDev udev;

    QLineEdit *eline_eth_ip;
    QLineEdit *eline_eth_port;
    QPushButton *btn_eth;

    QPushButton *btn_img_open;
    QCheckBox *chbox_img;

    QPushButton *btn_usr_set;

    QTextEdit *etext_log;

    QLabel *lbimage;

    bool imgToboard(QImage *img);

//    void dev_pkt(unsigned char *data, unsigned char *dir, unsigned char dev);
    qint64 dev_write(unsigned char *data, long long dlen, unsigned char interface);

private slots:

    void cfg_txd();
    void eth_rxd();
    void eth_on_off();
    void img_open();

};

#endif // WMAIN_H
