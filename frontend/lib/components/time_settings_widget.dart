import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeSettingsWidget extends StatefulWidget {
  final Function(Map<String, dynamic>)? onChanged;

  const TimeSettingsWidget({super.key, this.onChanged});

  @override
  State<TimeSettingsWidget> createState() => _TimeSettingsWidgetState();
}

class _TimeSettingsWidgetState extends State<TimeSettingsWidget> {
  // Lokální stav: true = Okamžité, false = Naplánované
  bool _isInstant = true;
  
  // Stavy pro vybraná data a časy
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  
  // Délka testu
  int _durationMinutes = 45;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChanges();
    });
  }

  void _notifyChanges() {
    if (widget.onChanged != null) {
      widget.onChanged!({
        'isInstant': _isInstant,
        'startDate': _startDate?.toIso8601String(),
        'startTime': _startTime != null ? '${_startTime!.hour}:${_startTime!.minute}' : null,
        'endDate': _endDate?.toIso8601String(),
        'endTime': _endTime != null ? '${_endTime!.hour}:${_endTime!.minute}' : null,
        'durationMinutes': _durationMinutes,
      });
    }
  }

  // Funkce pro výběr data
  Future<void> _pickDate(BuildContext context, bool isStart) async {
    DateTime initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now());
    DateTime first = isStart ? DateTime.now() : (_startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      cancelText: 'ZRUŠIT',
      confirmText: 'VYBRAT',
      helpText: isStart ? 'VYBERTE DATUM SPUŠTĚNÍ' : 'VYBERTE DATUM UKONČENÍ',
      errorFormatText: 'Neplatný formát',
      errorInvalidText: 'Neplatné datum',
      fieldLabelText: 'Zadejte datum',
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
      _notifyChanges();
    }
  }

  // Funkce pro výběr času
  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? _startTime ?? TimeOfDay.now()),
      cancelText: 'ZRUŠIT',
      confirmText: 'VYBRAT',
      helpText: isStart ? 'VYBERTE ČAS SPUŠTĚNÍ' : 'VYBERTE ČAS UKONČENÍ',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!isStart && _startDate != null && _endDate != null && _startTime != null) {
        bool isSameDay = _startDate!.year == _endDate!.year && 
                         _startDate!.month == _endDate!.month && 
                         _startDate!.day == _endDate!.day;
        
        if (isSameDay) {
          final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
          final pickedMinutes = picked.hour * 60 + picked.minute;
          
          if (pickedMinutes <= startMinutes) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Čas "do" musí být později než čas "od" ve stejný den.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        }
      }

      setState(() {
        if (isStart) {
          _startTime = picked;
          if (_startDate != null && _endDate != null && _endTime != null) {
            bool isSameDay = _startDate!.year == _endDate!.year && 
                             _startDate!.month == _endDate!.month && 
                             _startDate!.day == _endDate!.day;
            if (isSameDay) {
              final startMinutes = picked.hour * 60 + picked.minute;
              final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
              if (endMinutes <= startMinutes) {
                _endTime = null;
              }
            }
          }
        } else {
          _endTime = picked;
        }
      });
      _notifyChanges();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'dd. mm. rrrr';
    return '${date.day}. ${date.month}. ${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'hh : mm';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 10.0,
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true, 
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Icon(Icons.schedule_rounded, color: Theme.of(context).colorScheme.secondary),
          title: Text(
            'DOSTUPNOST TESTU', 
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.1)
          ),
          childrenPadding: const EdgeInsets.all(20),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            Text('Typ spuštění', style: GoogleFonts.inter(fontSize: 15.0, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    label: 'Okamžité', // Mírně zkráceno pro lepší responzivitu
                    icon: Icons.bolt_rounded,
                    isSelected: _isInstant,
                    onTap: () {
                      setState(() => _isInstant = true);
                      _notifyChanges();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToggleButton(
                    label: 'Naplánované',
                    icon: Icons.edit_calendar_rounded,
                    isSelected: !_isInstant,
                    onTap: () {
                      setState(() => _isInstant = false);
                      _notifyChanges();
                    },
                  ),
                ),
              ],
            ),

            if (!_isInstant) ...[
              const SizedBox(height: 24),
              Text('Datum a čas dostupnosti testu', style: GoogleFonts.inter(fontSize: 15.0, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(child: _buildTimeBox('Datum (od)', _formatDate(_startDate), Icons.calendar_today_rounded, _startDate != null, () => _pickDate(context, true))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimeBox('Čas (od)', _formatTime(_startTime), Icons.access_time_rounded, _startTime != null, () => _pickTime(context, true))),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(child: _buildTimeBox('Datum (do)', _formatDate(_endDate), Icons.calendar_today_rounded, _endDate != null, () => _pickDate(context, false))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimeBox('Čas (do)', _formatTime(_endTime), Icons.access_time_rounded, _endTime != null, () => _pickTime(context, false))),
                ],
              ),
            ],

            const SizedBox(height: 24),
            Divider(thickness: 1, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 20),

            // DÉLKA TESTU 
            Row(
              children: [
                Icon(Icons.timer_outlined, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Časový limit (min):', 
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)
                  ),
                ),
                
                IconButton(
                  onPressed: () {
                    setState(() => _durationMinutes = (_durationMinutes > 5) ? _durationMinutes - 5 : 5);
                    _notifyChanges();
                  },
                  icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.primary),
                  splashRadius: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  alignment: Alignment.center,
                  child: Text('$_durationMinutes', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() => _durationMinutes += 5);
                    _notifyChanges();
                  },
                  icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                  splashRadius: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Pomocný widget pro přepínací tlačítka (Ochrana proti overflow)
  Widget _buildToggleButton({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48.0,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pomocný widget pro pole s datem/časem
  Widget _buildTimeBox(String label, String value, IconData icon, bool hasValue, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            height: 46.0,
            decoration: BoxDecoration(
              color: hasValue ? Theme.of(context).colorScheme.surface : Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: hasValue ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outline),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    value, 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: hasValue ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.secondary,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    )
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, color: hasValue ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}