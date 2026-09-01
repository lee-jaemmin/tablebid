import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tablebid/models/company_model.dart';
import 'package:tablebid/services/floor_image_api.dart';

class CompanyFloorImage extends StatefulWidget {
  final CompanyModel company;
  final bool canAdd;
  final bool canReplace;
  final ValueChanged<CompanyModel> onCompanyUpdated;

  const CompanyFloorImage({
    super.key,
    required this.company,
    required this.canAdd,
    required this.canReplace,
    required this.onCompanyUpdated,
  });

  @override
  State<CompanyFloorImage> createState() => _CompanyFloorImageState();
}

class _CompanyFloorImageState extends State<CompanyFloorImage>
    with AutomaticKeepAliveClientMixin {
  String? _imageUrl;
  String? _loadedPath;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  bool get wantKeepAlive => true;

  String? _normalizedPath(String? path) {
    final value = path?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  @override
  void initState() {
    super.initState();
    _loadedPath = _normalizedPath(widget.company.floorImagePath);
    if (_loadedPath != null) _loadImageUrl();
  }

  @override
  void didUpdateWidget(covariant CompanyFloorImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newPath = _normalizedPath(widget.company.floorImagePath);
    if (newPath == _loadedPath) return;
    _loadedPath = newPath;
    if (newPath == null) {
      setState(() {
        _imageUrl = null;
        _errorMessage = null;
        _isLoading = false;
      });
    } else {
      _loadImageUrl();
    }
  }

  String _messageForError(FloorImageApiException error) {
    switch (error.statusCode) {
      case 401:
        return '로그인이 만료되었습니다. 다시 로그인해주세요.';
      case 403:
        return '이미지에 접근할 권한이 없습니다.';
      case 400:
        return 'JPEG, PNG, WebP 이미지만 등록할 수 있습니다.';
      case 413:
        return '이미지는 최대 5MB까지 등록할 수 있습니다.';
      case 502:
      case 503:
        return '이미지 저장소에 일시적인 문제가 발생했습니다.';
      default:
        return error.message;
    }
  }

  Future<void> _loadImageUrl() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final url = await FloorImageApi().getFloorImageUrl(widget.company.id);
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _isLoading = false;
      });
    } on FloorImageApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _imageUrl = null;
        _errorMessage = e.statusCode == 404 ? null : _messageForError(e);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _imageUrl = null;
        _errorMessage = '이미지를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  String? _contentTypeFor(XFile file) {
    final mimeType = file.mimeType?.toLowerCase();
    if (mimeType == 'image/jpeg' ||
        mimeType == 'image/png' ||
        mimeType == 'image/webp') {
      return mimeType;
    }
    final name = file.name.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return null;
  }

  Future<void> _pickAndUpload() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final contentType = _contentTypeFor(file);
    if (contentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JPEG, PNG, WebP 이미지만 등록할 수 있습니다.')),
      );
      return;
    }
    if (await file.length() > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지는 최대 5MB까지 등록할 수 있습니다.')),
      );
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });
    try {
      final company = await FloorImageApi().uploadFloorImage(
        companyId: widget.company.id,
        bytes: bytes,
        filename: file.name,
        contentType: contentType,
      );
      if (!mounted) return;
      _loadedPath = _normalizedPath(company.floorImagePath);
      widget.onCompanyUpdated(company);
      await _loadImageUrl();
    } on FloorImageApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageForError(e))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _confirmReplacement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('이미지 교체'),
        content: const Text('새로운 이미지를 올리시겠습니까?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text(
                    '아니요',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('예'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _pickAndUpload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isUploading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadedPath == null ||
        _imageUrl == null && _errorMessage == null && !_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('매장 테이블 배치도가 없습니다.'),
            if (widget.canAdd) ...[
              SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black
                ),
                onPressed: _pickAndUpload,
                child: const Text('+ 이미지 추가하기'),
              ),
            ],
          ],
        ),
      );
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadImageUrl,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        onTap: widget.canReplace ? _confirmReplacement : null,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Center(
            child: Image.network(
              _imageUrl!,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const CircularProgressIndicator(),
              errorBuilder: (context, error, stackTrace) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('이미지를 표시하지 못했습니다.'),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadImageUrl,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
