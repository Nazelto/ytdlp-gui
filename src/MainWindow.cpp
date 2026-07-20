#include "MainWindow.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileDialog>
#include <QFileInfo>
#include <QFormLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QMessageBox>
#include <QPlainTextEdit>
#include <QProgressBar>
#include <QPushButton>
#include <QStandardPaths>
#include <QStringList>
#include <QTimer>
#include <QVBoxLayout>
#include <QWidget>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent), url_edit(new QLineEdit(this)),
      output_directory_edit(new QLineEdit(this)),
      download_button(new QPushButton("下载", this)),
      cancel_button(new QPushButton("取消", this)),
      progress_bar(new QProgressBar(this)), status_label(new QLabel("就绪", this)),
      log_edit(new QPlainTextEdit(this)), process(new QProcess(this)) {
    setWindowTitle("yt-dlp GUI");
    resize(820, 560);
    setMinimumSize(680, 460);

    setStyleSheet(R"(
        QMainWindow {
            background: #f5f7fb;
        }

        QWidget#centralPanel {
            background: #f5f7fb;
            color: #1f2937;
            font-size: 14px;
        }

        QLabel#titleLabel {
            color: #111827;
            font-size: 24px;
            font-weight: 700;
        }

        QLabel#subtitleLabel {
            color: #6b7280;
            font-size: 13px;
        }

        QLabel#statusLabel {
            color: #374151;
            background: #eef2ff;
            border: 1px solid #dbe4ff;
            border-radius: 8px;
            padding: 8px 10px;
        }

        QLabel {
            color: #374151;
        }

        QLineEdit {
            background: #ffffff;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            padding: 9px 10px;
            selection-background-color: #2563eb;
        }

        QLineEdit:focus {
            border: 1px solid #2563eb;
        }

        QPushButton {
            background: #ffffff;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            color: #1f2937;
            font-weight: 600;
            min-height: 34px;
            padding: 7px 14px;
        }

        QPushButton:hover {
            background: #f9fafb;
            border-color: #9ca3af;
        }

        QPushButton:pressed {
            background: #eef2ff;
        }

        QPushButton:disabled {
            background: #f3f4f6;
            color: #9ca3af;
            border-color: #e5e7eb;
        }

        QPushButton#downloadButton {
            background: #2563eb;
            border-color: #2563eb;
            color: #ffffff;
        }

        QPushButton#downloadButton:hover {
            background: #1d4ed8;
            border-color: #1d4ed8;
        }

        QPushButton#cancelButton {
            color: #b91c1c;
        }

        QProgressBar {
            background: #e5e7eb;
            border: 0;
            border-radius: 8px;
            height: 16px;
            text-align: center;
            color: #111827;
            font-size: 11px;
        }

        QProgressBar::chunk {
            background: #22c55e;
            border-radius: 8px;
        }

        QPlainTextEdit {
            background: #111827;
            border: 1px solid #1f2937;
            border-radius: 8px;
            color: #d1d5db;
            font-family: "JetBrains Mono", "Consolas", monospace;
            font-size: 12px;
            padding: 10px;
            selection-background-color: #2563eb;
        }
    )");

    url_edit->setPlaceholderText("粘贴视频 URL");

    output_directory_edit->setText(
        QStandardPaths::writableLocation(QStandardPaths::DownloadLocation));

    auto *choose_directory_button = new QPushButton("选择目录", this);

    download_button->setObjectName("downloadButton");
    cancel_button->setObjectName("cancelButton");
    status_label->setObjectName("statusLabel");
    cancel_button->setEnabled(false);

    progress_bar->setRange(0, 100);
    progress_bar->setValue(0);

    log_edit->setReadOnly(true);
    log_edit->setPlaceholderText("yt-dlp 输出会显示在这里");

    auto *title_label = new QLabel("yt-dlp GUI", this);
    title_label->setObjectName("titleLabel");

    auto *subtitle_label = new QLabel("粘贴地址，选择保存目录，然后开始下载。", this);
    subtitle_label->setObjectName("subtitleLabel");

    auto *header_layout = new QVBoxLayout;
    header_layout->setSpacing(4);
    header_layout->addWidget(title_label);
    header_layout->addWidget(subtitle_label);

    auto *output_directory_row = new QWidget(this);
    auto *output_directory_layout = new QHBoxLayout(output_directory_row);

    output_directory_layout->setContentsMargins(0, 0, 0, 0);
    output_directory_layout->setSpacing(8);
    output_directory_layout->addWidget(output_directory_edit);
    output_directory_layout->addWidget(choose_directory_button);

    auto *form_layout = new QFormLayout;
    form_layout->setLabelAlignment(Qt::AlignRight);
    form_layout->setFormAlignment(Qt::AlignTop);
    form_layout->setHorizontalSpacing(12);
    form_layout->setVerticalSpacing(12);
    form_layout->addRow("视频地址：", url_edit);
    form_layout->addRow("保存目录：", output_directory_row);

    auto *button_layout = new QHBoxLayout;
    button_layout->setSpacing(8);
    button_layout->addWidget(download_button);
    button_layout->addWidget(cancel_button);
    button_layout->addStretch();

    auto *root_layout = new QVBoxLayout;
    root_layout->setContentsMargins(24, 22, 24, 24);
    root_layout->setSpacing(16);
    root_layout->addLayout(header_layout);
    root_layout->addSpacing(4);
    root_layout->addLayout(form_layout);
    root_layout->addLayout(button_layout);
    root_layout->addWidget(progress_bar);
    root_layout->addWidget(status_label);
    root_layout->addWidget(log_edit, 1);

    auto *central_widget = new QWidget(this);
    central_widget->setObjectName("centralPanel");
    central_widget->setLayout(root_layout);
    setCentralWidget(central_widget);

    process->setProcessChannelMode(QProcess::MergedChannels);

    connect(choose_directory_button, &QPushButton::clicked, this,
            &MainWindow::choose_output_directory);

    connect(download_button, &QPushButton::clicked, this,
            &MainWindow::start_download);

    connect(cancel_button, &QPushButton::clicked, this,
            &MainWindow::cancel_download);

    connect(process, &QProcess::readyReadStandardOutput, this,
            &MainWindow::read_process_output);

    connect(process,
            qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            &MainWindow::process_finished);

    connect(process, &QProcess::errorOccurred, this, &MainWindow::process_error);
}

