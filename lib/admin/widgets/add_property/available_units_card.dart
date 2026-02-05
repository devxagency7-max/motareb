import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_motareb/core/utils/loc_extension.dart';
import 'add_property_helpers.dart';

class AvailableUnitsCard extends StatefulWidget {
  final ValueNotifier<List<Map<String, dynamic>>> roomsNotifier;
  final TextEditingController bathroomsController;
  final TextEditingController priceController;
  final TextEditingController discountPriceController;

  // New Booking Modes
  final ValueNotifier<String> bookingModeNotifier; // 'unit' | 'bed'
  final ValueNotifier<bool> isFullApartmentNotifier;
  final TextEditingController totalBedsController;
  final TextEditingController bedPriceController;
  final TextEditingController apartmentRoomsCountController;
  final TextEditingController roomTypeController;

  const AvailableUnitsCard({
    super.key,
    required this.roomsNotifier,
    required this.bathroomsController,
    required this.priceController,
    required this.discountPriceController,
    required this.bookingModeNotifier,
    required this.isFullApartmentNotifier,
    required this.totalBedsController,
    required this.bedPriceController,
    required this.apartmentRoomsCountController,
    required this.roomTypeController,
  });

  @override
  State<AvailableUnitsCard> createState() => _AvailableUnitsCardState();
}

class _AvailableUnitsCardState extends State<AvailableUnitsCard> {
  Timer? _debouncePrice;

  @override
  void initState() {
    super.initState();
    widget.priceController.addListener(_onPriceChanged);
    widget.discountPriceController.addListener(_onPriceChanged);
    // Listen to changes that affect price helper text or logic
    widget.bookingModeNotifier.addListener(_updateState);
    widget.isFullApartmentNotifier.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.priceController.removeListener(_onPriceChanged);
    widget.discountPriceController.removeListener(_onPriceChanged);
    widget.bookingModeNotifier.removeListener(_updateState);
    widget.isFullApartmentNotifier.removeListener(_updateState);
    _debouncePrice?.cancel();
    super.dispose();
  }

  void _onPriceChanged() {
    if (_debouncePrice?.isActive ?? false) _debouncePrice!.cancel();
    _debouncePrice = Timer(const Duration(milliseconds: 500), () {
      _recalculatePrices();
    });
  }

  void _recalculatePrices() {
    // In bed mode, we don't need to distribute prices among rooms since each bed has the same price
    if (widget.bookingModeNotifier.value == 'bed') {
      if (mounted) setState(() {});
      return;
    }

    final discountText = widget.discountPriceController.text.trim();
    final regularText = widget.priceController.text.trim();

    double totalPrice = double.tryParse(discountText) ?? 0.0;
    if (totalPrice <= 0) {
      totalPrice = double.tryParse(regularText) ?? 0.0;
    }

    final currentRooms = List<Map<String, dynamic>>.from(
      widget.roomsNotifier.value,
    );
    if (currentRooms.isEmpty) return;

    int totalWeight = 0;
    for (var room in currentRooms) {
      final type = room['type'];
      final beds = (room['beds'] as int?) ?? 0;

      if (type == 'Single') {
        totalWeight += 2;
      } else {
        totalWeight += beds;
      }
    }

    if (totalWeight == 0) return;

    final pricePerUnit = totalPrice / totalWeight;

    final updatedRooms = currentRooms.map((room) {
      final type = room['type'];
      final beds = (room['beds'] as int?) ?? 0;

      double roomPrice;
      if (type == 'Single') {
        roomPrice = pricePerUnit * 2;
      } else {
        roomPrice = pricePerUnit * beds;
      }

      double bedPrice = beds > 0 ? roomPrice / beds : 0.0;

      final newRoom = Map<String, dynamic>.from(room);
      newRoom['price'] = double.parse(roomPrice.toStringAsFixed(2));
      newRoom['bedPrice'] = double.parse(bedPrice.toStringAsFixed(2));
      return newRoom;
    }).toList();

    widget.roomsNotifier.value = updatedRooms;
  }

