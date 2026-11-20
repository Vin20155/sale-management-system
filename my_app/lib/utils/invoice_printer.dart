export 'invoice_printer_stub.dart'
    if (dart.library.html) 'invoice_printer_web.dart'
    if (dart.library.io) 'invoice_printer_io.dart';
