#include "wmain.h"

MainWindow::MainWindow(QWidget *parent)
    : QWidget(parent)
{
    //--- ETH group ---
    eline_eth_ip = new QLineEdit("10.1.7.234");
    eline_eth_port = new QLineEdit("3000");
    btn_eth = new QPushButton(tr("&Open"));
    btn_eth->setCheckable(true);

    QHBoxLayout *hbox_eth_prm = new QHBoxLayout;
    hbox_eth_prm->addWidget(eline_eth_ip);
    hbox_eth_prm->addWidget(eline_eth_port);

    QHBoxLayout *hbox_eth_btn = new QHBoxLayout;
    hbox_eth_btn->addWidget(btn_eth);

    QVBoxLayout *lvbox_eth = new QVBoxLayout;
    lvbox_eth->addLayout(hbox_eth_prm);
    lvbox_eth->addLayout(hbox_eth_btn);

    QGroupBox *grbox_eth = new QGroupBox(tr("&Eth"));
    grbox_eth->setLayout(lvbox_eth);


    //--- Image group ---
    btn_img_open = new QPushButton(tr("&Open"));
    chbox_img = new QCheckBox(tr("&View"));

    QVBoxLayout *lvbox_img = new QVBoxLayout;
    lvbox_img->addWidget(btn_img_open);
    lvbox_img->addWidget(chbox_img);

    QGroupBox *grbox_img = new QGroupBox(tr("&Image"));
    grbox_img->setLayout(lvbox_img);


    //--- USR group ---
    btn_usr_set = new QPushButton(tr("&Set"));

    QVBoxLayout *lvbox_usr = new QVBoxLayout;
    lvbox_usr->addWidget(btn_usr_set);

    QGroupBox *grbox_usr = new QGroupBox(tr("&Usr"));
    grbox_usr->setLayout(lvbox_usr);


    //--- Log group ---
    etext_log = new QTextEdit;
    etext_log->setReadOnly(true);

    QVBoxLayout *lvbox_log = new QVBoxLayout;
    lvbox_log->addWidget(etext_log);

    QGroupBox *grbox_log = new QGroupBox(tr("&Log"));
    grbox_log->setLayout(lvbox_log);

//    //--- ImageViewer group ---
//    imgview = new QLabel;

//    QVBoxLayout *lvbox_imgview = new QVBoxLayout;
//    lvbox_imgview->addWidget(imgview);

//    QGroupBox *grbox_imgview = new QGroupBox(tr("&Viewer"));
//    grbox_imgview->setLayout(lvbox_imgview);

    //--- Ctrl group ---
    QVBoxLayout *lvbox_ctrl = new QVBoxLayout;
    lvbox_ctrl->addWidget(grbox_eth);
    lvbox_ctrl->addWidget(grbox_img);
    lvbox_ctrl->addWidget(grbox_usr);
    lvbox_ctrl->addStretch(1);

    QGroupBox *grbox_ctrl = new QGroupBox(tr("&Ctrl"));
    grbox_ctrl->setLayout(lvbox_ctrl);


    //!!! MainForm Layout !!!
    QHBoxLayout *lhbox_form = new QHBoxLayout;
    lhbox_form->addWidget(grbox_ctrl);
    lhbox_form->addWidget(grbox_log);

    QVBoxLayout *lvbox_form = new QVBoxLayout;
    lvbox_form->addLayout(lhbox_form);
    setLayout(lvbox_form);



    //---
    eth.udpSocket = new QUdpSocket(this);

    connect(eth.udpSocket, SIGNAL(readyRead()),
            this, SLOT(eth_rxd()));

    connect(btn_usr_set, SIGNAL(clicked()),
            this, SLOT(cfg_txd()));

    connect(btn_eth, SIGNAL(clicked()),
            this, SLOT(eth_on_off()));

}

MainWindow::~MainWindow()
{

}


void MainWindow::eth_rxd()
{
    while (eth.udpSocket->hasPendingDatagrams()) {
        QByteArray rxd;
        rxd.resize(eth.udpSocket->pendingDatagramSize());
        eth.udpSocket->readDatagram(rxd.data(), rxd.size());

        etext_log->append(QString("%1: size=0x%2")
                          .arg(__func__)
                          .arg(rxd.size(), 0 , 16));
    }
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

    eth.udpSocket->writeDatagram(txd, eth.ip, eth.port);

    etext_log->append(QString("%1: data=0x%2,0x%3,0x%4,0x%5")
                      .arg(__func__)
                      .arg(txd16[0], 0 , 16)
                      .arg(txd16[1], 0 , 16)
                      .arg(txd16[2], 0 , 16)
                      .arg(txd16[3], 0 , 16));
}


void MainWindow::eth_on_off()
{
    bool ok;
    QString str = eline_eth_port->text();
    eth.ip = QHostAddress(eline_eth_ip->text());
    eth.port = str.toInt(&ok, 10);

    if ( btn_eth->isChecked() ){
        eth.udpSocket->bind(eth.port);
        btn_eth->setText("Close");
        etext_log->append(QString("%1: %2 %3/%4")
                          .arg(__func__)
                          .arg("open")
                          .arg(eth.ip.toString())
                          .arg(eth.port, 0 , 10));
    }
    else {
        eth.udpSocket->close();
        btn_eth->setText("Open");
        etext_log->append(QString("%1: %2")
                          .arg(__func__)
                          .arg("closed"));
    }

}

