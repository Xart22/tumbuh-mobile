import '../models/kds_ticket.dart';

class KdsMockData {
  KdsMockData._();

  static List<KdsTicket> getInitialTickets() {
    final now = DateTime.now();

    return [
      KdsTicket(
        id: 'ticket-104',
        ticketNumber: '#TB-104',
        orderType: 'Dine-in',
        tableOrCustomer: 'MEJA 03',
        serverName: 'Rama',
        enteredAt: now.subtract(const Duration(minutes: 16, seconds: 42)),
        fixedElapsedSeconds: 16 * 60 + 42,
        urgencyOverride: KdsUrgency.overdue,
        status: KdsTicketStatus.ready,
        specialInstructions: 'Minta sambal dipisah wadah kecil!',
        items: const [
          KdsTicketItem(
            id: 'item-104-1',
            name: 'Nasi Goreng Kampung',
            quantity: 1,
            station: KdsStation.kitchen,
            stationBadge: 'Siap Saji',
            notes: 'Level Pedas: Sedang, Telur Ceplok 1/2 Matang',
            isCompleted: true,
          ),
          KdsTicketItem(
            id: 'item-104-2',
            name: 'Creamy Truffle Fettuccine',
            quantity: 1,
            station: KdsStation.kitchen,
            stationBadge: 'Wok 1',
            modifierText: '⚡ Mod: Extra Beef Rashers, Parsley, Less Salt',
            isCompleted: false,
          ),
        ],
      ),
      KdsTicket(
        id: 'ticket-105',
        ticketNumber: '#TB-105',
        orderType: 'Dine-in',
        tableOrCustomer: 'MEJA 08',
        serverName: 'Dika',
        enteredAt: now.subtract(const Duration(minutes: 11, seconds: 15)),
        fixedElapsedSeconds: 11 * 60 + 15,
        urgencyOverride: KdsUrgency.warning,
        status: KdsTicketStatus.cooking,
        items: const [
          KdsTicketItem(
            id: 'item-105-1',
            name: 'Iced Aren Latte',
            quantity: 2,
            station: KdsStation.barista,
            stationBadge: 'BARISTA',
            notes: 'Less Ice, Normal Sugar',
            isCompleted: false,
          ),
          KdsTicketItem(
            id: 'item-105-2',
            name: 'Almond Butter Croissant',
            quantity: 1,
            station: KdsStation.pastry,
            stationBadge: 'BAKERY',
            modifierText: '🔥 Hangatkan / Toasting (Oven 2)',
            isCompleted: false,
          ),
        ],
      ),
      KdsTicket(
        id: 'ticket-106',
        ticketNumber: '#TB-106',
        orderType: 'Take Away',
        tableOrCustomer: 'GOJEK DRIVER: BUDI',
        serverName: 'Kasir 1',
        enteredAt: now.subtract(const Duration(minutes: 3, seconds: 20)),
        fixedElapsedSeconds: 3 * 60 + 20,
        urgencyOverride: KdsUrgency.fresh,
        status: KdsTicketStatus.cooking,
        customerArrivalNote: 'Driver sudah tiba di counter',
        items: const [
          KdsTicketItem(
            id: 'item-106-1',
            name: 'Iced Matcha Latte',
            quantity: 3,
            station: KdsStation.barista,
            stationBadge: 'BARISTA',
            notes: 'Oat Milk Substituted',
            isCompleted: false,
          ),
          KdsTicketItem(
            id: 'item-106-2',
            name: 'Pain Au Chocolat',
            quantity: 2,
            station: KdsStation.pastry,
            stationBadge: 'BAKERY',
            modifierText: '📦 Bungkus Paper Bag Terpisah',
            isCompleted: false,
          ),
        ],
      ),
      KdsTicket(
        id: 'ticket-107',
        ticketNumber: '#TB-107',
        orderType: 'Dine-in',
        tableOrCustomer: 'MEJA 01',
        serverName: 'Rama',
        enteredAt: now.subtract(const Duration(seconds: 45)),
        fixedElapsedSeconds: 45,
        urgencyOverride: KdsUrgency.newOrder,
        status: KdsTicketStatus.queued,
        items: const [
          KdsTicketItem(
            id: 'item-107-1',
            name: 'Wagyu Beef Burger',
            quantity: 1,
            station: KdsStation.kitchen,
            stationBadge: 'GRILL',
            modifierText: 'No Onion, Extra Cheese, Medium Well',
            isCompleted: false,
          ),
          KdsTicketItem(
            id: 'item-107-2',
            name: 'French Fries Truffle',
            quantity: 1,
            station: KdsStation.kitchen,
            stationBadge: 'FRYER',
            notes: 'Saus Mayo Dipisah',
            isCompleted: false,
          ),
        ],
      ),
    ];
  }

  static List<KdsTicket> getInitialRecalledTickets() {
    final now = DateTime.now();
    return [
      KdsTicket(
        id: 'ticket-102',
        ticketNumber: '#TB-102',
        orderType: 'Dine-in',
        tableOrCustomer: 'MEJA 04',
        serverName: 'Siti',
        enteredAt: now.subtract(const Duration(minutes: 35)),
        status: KdsTicketStatus.served,
        items: const [
          KdsTicketItem(
            id: 'item-102-1',
            name: 'Americano Hot',
            quantity: 1,
            station: KdsStation.barista,
            isCompleted: true,
          ),
          KdsTicketItem(
            id: 'item-102-2',
            name: 'Avocado Toast',
            quantity: 1,
            station: KdsStation.kitchen,
            isCompleted: true,
          ),
        ],
      ),
      KdsTicket(
        id: 'ticket-103',
        ticketNumber: '#TB-103',
        orderType: 'Take Away',
        tableOrCustomer: 'GRABFOOD: AGUS',
        serverName: 'Kasir 2',
        enteredAt: now.subtract(const Duration(minutes: 25)),
        status: KdsTicketStatus.served,
        items: const [
          KdsTicketItem(
            id: 'item-103-1',
            name: 'Caramel Macchiato',
            quantity: 2,
            station: KdsStation.barista,
            isCompleted: true,
          ),
        ],
      ),
    ];
  }
}
