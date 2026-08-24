import 'package:flutter/material.dart';
import '../../../core/models/calendar_event.dart';

class WeeklyView extends StatelessWidget {
  final DateTime currentDate;
  final List<CalendarEvent> Function(DateTime) getEventsForDate;

  // Bộ lọc hiển thị: cho phép ẩn/hiện riêng Lớp học phần và Lịch thi
  final bool showClasses;
  final bool showExams;

  const WeeklyView({
    super.key,
    required this.currentDate,
    required this.getEventsForDate,
    this.showClasses = true,
    this.showExams = true,
  });

  DateTime _getMonday(DateTime date) {
    int day = date.weekday;
    return date.subtract(Duration(days: day - 1));
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
  String _formatShortDate(DateTime d) => '${_pad(d.day)}/${_pad(d.month)}';

  @override
  Widget build(BuildContext context) {
    DateTime monday = _getMonday(currentDate);
    
    // Khởi tạo lưới [3 ca][7 ngày]
    List<List<List<CalendarEvent>>> grid = List.generate(3, (_) => List.generate(7, (_) => []));

    // Đổ dữ liệu vào lưới của cả 7 ngày
    for (int i = 0; i < 7; i++) {
      DateTime day = monday.add(Duration(days: i));
      List<CalendarEvent> dayEvents = getEventsForDate(day);
      
      for (var e in dayEvents) {
        // Bỏ qua sự kiện thuộc loại đang bị ẩn theo bộ lọc
        if (e.isExam && !showExams) continue;
        if (!e.isExam && !showClasses) continue;

        int sessionIdx = 0;
        if (e.session == 'AFTERNOON') sessionIdx = 1;
        if (e.session == 'EVENING') sessionIdx = 2;
        grid[sessionIdx][i].add(e);
      }
    }

    final weekDaysLabels = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            columnWidths: const {
              0: FixedColumnWidth(60),
              1: FixedColumnWidth(130),
              2: FixedColumnWidth(130),
              3: FixedColumnWidth(130),
              4: FixedColumnWidth(130),
              5: FixedColumnWidth(130),
              6: FixedColumnWidth(130),
              7: FixedColumnWidth(130),
            },
            children: [
              // Hàng Tiêu đề (Header ngày)
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8F9FE)),
                children: [
                  const SizedBox.shrink(),
                  ...List.generate(7, (index) {
                    DateTime day = monday.add(Duration(days: index));
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            weekDaysLabels[index],
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6E8CF0)),
                          ),
                          Text(
                            _formatShortDate(day),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              _buildWeeklyTimeRow('Ca\nSáng', grid[0]),
              _buildWeeklyTimeRow('Ca\nChiều', grid[1]),
              _buildWeeklyTimeRow('Ca\nTối', grid[2]),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildWeeklyTimeRow(String sessionName, List<List<CalendarEvent>> weekData) {
    return TableRow(
      children: [
        TableCell(
          // Không dùng `fill` ở đây: cell `fill` bị Table LOẠI KHỎI phép tính
          // row height (vì kích thước của nó phụ thuộc ngược vào row height,
          // nên Table không thể dùng nó để suy ra row height mà không bị vòng lặp).
          // Kết quả là minHeight bên dưới sẽ bị "vô hiệu hoá" nếu dùng fill.
          // Dùng `middle` (mặc định) để cell này được TÍNH vào row height,
          // đảm bảo hàng luôn cao tối thiểu 120 kể cả khi các ô ngày rỗng.
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            constraints: const BoxConstraints(minHeight: 120),
            alignment: Alignment.center,
            color: const Color(0xFFF8F9FE),
            child: Text(
              sessionName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
        ),
        ...weekData.map((events) {

          // Tách riêng 2 nhóm: Lớp học phần và Lịch thi, mỗi nhóm giới hạn
          // hiển thị tối đa 2 thẻ, phần dư ra gộp thành nhãn "+N" riêng của nhóm đó.
          final classEvents = events.where((e) => !e.isExam).toList();
          final examEvents = events.where((e) => e.isExam).toList();

          List<Widget> displayWidgets = [];

          if (classEvents.isNotEmpty) {
            displayWidgets.addAll(classEvents.take(2).map((e) => _buildWeeklyCard(e)));
            if (classEvents.length > 2) {
              displayWidgets.add(_buildMoreLabel(
                '+${classEvents.length - 2} lớp học phần khác',
                const Color(0xFF6E8CF0),
              ));
            }
          }

          if (examEvents.isNotEmpty) {
            displayWidgets.addAll(examEvents.take(2).map((e) => _buildWeeklyCard(e)));
            if (examEvents.length > 2) {
              displayWidgets.add(_buildMoreLabel(
                '+${examEvents.length - 2} lịch thi khác',
                Colors.orange,
              ));
            }
          }

          return TableCell(
            verticalAlignment: TableCellVerticalAlignment.top,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min, 
                children: displayWidgets,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMoreLabel(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildWeeklyCard(CalendarEvent e) {
    final color = e.isExam ? Colors.orange : const Color(0xFF6E8CF0);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(left: BorderSide(color: color, width: 3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          Text(
            e.title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.9)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          
          // Phòng
          Text(
            'Phòng: ${e.roomName}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Giảng viên / CBCT
          Text(
            '${e.isExam ? "CBCT" : "GV"}: ${e.teacherName}',
            style: TextStyle(
              fontSize: 10, 
              color: e.teacherName.contains('Chưa phân công') ? Colors.grey : Colors.grey.shade800,
              fontStyle: e.teacherName.contains('Chưa phân công') ? FontStyle.italic : FontStyle.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Thông tin thêm nếu là Lịch thi (Thời gian, Thời lượng)
          if (e.isExam && e.examTime != null) ...[
            const SizedBox(height: 2),
            Text(
              'Ca thi: ${e.examTime} (${e.duration}p)',
              style: const TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}