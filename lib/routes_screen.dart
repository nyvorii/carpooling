import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/route_model.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  late Box<RouteModel> routesBox;

  @override
  void initState() {
    super.initState();
    routesBox = Hive.box<RouteModel>('routes');
  }

  void reserveSeat(RouteModel route) async {
    if (route.bookedSeats < route.seats) {

      final updatedRoute = RouteModel(
        id: route.id,
        start: route.start,
        end: route.end,
        date: route.date,
        seats: route.seats,
        routePoints: route.routePoints,
        bookedSeats: route.bookedSeats + 1,
        driverId: route.driverId,
        driverName: route.driverName,
        totalCost: route.totalCost,
        passengerIds: route.passengerIds,
        isActive: route.isActive,
      );

      // zapis zaktualizowanych tras
      await routesBox.put(route.id, updatedRoute);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Miejsce zarezerwowane!')),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak wolnych miejsc!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: routesBox.listenable(),
      builder: (context, Box<RouteModel> box, _) {
        if (box.isEmpty) {
          return const Center(child: Text('Brak tras'));
        }

        final routes = box.values.toList();

        return ListView.builder(
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final route = routes[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(
                  'Trasa: (${route.start.latitude.toStringAsFixed(4)}, ${route.start.longitude.toStringAsFixed(4)}) → '
                      '(${route.end.latitude.toStringAsFixed(4)}, ${route.end.longitude.toStringAsFixed(4)})',
                ),
                subtitle: Text(
                  'Data: ${route.date.day}.${route.date.month}.${route.date.year} '
                      '${route.date.hour.toString().padLeft(2, '0')}:${route.date.minute.toString().padLeft(2, '0')}\n'
                      'Miejsca: ${route.seats - route.bookedSeats} / ${route.seats}',
                ),
                trailing: ElevatedButton(
                  onPressed: () => reserveSeat(route),
                  child: const Text('Rezerwuj'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}