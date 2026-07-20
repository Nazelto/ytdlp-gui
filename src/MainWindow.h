#pragma once

#include <QByteArray>
#include <QMainWindow>
#include <QProcess>

class QLabel;
class QLineEdit;
class QPlainTextEdit;
class QProgressBar;
class QPushButton;

class MainWindow final : public QMainWindow {
    Q_OBJECT

  public:
    explicit MainWindow(QWidget *parent = nullptr);
    MainWindow(const MainWindow &) = delete;
    MainWindow &operator=(const MainWindow &) = delete;

  private slots:
    void choose_output_directory();
    void start_download();
    void cancel_download();
    void read_process_output();
    void process_finished(int exit_code, QProcess::ExitStatus exit_status);
    void process_error(QProcess::ProcessError error);

  private:
    [[nodiscard]] QString find_yt_dlp() const;
    [[nodiscard]] QString find_ffmpeg_directory() const;
    void handle_output_line(const QString &line);
    void set_downloading(bool downloading);

    QLineEdit *url_edit;
    QLineEdit *output_directory_edit;
    QPushButton *download_button;
    QPushButton *cancel_button;
    QProgressBar *progress_bar;
    QLabel *status_label;
    QPlainTextEdit *log_edit;
    QProcess *process;
    QByteArray output_buffer;
};
