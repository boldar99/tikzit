/*
    TikZiT - a GUI diagram editor for TikZ
    Copyright (C) 2018 Aleks Kissinger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

/*!
  * \file main.cpp
  *
  * The main entry point for the TikZiT executable.
  */

#include "tikzit.h"

#include <QApplication>
#include <QMenuBar>
#include <QDebug>
#include <QScreen>

class MyApplication : public QApplication
{
public:
    Tikzit* tzt;

    MyApplication(int &argc, char **argv)
            : QApplication(argc, argv)
    {
    }

    bool event(QEvent *event) override {
        if (event->type() == QEvent::FileOpen) {
            auto *openEvent = dynamic_cast<QFileOpenEvent *>(event);
            tzt->open(openEvent->file());
        }

        return QApplication::event(event);
    }
};

int main(int argc, char *argv[])
{
    // #ifdef Q_OS_WIN
    //     SetProcessDPIAware();
    // #endif
    // QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    // QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

    // dummy application for detecting DPI
    // QApplication *a0 = new QApplication(argc, argv);
    // qDebug() << "physical DPI" << QApplication::screens()[0]->physicalDotsPerInch();

    // if (QApplication::screens()[0]->physicalDotsPerInch() >= 100) {
    //     QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    // } else {
    //     QApplication::setAttribute(Qt::AA_DisableHighDpiScaling);
    // }

    // delete a0;

    MyApplication a(argc, argv);
    a.setQuitOnLastWindowClosed(false);

    tikzit = new Tikzit();
    a.tzt = tikzit;
    tikzit->init();

    qDebug() << a.arguments().length();

    if (a.arguments().length() > 1) {
        tikzit->open(a.arguments()[1]);
    }

    return a.exec();
}
