import 'package:flutter/material.dart';
import 'package:tablebid/models/item_model.dart';
import 'package:tablebid/widgets/purchase_item_chip.dart';

class MixerSelectionBottomSheet extends StatefulWidget {
  final List<ItemModel> mixers;

  const MixerSelectionBottomSheet({super.key, required this.mixers});

  @override
  State<MixerSelectionBottomSheet> createState() =>
      _MixerSelectionBottomSheetState();
}

class _MixerSelectionBottomSheetState extends State<MixerSelectionBottomSheet> {
  final Map<int, int> _selectedMixerQuantities = {};

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).dialogTheme.backgroundColor,
      child: SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.65,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    '믹서 선택',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: widget.mixers.isEmpty
                      ? const Center(child: Text('선택 가능한 무료 믹서가 없습니다.'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.mixers.map((mixer) {
                              final quantity =
                                  _selectedMixerQuantities[mixer.id] ?? 0;
                              return PurchaseItemChip(
                                itemName: mixer.itemName,
                                onTap: () {
                                  setState(() {
                                    _selectedMixerQuantities[mixer.id] =
                                        quantity + 1;
                                  });
                                },
                                isSelected: quantity > 0,
                                quantity: quantity,
                              );
                            }).toList(),
                          ),
                        ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedMixerQuantities.clear();
                          });
                        },
                        child: const Text(
                          '다시 선택',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final selectedMixers = <ItemModel>[];
                          for (final mixer in widget.mixers) {
                            final quantity =
                                _selectedMixerQuantities[mixer.id] ?? 0;
                            selectedMixers.addAll(
                              List<ItemModel>.filled(quantity, mixer),
                              // filled(리스트길이, 채울 값)
                              // 콜라3 토닉2 고르면 [콜라 콜라 콜라 토닉 토닉] 이렇게 전달한다는 거구나
                              //addPurchase그대로 사용하기 위함
                            );
                          }
                          Navigator.pop(context, selectedMixers);
                        },
                        child: const Text(
                          '선택 완료',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
