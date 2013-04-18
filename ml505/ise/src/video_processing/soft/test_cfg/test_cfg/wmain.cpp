#include "wmain.h"
#include "ui_wmain.h"


MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    ui->txtedit_log->setReadOnly(true);

    eth_dev.ip.setAddress("10.1.7.234");
    eth_dev.port = 3000;

    udpSocket = new QUdpSocket(this);
    udpSocket->bind(eth_dev.port);

    connect(udpSocket, SIGNAL(readyRead()),
            this, SLOT(eth_rxd()));

    connect(ui->BtnTx, SIGNAL(clicked()),
            this, SLOT(cfg_txd()));
    connect(ui->BtnRx, SIGNAL(clicked()),
            this, SLOT(cfg_rxd()));
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::eth_rxd()
{
    while (udpSocket->hasPendingDatagrams()) {
        QByteArray rxd;
        rxd.resize(udpSocket->pendingDatagramSize());
        udpSocket->readDatagram(rxd.data(), rxd.size());

        ui->txtedit_log->append(QString("%1: size=0x%2")
                                .arg(__func__)
                                .arg(rxd.size(), 0 , 16));
    }
}

void MainWindow::cfg_rxd()
{
    QByteArray txd;
    txd.resize((3 + 0) * sizeof(qint16));
    qint16 *txd16 = (qint16 *)txd.data();
    txd16[0] = ((0 & C_CFGPKT_DADR_MASK) << 1) |
            (C_CFGPKT_RD << C_CFGPKT_WR_BIT) | (0 << C_CFGPKT_FIFO_BIT);
    txd16[1] = (1 & C_CFGPKT_RADR_MASK) << C_CFGPKT_RADR_L_BIT;
    txd16[2] = (1 & C_CFGPKT_DLEN_MASK) << C_CFGPKT_DLEN_L_BIT;

    udpSocket->writeDatagram(txd, eth_dev.ip, eth_dev.port);

    ui->txtedit_log->append(QString("%1: data=0x%2,0x%3,0x%4")
                            .arg(__func__)
                            .arg(txd16[0], 0 , 16)
                            .arg(txd16[1], 0 , 16)
                            .arg(txd16[2], 0 , 16));
}

void MainWindow::cfg_txd()
{
    QByteArray txd;
    txd.resize((3 + 1) * sizeof(qint16));
    qint16 *txd16 = (qint16 *)txd.data();
    txd16[0] = ((0 & C_CFGPKT_DADR_MASK) << 1) |
            (C_CFGPKT_WR << C_CFGPKT_WR_BIT) | (0 << C_CFGPKT_FIFO_BIT);
    txd16[1] = (1 & C_CFGPKT_RADR_MASK) << C_CFGPKT_RADR_L_BIT;
    txd16[2] = (1 & C_CFGPKT_DLEN_MASK) << C_CFGPKT_DLEN_L_BIT;
    txd16[3] = 5;

    udpSocket->writeDatagram(txd, eth_dev.ip, eth_dev.port);

    ui->txtedit_log->append(QString("%1: data=0x%2,0x%3,0x%4,0x%5")
                            .arg(__func__)
                            .arg(txd16[0], 0 , 16)
                            .arg(txd16[1], 0 , 16)
                            .arg(txd16[2], 0 , 16)
                            .arg(txd16[3], 0 , 16));
}
