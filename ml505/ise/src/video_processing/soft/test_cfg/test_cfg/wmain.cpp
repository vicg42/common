#include "wmain.h"
#include "timestamp.h"

namespace LDCU = Linkos::DCU;

MainWindow::MainWindow(QWidget *parent)
    : QWidget(parent)
{
    //--- ETH group ---
    eline_eth_ip = new QLineEdit("10.1.7.235");
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

//    connect(btn_usr_set, SIGNAL(clicked()),
//            this, SLOT(board_init()));

    connect(btn_eth, SIGNAL(clicked()),
            this, SLOT(eth_connect()));

    connect(btn_img_open, SIGNAL(clicked()),
            this, SLOT(img_open()));

    TVCH_prm  vch;
    vch.fr_size.activ.x = 1024/4;
    vch.fr_size.activ.y = 1024;
    vch.fr_size.skip.x = 0;
    vch.fr_size.skip.y = 0;

    fg.vch_count = C_BOARD_VCH_COUNT_MAX;
    for (uint8_t idx = 0; idx < fg.vch_count; idx++){
      fg.vch[idx] = vch;
    }
}

MainWindow::~MainWindow()
{

}



bool MainWindow::board_init(void) {
  bool result = true;

  int16_t firmware = get_firmware();
  if (firmware == -1)
    return false;

  etext_log->append(QString("%1: firmware=0x%2")
                    .arg(__func__)
                    .arg(firmware, 0 , 16));


  const uint8_t vch_count = 1;
  for (uint8_t idx = 0; idx < vch_count; idx++){
    result = set_vch_prm(idx, fg.vch[idx]);
    if (!result) {
      etext_log->append(QString("%1: error init vch%2")
                        .arg(__func__)
                        .arg(idx, 0 , 10));
      return result;
    }
  }

  return result;
}


int16_t MainWindow::get_firmware(void) {
  bool result;
  uint16_t firmware;

  result = cfg_read(C_CFGDEV_TESTING, 0,
                    C_PKT_TYPE_CFG, (uint8_t *) &firmware, (uint16_t) sizeof(uint16_t), 0);
  if (!result)
    return -1;

  return firmware;
}

void MainWindow::eth_connect() {
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

        if (!board_init()) {
            etext_log->append("Not detected Board!!!");
        }
    }
    else {
        udev.eth.udpSocket->close();
        btn_eth->setText("Open");
        etext_log->append(QString("%1: %2")
                          .arg(__func__)
                          .arg("closed"));
        //qDebug() << udev.eth.udpSocket->isValid();
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
  bool result = true;
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

          //result = dev_wr(&buffer[0], (qint64) buffer.size());
          if (!result)
            return result;
      }
  }

  return true;
}


bool MainWindow::set_vch_prm(uint8_t vch, TVCH_prm val) {
  uint32_t txd;
  bool result = true;

  //Set Active Zone X,Y
  txd = 0;
  txd = ((val.fr_size.activ.x & 0xFFFF) << 0)
        | ((val.fr_size.activ.y & 0xFFFF) << 16);
  result = cfg_write(C_CFGDEV_FG, C_FR_REG_DATA_L,
                     C_PKT_TYPE_CFG, (uint8_t *) &txd, (uint16_t) sizeof(uint32_t), 0);
  if (!result) {
    return false;
  }

  txd = 0;
  txd = ((vch & C_FG_REG_CTRL_VCH_MASK) << C_FG_REG_CTRL_VCH_L_BIT)
        | ((C_FG_PRM_FR_ZONE_ACTIVE & C_FG_REG_CTRL_PRM_MASK) << C_FG_REG_CTRL_PRM_L_BIT)
        | (1 << C_FG_REG_CTRL_SET_BIT);
  result = cfg_write(C_CFGDEV_FG, C_FR_REG_CTRL,
                     C_PKT_TYPE_CFG, (uint8_t *) &txd, (uint16_t) sizeof(uint16_t), 0);
  if (!result) {
    return false;
  }

  //Set Skip Zone X,Y
  txd = 0;
  txd = ((val.fr_size.skip.x & 0xFFFF) << 0)
        | ((val.fr_size.skip.y & 0xFFFF) << 16);
  result = cfg_write(C_CFGDEV_FG, C_FR_REG_DATA_L,
                     C_PKT_TYPE_CFG, (uint8_t *) &txd, (uint16_t) sizeof(uint32_t), 0);
  if (!result) {
    return false;
  }

  txd = 0;
  txd = ((vch & C_FG_REG_CTRL_VCH_MASK) << C_FG_REG_CTRL_VCH_L_BIT)
        | ((C_FG_PRM_FR_ZONE_SKIP & C_FG_REG_CTRL_PRM_MASK) << C_FG_REG_CTRL_PRM_L_BIT)
        | (1 << C_FG_REG_CTRL_SET_BIT);
  result = cfg_write(C_CFGDEV_FG, C_FR_REG_CTRL,
                     C_PKT_TYPE_CFG, (uint8_t *) &txd, (uint16_t) sizeof(uint16_t), 0);
  if (!result) {
    return false;
  }

  return result;
}