void MainWindow::choose_output_directory() {
    const QString directory = QFileDialog::getExistingDirectory(
        this, "选择保存目录", output_directory_edit->text());

    if (!directory.isEmpty()) {
        output_directory_edit->setText(directory);
    }
}

QString MainWindow::find_yt_dlp() const {
    const QString tools_directory =
        QDir(QCoreApplication::applicationDirPath()).filePath("tools");

#ifdef Q_OS_WIN
    const QString bundled_executable =
        QDir(tools_directory).filePath("yt-dlp.exe");

    if (QFileInfo::exists(bundled_executable)) {
        return bundled_executable;
    }

    return QStandardPaths::findExecutable("yt-dlp.exe");
#else
    const QString bundled_executable = QDir(tools_directory).filePath("yt-dlp");

    if (QFileInfo::exists(bundled_executable)) {
        return bundled_executable;
    }

    return QStandardPaths::findExecutable("yt-dlp");
#endif
}

QString MainWindow::find_ffmpeg_directory() const {
    const QString tools_directory =
        QDir(QCoreApplication::applicationDirPath()).filePath("tools");

#ifdef Q_OS_WIN
    const QString bundled_ffmpeg = QDir(tools_directory).filePath("ffmpeg.exe");
#else
    const QString bundled_ffmpeg = QDir(tools_directory).filePath("ffmpeg");
#endif

    if (QFileInfo::exists(bundled_ffmpeg)) {
        return tools_directory;
    }

    const QString ffmpeg = QStandardPaths::findExecutable("ffmpeg");

    if (ffmpeg.isEmpty()) {
        return {};
    }

    return QFileInfo(ffmpeg).absolutePath();
}

