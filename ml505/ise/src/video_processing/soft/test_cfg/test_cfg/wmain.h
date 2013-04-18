#ifndef WMAIN_H
#define WMAIN_H

#include <QMainWindow>
#include <QtNetwork>

//C_CFGPKT_WR_BIT/ Bit Map:
#define C_CFGPKT_WR                0
#define C_CFGPKT_RD                1
//HEADER(0)/ Bit map:
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

struct TEth_dev{
    QHostAddress ip;
    qint16 port;
};

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT
    
public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();
    
private:
    Ui::MainWindow *ui;
    QUdpSocket *udpSocket;
    TEth_dev eth_dev;

private slots:

    void cfg_txd();
    void cfg_rxd();

    void eth_rxd();

};

#endif // WMAIN_H