bool MainWindow::cfg_write(uint16_t cfgdev, uint16_t sreg,
                           uint8_t tpkt, uint8_t *data, uint16_t dlen, uint8_t fifo) {
  bool result = true;
  TUDevWR rq;

  rq.tx.size = C_CFGPKT_HEADER_SIZE * C_CFGPKT_DATA_ALIGN + dlen;
  if((rq.tx.data = (uint8_t*) malloc(rq.tx.size)) == NULL) {
    return false;
  }

  rq.rx.size = C_CFGPKT_HEADER_SIZE * C_CFGPKT_DATA_ALIGN;
  rq.rx.data = rq.tx.data;

  *(uint16_t *)(&rq.tx.data[0])= ((tpkt & C_CFGPKT_TYPE_MASK) << C_CFGPKT_TYPE_BIT)
                          | (C_CFGPKT_WR << C_CFGPKT_WR_BIT)
                          | (fifo << C_CFGPKT_FIFO_BIT)
                          | ((cfgdev & C_CFGPKT_DADR_MASK) << C_CFGPKT_DADR_L_BIT);
  *(uint16_t *)(&rq.tx.data[2]) = (sreg & C_CFGPKT_RADR_MASK) << C_CFGPKT_RADR_L_BIT;
  *(uint16_t *)(&rq.tx.data[4]) = ((dlen / C_CFGPKT_DATA_ALIGN) & C_CFGPKT_DLEN_MASK) << C_CFGPKT_DLEN_L_BIT;

  memcpy(&rq.tx.data[6], data, dlen);

  //send txreq(header + data)
  rq.dir = C_UDEV_REQ_WRITE;
  result = dev_wr(rq);
  if (!result)
    return false;

  //recieve txack(header)
  rq.dir = C_UDEV_REQ_READ;
  result = dev_wr(rq);
  if (!result)
    return false;

  if ( memcmp(rq.tx.data, rq.rx.data, (C_CFGPKT_HEADER_SIZE * C_CFGPKT_DATA_ALIGN)) != 0 )
    return false;

  free(rq.tx.data);
  return result;
}

bool MainWindow::cfg_read(uint16_t cfgdev, uint16_t sreg,
                          uint8_t tpkt, uint8_t *data, uint16_t dlen, uint8_t fifo) {
  bool result = true;
  TUDevWR rq;

  rq.rx.size = C_CFGPKT_HEADER_SIZE * C_CFGPKT_DATA_ALIGN + dlen;
  if((rq.rx.data = (uint8_t*) malloc(rq.rx.size)) == NULL) {
    return false;
  }
  rq.tx.size = C_CFGPKT_HEADER_SIZE * C_CFGPKT_DATA_ALIGN;
  rq.tx.data = rq.rx.data;

  *(uint16_t *)(&rq.tx.data[0])= ((tpkt & C_CFGPKT_TYPE_MASK) << C_CFGPKT_TYPE_BIT)
                          | (C_CFGPKT_RD << C_CFGPKT_WR_BIT)
                          | (fifo << C_CFGPKT_FIFO_BIT)
                          | ((cfgdev & C_CFGPKT_DADR_MASK) << C_CFGPKT_DADR_L_BIT);
  *(uint16_t *)(&rq.tx.data[2]) = (sreg & C_CFGPKT_RADR_MASK) << C_CFGPKT_RADR_L_BIT;
  *(uint16_t *)(&rq.tx.data[4]) = ((dlen / C_CFGPKT_DATA_ALIGN) & C_CFGPKT_DLEN_MASK) << C_CFGPKT_DLEN_L_BIT;

  //send rxreq(header)
  rq.dir = C_UDEV_REQ_WRITE;
  result = dev_wr(rq);
  if (!result)
    return false;

  //recieve rxack(header + data)
  rq.dir = C_UDEV_REQ_READ;
  result = dev_wr(rq);
  if (!result)
    return false;

  if ( memcmp(rq.tx.data, rq.rx.data, (C_CFGPKT_HEADER_SIZE * C_CFGPKT_DATA_ALIGN)) != 0 )
    return false;

  rq.rx.data = rq.rx.data + rq.tx.size;
  memcpy(data, rq.rx.data, dlen);

  free(rq.rx.data);
  return result;
}

bool MainWindow::dev_wr(TUDevWR rq) {
  uint64_t write;
  int16_t timeout;

//  if (rq.transport == C_BOARD_IF) {
    if (!udev.eth.udpSocket->isValid())
      return false;

    if (rq.dir == C_UDEV_REQ_WRITE) {
      write = udev.eth.udpSocket->writeDatagram((char *)rq.tx.data, rq.tx.size, udev.eth.ip, udev.eth.port);
      if (write != rq.tx.size)
        return false;
    }
    else {
      timeout = 100;//msec
      if (!udev.eth.udpSocket->waitForReadyRead(timeout)) {
        //timeout
        return false;
      }
      while (udev.eth.udpSocket->hasPendingDatagrams()) {
          if (udev.eth.udpSocket->pendingDatagramSize() != (int64_t) rq.rx.size)
            return false;
          else
            udev.eth.udpSocket->readDatagram((char *)rq.tx.data, udev.eth.udpSocket->pendingDatagramSize());
          return true;
      }
    }
//  }

  return true;
}
