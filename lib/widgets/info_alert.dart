// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:tablebid/class/app_user.dart';
// import 'package:tablebid/class/table.dart';
// import 'package:tablebid/class/table_repo.dart';
// import 'package:tablebid/screens/move_screen.dart';
// import 'package:tablebid/widgets/phonenumber_formatter.dart';
// import 'package:tablebid/widgets/price_formatter.dart';
// import 'package:intl/intl.dart';

// class InfoAlert extends StatefulWidget {
//   final String companyId;
//   final TableModel table;

//   const InfoAlert({
//     super.key,
//     required this.companyId,
//     required this.table,
//   });

//   @override
//   State<InfoAlert> createState() => _TableRegistrationDialogState();
// }

// class _TableRegistrationDialogState extends State<InfoAlert> {
//   // 입력 컨트롤러 정의
//   late TextEditingController _nameController;
//   late TextEditingController _phoneController;
//   final List<TextEditingController> _purchasesController = [];
//   late TextEditingController _staffController;
//   late TextEditingController _remarksController;
//   late TextEditingController _personsController;
//   late TextEditingController _priceController;
//   final _repo = TableRepository();
//   Timer? _localTimer;

//   Future<AppUser?> _fetchCurrentUser() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       return null;
//     }
//     final doc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .get();

//     return AppUser.fromMap(doc.id, doc.data()!);
//   }

//   @override
//   void initState() {
//     super.initState();
//     // [핵심] 테이블의 기존 정보를 컨트롤러의 초기값으로 설정합니다.
//     // '미지정' 혹은 '없음'과 같은 기본값일 때는 빈 칸으로 보여줍니다.
//     _nameController = TextEditingController(
//       text: widget.table.customer == '손님 미지정' ? '' : widget.table.customer,
//     );
//     _phoneController = TextEditingController(
//       text: widget.table.phonenumber == '번호 없음' ? '' : widget.table.phonenumber,
//     );

//     final initialPurchase = widget.table.purchases.isNotEmpty
//         ? widget.table.purchases
//         : widget.table.bottle
//               .split('\n')
//               .map((e) => e.trim())
//               .where((elem) => elem.isNotEmpty && elem != '바틀 미지정')
//               .toList();
//     // 구버전이 write한 경우, READ bottle field, 신버전이 write 한 경우, READ purchases field,

//     if (initialPurchase.isEmpty) {
//       _purchasesController.add(TextEditingController());
//     } else {
//       for (var item in initialPurchase) {
//         _purchasesController.add(TextEditingController(text: item));
//       }
//     }

//     _personsController = TextEditingController(
//       text: widget.table.persons == 0 ? '' : widget.table.persons.toString(),
//     );
//     _priceController = TextEditingController(
//       text: widget.table.price == 0
//           ? ''
//           : NumberFormat('#,###').format(widget.table.price),
//     );
//     _staffController = TextEditingController();
//     _remarksController = TextEditingController(
//       text: widget.table.remark == '비고 없음' ? '' : widget.table.remark,
//     );
//     _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (mounted) setState(() {}); // 1초마다 타이머 렌더링
//     });
//   }

//   @override
//   void dispose() {
//     _localTimer?.cancel();
//     _nameController.dispose();
//     _phoneController.dispose();
//     for (var controller in _purchasesController) {
//       controller.dispose();
//     }
//     _staffController.dispose();
//     _priceController.dispose();
//     _personsController.dispose();
//     _remarksController.dispose();
//     super.dispose();
//   }

//   Future<void> _setTimerToDatabase(Duration duration) async {
//     // 몇 분 뒤인지 계산, 0초면 유지
//     DateTime? newEndTime;
//     if (duration.inSeconds > 0) {
//       newEndTime = DateTime.now().add(duration);
//     }

//     // Repo 함수 호출해서 데이터 전송
//     try {
//       await _repo.setTimer(
//         widget.companyId,
//         widget.table.tid,
//         newEndTime != null ? Timestamp.fromDate(newEndTime) : null,
//       );

//       // InfoAlert 창이 닫혔으면 setState 렌더링 시도를 아예 포기
//       if (!mounted) return;

//       setState(() {
//         widget.table.timer = newEndTime != null
//             ? Timestamp.fromDate(newEndTime)
//             : null;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('타이머 설정 중 오류가 발생하였습니다.'),
//         ),
//       );
//     }

//     // 로컬 변수도 바꿔서 화면에 즉시 렌더링 되게 함
//     setState(() {
//       widget.table.timer = newEndTime != null
//           ? Timestamp.fromDate(newEndTime)
//           : null;
//     });
//   }

