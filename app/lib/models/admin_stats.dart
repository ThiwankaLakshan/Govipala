class UserStats {
  final int totalUsers;
  final int farmers;
  final int owners;
  final int bothRoles;
  final int admins;
  final int activeUsers;
  final int suspendedUsers;

  const UserStats({
    required this.totalUsers,
    required this.farmers,
    required this.owners,
    required this.bothRoles,
    required this.admins,
    required this.activeUsers,
    required this.suspendedUsers,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalUsers: json['total_users'] as int? ?? 0,
      farmers: json['farmers'] as int? ?? 0,
      owners: json['owners'] as int? ?? 0,
      bothRoles: json['both_roles'] as int? ?? 0,
      admins: json['admins'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      suspendedUsers: json['suspended_users'] as int? ?? 0,
    );
  }
}

class MachineStats {
  final int totalMachines;
  final int activeMachines;
  final int inactiveMachines;

  const MachineStats({
    required this.totalMachines,
    required this.activeMachines,
    required this.inactiveMachines,
  });

  factory MachineStats.fromJson(Map<String, dynamic> json) {
    return MachineStats(
      totalMachines: json['total_machines'] as int? ?? 0,
      activeMachines: json['active_machines'] as int? ?? 0,
      inactiveMachines: json['inactive_machines'] as int? ?? 0,
    );
  }
}

class BookingStats {
  final int totalBookings;
  final int pendingBookings;
  final int confirmedBookings;
  final int inProgressBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int bookingsToday;

  const BookingStats({
    required this.totalBookings,
    required this.pendingBookings,
    required this.confirmedBookings,
    required this.inProgressBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.bookingsToday,
  });

  factory BookingStats.fromJson(Map<String, dynamic> json) {
    return BookingStats(
      totalBookings: json['total_bookings'] as int? ?? 0,
      pendingBookings: json['pending_bookings'] as int? ?? 0,
      confirmedBookings: json['confirmed_bookings'] as int? ?? 0,
      inProgressBookings: json['in_progress_bookings'] as int? ?? 0,
      completedBookings: json['completed_bookings'] as int? ?? 0,
      cancelledBookings: json['cancelled_bookings'] as int? ?? 0,
      bookingsToday: json['bookings_today'] as int? ?? 0,
    );
  }
}

class AdminDashboardStats {
  final UserStats users;
  final MachineStats machines;
  final BookingStats bookings;

  const AdminDashboardStats({
    required this.users,
    required this.machines,
    required this.bookings,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      users: UserStats.fromJson(json['users'] as Map<String, dynamic>? ?? {}),
      machines: MachineStats.fromJson(json['machines'] as Map<String, dynamic>? ?? {}),
      bookings: BookingStats.fromJson(json['bookings'] as Map<String, dynamic>? ?? {}),
    );
  }
}
