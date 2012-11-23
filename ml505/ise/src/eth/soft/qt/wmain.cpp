#include "wmain.h"
#include <QDebug>

wmain::wmain(QObject *parent)
:   QObject(parent)
{

    udpSocket = new QUdpSocket(this);

    udpSocket->bind(3000);

    connect(udpSocket, SIGNAL(readyRead()),
            this, SLOT(rx_data()));

    err = 0;
    vrow_chk = 0;
    vrow_clc = 0;
    vfr_chk = 0;
    vfr_clc = 0;
    rcv_cnt = 0;
    err_cnt = 0;
    qDebug("%s: socket created!!!",__func__);
}

wmain::~wmain()
{
    delete udpSocket;
}


void wmain::rx_data()
{
    while (udpSocket->hasPendingDatagrams()) {
        QByteArray datagram;
        datagram.resize(udpSocket->pendingDatagramSize());
        udpSocket->readDatagram(datagram.data(), datagram.size());

        vpkt = (ushort *)datagram.data();
        //vpkt[0]-pkt_type
        //vpkt[1]-vfr_num
        //vpkt[2]-vpix_count
        //vpkt[3]-vrow_count
        //vpkt[4]-vrow_num

        if (vpkt[0]!=0x301){
            qDebug("RCV: cnt=x%04X, size=%04d. PKT: vpix_count=%04d, vrow_count=%04d, vfr_num=%02d, vrow_num=%04d. ERR: cnt=x%04X: pkt type\n",rcv_cnt, datagram.size(), vpkt[2], vpkt[3], (vpkt[1]&0x0F), vpkt[4], err_cnt);
            err = 1;
        }
        if (((vpkt[1]&0x0F)!=vfr_clc) && vfr_chk){
            qDebug("RCV: cnt=x%04X, size=%04d. PKT: vpix_count=%04d, vrow_count=%04d, vfr_num=%02d, vrow_num=%04d. ERR: cnt=x%04X: vfr_clc=%02d\n",rcv_cnt, datagram.size(), vpkt[2], vpkt[3], (vpkt[1]&0x0F), vpkt[4], err_cnt, vfr_clc);
            err = 1; vfr_chk = 0;
        }
        if (vpkt[2]!=0x400){
            qDebug("RCV: cnt=x%04X, size=%04d. PKT: vpix_count=%04d, vrow_count=%04d, vfr_num=%02d, vrow_num=%04d. ERR: cnt=x%04X: vpix_count\n",rcv_cnt, datagram.size(), vpkt[2], vpkt[3], (vpkt[1]&0x0F), vpkt[4], err_cnt);
            err = 1;
        }
        if (vpkt[3]!=0x400){
            qDebug("RCV: cnt=x%04X, size=%04d. PKT: vpix_count=%04d, vrow_count=%04d, vfr_num=%02d, vrow_num=%04d. ERR: cnt=x%04X: vrow_count\n",rcv_cnt, datagram.size(), vpkt[2], vpkt[3], (vpkt[1]&0x0F), vpkt[4], err_cnt);
            err = 1;
        }
        if ((vpkt[4]!=vrow_clc) && vrow_chk){
            qDebug("RCV: cnt=x%04X, size=%04d. PKT: vpix_count=%04d, vrow_count=%04d, vfr_num=%02d, vrow_num=%04d. ERR: cnt=x%04X: vrow_clc=%04d\n",rcv_cnt, datagram.size(), vpkt[2], vpkt[3], (vpkt[1]&0x0F), vpkt[4], err_cnt, vrow_clc);
            err = 1;
        }

        if (err){
            err = 0;
            err_cnt++;
        }

        vrow_chk = 1;
        if ((vpkt[4]+1)==0x400)
        vrow_clc = 0;
        else
        vrow_clc = vpkt[4] + 1;

        if (vpkt[4]==(vpkt[3]-1)){
            vfr_chk = 1;
            if ((vpkt[1]+1)==16)
            vfr_clc = 0;
            else
            vfr_clc = vpkt[1] + 1;
        }

        rcv_cnt++;
   }
}