//   // 쿠퍼티노 타임 피커
//   Future<void> _showCupertinoTimerPicker(BuildContext context) async {
//     if (widget.table.status != 'inuse') {
//       if (mounted) Navigator.pop(context); // info_alert 내리기
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('사용 중인 테이블만 타이머를 설정할 수 있습니다.'),
//           duration: Duration(seconds: 2),
//           behavior: SnackBarBehavior.floating,
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     // 00:00 시작
//     Duration selectedDuration = Duration.zero;

//     // await => 빈 공간을 터치해 팝업을 닫을 때까지 기다림
//     await showCupertinoModalPopup<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return Container(
//           height: 300, // 상단바가 빠졌으니 높이를 살짝 줄임
//           color: CupertinoColors.systemBackground.resolveFrom(context),
//           child: SafeArea(
//             top: false,
//             child: CupertinoTimerPicker(
//               mode: CupertinoTimerPickerMode.hm, // mm:ss
//               minuteInterval: 5,
//               initialTimerDuration: Duration.zero, // 00:00 세팅
//               onTimerDurationChanged: (Duration newDuration) {
//                 // 룰렛을 굴릴 때마다 변수에 저장만
//                 selectedDuration = newDuration;
//               },
//             ),
//           ),
//         );
//       },
//     );

//     // 팝업이 닫히면 서버로 전송
//     if (selectedDuration.inSeconds > 0) {
//       final messenger = ScaffoldMessenger.of(context);
//       final navigator = Navigator.of(context);
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(child: CircularProgressIndicator()),
//       );
//       // 타이머 db로 보내기
//       await _setTimerToDatabase(selectedDuration);

//       navigator.pop(); // 로딩창 끄기
//       navigator.pop(); // info 내리기
//       messenger.showSnackBar(
//         SnackBar(
//           content: Text("타이머 설정이 완료되었습니다."),
//           duration: Duration(seconds: 2),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   // 타이머 해제
//   void _showCancelTimerDialog() {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('타이머 해제'),
//         content: const Text('타이머를 해제하시겠습니까?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext), // 아니오: 그냥 창 닫기
//             child: const Text('아니오', style: TextStyle(color: Colors.black)),
//           ),
//           TextButton(
//             onPressed: () async {
//               final messenger = ScaffoldMessenger.of(context);
//               final navigator = Navigator.of(context);

//               Navigator.pop(dialogContext); // 해제하시겠습니까? 창 닫기

//               showDialog(
//                 context: context,
//                 barrierDismissible: false,
//                 builder: (context) =>
//                     const Center(child: CircularProgressIndicator()),
//               );
//               // 해제 사실 db로 보내기
//               await _setTimerToDatabase(Duration.zero);

//               navigator.pop(); // 로딩창 끄기
//               navigator.pop(); // info 내리기
//               messenger.showSnackBar(
//                 SnackBar(
//                   content: Text("타이머가 해제되었습니다."),
//                   duration: Duration(seconds: 2),
//                   behavior: SnackBarBehavior.floating,
//                 ),
//               );
//             },
//             child: const Text('예', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: _fetchCurrentUser(),
//       builder: (context, userSnapshot) {
//         if (!userSnapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final currentUser = userSnapshot.data!;

//         // 해당 스태프 이름이 미리 채워지게 하는 코드
//         if (_staffController.text.isEmpty) {
//           if (widget.table.staff == '스태프 미지정' || widget.table.staff.isEmpty) {
//             _staffController.text = currentUser.username;
//           } else {
//             _staffController.text = widget.table.staff;
//           }
//         }