void MainWindow::start_download() {
    if (process->state() != QProcess::NotRunning) {
        return;
    }

    const QString url = url_edit->text().trimmed();
    const QString output_directory = output_directory_edit->text().trimmed();

    if (url.isEmpty()) {
        QMessageBox::warning(this, "缺少 URL", "请先输入视频地址。");
        return;
    }

    if (output_directory.isEmpty()) {
        QMessageBox::warning(this, "缺少目录", "请选择保存目录。");
        return;
    }

    if (!QDir().mkpath(output_directory)) {
        QMessageBox::critical(this, "目录错误", "无法创建或访问保存目录。");
        return;
    }

    const QString yt_dlp = find_yt_dlp();

    if (yt_dlp.isEmpty()) {
        QMessageBox::critical(this, "找不到 yt-dlp",
                              "请确认 yt-dlp 已经包含在 flake 开发环境中。");
        return;
    }

    const QString ffmpeg_directory = find_ffmpeg_directory();

    if (ffmpeg_directory.isEmpty()) {
        QMessageBox::critical(this, "找不到 FFmpeg",
                              "下载高质量视频通常需要 FFmpeg 合并音视频。");
        return;
    }

    QStringList arguments{
        "--ignore-config",
        "--no-simulate",
        "--progress",
        "--newline",
        "--color",
        "never",
        "--progress-template",
        QStringLiteral("download:__YTDLP_PROGRESS__"
                       "%(progress._percent_str)s|"
                       "%(progress._speed_str)s|"
                       "%(progress._eta_str)s"),
        "--print",
        QStringLiteral("after_move:__YTDLP_FILE__%(filepath)s"),
        "--ffmpeg-location",
        ffmpeg_directory,
        "--paths",
        output_directory,
        "--output",
        "%(title)s [%(id)s].%(ext)s",
        "--format",
        "bv*+ba/b",
        "--no-playlist",
        url};

    output_buffer.clear();
    log_edit->clear();
    progress_bar->setValue(0);

    log_edit->appendPlainText(QString("启动：%1").arg(yt_dlp));

    set_downloading(true);
    process->start(yt_dlp, arguments);
}

void MainWindow::read_process_output() {
    output_buffer.append(process->readAllStandardOutput());

    while (true) {
        const qsizetype newline = output_buffer.indexOf('\n');

        if (newline < 0) {
            break;
        }

        const QByteArray raw_line = output_buffer.left(newline);
        output_buffer.remove(0, newline + 1);

        handle_output_line(QString::fromUtf8(raw_line).trimmed());
    }
}

void MainWindow::handle_output_line(const QString &line) {
    if (line.isEmpty()) {
        return;
    }

    const QString progress_prefix = "__YTDLP_PROGRESS__";
    const QString file_prefix = "__YTDLP_FILE__";

    if (line.startsWith(progress_prefix)) {
        const QString content = line.mid(progress_prefix.size());
        const QStringList fields = content.split('|');

        if (fields.size() >= 3) {
            QString percent_text = fields[0].trimmed();
            percent_text.remove('%');

            bool valid = false;
            const double percent = percent_text.toDouble(&valid);

            if (valid) {
                const int value =
                    qBound(0, static_cast<int>(percent), 100);
                progress_bar->setValue(value);
            }

            status_label->setText(QString("%1  速度：%2  ETA：%3")
                                      .arg(fields[0].trimmed(),
                                           fields[1].trimmed(),
                                           fields[2].trimmed()));
        }

        return;
    }

    if (line.startsWith(file_prefix)) {
        const QString file_path = line.mid(file_prefix.size());
        log_edit->appendPlainText("下载完成：" + file_path);
        return;
    }

    log_edit->appendPlainText(line);
}

void MainWindow::cancel_download() {
    if (process->state() == QProcess::NotRunning) {
        return;
    }

    status_label->setText("正在取消...");
    cancel_button->setEnabled(false);

    process->terminate();

    QTimer::singleShot(1500, this, [this] {
        if (process->state() != QProcess::NotRunning) {
            process->kill();
        }
    });
}

void MainWindow::process_finished(int exit_code,
                                  QProcess::ExitStatus exit_status) {
    if (!output_buffer.isEmpty()) {
        handle_output_line(QString::fromUtf8(output_buffer).trimmed());
        output_buffer.clear();
    }

    const bool succeeded =
        exit_status == QProcess::NormalExit && exit_code == 0;

    if (succeeded) {
        progress_bar->setValue(100);
        status_label->setText("下载完成");
    } else {
        status_label->setText(QString("下载失败，退出码：%1").arg(exit_code));
    }

    set_downloading(false);
}

void MainWindow::process_error(QProcess::ProcessError error) {
    log_edit->appendPlainText("进程错误：" + process->errorString());

    if (error == QProcess::FailedToStart) {
        status_label->setText("无法启动 yt-dlp");
        set_downloading(false);
    }
}

void MainWindow::set_downloading(bool downloading) {
    url_edit->setEnabled(!downloading);
    output_directory_edit->setEnabled(!downloading);

    download_button->setEnabled(!downloading);
    cancel_button->setEnabled(downloading);
}
