import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_helper.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class CreateInvoicePage extends StatefulWidget
{
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage>
{
  // --- BRANDING COLORS ---
  final Color royalBlue = const Color(0xFF1E40AF);
  final Color navyBlue = const Color(0xFF1E3A8A);
  final Color skyBlue = const Color(0xFF3B82F6);
  final Color lightBg = const Color(0xFFF1F5F9);
  final Color textColor = const Color(0xFF0F172A);

  final TextEditingController _customerName = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final FocusNode _customerFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  List<Map<String, dynamic>> _items = [];
  late String _billNumber;

  @override
  void initState()
{
    super.initState();
    _billNumber = "SE-${DateFormat('yyMM').format(DateTime.now())}-${(100 + (DateTime.now().second)).toString()}";
    _dateController.text = DateFormat('dd MMM yyyy').format(DateTime.now());
    _addNewItem();
  }

  @override
  void dispose()
{
    _customerName.dispose();
    _phoneNumber.dispose();
    _dateController.dispose();
    _customerFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }



  void _addNewItem({String name = "", String price = "0"})
{
    setState(()
{
      for (var item in _items)
{
        item['isEditable'] = false;
      }
      _items.add(
{
        "name": TextEditingController(text: name),
        "qty": TextEditingController(text: "1"),
        "price": TextEditingController(text: price),
        "isEditable": true,

}
);
    }
);
  }

  double get _total => _items.fold(0, (sum, item)
{
    double q = double.tryParse(item['qty'].text) ?? 0;
    double p = double.tryParse(item['price'].text) ?? 0;
    return sum + (q * p);
  }
);

  void _showBestExitAlert() {
    // 1. Pro Detail: Unfocus and trigger a "Warning" Haptic vibration
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.heavyImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Allows for a smoother bounce animation
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
      )..forward(),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95), // Slight transparency
            borderRadius: const BorderRadius.vertical(top: Radius.circular(44)),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 2. Pro Detail: Thicker, more tactile drag handle
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 32),

              // --- NEUMORPHIC DANGER ICON ---
              // Designed to look like a high-end system alert
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.redAccent.shade400, Colors.red.shade900],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.priority_high_rounded, // Sharper, more "Pro" icon
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // --- HEADER SECTION ---
              const Text(
                "Discard Changes?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A), // Deep Navy Slate
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Leaving this invoice will permanently delete all added items. This action cannot be undone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B), // Soft Slate
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // --- PRO ACTION BUTTONS ---
              Row(
                children: [
                  // Secondary: Keep Editing
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        foregroundColor: const Color(0xFF475569),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: const Text(
                        "RESUME",
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Primary: Discard (High-End Danger Style)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A), // Luxury Dark Navy
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "EXIT",
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODERN SUCCESS DIALOG ---
  void _showSuccessDialog(File file, Uint8List pdfBytes)
{
    showDialog(
      context: context,
 barrierDismissible: false,
 builder: (BuildContext context)
{
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
 child: Container(
            padding: const EdgeInsets.all(24),
 child: Column(
              mainAxisSize: MainAxisSize.min,
 children: [
                Container(
                  padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
 child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
                ),
 const SizedBox(height: 20),
 Text("Invoice Saved!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: navyBlue)),
 const SizedBox(height: 8),
 Text("Location: Shakti Electric Folder", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
 const SizedBox(height: 25),
 Row(
                  children: [
                    Expanded(
                      child: _dialogBtn(
                        label: "SHARE PDF",
 icon: Icons.share_rounded,
 color: skyBlue,
 onTap: () => Share.shareXFiles([XFile(file.path)], text: 'Invoice from Shree Shakti Electric'),
                      ),
                    ),
 const SizedBox(width: 12),
 Expanded(
                      child: _dialogBtn(
                        label: "VIEW / PRINT",
 icon: Icons.picture_as_pdf_rounded,
 color: Colors.redAccent,
 onTap: () async
{
                          await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: "Invoice_$_billNumber");
                        },
                      ),
                    ),
                  ],
                ),
 const SizedBox(height: 25),
 SizedBox(
                  width: double.infinity,
 height: 50,
 child: ElevatedButton(
                    onPressed: ()
{
                      Navigator.pop(context); // Close Dialog
                      Navigator.pop(context); // Go back to Dashboard
                    },
 style: ElevatedButton.styleFrom(
                      backgroundColor: navyBlue,
 foregroundColor: Colors.white,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
 child: const Text("FINISH & EXIT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dialogBtn({required String label, required IconData icon, required Color color, required VoidCallback onTap})
{
    return InkWell(
      onTap: onTap,
 borderRadius: BorderRadius.circular(15),
 child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
 decoration: BoxDecoration(
          color: color.withOpacity(0.08),
 borderRadius: BorderRadius.circular(15),
 border: Border.all(color: color.withOpacity(0.2)),
        ),
 child: Column(
          children: [
            Icon(icon, color: color),
 const SizedBox(height: 5),
 Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // --- IMPROVED PROCESS ENGINE ---
  Future<void> _processInvoice() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add items before saving")),
      );
      return;
    }

    _showLoading("Generating PDF & Saving...");

    try {
      // --- STEP 0: Identify User & Load Signature ---
      final prefs = await SharedPreferences.getInstance();
      final String loggedInUser = (prefs.getString('userName') ?? "Suresh").toLowerCase();

      // Choose the asset path based on the login name
      String sigAssetPath = loggedInUser.contains("hiren")
          ? 'assets/images/hiren.png'
          : 'assets/images/suresh.png';

      // Load image from assets and convert to PDF-compatible format
      final Uint8List signatureData = (await rootBundle.load(sigAssetPath)).buffer.asUint8List();
      final pw.MemoryImage signatureImage = pw.MemoryImage(signatureData);

      // --- STEP 1: Data Preparation ---
      final String finalCustomer = _customerName.text.trim().isEmpty ? "CASH CUSTOMER" : _customerName.text.trim().toUpperCase();
      final String finalPhone = _phoneNumber.text.trim().isEmpty ? "N/A" : _phoneNumber.text.trim();

      // --- STEP 2: Build PDF Document ---
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          build: (pw.Context context) => [
            _buildPdfHeader(),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 15),
            _buildPdfCustomerBox(finalCustomer, finalPhone),
            pw.SizedBox(height: 25),
            _buildPdfTable(),
            _buildPdfSummary(),
            pw.SizedBox(height: 40),
            // Pass the loaded signature image here
            _buildPdfFooter(signatureImage),
          ],
        ),
      );

      final Uint8List bytes = await pdf.save();

      // --- STEP 3: Save to File System ---
      Directory? baseDir = await getExternalStorageDirectory();
      baseDir ??= await getApplicationDocumentsDirectory();

      final Directory shaktiDir = Directory("${baseDir.path}/Shakti Electric");
      if (!await shaktiDir.exists()) await shaktiDir.create(recursive: true);

      final String fileName = "Invoice_${_billNumber.replaceAll('-', '_')}.pdf";
      final File file = File("${shaktiDir.path}/$fileName");
      await file.writeAsBytes(bytes);

      // --- STEP 4: Database Save ---
      await DatabaseHelper.instance.saveCompleteInvoice({
        'billNumber': _billNumber,
        'customerName': finalCustomer,
        'phoneNumber': finalPhone,
        'date': _dateController.text,
        'totalAmount': _total,
        'pdfPath': file.path,
      }, _items.map((item) => {
        'itemName': item['name'].text.trim().isEmpty ? "Electric Item" : item['name'].text.trim(),
        'qty': double.tryParse(item['qty'].text) ?? 0.0,
        'price': double.tryParse(item['price'].text) ?? 0.0,
      }).toList());

      if (mounted) Navigator.pop(context); // Close Loading Dialog
      _showSuccessDialog(file, bytes);

    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("PDF Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Critical Error: $e")));
    }
  }

  // --- PDF WIDGETS ---
  pw.Widget _buildPdfHeader()
{
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
 crossAxisAlignment: pw.CrossAxisAlignment.start,
 children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
 children: [
            pw.Text("SHREE SHAKTI", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
 pw.Text("ELECTRIC SERVICE", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
 pw.SizedBox(height: 4),
 pw.Text("Specialist in: All types of Electric Fitting & Maintenance", style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
 pw.SizedBox(height: 10),
 pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
 children: [
                pw.Text("Suresh K. Lakhadiya: +91 90336 60384", style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
 pw.Text("Hiren S. Lakhadiya:  +91 70160 55176", style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
              ],
            ),
          ],
        ),
 pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
 children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
 decoration: const pw.BoxDecoration(color: PdfColors.blue900, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
 child: pw.Text("ESTIMATE / BILL", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12)),
            ),
 pw.SizedBox(height: 10),
 pw.Text("Invoice No: $_billNumber", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
 pw.Text("Date: ${_dateController.text}", style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfCustomerBox(String name, String phone)
{
    return pw.Container(
      width: double.infinity,
 padding: const pw.EdgeInsets.all(12),
 decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
 child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
 children: [
          pw.Text("BILL TO:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
 pw.SizedBox(height: 4),
 pw.Text(name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
 pw.SizedBox(height: 2),
 pw.Text("Phone: $phone", style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTable()
{
    return pw.TableHelper.fromTextArray(
      headers: ['SR.', 'DESCRIPTION', 'QTY', 'RATE', 'AMOUNT'],
 headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
 headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
 cellHeight: 25,
 border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
 data: List.generate(_items.length, (index)
{
        final item = _items[index];
        double q = double.tryParse(item['qty'].text) ?? 0;
        double p = double.tryParse(item['price'].text) ?? 0;
        return [(index + 1).toString(), item['name'].text.toUpperCase(), q.toStringAsFixed(0), p.toStringAsFixed(2), (q * p).toStringAsFixed(2)];
      }
),
    );
  }

  pw.Widget _buildPdfSummary()
{
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
 children: [
        pw.Container(
          width: 170,
 decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
 child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
 children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("NET TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
 pw.Container(
                padding: const pw.EdgeInsets.all(8),
 color: PdfColors.blue50,
 child: pw.Text("Rs. ${_total.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.MemoryImage sigImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Left side: Terms & Conditions
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Terms & Conditions:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.blue900)),
            pw.SizedBox(height: 1),
            pw.Text("1. Goods once sold will not be taken back.", style: const pw.TextStyle(fontSize: 7)),
            pw.Text("2. This is a computer generated estimate.", style: const pw.TextStyle(fontSize: 7)),
          ],
        ),

        // Right side: Signature Section
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // 1. Company Name - Moved DOWN closer to image
            pw.Transform.translate(
              offset: const PdfPoint(0, -15),
              child: pw.Text("For, SHREE SHAKTI ELECTRIC SERVICE",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
            ),

            // 2. Signature Image - Pushed DOWN to sit ON the line
            pw.Transform.translate(
              offset: const PdfPoint(0, -15), // Pushes the ink down onto the line
              child: pw.Container(
                width: 130,
                height: 50,
                child: pw.Image(
                  sigImage,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),

            // 3. The Signature Line
            pw.SizedBox(
              width: 150,
              child: pw.Divider(thickness: 1.0, color: PdfColors.black),
            ),

            // 4. Authorized Signatory - Pulled UP to touch the line
            pw.Transform.translate(
              offset: const PdfPoint(0, 5), // Moves text UP towards the line
              child: pw.Text("Authorized Signatory",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEditingItem = _items.any((item) => item['isEditable']);
    bool shouldHideFooter = isEditingItem || _customerFocus.hasFocus || _phoneFocus.hasFocus;

    return PopScope(
      canPop: false, // Prevents automatic closing
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Logic: If list is not empty, ask. If empty, just leave.
        if (_items.isNotEmpty || _customerName.text.isNotEmpty) {
          _showBestExitAlert();
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: lightBg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildCustomerCard()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt_rounded, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text("BILLING ITEMS",
                        style: TextStyle(
                            color: navyBlue,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildQuickCatalogHeader()),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildItemTile(index),
                  childCount: _items.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 180)),
          ],
        ),
        bottomSheet: shouldHideFooter ? null : _buildModernFooter(),
      ),
    );
  }

  Widget _buildAppBar()
{
    return SliverAppBar(
      expandedHeight: 140.0,
 pinned: true,
 backgroundColor: royalBlue,
 flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
 title: const Text("CREATE NEW BILL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 2)),
 background: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [royalBlue, navyBlue])),
 child: Opacity(opacity: 0.1, child: const Icon(Icons.electric_bolt_rounded, size: 150, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildCustomerCard()
{
    return Container(
      margin: const EdgeInsets.all(16),
 padding: const EdgeInsets.all(24),
 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
 child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: skyBlue.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.person, color: skyBlue, size: 20)),
 const SizedBox(width: 15),
 Expanded(child: TextField(controller: _customerName, focusNode: _customerFocus, textCapitalization: TextCapitalization.characters, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18), decoration: const InputDecoration(hintText: "Customer Name", border: InputBorder.none))),
 Text(_billNumber, style: TextStyle(color: royalBlue, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
 const Divider(height: 40),
 Row(
            children: [
              Expanded(child: _miniInput(Icons.phone_android, _phoneNumber, "Mobile No.", focus: _phoneFocus, isNum: true)),
 Container(width: 1, height: 25, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 10)),
 Expanded(child: InkWell(onTap: () => _selectDate(context), child: AbsorbPointer(child: _miniInput(Icons.calendar_month, _dateController, "Date")))),
            ],
          )
],
      ),
    );
  }

  Widget _buildItemTile(int index)
{
    bool isEdit = _items[index]['isEditable'];
    double qty = double.tryParse(_items[index]['qty'].text) ?? 0;
    double price = double.tryParse(_items[index]['price'].text) ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isEdit ? royalBlue : Colors.transparent, width: 2)),
 child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: lightBg, radius: 15, child: Text("${index + 1}", style: TextStyle(fontSize: 12, color: royalBlue))),
 const SizedBox(width: 12),
 Expanded(child: TextField(controller: _items[index]['name'], enabled: isEdit, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: "Item name...", border: InputBorder.none))),
 IconButton(onPressed: () => setState(() => _items[index]['isEditable'] = !isEdit), icon: Icon(isEdit ? Icons.check_circle : Icons.edit_rounded, color: isEdit ? Colors.green : royalBlue)),
 if (!isEdit) IconButton(onPressed: () => setState(() => _items.removeAt(index)), icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent)),
            ],
          ),
 if (isEdit) ...[
            const Divider(),
 Row(children: [_editBox("QTY", _items[index]['qty']), _editBox("RATE (₹)", _items[index]['price']), const Spacer(), Text("₹${(qty * price).toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: royalBlue))])
]
],
      ),
    );
  }

  Widget _buildModernFooter()
{
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
 decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(35)), boxShadow: [BoxShadow(color: royalBlue.withOpacity(0.1), blurRadius: 40)]),
 child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
 children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("TOTAL PAYABLE", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11)), Text("₹${_total.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: navyBlue))]),
 const SizedBox(height: 20),
 Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _addNewItem(), icon: const Icon(Icons.add), label: const Text("ADD ITEM"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), side: BorderSide(color: royalBlue, width: 2), foregroundColor: royalBlue))),
 const SizedBox(width: 12),
 Expanded(child: ElevatedButton.icon(onPressed: _items.isEmpty ? null : _processInvoice, icon: const Icon(Icons.picture_as_pdf), label: const Text("SAVE & SHARE"), style: ElevatedButton.styleFrom(backgroundColor: royalBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 5))),
            ])
],
        ),
      ),
    );
  }

  Widget _miniInput(IconData icon, TextEditingController ctrl, String hint, {FocusNode? focus, bool isNum = false})
{
    return Row(children: [Icon(icon, size: 18, color: skyBlue), const SizedBox(width: 10), Expanded(child: TextField(controller: ctrl, focusNode: focus, keyboardType: isNum ? TextInputType.number : TextInputType.text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor), decoration: InputDecoration(hintText: hint, border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey[400]))))]);
  }

  Widget _editBox(String label, TextEditingController ctrl)
{
    return Container(width: 80, margin: const EdgeInsets.only(right: 15), child: TextField(controller: ctrl, keyboardType: TextInputType.number, onChanged: (v) => setState(()
{
}
), style: const TextStyle(fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: label, labelStyle: TextStyle(fontSize: 10, color: skyBlue))));
  }

  Widget _buildQuickCatalogHeader()
{
    final suggestions = [{"n": "Switch", "p": "45"}, {"n": "Socket", "p": "85"}, {"n": "LED 9W", "p": "120"}, {"n": "1.5mm Wire", "p": "1200"}];
    return SizedBox(height: 50, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 16), itemCount: suggestions.length, itemBuilder: (context, i) => Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: Text(suggestions[i]['n']!), onPressed: () => _addNewItem(name: suggestions[i]['n']!, price: suggestions[i]['p']!), backgroundColor: Colors.white, labelStyle: TextStyle(color: royalBlue, fontWeight: FontWeight.bold), side: BorderSide(color: royalBlue.withOpacity(0.2))))));
  }

  void _showLoading(String message)
{
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), content: Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(height: 10), CircularProgressIndicator(color: royalBlue), const SizedBox(height: 25), Text(message, style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue))])));
  }

  Future<void> _selectDate(BuildContext context) async
{
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: royalBlue)), child: child!));
if (picked != null) setState(() => _dateController.text = DateFormat('dd MMM yyyy').format(picked));
  }
}
