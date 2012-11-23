#include <QCoreApplication>
#include "wmain.h"

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);
    wmain w;

    return a.exec();
}
