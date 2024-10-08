#include "preferencedialog.h"
#include "ui_preferencedialog.h"

#include <QColorDialog>
#include <QFileDialog>
#include <QSettings>
#include <QFontDatabase>

PreferenceDialog::PreferenceDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::PreferenceDialog)
{
    ui->setupUi(this);
    QSettings settings("tikzit", "tikzit");
    ui->autoPdflatex->setChecked(true);

    if (!settings.value("auto-detect-pdflatex").isNull())
        ui->autoPdflatex->setChecked(settings.value("auto-detect-pdflatex").toBool());
    if (!settings.value("pdflatex-path").isNull())
        ui->pdflatexPath->setText(settings.value("pdflatex-path").toString());


    setColor(ui->axesColor, settings.value("grid-color-axes",
      QColor(220,220,240)).value<QColor>());
    setColor(ui->majorColor, settings.value("grid-color-major",
      QColor(240,240,250)).value<QColor>());
    setColor(ui->minorColor, settings.value("grid-color-minor",
      QColor(250,250,255)).value<QColor>());

    connect(ui->axesColor, SIGNAL(clicked()), this, SLOT(colorClick()));
    connect(ui->majorColor, SIGNAL(clicked()), this, SLOT(colorClick()));
    connect(ui->minorColor, SIGNAL(clicked()), this, SLOT(colorClick()));

    if (!settings.value("style-icon-spacing").isNull())
        ui->styleIconSpacing->setText(settings.value("style-icon-spacing").toString());
    else
        ui->styleIconSpacing->setText("48");

    ui->selectNewEdges->setChecked(settings.value("select-new-edges", false).toBool());
    ui->shiftToScroll->setChecked(settings.value("shift-to-scroll", false).toBool());

    const QFontDatabase fdb = QFontDatabase();
    ui->previewFontSize->setValue(settings.value("preview-font-size", 12).toInt());
    ui->previewFontFamily->addItems(fdb.families());
    ui->previewFontFamily->setCurrentText(settings.value("preview-font-family", "").toString());
}

PreferenceDialog::~PreferenceDialog()
{
    delete ui;
}

void PreferenceDialog::accept()
{
    QSettings settings("tikzit", "tikzit");
    bool ok;
    int i;

    settings.setValue("auto-detect-pdflatex", ui->autoPdflatex->isChecked());
    settings.setValue("pdflatex-path", ui->pdflatexPath->text());
    i = ui->styleIconSpacing->text().toInt(&ok);
    if (ok) settings.setValue("style-icon-spacing", i);

    settings.setValue("grid-color-axes", color(ui->axesColor));
    settings.setValue("grid-color-major", color(ui->majorColor));
    settings.setValue("grid-color-minor", color(ui->minorColor));
    settings.setValue("select-new-edges", ui->selectNewEdges->isChecked());
    settings.setValue("shift-to-scroll", ui->shiftToScroll->isChecked());
    settings.setValue("preview-font-size", ui->previewFontSize->value());
    settings.setValue("preview-font-family", ui->previewFontFamily->currentText());
    QDialog::accept();
}

void PreferenceDialog::on_resetColors_clicked()
{
    setColor(ui->axesColor, QColor(220,220,240));
    setColor(ui->majorColor, QColor(240,240,250));
    setColor(ui->minorColor, QColor(250,250,255));
}

void PreferenceDialog::colorClick()
{
    if (QPushButton *btn = dynamic_cast<QPushButton*>(sender())) {
        QColor col = QColorDialog::getColor(
                        color(btn),
                        this,
                        "Set color",
                        QColorDialog::DontUseNativeDialog);
        if (col.isValid()) setColor(btn, col);
    }
}

void PreferenceDialog::on_autoPdflatex_stateChanged(int state)
{
    ui->pdflatexPath->setEnabled(state != Qt::Checked);
    ui->browsePdflatex->setEnabled(state != Qt::Checked);
}

void PreferenceDialog::on_browsePdflatex_clicked()
{
    QSettings settings("tikzit", "tikzit");

    QFileDialog dialog;
    dialog.setWindowTitle(tr("pdflatex Path"));
    dialog.setAcceptMode(QFileDialog::AcceptOpen);
    dialog.setFileMode(QFileDialog::ExistingFile);
    dialog.setLabelText(QFileDialog::Accept, "Select");

    QFileInfo fi(ui->pdflatexPath->text());
    if (!fi.absolutePath().isEmpty()) {
        dialog.setDirectory(fi.absolutePath());
        dialog.selectFile(fi.baseName());
    }

    dialog.setOption(QFileDialog::DontUseNativeDialog);

    if (dialog.exec()) {
        ui->pdflatexPath->setText(QDir::toNativeSeparators(dialog.selectedFiles()[0]));
    }
}

void PreferenceDialog::setColor(QPushButton *btn, QColor col)
{
    QPalette pal = btn->palette();
    pal.setColor(QPalette::Button, col);
    btn->setPalette(pal);
    btn->update();
}

QColor PreferenceDialog::color(QPushButton *btn)
{
    QPalette pal = btn->palette();
    return pal.color(QPalette::Button);
}

void PreferenceDialog::on_preview_font_size_changed() {
    QSettings settings("tikzit", "tikzit");

    settings.setValue("preview-font-size", ui->previewFontSize->value());
}

void PreferenceDialog::on_preview_font_family_changed() {
    QSettings settings("tikzit", "tikzit");

    settings.setValue("preview-font-family", ui->previewFontFamily->currentText());

}
