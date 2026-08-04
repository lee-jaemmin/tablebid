import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tablebid/services/address_api.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _controller = TextEditingController();
  final _api = AddressApi();
  bool _isLoading = false;
  List<AddressResult> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final results = await _api.getAddress(keyword);
      if (!mounted) return;
      setState(() => _results = results.take(10).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('주소 검색 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('매장 주소 입력'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '도로명, 건물명, 번지 검색',
                suffixIcon: IconButton(
                  onPressed: _searchAddress,
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => _searchAddress(),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(child: CupertinoActivityIndicator()),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final address = _results[index];
                    return ListTile(
                      title: Text(address.roadAddr),
                      subtitle: Text('${address.jibunAddr}\n${address.zipNo}'),
                      isThreeLine: true,
                      onTap: () => Navigator.pop(context, address),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