  void _addRoom(BuildContext context) {
    // Unfocus to prevent the screen from jumping back to the last active field after closing
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddRoomSheet(
        onAdd: (room) {
          final list = List<Map<String, dynamic>>.from(
            widget.roomsNotifier.value,
          );
          list.add(room);
          widget.roomsNotifier.value = list;
          _recalculatePrices();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _removeRoom(int index) {
    final list = List<Map<String, dynamic>>.from(widget.roomsNotifier.value);
    list.removeAt(index);
    widget.roomsNotifier.value = list;
    _recalculatePrices();
  }

  void _editRoomDetails(
    BuildContext context,
    int index,
    Map<String, dynamic> room,
  ) {
    showDialog(
      context: context,
      builder: (context) => RoomEditDialog(
        currentRoom: room,
        onSave: (updatedRoom) {
          final list = List<Map<String, dynamic>>.from(
            widget.roomsNotifier.value,
          );
          list[index] = updatedRoom;
          widget.roomsNotifier.value = list;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      children: [
        // --- Header: Mode Selection and Bathrooms ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(context.loc.bookingSystem, fontSize: 13),
                  const SizedBox(height: 8),
                  // Booking Mode Logic
                  ValueListenableBuilder<String>(
                    valueListenable: widget.bookingModeNotifier,
                    builder: (context, mode, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1E2329)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2F3640)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: mode,
                            isExpanded: true,
                            style: GoogleFonts.cairo(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            dropdownColor: Theme.of(context).cardTheme.color,
                            items: [
                              DropdownMenuItem(
                                value: 'unit',
                                child: Text(context.loc.unitSystem),
                              ),
                              DropdownMenuItem(
                                value: 'bed',
                                child: Text(context.loc.bedSystem),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                widget.bookingModeNotifier.value = val;
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: CustomTextField(
                label: context.loc.bathrooms,
                hint: '1',
                controller: widget.bathroomsController,
                keyboardType: TextInputType.number,
                icon: Icons.bathtub_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // --- Body: Dependent on Mode ---
        ValueListenableBuilder<String>(
          valueListenable: widget.bookingModeNotifier,
          builder: (context, mode, _) {
            if (mode == 'bed') {
              return _buildBedModeUI();
            } else {
              return _buildUnitModeUI();
            }
          },
        ),
      ],
    );
  }

  Widget _buildBedModeUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: '',
                hint: context.loc.totalBedsCount,
                controller: widget.totalBedsController,
                keyboardType: TextInputType.number,
                icon: Icons.bed,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                label: '',
                hint: context.loc.roomsCount,
                controller: widget.apartmentRoomsCountController,
                keyboardType: TextInputType.number,
                icon: Icons.meeting_room,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        CustomTextField(
          label: context.loc.roomTypeDescription,
          hint: 'Shared rooms, double rooms...',
          controller: widget.roomTypeController,
          icon: Icons.description,
        ),
        const SizedBox(height: 15),
        // Helper Calculation Display
        Builder(
          builder: (context) {
            final priceText =
                widget.discountPriceController.text.trim().isNotEmpty
                ? widget.discountPriceController.text.trim()
                : widget.priceController.text.trim();
            final bedPrice = double.tryParse(priceText) ?? 0.0;

            return Text(
              '${context.loc.expectedBedPrice} ${bedPrice.toStringAsFixed(0)} ${context.loc.currency}',
              style: GoogleFonts.cairo(
                color: const Color(0xFF39BB5E),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUnitModeUI() {
    return Column(
      children: [
        // Full Apartment Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isFullApartmentNotifier.value
                ? const Color(0xFF008695).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isFullApartmentNotifier.value
                  ? const Color(0xFF008695)
                  : (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2F3640)
                        : Colors.grey.shade300),
            ),
          ),
          child: SwitchListTile(
            title: Text(
              context.loc.fullApartmentBooking,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: widget.isFullApartmentNotifier.value
                    ? const Color(0xFF008695)
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              context.loc.fullApartmentSubtitle,
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
            ),
            value: widget.isFullApartmentNotifier.value,
            activeColor: const Color(0xFF008695),
            onChanged: (val) {
              setState(() {
                widget.isFullApartmentNotifier.value = val;
              });
            },
          ),
        ),
        const SizedBox(height: 15),

        const SizedBox(height: 15),

        // Removed the check: if (!widget.isFullApartmentNotifier.value) ...[
        SectionLabel(context.loc.roomDetails, fontSize: 15),
        if (widget.isFullApartmentNotifier.value)
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 5),
            child: Text(
              context.loc.roomDetailsNote,
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.orange),
            ),
          ),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: widget.roomsNotifier,
          builder: (context, rooms, child) {
            return Column(
              children: [
                if (rooms.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E2329)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2F3640)
                            : Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'لا توجد غرف مضافة بعد',
                          style: GoogleFonts.cairo(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rooms.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      String label = context.loc.customRoom;
                      final type = room['type'];
                      if (type == 'Single') {
                        label = context.loc.singleRoom;
                      } else if (type == 'Double') {
                        label = context.loc.doubleRoom;
                      } else if (type == 'Triple') {
                        label = context.loc.tripleRoom;
                      }

                      final beds = room['beds'] ?? 0;
                      final price = room['price'] ?? 0.0;
                      final bedPrice = room['bedPrice'] ?? 0.0;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:
                              Theme.of(context).brightness == Brightness.dark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2F3640)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF39BB5E).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bed,
                                color: Color(0xFF39BB5E),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Text(
                                    '${context.loc.numBeds}: $beds',
                                    style: GoogleFonts.cairo(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        '${context.loc.unitSystem}: $price ${context.loc.currency}',
                                        style: GoogleFonts.cairo(
                                          color: const Color(0xFF008695),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        height: 10,
                                        width: 1,
                                        color: Colors.grey,
                                      ),
                                      Text(
                                        '${context.loc.bedSystem}: $bedPrice ${context.loc.currency}',
                                        style: GoogleFonts.cairo(
                                          color: Colors.orange.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _editRoomDetails(context, index, room),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeRoom(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => _addRoom(context),
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF39BB5E)),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFF39BB5E).withOpacity(0.05),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Color(0xFF39BB5E)),
                        const SizedBox(width: 5),
                        Text(
                          context.loc.addRoom,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF39BB5E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 15),

        if (widget.isFullApartmentNotifier.value)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E2329)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2F3640)
                    : Colors.grey.shade400,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.home_work_outlined,
                  size: 50,
                  color: Colors.grey,
                ),
                const SizedBox(height: 10),
                Text(
                  'تم تفعيل وضع "حجز الشقة بالكامل"',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                  ),
                ),
                Text(
                  'السعر المعروض للعميل سيكون سعر العقار الكلي',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class RoomEditDialog extends StatefulWidget {
  final Map<String, dynamic> currentRoom;
  final Function(Map<String, dynamic>) onSave;

  const RoomEditDialog({
    super.key,
    required this.currentRoom,
    required this.onSave,
  });

  @override
  State<RoomEditDialog> createState() => _RoomEditDialogState();
}

class _RoomEditDialogState extends State<RoomEditDialog> {
  late TextEditingController _bedsController;
  late TextEditingController _roomPriceController;
  late TextEditingController _bedPriceController;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final beds = widget.currentRoom['beds'] ?? 0;
    final roomPrice = widget.currentRoom['price'] ?? 0.0;
    final bedPrice =
        widget.currentRoom['bedPrice'] ?? (beds > 0 ? roomPrice / beds : 0.0);

    _bedsController = TextEditingController(text: beds.toString());
    _roomPriceController = TextEditingController(text: roomPrice.toString());
    _bedPriceController = TextEditingController(text: bedPrice.toString());

    _roomPriceController.addListener(_onRoomPriceChanged);
    _bedPriceController.addListener(_onBedPriceChanged);
    _bedsController.addListener(_onBedsChanged);
  }

  void _onRoomPriceChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final roomPrice = double.tryParse(_roomPriceController.text) ?? 0.0;
    final beds = double.tryParse(_bedsController.text) ?? 1.0;
    if (beds > 0) {
      final bedPrice = roomPrice / beds;
      _bedPriceController.text = bedPrice.toStringAsFixed(2);
    }
    _isUpdating = false;
  }

  void _onBedPriceChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final bedPrice = double.tryParse(_bedPriceController.text) ?? 0.0;
    final beds = double.tryParse(_bedsController.text) ?? 1.0;
    final roomPrice = bedPrice * beds;
    _roomPriceController.text = roomPrice.toStringAsFixed(2);
    _isUpdating = false;
  }

  void _onBedsChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final bedPrice = double.tryParse(_bedPriceController.text) ?? 0.0;
    final beds = double.tryParse(_bedsController.text) ?? 1.0;
    final roomPrice = bedPrice * beds;
    _roomPriceController.text = roomPrice.toStringAsFixed(2);
    _isUpdating = false;
  }

  @override
  void dispose() {
    _bedsController.dispose();
    _roomPriceController.dispose();
    _bedPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.loc.editRoom,
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _bedsController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                labelText: context.loc.numBeds,
                labelStyle: GoogleFonts.cairo(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[700],
                ),
                suffixIcon: const Icon(Icons.bed),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _roomPriceController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                labelText: context.loc.roomPrice,
                labelStyle: GoogleFonts.cairo(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[700],
                ),
                suffixText: context.loc.currency,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _bedPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.loc.bedPrice,
                labelStyle: GoogleFonts.cairo(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[700],
                ),
                suffixText: context.loc.currency,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fillColor: Colors.orange.withOpacity(0.1),
                filled: true,
              ),
              style: GoogleFonts.cairo(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.loc.cancel,
            style: GoogleFonts.cairo(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: () {
            final beds = int.tryParse(_bedsController.text) ?? 0;
            final roomPrice = double.tryParse(_roomPriceController.text) ?? 0.0;
            final bedPrice = double.tryParse(_bedPriceController.text) ?? 0.0;
            final updatedRoom = Map<String, dynamic>.from(widget.currentRoom);
            updatedRoom['beds'] = beds;
            updatedRoom['price'] = roomPrice;
            updatedRoom['bedPrice'] = bedPrice;
            widget.onSave(updatedRoom);
            Navigator.pop(context);
          },
          child: Text(
            context.loc.save,
            style: GoogleFonts.cairo(
              color: const Color(0xFF39BB5E),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class AddRoomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const AddRoomSheet({super.key, required this.onAdd});

  @override
  State<AddRoomSheet> createState() => _AddRoomSheetState();
}

class _AddRoomSheetState extends State<AddRoomSheet> {
  String _selectedType = 'Single';
  final _bedsController = TextEditingController();
  final List<String> _types = ['Single', 'Double', 'Triple', 'Custom'];

  @override
  void initState() {
    super.initState();
    _updateBedsFromType();
  }

  void _updateBedsFromType() {
    if (_selectedType == 'Single') {
      _bedsController.text = '1';
    } else if (_selectedType == 'Double') {
      _bedsController.text = '2';
    } else if (_selectedType == 'Triple') {
      _bedsController.text = '3';
    } else {
      _bedsController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.loc.addNewRoom,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.loc.roomType,
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _types.map((type) {
              final isSelected = _selectedType == type;
              String label = type;
              if (type == 'Single') label = context.loc.single;
              if (type == 'Double') label = context.loc.double;
              if (type == 'Triple') label = context.loc.triple;
              if (type == 'Custom') label = context.loc.custom;

              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: const Color(0xFF39BB5E).withOpacity(0.2),
                labelStyle: GoogleFonts.cairo(
                  color: isSelected
                      ? const Color(0xFF39BB5E)
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedType = type;
                      _updateBedsFromType();
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            context.loc.bedsInRoom,
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bedsController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.cairo(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: context.loc.enterNumBeds,
              hintStyle: GoogleFonts.cairo(
                color: isDark ? Colors.grey[600] : Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey.shade300,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39BB5E),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final beds = int.tryParse(_bedsController.text) ?? 0;
                if (beds <= 0) return;
                widget.onAdd({
                  'type': _selectedType,
                  'beds': beds,
                  'createdAt': DateTime.now().toIso8601String(),
                });
              },
              child: Text(
                context.loc.add,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