//         return GestureDetector(
//           behavior: HitTestBehavior.opaque,
//           onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
//           child: AlertDialog(
//             title: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(child: Text('${widget.table.tablename} 정보 등록')),
//                 InkWell(
//                   onTap: () => widget.table.timer != null
//                       ? _showCancelTimerDialog()
//                       : _showCupertinoTimerPicker(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     child: widget.table.timer != null
//                         ? Icon(Icons.timer_off)
//                         : Icon(Icons.timer),
//                   ),
//                 ),
//               ],
//             ),
//             content: SizedBox(
//               width: MediaQuery.of(context).size.width * 0.9,
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: _nameController,
//                       decoration: const InputDecoration(labelText: '손님 이름'),
//                     ),
//                     TextField(
//                       controller: _phoneController,
//                       decoration: InputDecoration(
//                         labelText: '전화 번호',
//                         suffixIcon: IconButton(
//                           icon: Icon(FontAwesomeIcons.copy, size: 20),
//                           onPressed: () {
//                             final phoneNumber = _phoneController.text;
//                             if (phoneNumber.isNotEmpty) {
//                               Clipboard.setData(
//                                 ClipboardData(text: phoneNumber),
//                               );
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text('번호 복사 완료'),
//                                   duration: Duration(seconds: 2),
//                                   behavior: SnackBarBehavior.floating,
//                                   backgroundColor: Colors.black,
//                                 ),
//                               );
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text('복사할 번호가 없습니다. 번호를 먼저 등록해주세요.'),
//                                   duration: Duration(seconds: 2),
//                                   behavior: SnackBarBehavior.floating,
//                                   backgroundColor: Colors.red,
//                                 ),
//                               );
//                             }
//                           },
//                         ),
//                       ),
//                       keyboardType: TextInputType.phone,
//                       inputFormatters: [PhoneNumberFormatter()],
//                     ),
//                     Column(
//                       children: [
//                         for (int i = 0; i < _purchasesController.length; i++)
//                           TextField(
//                             controller: _purchasesController[i],
//                             decoration: InputDecoration(
//                               labelText: i == 0 ? '구매 목록' : '추가 구매 $i',
//                               suffixIcon: i == 0
//                                   ? IconButton(
//                                       icon: Icon(Icons.add_circle_outline),
//                                       onPressed: () {
//                                         setState(() {
//                                           _purchasesController.add(
//                                             TextEditingController(),
//                                           );
//                                         });
//                                       },
//                                     )
//                                   : IconButton(
//                                       icon: Icon(
//                                         Icons.remove_circle_outline_outlined,
//                                       ),
//                                       onPressed: () {
//                                         setState(() {
//                                           _purchasesController[i].dispose();
//                                           _purchasesController.removeAt(i);
//                                         });
//                                       },
//                                     ),
//                             ),
//                             maxLines: null,
//                             keyboardType: TextInputType.multiline,
//                           ),
//                       ],
//                     ),
//                     TextField(
//                       controller: _priceController,
//                       keyboardType: TextInputType.phone,
//                       decoration: const InputDecoration(labelText: '가격'),
//                       inputFormatters: [PriceFormatters()],
//                     ),
//                     TextField(
//                       controller: _personsController,
//                       decoration: const InputDecoration(labelText: '인원'),
//                       keyboardType: TextInputType.phone,
//                     ),
//                     TextField(
//                       controller: _staffController,
//                       decoration: const InputDecoration(labelText: '담당 스태프'),
//                       maxLines: null,
//                       keyboardType: TextInputType.multiline,
//                     ),
//                     TextField(
//                       controller: _remarksController,
//                       decoration: const InputDecoration(labelText: '비고(특이사항)'),
//                       maxLines: null,
//                       keyboardType: TextInputType.multiline,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             actions: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 4),
//                       child: FittedBox(
//                         fit: BoxFit.scaleDown,
//                         child: TextButton(
//                           onPressed: () => Navigator.pop(context),
//                           child: const Text(
//                             '취소',
//                             style: TextStyle(color: Colors.black),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 4),
//                       child: FittedBox(
//                         fit: BoxFit.scaleDown,
//                         child: TextButton(
//                           onPressed: () async {
//                             if (widget.table.status != 'inuse') {
//                               Navigator.pop(context); // 현재 알림창 닫기
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text(
//                                     '빈 테이블을 아웃 시킬 수 없습니다. 손님을 먼저 등록해주세요.',
//                                   ),
//                                   duration: Duration(seconds: 2),
//                                 ),
//                               );
//                               return;
//                             }

//                             // 취소=fasle, 아웃=true
//                             final bool? confirmOut = await showDialog<bool>(
//                               context: context,
//                               builder: (context) => AlertDialog(
//                                 title: const Text('아웃 확인'),
//                                 content: Text(
//                                   '${widget.table.tablename} 테이블을 아웃 처리하시겠습니까?',
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(
//                                       context,
//                                       false,
//                                     ), // '취소' 누르면 false 반환
//                                     child: const Text(
//                                       '취소',
//                                       style: TextStyle(color: Colors.black),
//                                     ),
//                                   ),
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(
//                                       context,
//                                       true,
//                                     ), // '확정' 누르면 true 반환
//                                     child: const Text(
//                                       '아웃 확정',
//                                       style: TextStyle(color: Colors.red),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                             if (confirmOut != true) return;

//                             showDialog(
//                               context: context,
//                               barrierDismissible: false,
//                               builder: (context) => const Center(
//                                 child: CircularProgressIndicator(),
//                               ),
//                             );
//                             try {
//                               await _repo.clearTable(
//                                 widget.companyId,
//                                 widget.table.tid,
//                                 currentUser.username,
//                               );
//                               if (context.mounted) Navigator.pop(context);
//                               if (context.mounted) Navigator.pop(context);
//                             } catch (e) {
//                               if (context.mounted) Navigator.pop(context);
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text(
//                                     '인터넷 연결이 불안정하거나 에러가 발생했습니다. 다시 시도해주세요.',
//                                   ),
//                                   duration: Duration(
//                                     seconds: 2,
//                                   ), // 2초 뒤 자연스럽게 사라짐
//                                 ),
//                               );
//                               print("아웃 중 에러 발생 $e");
//                             }
//                           },
//                           child: const Text(
//                             '아웃',
//                             style: TextStyle(color: Colors.red),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Padding(
//                       padding: EdgeInsetsGeometry.symmetric(horizontal: 4),
//                       child: FittedBox(
//                         fit: BoxFit.scaleDown,
//                         child: TextButton(
//                           onPressed: () async {
//                             if (widget.table.status != 'inuse') {
//                               Navigator.pop(context); // 현재 알림창 닫기
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text(
//                                     '빈 테이블은 이동할 수 없습니다. 손님을 먼저 등록해주세요.',
//                                   ),
//                                   duration: Duration(seconds: 2),
//                                 ),
//                               );
//                               return;
//                             }
//                             Navigator.pop(context); // 현재 알림창 닫기
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => MoveScreen(
//                                   companyId: widget.companyId,
//                                   fromTable: widget.table,
//                                 ),
//                               ),
//                             );
//                           },
//                           child: const Text(
//                             '이동',
//                             style: TextStyle(color: Colors.blue),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 4),
//                       child: FittedBox(
//                         fit: BoxFit.scaleDown,
//                         child: TextButton(
//                           onPressed: () async {
//                             // 필수 정보 입력 확인 (이름, 바틀 등)

//                             final purchases = _purchasesController
//                                 .map((controller) => controller.text.trim())
//                                 .where((text) => text.isNotEmpty)
//                                 .toList();

//                             if (_nameController.text.isNotEmpty ||
//                                 purchases.isNotEmpty ||
//                                 _phoneController.text.isNotEmpty ||
//                                 _remarksController.text.isNotEmpty ||
//                                 _personsController.text.isNotEmpty) {
//                               showDialog(
//                                 context: context,
//                                 barrierDismissible: false,
//                                 builder: (context) => const Center(
//                                   child: CircularProgressIndicator(),
//                                 ),
//                               );
//                               try {
//                                 await _repo.registerBottleKeep(
//                                   company: widget.companyId,
//                                   tid: widget.table.tid,
//                                   customer: _nameController.text.trim(),
//                                   phonenumber: _phoneController.text.trim(),
//                                   staff: widget.table.staff.isEmpty
//                                       ? currentUser.username
//                                       : "${widget.table.staff}, ${currentUser.username}",
//                                   price:
//                                       int.tryParse(
//                                         _priceController.text
//                                             .replaceAll(',', '')
//                                             .trim(),
//                                       ) ??
//                                       0,
//                                   persons:
//                                       int.tryParse(
//                                         _personsController.text.trim(),
//                                       ) ??
//                                       0, // 기존 인원 유지
//                                   purchases: purchases,
//                                   remark: _remarksController.text.trim(),
//                                   isFirstRegister:
//                                       widget.table.status == 'available',
//                                 );
//                                 if (context.mounted) Navigator.pop(context);
//                                 if (context.mounted) Navigator.pop(context);
//                               } catch (e) {
//                                 if (context.mounted)
//                                   Navigator.pop(context); // 프로그레스서클 끄기
//                                 // 레이스 컨디션 오류면
//                                 if (e.toString().contains('ALREADY_IN_USE')) {
//                                   if (context.mounted)
//                                     Navigator.pop(context); // 정보 입력창 끄기
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text(
//                                         "다른 직원이 이미 등록한 테이블입니다.",
//                                       ),
//                                       backgroundColor: Colors.red,
//                                     ),
//                                   );
//                                 } else if (e.toString().contains(
//                                   'NOT_IN_USE',
//                                 )) {
//                                   if (context.mounted)
//                                     Navigator.pop(context); // 정보 입력창 끄기
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text(
//                                         "다른 직원이 이미 아웃 시킨 테이블입니다.",
//                                       ),
//                                       backgroundColor: Colors.red,
//                                     ),
//                                   );
//                                 } else {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text(
//                                         '인터넷 연결이 불안정하거나 에러가 발생했습니다. 다시 시도해주세요.',
//                                       ),
//                                       duration: Duration(
//                                         seconds: 2,
//                                       ), // 2초 뒤 자연스럽게 사라짐
//                                     ),
//                                   );
//                                 }
//                                 print('등록 중 에러 발생 $e');
//                               }
//                             }
//                           },
//                           child: const Text('등록'),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }