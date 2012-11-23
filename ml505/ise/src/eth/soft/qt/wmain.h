#ifndef WMAIN_H
#define WMAIN_H

#include <QObject>
#include <QtNetwork>

class wmain
: public QObject
{
    Q_OBJECT

public:
    explicit wmain(QObject * parent = 0);
    ~wmain();

private slots:

    void rx_data();

private:

    QUdpSocket *udpSocket;
     unsigned short *vpkt;
     unsigned char err;
     unsigned char vrow_chk;
     unsigned short vrow_clc;
     unsigned char vfr_chk;
     unsigned short vfr_clc;
     unsigned short rcv_cnt;
     unsigned short err_cnt;
};

#endif // WMAIN_H
