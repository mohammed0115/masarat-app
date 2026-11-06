import 'package:flutter_test/flutter_test.dart';
import 'package:masarat_app/src/config.dart';
import 'package:masarat_app/src/downloader.dart';

void main() {
  test('own server pages stay in the app, everything else opens outside', () {
    expect(AppConfig.isOwn(Uri.parse('https://marhaba-edu.com/masarat_portal')), isTrue);
    expect(AppConfig.isOwn(Uri.parse('https://marhaba-edu.com/teacher-portal?x=1')), isTrue);
    expect(AppConfig.isOwn(Uri.parse('https://wa.me/966500000000')), isFalse);
    expect(AppConfig.isOwn(Uri.parse('tel:0500000000')), isFalse);
    expect(AppConfig.isOwn(Uri.parse('https://evil.example/marhaba-edu.com')), isFalse);
    expect(AppConfig.isOwn(Uri.parse('https://marhaba-edu.com.evil.example/')), isFalse);
  });

  test('the app starts on the login page, which forwards a signed-in user to their portal', () {
    expect(AppConfig.startUri.toString(), 'https://marhaba-edu.com/login');
  });

  test('downloaded file names come from the server but cannot leave the downloads folder', () {
    expect(Downloader.fromDisposition('attachment; filename="Fees Report.pdf"'), 'Fees Report.pdf');
    expect(Downloader.fromDisposition("attachment; filename*=UTF-8''%D8%AA%D9%82%D8%B1%D9%8A%D8%B1.xlsx"), 'تقرير.xlsx');
    expect(Downloader.fromDisposition(null), isNull);
    expect(Downloader.safeName('../../etc/passwd'), 'passwd');
    expect(Downloader.safeName('..\\secret.pdf'), 'secret.pdf');
    expect(Downloader.safeName('.hidden'), 'hidden');
    expect(Downloader.safeName('a:b?.pdf'), 'a_b_.pdf');
    expect(Downloader.safeName(''), 'file');
  });

  test('without a flavor the app is the family app', () {
    expect(AppConfig.isAdmin, isFalse);
    expect(AppConfig.appName, 'مسارات');
  });
}
