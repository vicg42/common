#include "wmain.h"
#include "timestamp.h"

namespace LDCU = Linkos::DCU;

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

    //--- ImageViewer group ---
    lbimage = new QLabel;

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
    udev.eth.udpSocket = new QUdpSocket(this);

    connect(udev.eth.udpSocket, SIGNAL(readyRead()),
            this, SLOT(eth_rxd()));

    connect(btn_usr_set, SIGNAL(clicked()),
            this, SLOT(cfg_txd()));

    connect(btn_eth, SIGNAL(clicked()),
            this, SLOT(eth_on_off()));

    connect(btn_img_open, SIGNAL(clicked()),
            this, SLOT(img_open()));


}

MainWindow::~MainWindow()
{

}


void MainWindow::eth_rxd()
{
    while (udev.eth.udpSocket->hasPendingDatagrams()) {
        QByteArray rxd;
        rxd.resize(udev.eth.udpSocket->pendingDatagramSize());
        udev.eth.udpSocket->readDatagram(rxd.data(), rxd.size());

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

    //eth.udpSocket->writeDatagram(txd, eth.ip, eth.port);
    dev_transport((quint8 *) txd.data(), (qint64) txd.size(), 0);

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
    udev.eth.ip = QHostAddress(eline_eth_ip->text());
    udev.eth.port = str.toInt(&ok, 10);

    if ( btn_eth->isChecked() ){
        udev.eth.udpSocket->bind(udev.eth.port);
        btn_eth->setText("Close");
        etext_log->append(QString("%1: %2 %3/%4")
                          .arg(__func__)
                          .arg("open")
                          .arg(udev.eth.ip.toString())
                          .arg(udev.eth.port, 0 , 10));
    }
    else {
        udev.eth.udpSocket->close();
        btn_eth->setText("Open");
        etext_log->append(QString("%1: %2")
                          .arg(__func__)
                          .arg("closed"));
    }

}


void MainWindow::img_open()
{
    QString fileName = QFileDialog::getOpenFileName(this,
                                                    trUtf8("Select files"),
                                                    trUtf8(""),
                                                    trUtf8("Images (*.png *.jpeg *.jpg);;All (*.*)"));
    if (!fileName.isEmpty()) {
        QImage img(fileName);
        if (img.isNull()) {
            QMessageBox::information(this, tr("Image Viewer"),
                                     tr("Cannot load %1.").arg(fileName));
            return;
        }

        if	(	(img.width() > 0xFFFF)
            ||	(img.height() > 0xFFFF)
            )
        {
            QMessageBox::information(this, tr("Image Viewer"),
                                     tr("Too big image (isn't compatible with \"video row\" format)"));
            return;
        }

//        lbimage->setPixmap(QPixmap::fromImage(img));
/*        scaleFactor = 1.0;

        printAct->setEnabled(true);
        fitToWindowAct->setEnabled(true);
        updateActions();

        if (!fitToWindowAct->isChecked())
            imageLabel->adjustSize();*/

        imgToboard(&img);
    }

}

bool MainWindow::imgToboard(QImage *img)
{
    size_t frame = 0;
    size_t split = 1024;
    size_t width = img->width();

    if (width % 4)
    {
        width += 4 - width % 4;
        //cout << "Warning: Image width is realigned, new width is " << width << endl;
    }

    if (!split)
        split = width;
    else
    if (split >= width)
    {
        split = width;
        //cout << "Warning: Too small image width (will not be splitted)" << endl;
    }

    const QTime ct = QTime::currentTime();
    //cout << "Image timestamp: " << qPrintable(ct.toString("hh:mm:ss.zzz")) << endl;
    const uint32_t ts = LDCU::Timestamp::Make(ct);

    const size_t HEAD_SIZE = 16;
    std::vector<uint8_t> buffer;

    for (size_t y = 0, ylim = img->height(); y < ylim; ++y)
    {
        //cout << L::Console::Cursor::Restore << (y * 100 / ylim) << "%" << flush;

        for (size_t chunk = 0, clim = (width + split - 1) / split; chunk < clim; ++chunk)
        {
            size_t chunk_width = (width - chunk * split >= split) ? split : width - chunk * split;

            buffer.resize(HEAD_SIZE + chunk_width);

            *reinterpret_cast<uint16_t *>(&buffer[0]) = frame;
            *reinterpret_cast<uint16_t *>(&buffer[2]) = width;
            *reinterpret_cast<uint16_t *>(&buffer[4]) = img->height();
            *reinterpret_cast<uint16_t *>(&buffer[6]) = y;
            *reinterpret_cast<uint16_t *>(&buffer[8]) = chunk * split;
            *reinterpret_cast<uint16_t *>(&buffer[10]) = ts & 0x0000ffff;
            *reinterpret_cast<uint16_t *>(&buffer[12]) = ts >> 16;
            *reinterpret_cast<uint16_t *>(&buffer[14]) = 0; // alignment

            for (size_t x = 0, xlim = chunk_width; x < xlim; ++x)
                buffer[HEAD_SIZE + x] = qGray(img->pixel(x + chunk * split, y));

            //const ssize_t written = write(fd, &buffer[0], buffer.size());
            const ssize_t written = dev_transport(&buffer[0], (qint64) buffer.size(), 0);

            if (written == -1)
                return false; //throw L::system_error();

            if (static_cast<size_t>(written) != buffer.size())
                return false; //throw runtime_error("Writing error");*/
        }
    }

    etext_log->append(QString("%1: image:%2 x %3")
                      .arg(__func__)
                      .arg(img->width(), 0 , 10)
                      .arg(img->height(), 0 , 10));
    return true;
}

qint64 MainWindow::dev_transport(unsigned char *data, long long int dlen, unsigned char interface)
{
    etext_log->append(QString("%1: %2")
                      .arg(__func__)
                      .arg(dlen, 0 , 10));
    //if (interface == 0) {
        return dlen;//udev.eth.udpSocket->writeDatagram((char *)data, (qint64) dlen, udev.eth.ip, udev.eth.port);
    //}

}
