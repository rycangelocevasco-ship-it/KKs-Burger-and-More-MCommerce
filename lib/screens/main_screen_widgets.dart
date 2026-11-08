part of 'main_screen.dart';

extension _MainScreenWidgets on _MainScreenState {
  Widget _summaryRow(String label, String value, {bool large = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(
          fontSize: large ? 18 : 14,
          fontWeight: large ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(
          fontSize: large ? 20 : 14,
          fontWeight: FontWeight.w900)),
      ]);

  Widget _infoPanel(String title, String message, IconData icon) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E8),
          borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: _brown),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(
                  fontSize: 12, color: Colors.black54)),
            ],
          )),
        ]),
      );
}
